#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";

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
    docId: "",
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = String(argv[index] || "").trim();
    if (!value) continue;
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
    if (value === "--doc-id") {
      args.docId = String(argv[index + 1] || "").trim();
      index += 1;
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

function initializeAdmin() {
  if (admin.apps.length > 0) return;
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT;
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    });
    return;
  }
  admin.initializeApp({
    projectId: PROJECT_ID,
    storageBucket: STORAGE_BUCKET,
  });
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
    if (parsed.hostname === "cdn.turqapp.com" || parsed.hostname === "storage.googleapis.com") {
      const pathname = parsed.pathname.replace(/^\/+/, "");
      if (pathname.startsWith(`${STORAGE_BUCKET}/`)) {
        return pathname.slice(STORAGE_BUCKET.length + 1);
      }
      if (pathname.startsWith("Posts/")) {
        return pathname;
      }
    }
  } catch {}

  return "";
}

function buildCanonicalPostAssetUrlFromStoragePath(storagePath) {
  const normalized = asString(storagePath).replace(/^\/+/, "");
  if (!normalized) return "";
  return `https://cdn.turqapp.com/${normalized}`;
}

function buildPatch(docId, data) {
  const currentThumbnail = asString(data.thumbnail);
  if (!currentThumbnail) return { patch: {}, changed: {} };

  const objectPath = decodeStorageObjectPath(currentThumbnail);
  if (!objectPath.startsWith(`Posts/${docId}/thumbnail.`)) {
    return { patch: {}, changed: {} };
  }

  const canonical = buildCanonicalPostAssetUrlFromStoragePath(objectPath);
  if (!canonical || canonical === currentThumbnail) {
    return { patch: {}, changed: {} };
  }

  return {
    patch: { thumbnail: canonical },
    changed: {
      thumbnail: {
        before: currentThumbnail,
        after: canonical,
      },
    },
  };
}

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    scannedPosts: 0,
    touchedPosts: 0,
    unchangedPosts: 0,
    lastDocId: "",
    samples: [],
  };

  let query = db.collection("Posts").orderBy(admin.firestore.FieldPath.documentId()).limit(options.pageSize);
  if (options.docId) {
    query = db.collection("Posts").where(admin.firestore.FieldPath.documentId(), "==", options.docId).limit(1);
  } else if (options.cursor) {
    query = query.startAfter(options.cursor);
  }

  let processed = 0;
  const bulkWriter = options.apply ? db.bulkWriter() : null;

  while (true) {
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const docId = doc.id;
      summary.scannedPosts += 1;
      summary.lastDocId = docId;

      const { patch, changed } = buildPatch(docId, doc.data() || {});
      if (Object.keys(changed).length === 0) {
        summary.unchangedPosts += 1;
      } else {
        summary.touchedPosts += 1;
        if (summary.samples.length < 10) {
          summary.samples.push({ docId, changed });
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

    if (options.docId) break;

    const lastDoc = snap.docs[snap.docs.length - 1];
    query = db
      .collection("Posts")
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
