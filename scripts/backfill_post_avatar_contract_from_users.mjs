#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const admin = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/firebase-admin",
));

function parseArgs(argv) {
  const args = {
    input: "",
    apply: false,
    report: "",
    limit: 0,
    offset: 0,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = argv[index];
    if (!args.input && !value.startsWith("--")) {
      args.input = value;
      continue;
    }
    if (value === "--apply") {
      args.apply = true;
      continue;
    }
    if (value === "--report") {
      args.report = String(argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
    if (value === "--limit") {
      args.limit = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
    if (value === "--offset") {
      args.offset = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
  }

  if (!args.input) {
    throw new Error(
      "Usage: node scripts/backfill_post_avatar_contract_from_users.mjs <input.ndjson> [--apply] [--offset N] [--limit N] [--report out.json]",
    );
  }

  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

function readRows(filePath) {
  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) return [];
  return raw.split(/\n+/).map((line) => JSON.parse(line));
}

function initializeAdmin() {
  if (admin.apps.length > 0) return;
  admin.initializeApp();
}

async function loadUserAvatarMap(db) {
  const result = new Map();
  let query = db
    .collection("users")
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(500);

  while (true) {
    const snap = await query.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      const avatarUrl = asString(doc.get("avatarUrl"));
      if (avatarUrl) {
        result.set(doc.id, avatarUrl);
      }
    }
    const last = snap.docs[snap.docs.length - 1];
    query = db
      .collection("users")
      .orderBy(admin.firestore.FieldPath.documentId())
      .startAfter(last.id)
      .limit(500);
  }

  return result;
}

function buildPatch(row, avatarByUserId) {
  const docId = asString(row.docId);
  const data = row.data || {};
  const userID = asString(data.userID);
  const canonicalAvatar = avatarByUserId.get(userID) || "";
  if (!docId || !userID || !canonicalAvatar) {
    return { docId, userID, patch: {}, changed: {} };
  }

  const currentAuthorAvatarUrl = asString(data.authorAvatarUrl);
  const currentAvatarUrl = asString(data.avatarUrl);
  const patch = {};
  const changed = {};

  if (currentAuthorAvatarUrl !== canonicalAvatar) {
    patch.authorAvatarUrl = canonicalAvatar;
    changed.authorAvatarUrl = {
      before: currentAuthorAvatarUrl || null,
      after: canonicalAvatar,
    };
  }

  if (currentAvatarUrl !== canonicalAvatar) {
    patch.avatarUrl = canonicalAvatar;
    changed.avatarUrl = {
      before: currentAvatarUrl || null,
      after: canonicalAvatar,
    };
  }

  return { docId, userID, patch, changed };
}

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();
  const avatarByUserId = await loadUserAvatarMap(db);
  const rows = readRows(options.input).slice(options.offset);
  const sourceRows = options.limit > 0 ? rows.slice(0, options.limit) : rows;

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    scannedRows: sourceRows.length,
    userAvatarsLoaded: avatarByUserId.size,
    touchedPosts: 0,
    unchangedPosts: 0,
    missingUserAvatar: 0,
    patchFields: {
      authorAvatarUrl: 0,
      avatarUrl: 0,
    },
    samples: [],
  };

  const bulkWriter = options.apply ? db.bulkWriter() : null;

  for (const row of sourceRows) {
    const { docId, userID, patch, changed } = buildPatch(row, avatarByUserId);
    if (!docId || !userID) continue;
    if (!avatarByUserId.get(userID)) {
      summary.missingUserAvatar += 1;
      continue;
    }
    if (Object.keys(changed).length === 0) {
      summary.unchangedPosts += 1;
      continue;
    }

    summary.touchedPosts += 1;
    if (changed.authorAvatarUrl) summary.patchFields.authorAvatarUrl += 1;
    if (changed.avatarUrl) summary.patchFields.avatarUrl += 1;
    if (summary.samples.length < 10) {
      summary.samples.push({ docId, userID, changed });
    }
    if (bulkWriter) {
      bulkWriter.set(db.collection("Posts").doc(docId), patch, { merge: true });
    }
  }

  if (bulkWriter) {
    await bulkWriter.close();
  }

  if (options.report) {
    ensureDir(options.report);
    fs.writeFileSync(options.report, JSON.stringify(summary, null, 2));
  }

  console.log(JSON.stringify(summary, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
