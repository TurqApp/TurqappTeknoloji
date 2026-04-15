#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "turqappteknoloji";
const DATABASE_ROOT = `projects/${PROJECT_ID}/databases/(default)`;
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/${DATABASE_ROOT}/documents`;
const POSTS_COLLECTION = "Posts";
const DEFAULT_ANCHOR_POST_ID =
  process.env.POSTS_RETIME_ANCHOR_POST_ID ||
  "ff7da5fd-7fab-4ea5-b920-ec2f676d47fb";
const DEFAULT_START_LOCAL =
  process.env.POSTS_RETIME_START_LOCAL || "2026-04-12T00:00:00+03:00";
const QUERY_PAGE_SIZE = Math.max(
  1,
  Math.min(500, Number(process.env.POSTS_RETIME_QUERY_PAGE_SIZE || 300)),
);
const COMMIT_BATCH_SIZE = Math.max(
  1,
  Math.min(500, Number(process.env.POSTS_RETIME_COMMIT_BATCH_SIZE || 150)),
);
const LIMIT = Math.max(0, Number(process.env.POSTS_RETIME_LIMIT || 0));
const SKIP = Math.max(0, Number(process.env.POSTS_RETIME_SKIP || 0));
const PAUSE_MS = Math.max(0, Number(process.env.POSTS_RETIME_PAUSE_MS || 150));
const MAX_QUERY_PAGES = Math.max(0, Number(process.env.POSTS_RETIME_MAX_QUERY_PAGES || 0));
const EXECUTE = process.argv.includes("--execute");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function decodeSecretPayload(payload) {
  const encoded = payload?.payload?.data;
  if (!encoded) {
    throw new Error("secret_payload_missing");
  }
  return Buffer.from(encoded, "base64").toString("utf8").trim();
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
  } catch (_) {
    // Fall through to firebase-tools auth refresh path.
  }

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

function documentIdFromName(name) {
  return String(name || "").split("/").pop() || "";
}

function toIntegerValue(number) {
  return { integerValue: String(Math.trunc(number)) };
}

async function fetchAnchor(accessToken, postId) {
  const url = `${FIRESTORE_BASE}/${POSTS_COLLECTION}/${postId}`;
  const data = await fetchGoogleJson(url, accessToken, { method: "GET" });
  const fields = data?.fields || {};
  const timeStamp = readNumberField(fields, "timeStamp", 0);
  const floodCount = readNumberField(fields, "floodCount", 0);
  if (timeStamp <= 0) {
    throw new Error(`anchor_missing_timestamp:${postId}`);
  }
  return {
    id: postId,
    name: data.name,
    timeStamp,
    floodCount,
  };
}

function buildStructuredQuery(anchorTimeStamp, cursor) {
  const query = {
    from: [{ collectionId: POSTS_COLLECTION }],
    where: {
      fieldFilter: {
        field: { fieldPath: "timeStamp" },
        op: "LESS_THAN",
        value: toIntegerValue(anchorTimeStamp),
      },
    },
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

async function queryCandidates(accessToken, anchorTimeStamp) {
  const url = `${FIRESTORE_BASE}:runQuery`;
  const targets = [];
  const skippedFlood = [];
  let cursor = null;
  let page = 0;
  let scanned = 0;

  while (true) {
    page += 1;
    const payload = buildStructuredQuery(anchorTimeStamp, cursor);
    const rows = await fetchGoogleJson(url, accessToken, {
      method: "POST",
      body: JSON.stringify(payload),
    });
    const documents = Array.isArray(rows)
      ? rows.map((row) => row?.document).filter(Boolean)
      : [];

    if (!documents.length) {
      break;
    }

    for (const document of documents) {
      const fields = document.fields || {};
      const timeStamp = readNumberField(fields, "timeStamp", 0);
      const floodCount = readNumberField(fields, "floodCount", 0);
      const entry = {
        id: documentIdFromName(document.name),
        name: document.name,
        oldTimeStamp: timeStamp,
        floodCount,
      };
      scanned += 1;
      if (floodCount <= 1) {
        targets.push(entry);
      } else {
        skippedFlood.push(entry);
      }
      cursor = {
        name: document.name,
        timeStamp,
      };
    }

    if (documents.length < QUERY_PAGE_SIZE) {
      break;
    }
    if (MAX_QUERY_PAGES > 0 && page >= MAX_QUERY_PAGES) {
      break;
    }
  }

  targets.sort((left, right) => {
    const tsCompare = left.oldTimeStamp - right.oldTimeStamp;
    if (tsCompare !== 0) return tsCompare;
    return left.name.localeCompare(right.name, "en");
  });

  return {
    scanned,
    targetCount: targets.length,
    skippedFloodCount: skippedFlood.length,
    targets,
  };
}

function buildAssignments(targets, startMs) {
  return targets.map((target, index) => {
    const msOffset = index % 1000;
    const newTimeStamp = startMs + index * 60_000 + msOffset;
    return {
      ...target,
      ordinal: index,
      newTimeStamp,
    };
  });
}

function sliceAssignments(assignments) {
  let output = assignments;
  if (SKIP > 0) {
    output = output.slice(SKIP);
  }
  if (LIMIT > 0) {
    output = output.slice(0, LIMIT);
  }
  return output;
}

function describeAssignment(item) {
  return {
    id: item.id,
    oldTimeStamp: item.oldTimeStamp,
    oldIso: new Date(item.oldTimeStamp).toISOString(),
    newTimeStamp: item.newTimeStamp,
    newIso: new Date(item.newTimeStamp).toISOString(),
    floodCount: item.floodCount,
    ordinal: item.ordinal,
  };
}

async function commitAssignments(accessToken, assignments) {
  const url = `${FIRESTORE_BASE}:commit`;
  let committed = 0;

  for (let index = 0; index < assignments.length; index += COMMIT_BATCH_SIZE) {
    const slice = assignments.slice(index, index + COMMIT_BATCH_SIZE);
    const writes = slice.map((item) => ({
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
      body: JSON.stringify({ writes }),
    });
    committed += slice.length;

    const last = slice[slice.length - 1];
    console.log(
      JSON.stringify({
        phase: "commit_progress",
        committed,
        total: assignments.length,
        lastId: last.id,
        lastNewTimeStamp: last.newTimeStamp,
        lastNewIso: new Date(last.newTimeStamp).toISOString(),
      }),
    );

    if (PAUSE_MS > 0 && committed < assignments.length) {
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
  const anchor = await fetchAnchor(accessToken, DEFAULT_ANCHOR_POST_ID);
  const query = await queryCandidates(accessToken, anchor.timeStamp);
  const assignments = buildAssignments(query.targets, startMs);
  const selected = sliceAssignments(assignments);
  const previewHead = selected.slice(0, Math.min(5, selected.length)).map(describeAssignment);
  const previewTail = selected.slice(Math.max(0, selected.length - 5)).map(describeAssignment);

  const summary = {
    execute: EXECUTE,
    projectId: PROJECT_ID,
    anchorPostId: anchor.id,
    anchorTimeStamp: anchor.timeStamp,
    anchorIso: new Date(anchor.timeStamp).toISOString(),
    anchorFloodCount: anchor.floodCount,
    startLocal: DEFAULT_START_LOCAL,
    startTimeStamp: startMs,
    startIso: new Date(startMs).toISOString(),
    scannedBeforeAnchor: query.scanned,
    skippedFloodCount: query.skippedFloodCount,
    targetCount: query.targetCount,
    selectedCount: selected.length,
    skip: SKIP,
    limit: LIMIT,
    queryPageSize: QUERY_PAGE_SIZE,
    commitBatchSize: COMMIT_BATCH_SIZE,
    pauseMs: PAUSE_MS,
    firstAssignments: previewHead,
    lastAssignments: previewTail,
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
        committed: selected.length,
        firstAssignments: previewHead,
        lastAssignments: previewTail,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error("retime_posts_before_anchor_failed", error);
  process.exit(1);
});
