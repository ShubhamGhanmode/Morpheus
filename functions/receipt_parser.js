const TOTAL_KEYWORDS = [
  "total",
  "subtotal",
  "tax",
  "vat",
  "amount due",
  "balance due",
  "change",
  "cash",
  "card",
  "visa",
  "mastercard",
  "amex",
  "payment",
];

const IGNORE_KEYWORDS = [
  "auth",
  "approval",
  "terminal",
  "trans",
  "txn",
  "thank",
  "refund",
  "void",
  "discount",
  "coupon",
  "member",
  "loyalty",
];

const DATE_KEYWORDS = ["date", "transaction", "txn", "sale", "time"];

const MONTHS = {
  jan: 1,
  january: 1,
  feb: 2,
  february: 2,
  mar: 3,
  march: 3,
  apr: 4,
  april: 4,
  may: 5,
  jun: 6,
  june: 6,
  jul: 7,
  july: 7,
  aug: 8,
  august: 8,
  sep: 9,
  sept: 9,
  september: 9,
  oct: 10,
  october: 10,
  nov: 11,
  november: 11,
  dec: 12,
  december: 12,
};

function parseReceiptText(text) {
  const lines = text
    .split(/\r?\n/g)
    .map((line) => line.trim().replace(/\s+/g, " "))
    .filter((line) => line.length > 0);

  const items = [];
  const totals = { total: null, subtotal: null, tax: null };
  const merchant = guessMerchant(lines);
  const currency = detectCurrency(lines);
  const date = parseReceiptDate(lines);

  for (const line of lines) {
    const lower = line.toLowerCase();
    if (shouldIgnoreLine(lower)) continue;

    const amountMatch = extractAmount(line);
    if (!amountMatch) continue;

    if (isTotalLine(lower)) {
      const amount = amountMatch.amount;
      if (lower.includes("subtotal") && totals.subtotal == null) {
        totals.subtotal = amount;
      } else if ((lower.includes("tax") || lower.includes("vat")) && totals.tax == null) {
        totals.tax = amount;
      } else if (totals.total == null) {
        totals.total = amount;
      }
      continue;
    }

    const description = amountMatch.description;
    if (!description || description.length < 2) continue;
    items.push({ name: description, amount: amountMatch.amount });
  }

  return {
    items,
    total: totals.total,
    subtotal: totals.subtotal,
    tax: totals.tax,
    currency,
    merchant,
    date,
  };
}

function shouldIgnoreLine(lower) {
  if (lower.length < 3) return true;
  for (const keyword of IGNORE_KEYWORDS) {
    if (lower.includes(keyword)) return true;
  }
  return false;
}

function isTotalLine(lower) {
  for (const keyword of TOTAL_KEYWORDS) {
    if (lower.includes(keyword)) return true;
  }
  return false;
}

function extractAmount(line) {
  const match = line.match(/(-?\d[\d., ]*\d|\d)(?!.*\d)/);
  if (!match || match.index == null) return null;
  const raw = match[0];
  const amount = parseAmount(raw);
  if (!Number.isFinite(amount)) return null;
  const description = line.slice(0, match.index).trim();
  return { amount, description };
}

function parseAmount(value) {
  const cleaned = value.replace(/[^0-9,.\-]/g, "");
  if (!cleaned) return null;

  if (cleaned.includes(",") && cleaned.includes(".")) {
    const lastComma = cleaned.lastIndexOf(",");
    const lastDot = cleaned.lastIndexOf(".");
    const decimalSep = lastComma > lastDot ? "," : ".";
    const thousandSep = decimalSep === "," ? "." : ",";
    const withoutThousands = cleaned.split(thousandSep).join("");
    const normalized =
      decimalSep === "," ? withoutThousands.replace(",", ".") : withoutThousands;
    return Number(normalized);
  }

  if (cleaned.includes(",")) {
    const parts = cleaned.split(",");
    const last = parts[parts.length - 1];
    const normalized =
      last.length === 2 ? cleaned.replace(",", ".") : cleaned.replace(/,/g, "");
    return Number(normalized);
  }

  if (cleaned.includes(".")) {
    const parts = cleaned.split(".");
    const last = parts[parts.length - 1];
    const normalized =
      last.length === 2 ? cleaned : cleaned.replace(/\./g, "");
    return Number(normalized);
  }

  return Number(cleaned);
}

function guessMerchant(lines) {
  for (const line of lines.slice(0, 4)) {
    const normalized = line.replace(/[^a-zA-Z0-9 ]/g, "").trim();
    if (normalized.length >= 3 && !/^\d+$/.test(normalized)) {
      return line.trim();
    }
  }
  return null;
}

function detectCurrency(lines) {
  const joined = lines.join(" ").toUpperCase();
  if (joined.includes("USD") || joined.includes("$")) return "USD";
  if (joined.includes("EUR")) return "EUR";
  if (joined.includes("GBP")) return "GBP";
  if (joined.includes("INR")) return "INR";
  return null;
}

function parseReceiptDate(lines) {
  const candidates = [];
  for (const line of lines) {
    const lower = line.toLowerCase();
    const parsed = parseDateFromLine(line);
    if (parsed) {
      const hasKeyword = DATE_KEYWORDS.some((keyword) => lower.includes(keyword));
      candidates.push({ date: parsed, score: hasKeyword ? 1 : 0 });
    }
  }
  if (candidates.length === 0) return null;
  candidates.sort((a, b) => b.score - a.score);
  return candidates[0].date;
}

function parseDateFromLine(line) {
  const numeric = line.match(/(\d{1,2})[\/.-](\d{1,2})[\/.-](\d{2,4})/);
  if (numeric) {
    const date = buildDateFromNumbers(numeric[1], numeric[2], numeric[3]);
    if (date) return date;
  }

  const named = line.match(/(\d{1,2})[-\s]([A-Za-z]{3,})[-\s](\d{2,4})/);
  if (named) {
    const month = monthFromName(named[2]);
    if (month) {
      const day = parseInt(named[1], 10);
      const year = normalizeYear(named[3]);
      return formatDate(year, month, day);
    }
  }

  const namedAlt = line.match(/([A-Za-z]{3,})[-\s](\d{1,2})[-\s](\d{2,4})/);
  if (namedAlt) {
    const month = monthFromName(namedAlt[1]);
    if (month) {
      const day = parseInt(namedAlt[2], 10);
      const year = normalizeYear(namedAlt[3]);
      return formatDate(year, month, day);
    }
  }

  return null;
}

function buildDateFromNumbers(first, second, yearRaw) {
  const a = parseInt(first, 10);
  const b = parseInt(second, 10);
  const year = normalizeYear(yearRaw);
  if (!Number.isFinite(a) || !Number.isFinite(b) || !Number.isFinite(year)) {
    return null;
  }

  const firstNum = a;
  const secondNum = b;
  let month = firstNum;
  let day = secondNum;
  if (firstNum > 12 && secondNum <= 12) {
    day = firstNum;
    month = secondNum;
  } else if (secondNum > 12 && firstNum <= 12) {
    day = secondNum;
    month = firstNum;
  }

  if (!isValidDate(year, month, day)) {
    const swapped = isValidDate(year, secondNum, firstNum);
    if (!swapped) return null;
    month = secondNum;
    day = firstNum;
  }

  return formatDate(year, month, day);
}

function normalizeYear(value) {
  const year = parseInt(value, 10);
  if (!Number.isFinite(year)) return null;
  if (year < 100) return 2000 + year;
  return year;
}

function isValidDate(year, month, day) {
  if (!year || month < 1 || month > 12 || day < 1 || day > 31) return false;
  const dt = new Date(Date.UTC(year, month - 1, day));
  return (
    dt.getUTCFullYear() === year &&
    dt.getUTCMonth() === month - 1 &&
    dt.getUTCDate() === day
  );
}

function monthFromName(value) {
  if (!value) return null;
  return MONTHS[value.toLowerCase()] ?? null;
}

function formatDate(year, month, day) {
  if (!isValidDate(year, month, day)) return null;
  const mm = String(month).padStart(2, "0");
  const dd = String(day).padStart(2, "0");
  return `${year}-${mm}-${dd}`;
}

module.exports = { parseReceiptText };
