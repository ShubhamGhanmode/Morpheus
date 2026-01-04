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
const CLASSIFIER_MODEL_COLLECTION = "expense_category_model";
const CLASSIFIER_MODEL_DOC = "meta";
const CLASSIFIER_TOKENS_SUBCOLLECTION = "tokens";
const CLASSIFIER_LEDGER_SUBCOLLECTION = "ledger";
const CLASSIFIER_MAX_TOKENS = 20;
const CLASSIFIER_MIN_TOKEN_LENGTH = 2;
const CLASSIFIER_MAX_TOKEN_LENGTH = 32;
const CLASSIFIER_PRIOR_SMOOTHING = 1;
const CLASSIFIER_TOKEN_SMOOTHING = 1;
const CLASSIFIER_ENABLE_BIGRAMS = true;
const CLASSIFIER_ENABLE_STEMMING = true;
const CLASSIFIER_ENABLE_TFIDF = true;
const CLASSIFIER_MIN_DOCS_FOR_PREDICTION = 5;
const CLASSIFIER_STOPWORDS = new Set([
  "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
  "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
  "be", "have", "has", "had", "do", "does", "did", "will", "would",
  "could", "should", "may", "might", "must", "shall", "can", "need",
  "it", "its", "this", "that", "these", "those", "i", "you", "he",
  "she", "we", "they", "my", "your", "his", "her", "our", "their",
  "me", "him", "us", "them", "what", "which", "who", "whom", "where",
  "when", "why", "how", "all", "each", "every", "both", "few", "more",
  "some", "any", "no", "not", "only", "own", "same", "so", "than",
  "too", "very", "just", "also", "now", "here", "there", "then",
  "payment", "paid", "pay", "bought", "purchase", "purchased", "bill",
]);

// ============================================================================
// Porter Stemmer Implementation (simplified for expense titles)
// Reduces words to their root form: "running" -> "run", "purchases" -> "purchas"
// ============================================================================

function porterStem(word) {
  if (!word || word.length < 3) return word;

  let stem = word.toLowerCase();

  // Step 1a: Handle plurals and past tenses
  if (stem.endsWith("sses")) {
    stem = stem.slice(0, -2);
  } else if (stem.endsWith("ies")) {
    stem = stem.slice(0, -2);
  } else if (stem.endsWith("ss")) {
    // Keep as is
  } else if (stem.endsWith("s") && stem.length > 3) {
    stem = stem.slice(0, -1);
  }

  // Step 1b: Handle -ed and -ing
  if (stem.endsWith("eed")) {
    if (stem.length > 4) stem = stem.slice(0, -1);
  } else if (stem.endsWith("ed") && containsVowel(stem.slice(0, -2))) {
    stem = stem.slice(0, -2);
    stem = handleStep1bSuffix(stem);
  } else if (stem.endsWith("ing") && containsVowel(stem.slice(0, -3))) {
    stem = stem.slice(0, -3);
    stem = handleStep1bSuffix(stem);
  }

  // Step 1c: y -> i
  if (stem.endsWith("y") && stem.length > 2 && !isVowel(stem[stem.length - 2])) {
    stem = stem.slice(0, -1) + "i";
  }

  // Step 2: Map double suffixes to single ones
  const step2Map = {
    "ational": "ate", "tional": "tion", "enci": "ence", "anci": "ance",
    "izer": "ize", "isation": "ize", "ization": "ize", "ation": "ate",
    "ator": "ate", "alism": "al", "iveness": "ive", "fulness": "ful",
    "ousness": "ous", "aliti": "al", "iviti": "ive", "biliti": "ble",
    "alli": "al", "entli": "ent", "eli": "e", "ousli": "ous",
  };
  for (const [suffix, replacement] of Object.entries(step2Map)) {
    if (stem.endsWith(suffix) && getMeasure(stem.slice(0, -suffix.length)) > 0) {
      stem = stem.slice(0, -suffix.length) + replacement;
      break;
    }
  }

  // Step 3: Handle -ful, -ness, etc.
  const step3Map = {
    "icate": "ic", "ative": "", "alize": "al", "iciti": "ic",
    "ical": "ic", "ful": "", "ness": "",
  };
  for (const [suffix, replacement] of Object.entries(step3Map)) {
    if (stem.endsWith(suffix) && getMeasure(stem.slice(0, -suffix.length)) > 0) {
      stem = stem.slice(0, -suffix.length) + replacement;
      break;
    }
  }

  // Step 4: Remove -ant, -ence, etc.
  const step4Suffixes = [
    "al", "ance", "ence", "er", "ic", "able", "ible", "ant", "ement",
    "ment", "ent", "ion", "ou", "ism", "ate", "iti", "ous", "ive", "ize",
  ];
  for (const suffix of step4Suffixes) {
    if (stem.endsWith(suffix) && getMeasure(stem.slice(0, -suffix.length)) > 1) {
      const base = stem.slice(0, -suffix.length);
      if (suffix === "ion" && (base.endsWith("s") || base.endsWith("t"))) {
        stem = base;
      } else if (suffix !== "ion") {
        stem = base;
      }
      break;
    }
  }

  // Step 5a: Remove trailing 'e'
  if (stem.endsWith("e")) {
    const base = stem.slice(0, -1);
    const m = getMeasure(base);
    if (m > 1 || (m === 1 && !endsWithCVC(base))) {
      stem = base;
    }
  }

  // Step 5b: Remove double consonant + 'l'
  if (stem.endsWith("ll") && getMeasure(stem.slice(0, -1)) > 1) {
    stem = stem.slice(0, -1);
  }

  return stem;
}

function isVowel(char) {
  return "aeiou".includes(char);
}

function containsVowel(str) {
  for (const char of str) {
    if (isVowel(char)) return true;
  }
  return false;
}

function getMeasure(str) {
  // Count VC sequences (consonant-vowel patterns)
  let count = 0;
  let prevVowel = false;
  for (const char of str) {
    const vowel = isVowel(char);
    if (prevVowel && !vowel) count++;
    prevVowel = vowel;
  }
  return count;
}

function endsWithCVC(str) {
  if (str.length < 3) return false;
  const c1 = !isVowel(str[str.length - 1]);
  const v = isVowel(str[str.length - 2]);
  const c2 = !isVowel(str[str.length - 3]);
  const lastChar = str[str.length - 1];
  return c1 && v && c2 && !"wxy".includes(lastChar);
}

function handleStep1bSuffix(stem) {
  if (stem.endsWith("at") || stem.endsWith("bl") || stem.endsWith("iz")) {
    return stem + "e";
  }
  // Double consonant -> single
  const lastTwo = stem.slice(-2);
  if (lastTwo[0] === lastTwo[1] && !"lsz".includes(lastTwo[0]) && !isVowel(lastTwo[0])) {
    return stem.slice(0, -1);
  }
  // Short word ending CVC
  if (getMeasure(stem) === 1 && endsWithCVC(stem)) {
    return stem + "e";
  }
  return stem;
}

// Common irregular word mappings for better matching
const IRREGULAR_WORDS = {
  "bought": "buy", "paid": "pay", "ate": "eat", "drank": "drink",
  "went": "go", "got": "get", "made": "make", "took": "take",
  "gave": "give", "found": "find", "thought": "think", "told": "tell",
  "became": "become", "left": "leave", "felt": "feel", "brought": "bring",
  "began": "begin", "kept": "keep", "held": "hold", "wrote": "write",
  "stood": "stand", "heard": "hear", "let": "let", "meant": "mean",
  "met": "meet", "ran": "run", "sat": "sit", "sent": "send",
  "spent": "spend", "built": "build", "lost": "lose", "caught": "catch",
};

function stemToken(token) {
  if (!CLASSIFIER_ENABLE_STEMMING) return token;
  // Check irregular words first
  if (IRREGULAR_WORDS[token]) return IRREGULAR_WORDS[token];
  // Apply Porter stemmer
  return porterStem(token);
}

// ============================================================================
// End of Stemmer
// ============================================================================

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

  let due = cycleEnd.plus({ days: graceDays });

  if (due < now) {
    const nextCycleEnd = safeDateInZone(
      cycleEnd.year,
      cycleEnd.month + 1,
      billingDay,
      zone
    );
    due = nextCycleEnd.plus({ days: graceDays });
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

async function getUserConfig(uid) {
  const snap = await db.collection("users").doc(uid).get();
  const data = snap.exists ? snap.data() : {};
  const zone = resolveZone(data?.timezone);
  const remindersEnabled = data?.cardRemindersEnabled !== false;
  const baseCurrency =
    typeof data?.baseCurrency === "string" && data.baseCurrency.length > 0
      ? data.baseCurrency
      : "EUR";
  return { zone, remindersEnabled, baseCurrency };
}

function amountForCurrency(expense, target) {
  const amount = Number(expense.amount ?? 0);
  const currency = expense.currency;
  if (target === currency) return amount;
  if (
    expense.baseCurrency === target &&
    expense.amountInBaseCurrency != null
  ) {
    return Number(expense.amountInBaseCurrency);
  }
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
  if (expense.baseCurrency === target && expense.baseRate != null) {
    return amount * Number(expense.baseRate);
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

function normalizeTitle(value) {
  if (typeof value !== "string") return "";
  return value.trim().toLowerCase();
}

function normalizeNumber(token) {
  // Normalize numbers to reduce vocabulary: 123.45 -> <NUM>, 2024 -> <YEAR>
  if (/^\d{4}$/.test(token)) {
    const num = parseInt(token, 10);
    if (num >= 1990 && num <= 2100) return "<YEAR>";
  }
  if (/^\d+(\.\d+)?$/.test(token)) return "<NUM>";
  if (/^\d+[a-z]+$/.test(token)) return token.replace(/\d+/, "<NUM>");
  return token;
}

function tokenizeTitle(value) {
  const normalized = normalizeTitle(value);
  if (!normalized) return [];
  // Match alphanumeric sequences
  const matches = normalized.match(/[a-z0-9]+/g) || [];
  const unigrams = [];
  for (const raw of matches) {
    if (raw.length < CLASSIFIER_MIN_TOKEN_LENGTH) continue;
    if (CLASSIFIER_STOPWORDS.has(raw)) continue;
    // Apply number normalization
    let token = normalizeNumber(raw);
    // Apply stemming to reduce vocabulary
    token = stemToken(token);
    // Skip if stemming produced a stopword
    if (CLASSIFIER_STOPWORDS.has(token)) continue;
    const trimmed =
      token.length > CLASSIFIER_MAX_TOKEN_LENGTH
        ? token.slice(0, CLASSIFIER_MAX_TOKEN_LENGTH)
        : token;
    unigrams.push(trimmed);
    if (unigrams.length >= CLASSIFIER_MAX_TOKENS) break;
  }
  // Generate bigrams for better phrase matching
  const tokens = [...unigrams];
  if (CLASSIFIER_ENABLE_BIGRAMS && unigrams.length >= 2) {
    for (let i = 0; i < unigrams.length - 1 && tokens.length < CLASSIFIER_MAX_TOKENS; i++) {
      let bigram = `${unigrams[i]}_${unigrams[i + 1]}`;
      // Clamp bigram length to max token length for consistent token IDs
      if (bigram.length > CLASSIFIER_MAX_TOKEN_LENGTH) {
        bigram = bigram.slice(0, CLASSIFIER_MAX_TOKEN_LENGTH);
      }
      tokens.push(bigram);
    }
  }
  return tokens;
}

// Get unique tokens for document frequency tracking
function getUniqueTokens(tokens) {
  return [...new Set(tokens)];
}

function buildTokenCounts(tokens) {
  const counts = {};
  let total = 0;
  for (const token of tokens) {
    counts[token] = (counts[token] ?? 0) + 1;
    total += 1;
  }
  return { counts, total };
}

function categoryKey(name) {
  return crypto
    .createHash("sha1")
    .update(String(name ?? "").trim())
    .digest("hex")
    .slice(0, 16);
}

function buildClassifierSample(expense) {
  if (!expense) return null;
  const title = normalizeTitle(expense.title);
  const category =
    typeof expense.category === "string" ? expense.category.trim() : "";
  if (!title || !category) return null;
  const tokens = tokenizeTitle(title);
  if (tokens.length === 0) return null;
  const { counts, total } = buildTokenCounts(tokens);
  return {
    category,
    categoryKey: categoryKey(category),
    tokenCounts: counts,
    tokenTotal: total,
  };
}

function tokenCountsEqual(a = {}, b = {}) {
  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  if (aKeys.length !== bKeys.length) return false;
  for (const key of aKeys) {
    if (a[key] !== b[key]) return false;
  }
  return true;
}

function applySampleDelta(sample, multiplier, updates, includeDocCounts, includeDocFreq) {
  if (!sample || sample.tokenTotal <= 0) return;
  const deltaTotal = multiplier * sample.tokenTotal;
  updates.categoryTokenTotals[sample.categoryKey] =
    (updates.categoryTokenTotals[sample.categoryKey] ?? 0) + deltaTotal;
  if (includeDocCounts) {
    updates.categoryDocCounts[sample.categoryKey] =
      (updates.categoryDocCounts[sample.categoryKey] ?? 0) + multiplier;
    updates.totalDocs += multiplier;
  }

  // Track unique tokens in this document for document frequency (IDF)
  const uniqueTokens = new Set(Object.keys(sample.tokenCounts));

  for (const [token, count] of Object.entries(sample.tokenCounts)) {
    const delta = multiplier * Number(count);
    if (delta == 0) continue;
    if (!updates.tokenUpdates[token]) {
      updates.tokenUpdates[token] = { total: 0, counts: {}, docFreq: 0, isNew: false };
    }
    updates.tokenUpdates[token].total += delta;
    updates.tokenUpdates[token].counts[sample.categoryKey] =
      (updates.tokenUpdates[token].counts[sample.categoryKey] ?? 0) + delta;
    // Track if this is a new token being added (for vocabulary size)
    if (multiplier > 0 && delta > 0) {
      updates.tokenUpdates[token].isNew = true;
    }
  }

  // Update document frequency for each unique token (for TF-IDF)
  // This is separate from includeDocCounts - we track docFreq whenever token set changes
  if (includeDocFreq) {
    for (const token of uniqueTokens) {
      if (!updates.tokenUpdates[token]) {
        updates.tokenUpdates[token] = { total: 0, counts: {}, docFreq: 0, isNew: false };
      }
      updates.tokenUpdates[token].docFreq += multiplier;
    }
  }
}

function ledgerSample(data) {
  if (!data) return null;
  const category =
    typeof data.category === "string" ? data.category.trim() : "";
  if (!category) return null;
  const key =
    typeof data.categoryKey === "string" && data.categoryKey.length > 0
      ? data.categoryKey
      : categoryKey(category);
  const tokens =
    data.tokens && typeof data.tokens === "object" ? data.tokens : {};
  let total = Number(data.tokenTotal ?? 0);
  if (!Number.isFinite(total) || total <= 0) {
    total = Object.values(tokens).reduce(
      (sum, value) => sum + Number(value ?? 0),
      0
    );
  }
  return {
    category,
    categoryKey: key,
    tokenCounts: tokens,
    tokenTotal: total,
  };
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
    const configCache = new Map();
    let scheduled = 0;
    let skipped = 0;

    for (const cardDoc of cardsSnap.docs) {
      const card = cardDoc.data();
      const uid = cardDoc.ref.parent.parent?.id;
      if (!uid) continue;

      let config = configCache.get(uid);
      if (!config) {
        config = await getUserConfig(uid);
        configCache.set(uid, config);
      }
      if (!config.remindersEnabled) {
        await clearCardTasks(uid, cardDoc.id);
        skipped += 1;
        continue;
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
        const sameZone = data?.timeZone === config.zone;
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
      const tasks = await scheduleCardTasks(
        uid,
        cardDoc.id,
        card,
        config.zone
      );
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

    const userConfig = await getUserConfig(uid);
    if (!userConfig.remindersEnabled) {
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

    const zone = userConfig.zone;
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
    const beforeEnabled = before?.cardRemindersEnabled !== false;
    const afterEnabled = after?.cardRemindersEnabled !== false;
    if (beforeZone === afterZone && beforeEnabled === afterEnabled) return;

    const cardsSnap = await db
      .collection("users")
      .doc(uid)
      .collection("cards")
      .where("reminderEnabled", "==", true)
      .get();
    for (const cardDoc of cardsSnap.docs) {
      const card = cardDoc.data();
      await clearCardTasks(uid, cardDoc.id);
      if (afterEnabled) {
        await scheduleCardTasks(uid, cardDoc.id, card, afterZone);
      }
    }
  }
);

exports.syncExpenseCategoryModel = onDocumentWritten(
  { region: REGION, document: "users/{uid}/expenses/{expenseId}" },
  async (event) => {
    const uid = event.params.uid;
    const expenseId = event.params.expenseId;
    const after = event.data?.after?.data();

    const modelRef = db
      .collection("users")
      .doc(uid)
      .collection(CLASSIFIER_MODEL_COLLECTION)
      .doc(CLASSIFIER_MODEL_DOC);
    const ledgerRef = modelRef
      .collection(CLASSIFIER_LEDGER_SUBCOLLECTION)
      .doc(expenseId);

    const ledgerSnap = await ledgerRef.get();
    const prevSample = ledgerSnap.exists
      ? ledgerSample(ledgerSnap.data())
      : null;
    const nextSample = buildClassifierSample(after);

    if (!prevSample && !nextSample) {
      if (ledgerSnap.exists) {
        await ledgerRef.delete();
      }
      return;
    }

    const updates = {
      totalDocs: 0,
      categoryDocCounts: {},
      categoryTokenTotals: {},
      tokenUpdates: {},
    };

    if (prevSample && nextSample) {
      const sameCategory = prevSample.categoryKey === nextSample.categoryKey;
      const sameTokens = tokenCountsEqual(
        prevSample.tokenCounts,
        nextSample.tokenCounts
      );
      if (sameCategory && sameTokens) {
        return;
      }
      // Track docFreq whenever tokens change, even if category stays the same
      // This fixes the stale docFreq issue for title-only edits
      const tokensChanged = !sameTokens;
      if (sameCategory) {
        applySampleDelta(prevSample, -1, updates, false, tokensChanged);
        applySampleDelta(nextSample, 1, updates, false, tokensChanged);
      } else {
        applySampleDelta(prevSample, -1, updates, true, true);
        applySampleDelta(nextSample, 1, updates, true, true);
      }
    } else if (prevSample && !nextSample) {
      applySampleDelta(prevSample, -1, updates, true, true);
    } else if (!prevSample && nextSample) {
      applySampleDelta(nextSample, 1, updates, true, true);
    }

    const hasMetaUpdate =
      updates.totalDocs !== 0 ||
      Object.keys(updates.categoryDocCounts).length > 0 ||
      Object.keys(updates.categoryTokenTotals).length > 0;
    const hasTokenUpdate = Object.keys(updates.tokenUpdates).length > 0;

    if (!hasMetaUpdate && !hasTokenUpdate && !nextSample) {
      if (ledgerSnap.exists) {
        await ledgerRef.delete();
      }
      return;
    }

    // Check which tokens are new (for vocabulary size tracking)
    // Fetch existing token documents to determine vocabulary size delta
    const tokenKeys = Object.keys(updates.tokenUpdates);
    let vocabularySizeDelta = 0;
    if (tokenKeys.length > 0) {
      const existingTokenRefs = tokenKeys.map((token) =>
        modelRef.collection(CLASSIFIER_TOKENS_SUBCOLLECTION).doc(token)
      );
      const existingTokenSnaps = await db.getAll(...existingTokenRefs);
      for (let i = 0; i < tokenKeys.length; i++) {
        const token = tokenKeys[i];
        const exists = existingTokenSnaps[i].exists;
        const update = updates.tokenUpdates[token];
        const newTotal = exists
          ? (Number(existingTokenSnaps[i].data()?.total ?? 0) + update.total)
          : update.total;
        // Token is being created (didn't exist, now has positive total)
        if (!exists && update.total > 0) {
          vocabularySizeDelta += 1;
        }
        // Token is being removed (existed, now has zero or negative total)
        if (exists && newTotal <= 0) {
          vocabularySizeDelta -= 1;
        }
      }
    }

    const batch = db.batch();

    // Update meta document (including vocabulary size)
    const needsMetaUpdate = hasMetaUpdate || vocabularySizeDelta !== 0;
    if (needsMetaUpdate) {
      const metaUpdate = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (updates.totalDocs !== 0) {
        metaUpdate.totalDocs = admin.firestore.FieldValue.increment(
          updates.totalDocs
        );
      }
      // Track global vocabulary size for consistent Laplace smoothing
      if (vocabularySizeDelta !== 0) {
        metaUpdate.vocabularySize = admin.firestore.FieldValue.increment(
          vocabularySizeDelta
        );
      }
      for (const [key, delta] of Object.entries(
        updates.categoryDocCounts
      )) {
        if (delta === 0) continue;
        metaUpdate[`categoryDocCounts.${key}`] =
          admin.firestore.FieldValue.increment(delta);
      }
      for (const [key, delta] of Object.entries(
        updates.categoryTokenTotals
      )) {
        if (delta === 0) continue;
        metaUpdate[`categoryTokenTotals.${key}`] =
          admin.firestore.FieldValue.increment(delta);
      }
      batch.set(modelRef, metaUpdate, { merge: true });
    }

    // Write token updates
    for (const [token, update] of Object.entries(updates.tokenUpdates)) {
      const tokenRef = modelRef
        .collection(CLASSIFIER_TOKENS_SUBCOLLECTION)
        .doc(token);
      const tokenUpdate = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      let shouldWrite = false;
      if (update.total !== 0) {
        tokenUpdate.total = admin.firestore.FieldValue.increment(update.total);
        shouldWrite = true;
      }
      // Track document frequency for TF-IDF calculation
      if (update.docFreq !== 0) {
        tokenUpdate.docFreq = admin.firestore.FieldValue.increment(update.docFreq);
        shouldWrite = true;
      }
      for (const [key, delta] of Object.entries(update.counts ?? {})) {
        if (delta === 0) continue;
        tokenUpdate[`counts.${key}`] =
          admin.firestore.FieldValue.increment(delta);
        shouldWrite = true;
      }
      if (shouldWrite) {
        batch.set(tokenRef, tokenUpdate, { merge: true });
      }
    }

    if (nextSample) {
      batch.set(
        ledgerRef,
        {
          category: nextSample.category,
          categoryKey: nextSample.categoryKey,
          tokens: nextSample.tokenCounts,
          tokenTotal: nextSample.tokenTotal,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } else {
      batch.delete(ledgerRef);
    }

    await batch.commit();
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
    const userSnap = await db.collection("users").doc(uid).get();
    const userData = userSnap.exists ? userSnap.data() : {};
    if (userData?.cardRemindersEnabled === false) {
      await clearCardTasks(uid, cardId);
      res.status(200).send("Reminders disabled");
      return;
    }
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

exports.predictExpenseCategory = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const rawTitle =
    typeof request.data?.title === "string" ? request.data.title : "";
  const tokens = tokenizeTitle(rawTitle);
  if (tokens.length === 0) {
    return { predictions: [], reason: "empty_tokens" };
  }

  const uid = request.auth.uid;
  const categoriesSnap = await db
    .collection("users")
    .doc(uid)
    .collection("expense_categories")
    .get();
  const categorySet = new Set(
    categoriesSnap.docs
      .map((doc) => doc.data()?.name)
      .filter((name) => typeof name === "string" && name.trim().length > 0)
      .map((name) => name.trim())
  );
  const categories = Array.from(categorySet.values());
  if (categories.length === 0) {
    return { predictions: [], reason: "no_categories" };
  }

  const modelRef = db
    .collection("users")
    .doc(uid)
    .collection(CLASSIFIER_MODEL_COLLECTION)
    .doc(CLASSIFIER_MODEL_DOC);
  const metaSnap = await modelRef.get();
  if (!metaSnap.exists) {
    return { predictions: [], reason: "no_model" };
  }

  const meta = metaSnap.data() ?? {};
  const totalDocs = Number(meta.totalDocs ?? 0);
  if (!Number.isFinite(totalDocs) || totalDocs <= 0) {
    return { predictions: [], reason: "no_training_data" };
  }

  // Cold start protection: require minimum training data
  if (totalDocs < CLASSIFIER_MIN_DOCS_FOR_PREDICTION) {
    return {
      predictions: [],
      reason: "insufficient_data",
      totalDocs,
      minRequired: CLASSIFIER_MIN_DOCS_FOR_PREDICTION,
    };
  }

  const categoryDocCounts =
    meta.categoryDocCounts && typeof meta.categoryDocCounts === "object"
      ? meta.categoryDocCounts
      : {};
  const categoryTokenTotals =
    meta.categoryTokenTotals && typeof meta.categoryTokenTotals === "object"
      ? meta.categoryTokenTotals
      : {};

  // Batch fetch all token documents
  const tokenRefs = tokens.map((token) =>
    modelRef.collection(CLASSIFIER_TOKENS_SUBCOLLECTION).doc(token)
  );
  const tokenSnaps =
    tokenRefs.length > 0 ? await db.getAll(...tokenRefs) : [];
  const tokenData = {};
  let knownTokenCount = 0;
  for (const snap of tokenSnaps) {
    if (!snap.exists) continue;
    tokenData[snap.id] = snap.data();
    knownTokenCount++;
  }

  // If none of the tokens are known, we can't make a good prediction
  if (knownTokenCount === 0) {
    return { predictions: [], reason: "unknown_tokens" };
  }

  const titleCounts = buildTokenCounts(tokens).counts;
  const titleTokenCount = tokens.length;
  const scores = [];
  const categoryCount = categories.length;
  // Use global vocabulary size from meta if available, otherwise estimate from request tokens
  // This provides more consistent Laplace smoothing across requests
  const globalVocabularySize = Number(meta.vocabularySize ?? 0);
  const vocabularySize = globalVocabularySize > 0 ? globalVocabularySize : (Object.keys(tokenData).length || 1);

  // Compute IDF weights for TF-IDF (if enabled)
  const idfWeights = {};
  if (CLASSIFIER_ENABLE_TFIDF) {
    for (const [token, info] of Object.entries(tokenData)) {
      // Safe clamp docFreq: must be at least 1 and at most totalDocs
      // This prevents negative or skewed IDF weights from stale data
      const rawDocFreq = Number(info.docFreq ?? 1);
      const docFreq = Math.max(1, Math.min(totalDocs, rawDocFreq));
      // IDF = log(totalDocs / (docFreq + 1)) + 1
      // Adding 1 to denominator prevents division by zero
      // Adding 1 to result ensures IDF is always positive
      idfWeights[token] = Math.log(totalDocs / (docFreq + 1)) + 1;
    }
  }

  for (const name of categories) {
    const key = categoryKey(name);
    const docCount = Number(categoryDocCounts[key] ?? 0);
    // Prior probability with Laplace smoothing
    const logPrior =
      Math.log(docCount + CLASSIFIER_PRIOR_SMOOTHING) -
      Math.log(totalDocs + CLASSIFIER_PRIOR_SMOOTHING * categoryCount);
    const tokenTotal = Number(categoryTokenTotals[key] ?? 0);
    let logLikelihood = 0;

    for (const [token, count] of Object.entries(titleCounts)) {
      const tokenInfo = tokenData[token];
      const tokenCounts =
        tokenInfo && tokenInfo.counts && typeof tokenInfo.counts === "object"
          ? tokenInfo.counts
          : {};
      const tokenCount = Number(tokenCounts[key] ?? 0);

      // Calculate TF (Term Frequency) - normalized by document length
      const tf = CLASSIFIER_ENABLE_TFIDF
        ? Number(count) / titleTokenCount
        : Number(count);

      // Get IDF weight (defaults to 1 if not found or TF-IDF disabled)
      const idf = CLASSIFIER_ENABLE_TFIDF
        ? (idfWeights[token] ?? 1)
        : 1;

      // TF-IDF weight
      const tfidfWeight = tf * idf;

      // Laplace smoothing with vocabulary size for better generalization
      const numerator = tokenCount + CLASSIFIER_TOKEN_SMOOTHING;
      const denominator =
        tokenTotal + CLASSIFIER_TOKEN_SMOOTHING * vocabularySize;

      // Apply TF-IDF weight to the log-likelihood
      logLikelihood += tfidfWeight * (Math.log(numerator) - Math.log(denominator));
    }

    scores.push({
      category: name,
      score: logPrior + logLikelihood,
      docCount,
    });
  }

  // Softmax normalization for probability distribution
  const maxScore = scores.reduce(
    (max, item) => (item.score > max ? item.score : max),
    Number.NEGATIVE_INFINITY
  );
  const expScores = scores.map((item) => Math.exp(item.score - maxScore));
  const sumExp = expScores.reduce((sum, value) => sum + value, 0) || 1;

  const predictions = scores
    .map((item, index) => ({
      category: item.category,
      confidence: expScores[index] / sumExp,
      support: item.docCount,
    }))
    .filter((p) => p.confidence > 0.01) // Filter very low confidence
    .sort((a, b) => b.confidence - a.confidence)
    .slice(0, 3); // Limit to top 3 to match UX requirement

  return {
    predictions,
    meta: {
      totalDocs,
      tokensUsed: tokens.length,
      tokensKnown: knownTokenCount,
    },
  };
});

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
      const userData = userSnap.data() ?? {};
      const zone = resolveZone(userData?.timezone);
      const baseCurrency =
        typeof userData?.baseCurrency === "string" && userData.baseCurrency
          ? userData.baseCurrency
          : "EUR";
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

      const displayCurrency = baseCurrency;
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
          currency: card.currency ?? "EUR",
          autopayEnabled: card.autopayEnabled ?? false,
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
            baseCurrency,
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
