#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "turqappteknoloji";
const DATABASE_ROOT = `projects/${PROJECT_ID}/databases/(default)`;
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/${DATABASE_ROOT}/documents`;
const POSTS_COLLECTION = "Posts";
const DEFAULT_HOURS = [17, 18, 19];
const DEFAULT_TZ_OFFSET = process.env.FLOOD_SLOT_TZ_OFFSET || "+03:00";
const DEFAULT_QUERY_LIMIT = Math.max(
  1,
  Math.min(500, Number(process.env.FLOOD_SLOT_QUERY_LIMIT || 300)),
);

function parseArgs(argv) {
  const options = {
    date: process.env.FLOOD_SLOT_DATE || "",
    hours: null,
    docIdsOnly: argv.includes("--doc-ids-only"),
    timezoneOffset: DEFAULT_TZ_OFFSET,
  };

  for (const arg of argv) {
    if (!arg.startsWith("--")) continue;
    const [flag, rawValue = ""] = arg.split("=", 2);
    const value = rawValue.trim();
    if (flag === "--date" && value) {
      options.date = value;
    } else if (flag === "--hours" && value) {
      options.hours = value
          .split(",")
          .map((item) => Number(item.trim()))
          .filter((item) => Number.isInteger(item) && item >= 0 && item <= 23);
    } else if (flag === "--tz" && value) {
      options.timezoneOffset = value;
    }
  }

  if (!options.date) {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const dd = String(now.getDate()).padStart(2, "0");
    options.date = `${yyyy}-${mm}-${dd}`;
  }
  if (!options.hours || options.hours.length === 0) {
    options.hours = DEFAULT_HOURS;
  }
  return options;
}

async function getAccessToken() {
  const configstorePath = path.join(
    os.homedir(),
    ".config",
    "configstore",
    "firebase-tools.json",
  );
  try {
    const raw = fs.readFileSync(configstorePath, "utf8");
    const parsed = JSON.parse(raw);
    const accessToken = String(parsed?.tokens?.access_token || "").trim();
    const expiresAt = Number(parsed?.tokens?.expires_at || 0);
    if (accessToken && Number.isFinite(expiresAt) && expiresAt > Date.now() + 60_000) {
      return accessToken;
    }
  } catch (_) {}

  const firebaseToolsRoot = path.join(
    __dirname,
    "..",
    "functions",
    "node_modules",
    "firebase-tools",
    "lib",
  );
  const auth = require(path.join(firebaseToolsRoot, "auth"));
  const apiv2 = require(path.join(firebaseToolsRoot, "apiv2"));
  const projectRoot = path.join(__dirname, "..");
  const account =
    auth.getProjectDefaultAccount(projectRoot) || auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) {
    throw new Error("firebase_cli_auth_missing");
  }
  apiv2.setRefreshToken(account.tokens.refresh_token);
  return apiv2.getAccessToken();
}

async function fetchGoogleJson(url, accessToken, init = {}) {
  const response = await fetch(url, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
  const text = await response.text();
  let data = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (_) {
      data = text;
    }
  }
  if (!response.ok) {
    throw new Error(`google_api_failed:${response.status}:${text}`);
  }
  return data;
}

function parseFirestoreValue(value) {
  if (!value || typeof value !== "object") return null;
  if ("nullValue" in value) return null;
  if ("booleanValue" in value) return Boolean(value.booleanValue);
  if ("integerValue" in value) return Number(value.integerValue);
  if ("doubleValue" in value) return Number(value.doubleValue);
  if ("stringValue" in value) return String(value.stringValue);
  if ("timestampValue" in value) return Date.parse(value.timestampValue);
  if ("referenceValue" in value) return String(value.referenceValue);
  if ("arrayValue" in value) {
    const values = Array.isArray(value.arrayValue?.values) ? value.arrayValue.values : [];
    return values.map(parseFirestoreValue);
  }
  if ("mapValue" in value) {
    const fields = value.mapValue?.fields || {};
    return Object.fromEntries(
      Object.entries(fields).map(([key, nested]) => [key, parseFirestoreValue(nested)]),
    );
  }
  return null;
}

function readNumberField(fields, key, fallback = 0) {
  const parsed = parseFirestoreValue(fields?.[key]);
  const numeric = Number(parsed);
  return Number.isFinite(numeric) ? numeric : fallback;
}

function readStringField(fields, key) {
  const parsed = parseFirestoreValue(fields?.[key]);
  return typeof parsed === "string" ? parsed.trim() : "";
}

function readBooleanField(fields, key) {
  const parsed = parseFirestoreValue(fields?.[key]);
  return parsed === true;
}

function documentIdFromName(name) {
  return String(name || "").split("/").pop() || "";
}

function toIntegerValue(number) {
  return { integerValue: String(Math.trunc(number)) };
}

function toReferenceValue(docName) {
  return { referenceValue: docName };
}

function resolveSeriesRootId(id, mainFlood) {
  const match = String(id || "").match(/^(.*)_([0-9]+)$/);
  if (match) return `${match[1]}_0`;
  const normalizedMainFlood = String(mainFlood || "").trim();
  if (normalizedMainFlood) {
    const mainMatch = normalizedMainFlood.match(/^(.*)_([0-9]+)$/);
    if (mainMatch) return `${mainMatch[1]}_0`;
    return normalizedMainFlood;
  }
  return String(id || "").trim();
}

function slotWindowMs(date, hour, timezoneOffset) {
  const start = Date.parse(`${date}T${String(hour).padStart(2, "0")}:00:00${timezoneOffset}`);
  const end = Date.parse(`${date}T${String(hour + 1).padStart(2, "0")}:00:00${timezoneOffset}`);
  if (!Number.isFinite(start) || !Number.isFinite(end)) {
    throw new Error(`invalid_slot_window:${date}:${hour}:${timezoneOffset}`);
  }
  return { start, end };
}

function buildStructuredQuery(startMs, endMs, cursor) {
  const query = {
    from: [{ collectionId: POSTS_COLLECTION }],
    where: {
      compositeFilter: {
        op: "AND",
        filters: [
          {
            fieldFilter: {
              field: { fieldPath: "timeStamp" },
              op: "GREATER_THAN_OR_EQUAL",
              value: toIntegerValue(startMs),
            },
          },
          {
            fieldFilter: {
              field: { fieldPath: "timeStamp" },
              op: "LESS_THAN",
              value: toIntegerValue(endMs),
            },
          },
        ],
      },
    },
    orderBy: [
      { field: { fieldPath: "timeStamp" }, direction: "ASCENDING" },
      { field: { fieldPath: "__name__" }, direction: "ASCENDING" },
    ],
    limit: DEFAULT_QUERY_LIMIT,
  };

  if (cursor) {
    query.startAt = {
      before: false,
      values: [
        toIntegerValue(cursor.timeStamp),
        toReferenceValue(cursor.name),
      ],
    };
  }

  return { structuredQuery: query };
}

async function querySlotDocs(accessToken, startMs, endMs) {
  const url = `${FIRESTORE_BASE}:runQuery`;
  const docs = [];
  let cursor = null;

  while (true) {
    const rows = await fetchGoogleJson(url, accessToken, {
      method: "POST",
      body: JSON.stringify(buildStructuredQuery(startMs, endMs, cursor)),
    });
    const documents = Array.isArray(rows)
      ? rows.map((row) => row?.document).filter(Boolean)
      : [];
    if (!documents.length) break;

    for (const document of documents) {
      const fields = document.fields || {};
      const id = documentIdFromName(document.name);
      const floodCount = readNumberField(fields, "floodCount", 0);
      const mainFlood = readStringField(fields, "mainFlood");
      docs.push({
        id,
        name: document.name,
        timeStamp: readNumberField(fields, "timeStamp", 0),
        scheduledAt: readNumberField(fields, "scheduledAt", 0),
        flood: readBooleanField(fields, "flood"),
        floodCount,
        mainFlood,
        rootId: resolveSeriesRootId(id, mainFlood),
        userID: readStringField(fields, "userID"),
        metin: readStringField(fields, "metin"),
      });
      cursor = {
        name: document.name,
        timeStamp: readNumberField(fields, "timeStamp", 0),
      };
    }

    if (documents.length < DEFAULT_QUERY_LIMIT) {
      break;
    }
  }

  return docs.filter((doc) => doc.floodCount > 1);
}

function buildSlotSummary({ date, hour, timezoneOffset, docs }) {
  const groups = new Map();
  for (const doc of docs) {
    const key = doc.rootId || doc.id;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key).push(doc);
  }

  const roots = Array.from(groups.entries())
    .map(([rootId, members]) => {
      const preferredRoot =
        members.find((item) => item.id === rootId) ||
        members.find((item) => !item.flood && item.mainFlood.length === 0) ||
        members[0];
      members.sort((left, right) => {
        const timeCompare = left.timeStamp - right.timeStamp;
        if (timeCompare !== 0) return timeCompare;
        return left.id.localeCompare(right.id, "en");
      });
      return {
        rootId: preferredRoot?.id || rootId,
        floodCount: preferredRoot?.floodCount || members[0]?.floodCount || members.length,
        memberCountInSlot: members.length,
        timeStamp: preferredRoot?.timeStamp || members[0]?.timeStamp || 0,
        scheduledAt: preferredRoot?.scheduledAt || 0,
        userID: preferredRoot?.userID || "",
        sampleMembers: members.slice(0, 5).map((item) => item.id),
        previewText: String(preferredRoot?.metin || "").slice(0, 80),
      };
    })
    .sort((left, right) => {
      const timeCompare = left.timeStamp - right.timeStamp;
      if (timeCompare !== 0) return timeCompare;
      return left.rootId.localeCompare(right.rootId, "en");
    });

  return {
    date,
    hour,
    timezoneOffset,
    slotStartIso: new Date(slotWindowMs(date, hour, timezoneOffset).start).toISOString(),
    slotEndIso: new Date(slotWindowMs(date, hour, timezoneOffset).end).toISOString(),
    floodRootCount: roots.length,
    floodDocCount: docs.length,
    floodRootDocIds: roots.map((item) => item.rootId),
    roots,
  };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const accessToken = await getAccessToken();
  const slotSummaries = [];

  for (const hour of options.hours) {
    const { start, end } = slotWindowMs(
      options.date,
      hour,
      options.timezoneOffset,
    );
    const docs = await querySlotDocs(accessToken, start, end);
    slotSummaries.push(
      buildSlotSummary({
        date: options.date,
        hour,
        timezoneOffset: options.timezoneOffset,
        docs,
      }),
    );
  }

  if (options.docIdsOnly) {
    const docIds = slotSummaries
      .flatMap((slot) => slot.floodRootDocIds)
      .filter((docId, index, list) => docId && list.indexOf(docId) === index);
    console.log(docIds.join(","));
    return;
  }

  console.log(
    JSON.stringify(
      {
        projectId: PROJECT_ID,
        date: options.date,
        hours: options.hours,
        timezoneOffset: options.timezoneOffset,
        slots: slotSummaries,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error("list_flood_slot_roots_failed", error);
  process.exit(1);
});
