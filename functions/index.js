const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { defineString } = require("firebase-functions/params");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { CloudTasksClient } = require("@google-cloud/tasks");
const { DateTime } = require("luxon");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();

const DEFAULT_KEY = "2Ioz6tXZgE3jc5k1S6dKvRm6VteCEfKH";
const DEFAULT_IV = "morpheus-iv-0001";
const REGION = "europe-west1";
const TASKS_QUEUE = "card-reminders";
const TASKS_LOCATION = REGION;
const TASKS_TARGET = "sendCardReminderTask";
const tasksWebhookSecret = defineString("TASKS_WEBHOOK_SECRET", {
  default: "",
});
const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "";
const cardEncryptionKey = defineString("CARD_ENCRYPTION_KEY", {
  default: DEFAULT_KEY,
});
const cardEncryptionIv = defineString("CARD_ENCRYPTION_IV", {
  default: DEFAULT_IV,
});

const MAX_TOKENS_PER_BATCH = 500;
const tasksClient = new CloudTasksClient();
let queueReady = null;

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}


function parseOffsets(raw) {
  if (Array.isArray(raw)) {
    return raw
      .map((value) => Number(value))
      .filter((value) => Number.isFinite(value) && value > 0);
  }
  if (typeof raw === "string") {
    return raw
      .split(",")
      .map((value) => Number(value.trim()))
      .filter((value) => Number.isFinite(value) && value > 0);
  }
  return [];
}

function resolveZone(zone) {
  if (!zone || typeof zone !== "string") return "UTC";
  const dt = DateTime.now().setZone(zone);
  return dt.isValid ? zone : "UTC";
}

function safeDateInZone(year, month, day, zone) {
  const base = DateTime.fromObject({ year, month, day: 1 }, { zone });
  const clampedDay = clamp(day, 1, base.daysInMonth);
  return DateTime.fromObject(
    { year, month, day: clampedDay, hour: 0, minute: 0, second: 0 },
    { zone }
  );
}

function nextDueInZone(card, zone, anchor) {
  const now = anchor ?? DateTime.now().setZone(zone);
  const billingDay = clamp(Number(card.billingDay ?? 1), 1, 28);
  const graceDays = clamp(Number(card.graceDays ?? 0), 0, 90);

  const currentBilling = safeDateInZone(now.year, now.month, billingDay, zone);
  const cycleEnd = now < currentBilling
    ? safeDateInZone(now.year, now.month - 1, billingDay, zone)
    : currentBilling;

  const dueDay = clamp(
    billingDay + graceDays,
    1,
    cycleEnd.daysInMonth
  );
  let due = safeDateInZone(cycleEnd.year, cycleEnd.month, dueDay, zone);

  if (due < now) {
    const nextCycleEnd = safeDateInZone(
      cycleEnd.year,
      cycleEnd.month + 1,
      billingDay,
      zone
    );
    const nextDueDay = clamp(
      billingDay + graceDays,
      1,
      nextCycleEnd.daysInMonth
    );
    due = safeDateInZone(
      nextCycleEnd.year,
      nextCycleEnd.month,
      nextDueDay,
      zone
    );
  }

  return due;
}

function dateKey(dt) {
  return dt.toFormat("yyyy-LL-dd");
}

function reminderScheduleForOffset(card, zone, offset, anchor) {
  const now = anchor ?? DateTime.now().setZone(zone);
  let due = nextDueInZone(card, zone, now);
  let scheduledAt = due.minus({ days: offset }).startOf("day");
  if (scheduledAt <= now) {
    due = nextDueInZone(card, zone, due.plus({ days: 1 }));
    scheduledAt = due.minus({ days: offset }).startOf("day");
  }
  return { due, scheduledAt };
}

function taskIdFor(uid, cardId, offset, dueKey) {
  const raw = `${uid}:${cardId}:${offset}:${dueKey}`;
  const hash = crypto.createHash("sha1").update(raw).digest("hex");
  return `card-${hash.slice(0, 24)}`;
}

function functionUrl(name) {
  if (!projectId) {
    throw new Error("Missing project id for function URL");
  }
  return `https://${REGION}-${projectId}.cloudfunctions.net/${name}`;
}

async function ensureQueue() {
  if (queueReady) return queueReady;
  if (!projectId) {
    throw new Error("Missing project id for Cloud Tasks");
  }
  const queuePath = tasksClient.queuePath(
    projectId,
    TASKS_LOCATION,
    TASKS_QUEUE
  );
  queueReady = tasksClient
    .getQueue({ name: queuePath })
    .catch((err) => {
      if (err.code !== 5) throw err;
      return tasksClient.createQueue({
        parent: tasksClient.locationPath(projectId, TASKS_LOCATION),
        queue: {
          name: queuePath,
          rateLimits: {
            maxDispatchesPerSecond: 20,
            maxConcurrentDispatches: 50,
          },
        },
      });
    });
  return queueReady;
}

async function createReminderTask({
  uid,
  cardId,
  offset,
  dueKey,
  scheduleAt,
}) {
  await ensureQueue();
  const queuePath = tasksClient.queuePath(
    projectId,
    TASKS_LOCATION,
    TASKS_QUEUE
  );
  const taskId = taskIdFor(uid, cardId, offset, dueKey);
  const taskName = tasksClient.taskPath(
    projectId,
    TASKS_LOCATION,
    TASKS_QUEUE,
    taskId
  );
  const url = functionUrl(TASKS_TARGET);
  const payload = { uid, cardId, offset, dueKey };
  const headers = { "Content-Type": "application/json" };
  const secret = tasksWebhookSecret.value();
  if (secret) {
    headers["X-Task-Secret"] = secret;
  }
  const scheduleSeconds = Math.floor(scheduleAt.toSeconds());
  const task = {
    name: taskName,
    scheduleTime: { seconds: scheduleSeconds },
    httpRequest: {
      httpMethod: "POST",
      url,
      headers,
      body: Buffer.from(JSON.stringify(payload)),
    },
  };
  try {
    await tasksClient.createTask({ parent: queuePath, task });
  } catch (err) {
    if (err.code !== 6) throw err;
  }
  return { name: taskName, offset, dueKey, scheduledAt: scheduleAt.toISO() };
}

async function deleteTasksByName(taskNames) {
  const deletes = taskNames.map(async (name) => {
    try {
      await tasksClient.deleteTask({ name });
    } catch (err) {
      if (err.code !== 5) throw err;
    }
  });
  await Promise.allSettled(deletes);
}

async function clearCardTasks(uid, cardId) {
  const ref = db
    .collection("users")
    .doc(uid)
    .collection("cardReminderTasks")
    .doc(cardId);
  const snap = await ref.get();
  if (!snap.exists) return;
  const tasks = snap.data()?.tasks ?? [];
  const names = tasks.map((t) => t.name).filter(Boolean);
  if (names.length > 0) {
    await deleteTasksByName(names);
  }
  await ref.delete();
}

async function storeCardTasks(uid, cardId, zone, tasks) {
  const ref = db
    .collection("users")
    .doc(uid)
    .collection("cardReminderTasks")
    .doc(cardId);
  await ref.set(
    {
      timeZone: zone,
      tasks,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function scheduleCardTasks(uid, cardId, card, zone) {
  if (!card.reminderEnabled) return [];
  const offsets = parseOffsets(card.reminderOffsets);
  if (offsets.length === 0) return [];
  const now = DateTime.now().setZone(zone);
  const tasks = [];
  for (const offset of offsets) {
    const { due, scheduledAt } = reminderScheduleForOffset(
      card,
      zone,
      offset,
      now
    );
    const dueKey = dateKey(due);
    const task = await createReminderTask({
      uid,
      cardId,
      offset,
      dueKey,
      scheduleAt: scheduledAt.toUTC(),
    });
    tasks.push(task);
  }
  await storeCardTasks(uid, cardId, zone, tasks);
  return tasks;
}

async function resolveUserTimezone(uid) {
  const snap = await db.collection("users").doc(uid).get();
  const zone = snap.exists ? snap.data()?.timezone : null;
  return resolveZone(zone);
}

function amountForCurrency(expense, target) {
  const amount = Number(expense.amount ?? 0);
  const currency = expense.currency;
  if (target === currency) return amount;
  if (target === "EUR" && expense.amountEur != null) {
    return Number(expense.amountEur);
  }
  if (expense.budgetCurrency === target) {
    if (expense.amountInBudgetCurrency != null) {
      return Number(expense.amountInBudgetCurrency);
    }
    if (expense.budgetRate != null) {
      return amount * Number(expense.budgetRate);
    }
  }
  return amount;
}


function decryptMaybe(value) {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }
  try {
    const decipher = crypto.createDecipheriv(
      "aes-256-cbc",
      Buffer.from(cardEncryptionKey.value(), "utf8"),
      Buffer.from(cardEncryptionIv.value(), "utf8")
    );
    let out = decipher.update(value, "base64", "utf8");
    out += decipher.final("utf8");
    return out;
  } catch (_) {
    return value;
  }
}

function chunkTokens(tokens) {
  const out = [];
  for (let i = 0; i < tokens.length; i += MAX_TOKENS_PER_BATCH) {
    out.push(tokens.slice(i, i + MAX_TOKENS_PER_BATCH));
  }
  return out;
}

async function getUserTokens(uid, cache) {
  if (cache.has(uid)) {
    return cache.get(uid);
  }
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("deviceTokens")
    .get();
  const tokens = snap.docs
    .map((doc) => doc.data().token || doc.id)
    .filter((token) => typeof token === "string" && token.length > 0);
  cache.set(uid, tokens);
  return tokens;
}

async function sendToTokens({ uid, tokens, message }) {
  let successCount = 0;
  let failureCount = 0;

  for (const batch of chunkTokens(tokens)) {
    const response = await admin.messaging().sendEachForMulticast({
      ...message,
      tokens: batch,
    });
    successCount += response.successCount;
    failureCount += response.failureCount;

    const deletes = [];
    response.responses.forEach((res, idx) => {
      if (res.success) return;
      const code = res.error?.code ?? "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        const token = batch[idx];
        deletes.push(
          db
            .collection("users")
            .doc(uid)
            .collection("deviceTokens")
            .doc(token)
            .delete()
        );
      }
    });

    if (deletes.length > 0) {
      await Promise.allSettled(deletes);
    }
  }

  return { successCount, failureCount };
}

exports.sendCardReminders = onSchedule(
  { schedule: "0 3 * * *", timeZone: "UTC", region: REGION },
  async () => {
    const now = DateTime.utc();
    const cardsSnap = await db
      .collectionGroup("cards")
      .where("reminderEnabled", "==", true)
      .get();
    const zoneCache = new Map();
    let scheduled = 0;
    let skipped = 0;

    for (const cardDoc of cardsSnap.docs) {
      const card = cardDoc.data();
      const uid = cardDoc.ref.parent.parent?.id;
      if (!uid) continue;

      let zone = zoneCache.get(uid);
      if (!zone) {
        zone = await resolveUserTimezone(uid);
        zoneCache.set(uid, zone);
      }

      const tasksRef = db
        .collection("users")
        .doc(uid)
        .collection("cardReminderTasks")
        .doc(cardDoc.id);
      const taskSnap = await tasksRef.get();
      const offsets = parseOffsets(card.reminderOffsets);
      const desiredOffsets = [...offsets].sort((a, b) => a - b);
      let needsRefresh = offsets.length > 0;

      if (taskSnap.exists) {
        const data = taskSnap.data();
        const tasks = Array.isArray(data?.tasks) ? data.tasks : [];
        const existingOffsets = tasks
          .map((t) => Number(t.offset))
          .filter((v) => Number.isFinite(v))
          .sort((a, b) => a - b);
        const sameOffsets =
          JSON.stringify(existingOffsets) === JSON.stringify(desiredOffsets);
        const sameZone = data?.timeZone === zone;
        const futureTasks = tasks.every((t) => {
          if (!t?.scheduledAt) return false;
          const dt = DateTime.fromISO(t.scheduledAt);
          return dt.isValid && dt.toUTC() > now;
        });
        needsRefresh = !(sameOffsets && sameZone && futureTasks);
      }

      if (!needsRefresh) {
        skipped += 1;
        continue;
      }

      await clearCardTasks(uid, cardDoc.id);
      const tasks = await scheduleCardTasks(uid, cardDoc.id, card, zone);
      if (tasks.length > 0) {
        scheduled += 1;
      } else {
        skipped += 1;
      }
    }

    logger.info("Card reminder task reconcile complete", {
      cards: cardsSnap.size,
      scheduled,
      skipped,
    });
  }
);

exports.syncCardReminders = onDocumentWritten(
  { region: REGION, document: "users/{uid}/cards/{cardId}" },
  async (event) => {
    const uid = event.params.uid;
    const cardId = event.params.cardId;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!after) {
      await clearCardTasks(uid, cardId);
      return;
    }

    if (!after.reminderEnabled) {
      await clearCardTasks(uid, cardId);
      return;
    }

    const beforeOffsets = parseOffsets(before?.reminderOffsets).sort();
    const afterOffsets = parseOffsets(after.reminderOffsets).sort();
    const changed =
      !before ||
      Number(before.billingDay ?? 0) !== Number(after.billingDay ?? 0) ||
      Number(before.graceDays ?? 0) !== Number(after.graceDays ?? 0) ||
      before.reminderEnabled !== after.reminderEnabled ||
      JSON.stringify(beforeOffsets) !== JSON.stringify(afterOffsets);

    if (!changed) return;

    const zone = await resolveUserTimezone(uid);
    await clearCardTasks(uid, cardId);
    await scheduleCardTasks(uid, cardId, after, zone);
  }
);

exports.syncUserTimezone = onDocumentWritten(
  { region: REGION, document: "users/{uid}" },
  async (event) => {
    const uid = event.params.uid;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after) return;
    const beforeZone = resolveZone(before?.timezone);
    const afterZone = resolveZone(after?.timezone);
    if (beforeZone === afterZone) return;

    const cardsSnap = await db
      .collection("users")
      .doc(uid)
      .collection("cards")
      .where("reminderEnabled", "==", true)
      .get();
    for (const cardDoc of cardsSnap.docs) {
      const card = cardDoc.data();
      await clearCardTasks(uid, cardDoc.id);
      await scheduleCardTasks(uid, cardDoc.id, card, afterZone);
    }
  }
);

exports.sendCardReminderTask = onRequest(
  { region: REGION },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }
    const secret = tasksWebhookSecret.value();
    if (secret && req.get("X-Task-Secret") !== secret) {
      res.status(403).send("Forbidden");
      return;
    }

    const uid = req.body?.uid;
    const cardId = req.body?.cardId;
    const offset = Number(req.body?.offset);
    const dueKey = req.body?.dueKey;

    if (!uid || !cardId || !Number.isFinite(offset) || offset <= 0) {
      res.status(400).send("Invalid payload");
      return;
    }

    const cardRef = db
      .collection("users")
      .doc(uid)
      .collection("cards")
      .doc(cardId);
    const cardSnap = await cardRef.get();
    if (!cardSnap.exists) {
      await clearCardTasks(uid, cardId);
      res.status(200).send("Card missing");
      return;
    }

    const card = cardSnap.data();
    if (!card?.reminderEnabled) {
      await clearCardTasks(uid, cardId);
      res.status(200).send("Reminders disabled");
      return;
    }

    const offsets = parseOffsets(card.reminderOffsets);
    if (!offsets.includes(offset)) {
      res.status(200).send("Offset disabled");
      return;
    }

    const zone = await resolveUserTimezone(uid);
    const due = dueKey
      ? DateTime.fromFormat(dueKey, "yyyy-LL-dd", { zone })
      : nextDueInZone(card, zone, DateTime.now().setZone(zone));
    const resolvedDue = due.isValid
      ? due
      : nextDueInZone(card, zone, DateTime.now().setZone(zone));
    const resolvedDueKey = dateKey(resolvedDue);

    const logId = `${cardId}_${offset}_${resolvedDueKey}`;
    const logRef = db
      .collection("users")
      .doc(uid)
      .collection("reminderLogs")
      .doc(logId);
    const logSnap = await logRef.get();
    if (logSnap.exists) {
      res.status(200).send("Already sent");
      return;
    }

    const tokens = await getUserTokens(uid, new Map());
    if (tokens.length === 0) {
      res.status(200).send("No tokens");
      return;
    }

    const bankName =
      decryptMaybe(card.bankName) || card.bankNamePlain || "Card";
    const title = "Card payment due soon";
    const body = `${bankName} due on ${resolvedDueKey}`;

    const message = {
      notification: { title, body },
      data: {
        type: "card_reminder",
        cardId,
        dueDate: resolvedDueKey,
        offsetDays: String(offset),
      },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "10" } },
    };

    const result = await sendToTokens({ uid, tokens, message });
    await logRef.set({
      cardId,
      offsetDays: offset,
      dueDate: resolvedDueKey,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      tokenCount: tokens.length,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });

    const nextAnchor = resolvedDue.plus({ days: 1 });
    const { due: nextDue, scheduledAt } = reminderScheduleForOffset(
      card,
      zone,
      offset,
      nextAnchor
    );
    const nextTask = await createReminderTask({
      uid,
      cardId,
      offset,
      dueKey: dateKey(nextDue),
      scheduleAt: scheduledAt.toUTC(),
    });

    const tasksRef = db
      .collection("users")
      .doc(uid)
      .collection("cardReminderTasks")
      .doc(cardId);
    const tasksSnap = await tasksRef.get();
    const tasks = Array.isArray(tasksSnap.data()?.tasks)
      ? tasksSnap.data().tasks.filter((t) => Number(t.offset) !== offset)
      : [];
    tasks.push(nextTask);
    await storeCardTasks(uid, cardId, zone, tasks);

    res.status(200).send("ok");
  }
);

exports.sendTestPush = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const data = request.data ?? {};
  const uid = request.auth.uid;
  const title =
    typeof data.title === "string" && data.title.trim().length > 0
      ? data.title.trim()
      : "Test notification";
  const body =
    typeof data.body === "string" && data.body.trim().length > 0
      ? data.body.trim()
      : "This is a test push from Morpheus.";

  const tokens = await getUserTokens(uid, new Map());
  if (tokens.length === 0) {
    return {
      tokenCount: 0,
      successCount: 0,
      failureCount: 0,
    };
  }

  const message = {
    notification: { title, body },
    data: {
      type: "test_push",
      cardId:
        typeof data.cardId === "string" && data.cardId.length > 0
          ? data.cardId
          : "",
    },
    android: { priority: "high" },
    apns: { headers: { "apns-priority": "10" } },
  };

  const result = await sendToTokens({ uid, tokens, message });
  return {
    tokenCount: tokens.length,
    successCount: result.successCount,
    failureCount: result.failureCount,
  };
});

exports.computeMonthlyCardSnapshots = onSchedule(
  {
    schedule: "15 4 1 * *",
    timeZone: "UTC",
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
    maxInstances: 1,
  },
  async () => {
    const now = DateTime.utc();
    const targetMonth = now.minus({ months: 1 }).startOf("month");
    const monthKey = targetMonth.toFormat("yyyy-LL");
    const cardsSnap = await db.collectionGroup("cards").get();
    const cardsByUser = new Map();
    for (const doc of cardsSnap.docs) {
      const uid = doc.ref.parent.parent?.id;
      if (!uid) continue;
      const list = cardsByUser.get(uid) ?? [];
      list.push({ id: doc.id, data: doc.data() });
      cardsByUser.set(uid, list);
    }
    let processed = 0;
    let skipped = 0;

    for (const [uid, cards] of cardsByUser.entries()) {
      const userSnap = await db.collection("users").doc(uid).get();
      const zone = resolveZone(userSnap.data()?.timezone);
      const monthStart = DateTime.fromObject(
        {
          year: targetMonth.year,
          month: targetMonth.month,
          day: 1,
          hour: 0,
          minute: 0,
          second: 0,
        },
        { zone }
      );
      const monthEnd = monthStart.plus({ months: 1 });
      const startMs = monthStart.toMillis();
      const endMs = monthEnd.toMillis();

      const cardsById = new Map();
      cards.forEach((card) => {
        cardsById.set(card.id, card.data);
      });

      const expensesSnap = await db
        .collection("users")
        .doc(uid)
        .collection("expenses")
        .where("date", ">=", startMs)
        .where("date", "<", endMs)
        .get();

      const displayCurrency =
        expensesSnap.docs[0]?.data()?.currency || "EUR";
      const summary = {};

      for (const [cardId, card] of cardsById.entries()) {
        summary[cardId] = {
          charges: 0,
          payments: 0,
          netSpend: 0,
          usageLimit:
            card.usageLimit != null ? Number(card.usageLimit) : null,
          utilization: null,
          billingDay: Number(card.billingDay ?? 1),
          graceDays: Number(card.graceDays ?? 0),
        };
      }

      for (const doc of expensesSnap.docs) {
        const expense = doc.data();
        const type = (expense.paymentSourceType || "cash").toLowerCase();
        if (type !== "card") continue;
        const cardId = expense.paymentSourceId;
        if (!cardId || !summary[cardId]) continue;

        const amount = amountForCurrency(expense, displayCurrency);
        if (amount >= 0) {
          summary[cardId].charges += amount;
        } else {
          summary[cardId].payments += Math.abs(amount);
        }
      }

      for (const cardId of Object.keys(summary)) {
        const cardSummary = summary[cardId];
        const net = cardSummary.charges - cardSummary.payments;
        cardSummary.netSpend = net < 0 ? 0 : net;
        if (cardSummary.usageLimit && cardSummary.usageLimit > 0) {
          cardSummary.utilization =
            cardSummary.netSpend / cardSummary.usageLimit;
        }
      }

      await db
        .collection("users")
        .doc(uid)
        .collection("cardSnapshots")
        .doc(monthKey)
        .set(
          {
            monthKey,
            periodStart: startMs,
            periodEnd: endMs,
            displayCurrency,
            cards: summary,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      processed += 1;
    }

    logger.info("Monthly card snapshots complete", {
      monthKey,
      processed,
      skipped,
    });
  }
);
