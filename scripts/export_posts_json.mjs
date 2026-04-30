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
    out: "/Users/turqapp/Documents/Turqapp/repo/tmp/target_Posts_all.json",
    pageSize: 500,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = String(argv[index] || "").trim();
    if (!value) continue;
    if (value === "--out") {
      args.out = String(argv[index + 1] || "").trim() || args.out;
      index += 1;
      continue;
    }
    if (value === "--page-size") {
      args.pageSize = Math.max(1, Number(argv[index + 1] || 500));
      index += 1;
    }
  }

  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function normalizeValue(value) {
  if (value === undefined) return null;
  if (value === null) return null;
  if (typeof value === "number" || typeof value === "string" || typeof value === "boolean") {
    return value;
  }
  if (Array.isArray(value)) {
    return value.map((entry) => normalizeValue(entry));
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value?.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (typeof value === "object") {
    const out = {};
    for (const [key, entry] of Object.entries(value)) {
      out[key] = normalizeValue(entry);
    }
    return out;
  }
  return String(value);
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

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  ensureDir(options.out);

  const db = admin.firestore();
  const stream = fs.createWriteStream(options.out, { encoding: "utf8" });
  let lastDoc = null;
  let scanned = 0;
  let first = true;

  stream.write("[\n");

  while (true) {
    let query = db
      .collection("Posts")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(options.pageSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc.id);
    }

    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const row = {
        docId: doc.id,
        ...normalizeValue(doc.data() || {}),
      };
      if (!first) {
        stream.write(",\n");
      }
      stream.write(JSON.stringify(row, null, 2));
      first = false;
      scanned += 1;
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < options.pageSize) break;
  }

  stream.write("\n]\n");
  await new Promise((resolve, reject) => {
    stream.end((error) => {
      if (error) reject(error);
      else resolve();
    });
  });
  console.log(JSON.stringify({
    ok: true,
    out: options.out,
    count: scanned,
    scanned,
    bytes: fs.statSync(options.out).size,
  }, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
