#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "turqappteknoloji";
const DATABASE_ROOT = `projects/${PROJECT_ID}/databases/(default)`;
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/${DATABASE_ROOT}/documents`;
const POSTS_COLLECTION = "Posts";
const DEFAULT_START_LOCAL =
  process.env.FLOOD_RETIME_START_LOCAL || "2026-04-15T17:00:00+03:00";
const QUERY_PAGE_SIZE = Math.max(
  1,
  Math.min(500, Number(process.env.FLOOD_RETIME_QUERY_PAGE_SIZE || 300)),
);
const COMMIT_BATCH_SIZE = Math.max(
  1,
  Math.min(500, Number(process.env.FLOOD_RETIME_COMMIT_BATCH_SIZE || 150)),
);
const LIMIT_GROUPS = Math.max(0, Number(process.env.FLOOD_RETIME_LIMIT_GROUPS || 0));
const SKIP_GROUPS = Math.max(0, Number(process.env.FLOOD_RETIME_SKIP_GROUPS || 0));
const PAUSE_MS = Math.max(0, Number(process.env.FLOOD_RETIME_PAUSE_MS || 150));
const EXECUTE = process.argv.includes("--execute");

const SLOT_HOURS = [17, 18, 19];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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

function documentIdFromName(name) {
  return String(name || "").split("/").pop() || "";
}

function toIntegerValue(number) {
  return { integerValue: String(Math.trunc(number)) };
}

function resolveSeriesRootId(id, mainFlood) {
  const match = String(id || "").match(/^(.*)_([0-9]+)$/);
  if (match) {
    return `${match[1]}_0`;
  }
  const normalizedMainFlood = String(mainFlood || "").trim();
  if (normalizedMainFlood) {
    return normalizedMainFlood;
  }
  return String(id || "").trim();
}

function buildStructuredQuery(cursor) {
  const query = {
    from: [{ collectionId: POSTS_COLLECTION }],
    orderBy: [
      { field: { fieldPath: "timeStamp" }, direction: "ASCENDING" },
      { field: { fieldPath: "__name__" }, direction: "ASCENDING" },
    ],
    limit: QUERY_PAGE_SIZE,
  };

  if (cursor) {
    query.startAt = {
      before: false,
      values: [
        toIntegerValue(cursor.timeStamp),
        { referenceValue: cursor.name },
      ],
    };
  }

  return { structuredQuery: query };
}

async function queryFloodDocs(accessToken) {
  const url = `${FIRESTORE_BASE}:runQuery`;
  const docs = [];
  let cursor = null;

  while (true) {
    const rows = await fetchGoogleJson(url, accessToken, {
      method: "POST",
      body: JSON.stringify(buildStructuredQuery(cursor)),
    });
    const documents = Array.isArray(rows)
      ? rows.map((row) => row?.document).filter(Boolean)
      : [];
    if (!documents.length) break;

    for (const document of documents) {
      const fields = document.fields || {};
      const id = documentIdFromName(document.name);
      const timeStamp = readNumberField(fields, "timeStamp", 0);
      const floodCount = readNumberField(fields, "floodCount", 0);
      const mainFlood = readStringField(fields, "mainFlood");
      docs.push({
        id,
        name: document.name,
        timeStamp,
        floodCount,
        mainFlood,
        rootId: resolveSeriesRootId(id, mainFlood),
      });
      cursor = {
        name: document.name,
        timeStamp,
      };
    }

    if (documents.length < QUERY_PAGE_SIZE) {
      break;
    }
  }

  return docs.filter((doc) => doc.floodCount > 1);
}

function groupSeries(docs) {
  const groups = new Map();
  for (const doc of docs) {
    const key = doc.rootId;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key).push(doc);
  }

  const series = Array.from(groups.entries()).map(([rootId, members]) => {
    members.sort((left, right) => {
      const timeCompare = left.timeStamp - right.timeStamp;
      if (timeCompare !== 0) return timeCompare;
      return left.id.localeCompare(right.id, "en");
    });
    return {
      rootId,
      members,
      firstTimeStamp: members[0]?.timeStamp || 0,
      floodCount: members[0]?.floodCount || members.length,
      memberCount: members.length,
    };
  });

  series.sort((left, right) => {
    const timeCompare = left.firstTimeStamp - right.firstTimeStamp;
    if (timeCompare !== 0) return timeCompare;
    return left.rootId.localeCompare(right.rootId, "en");
  });

  return series;
}

function buildSeriesAssignments(series, startMs) {
  return series.map((group, index) => {
    const dayOffset = Math.floor(index / SLOT_HOURS.length);
    const slotHour = SLOT_HOURS[index % SLOT_HOURS.length];
    const slotStart = startMs + dayOffset * 24 * 60 * 60 * 1000;
    const slotDate = new Date(slotStart);
    slotDate.setUTCHours(slotHour - 3, 0, 0, 0);
    const newTimeStamp = slotDate.getTime();
    return {
      ...group,
      ordinal: index,
      newTimeStamp,
    };
  });
}

function sliceAssignments(assignments) {
  let output = assignments;
  if (SKIP_GROUPS > 0) output = output.slice(SKIP_GROUPS);
  if (LIMIT_GROUPS > 0) output = output.slice(0, LIMIT_GROUPS);
  return output;
}

function describeGroup(group) {
  return {
    rootId: group.rootId,
    memberCount: group.memberCount,
    floodCount: group.floodCount,
    oldTimeStamp: group.firstTimeStamp,
    oldIso: new Date(group.firstTimeStamp).toISOString(),
    newTimeStamp: group.newTimeStamp,
    newIso: new Date(group.newTimeStamp).toISOString(),
    sampleMembers: group.members.slice(0, 4).map((item) => item.id),
    ordinal: group.ordinal,
  };
}

async function commitAssignments(accessToken, groups) {
  const url = `${FIRESTORE_BASE}:commit`;
  const writes = [];
  const flattened = [];

  for (const group of groups) {
    for (const member of group.members) {
      flattened.push({
        rootId: group.rootId,
        id: member.id,
        newTimeStamp: group.newTimeStamp,
        name: member.name,
      });
    }
  }

  let committed = 0;
  for (let index = 0; index < flattened.length; index += COMMIT_BATCH_SIZE) {
    const slice = flattened.slice(index, index + COMMIT_BATCH_SIZE);
    const batchWrites = slice.map((item) => ({
      update: {
        name: item.name,
        fields: {
          timeStamp: toIntegerValue(item.newTimeStamp),
        },
      },
      updateMask: {
        fieldPaths: ["timeStamp"],
      },
      currentDocument: {
        exists: true,
      },
    }));

    await fetchGoogleJson(url, accessToken, {
      method: "POST",
      body: JSON.stringify({ writes: batchWrites }),
    });
    committed += slice.length;

    const last = slice[slice.length - 1];
    console.log(
      JSON.stringify({
        phase: "commit_progress",
        committedDocs: committed,
        totalDocs: flattened.length,
        lastId: last.id,
        lastRootId: last.rootId,
        lastNewTimeStamp: last.newTimeStamp,
        lastNewIso: new Date(last.newTimeStamp).toISOString(),
      }),
    );

    if (PAUSE_MS > 0 && committed < flattened.length) {
      await sleep(PAUSE_MS);
    }
  }
}

async function main() {
  const startMs = Date.parse(DEFAULT_START_LOCAL);
  if (!Number.isFinite(startMs) || startMs <= 0) {
    throw new Error(`invalid_start_local:${DEFAULT_START_LOCAL}`);
  }

  const accessToken = await getAccessToken();
  const docs = await queryFloodDocs(accessToken);
  const series = groupSeries(docs);
  const assignments = buildSeriesAssignments(series, startMs);
  const selected = sliceAssignments(assignments);

  const summary = {
    execute: EXECUTE,
    projectId: PROJECT_ID,
    startLocal: DEFAULT_START_LOCAL,
    startTimeStamp: startMs,
    startIso: new Date(startMs).toISOString(),
    slotHoursLocal: SLOT_HOURS,
    floodDocCount: docs.length,
    seriesCount: series.length,
    selectedSeriesCount: selected.length,
    selectedDocCount: selected.reduce((sum, item) => sum + item.memberCount, 0),
    skipGroups: SKIP_GROUPS,
    limitGroups: LIMIT_GROUPS,
    firstGroups: selected.slice(0, 5).map(describeGroup),
    lastGroups: selected.slice(Math.max(0, selected.length - 5)).map(describeGroup),
  };

  console.log(JSON.stringify({ phase: "plan", ...summary }, null, 2));

  if (!EXECUTE) {
    return;
  }

  await commitAssignments(accessToken, selected);

  console.log(
    JSON.stringify(
      {
        phase: "done",
        committedSeriesCount: selected.length,
        committedDocCount: selected.reduce((sum, item) => sum + item.memberCount, 0),
        firstGroups: selected.slice(0, 5).map(describeGroup),
        lastGroups: selected.slice(Math.max(0, selected.length - 5)).map(describeGroup),
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error("retime_flood_series_failed", error);
  process.exit(1);
});
