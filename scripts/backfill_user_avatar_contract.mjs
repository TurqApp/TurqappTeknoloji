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
    apply: false,
    report: "",
    limit: 0,
    cursor: "",
    pageSize: 500,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = argv[index];
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
    if (value === "--cursor") {
      args.cursor = String(argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
    if (value === "--page-size") {
      args.pageSize = Math.max(1, Number(argv[index + 1] || 500));
      index += 1;
      continue;
    }
  }

  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

function decodeStorageObjectPath(rawUrl) {
  const text = asString(rawUrl);
  if (!text) return "";

  if (text.startsWith("gs://")) {
    const parts = text.replace("gs://", "").split("/");
    parts.shift();
    return parts.join("/");
  }

  try {
    const parsed = new URL(text);
    const objectIndex = parsed.pathname.indexOf("/o/");
    if (objectIndex >= 0) {
      return decodeURIComponent(parsed.pathname.slice(objectIndex + 3));
    }
    if (parsed.hostname === "cdn.turqapp.com") {
      return parsed.pathname.replace(/^\/+/, "");
    }
  } catch {}

  return "";
}

function canonicalizeUserAssetUrl(rawUrl, uid = "") {
  const text = asString(rawUrl);
  if (!text) return "";
  const objectPath = decodeStorageObjectPath(text);
  if (!objectPath.startsWith("users/")) return text;
  const relative = objectPath.slice("users/".length);
  const slashIndex = relative.indexOf("/");
  if (slashIndex <= 0) return text;
  const objectUid = relative.slice(0, slashIndex);
  if (uid && uid !== objectUid) return text;
  return `https://cdn.turqapp.com/${objectPath}`;
}

function buildPatch(uid, data) {
  const currentAvatarUrl = asString(data.avatarUrl);
  const currentProfileImage = asString(data.profileImage);
  const currentPhotoUrl = asString(data.photoUrl);
  const currentImageUrl = asString(data.imageUrl);

  const canonicalAvatarUrl = canonicalizeUserAssetUrl(
    currentAvatarUrl || currentProfileImage || currentPhotoUrl || currentImageUrl,
    uid,
  );

  const patch = {};
  const changed = {};

  if (canonicalAvatarUrl && canonicalAvatarUrl !== currentAvatarUrl) {
    patch.avatarUrl = canonicalAvatarUrl;
    changed.avatarUrl = {
      before: currentAvatarUrl || null,
      after: canonicalAvatarUrl,
    };
  }

  return { patch, changed };
}

function initializeAdmin() {
  if (admin.apps.length > 0) return;
  admin.initializeApp();
}

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    scannedUsers: 0,
    touchedUsers: 0,
    unchangedUsers: 0,
    patchFields: {
      avatarUrl: 0,
    },
    lastDocId: "",
    samples: [],
  };

  let query = db.collection("users").orderBy(admin.firestore.FieldPath.documentId()).limit(options.pageSize);
  if (options.cursor) {
    query = query.startAfter(options.cursor);
  }

  let processed = 0;
  let bulkWriter = options.apply ? db.bulkWriter() : null;

  while (true) {
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const uid = doc.id;
      const data = doc.data() || {};
      summary.scannedUsers += 1;
      summary.lastDocId = uid;

      const { patch, changed } = buildPatch(uid, data);
      if (Object.keys(changed).length === 0) {
        summary.unchangedUsers += 1;
      } else {
        summary.touchedUsers += 1;
        if (changed.avatarUrl) summary.patchFields.avatarUrl += 1;
        if (summary.samples.length < 10) {
          summary.samples.push({ uid, changed });
        }
        if (bulkWriter) {
          bulkWriter.set(doc.ref, patch, { merge: true });
        }
      }

      processed += 1;
      if (options.limit > 0 && processed >= options.limit) {
        if (bulkWriter) await bulkWriter.close();
        if (options.report) {
          ensureDir(options.report);
          fs.writeFileSync(options.report, JSON.stringify(summary, null, 2));
        }
        console.log(JSON.stringify(summary, null, 2));
        return;
      }
    }

    const lastDoc = snap.docs[snap.docs.length - 1];
    query = db
      .collection("users")
      .orderBy(admin.firestore.FieldPath.documentId())
      .startAfter(lastDoc.id)
      .limit(options.pageSize);
  }

  if (bulkWriter) await bulkWriter.close();
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
