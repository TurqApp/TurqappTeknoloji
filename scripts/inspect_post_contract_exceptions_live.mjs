#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";
const DEFAULT_DOC_IDS = [
  "2fab8c90-236c-4cf1-98d6-0f1bf11fb061",
  "5436e64b-5bc4-4889-804d-fd42e5701743_2",
  "5436e64b-5bc4-4889-804d-fd42e5701743_3",
  "5436e64b-5bc4-4889-804d-fd42e5701743_4",
  "5436e64b-5bc4-4889-804d-fd42e5701743_5",
  "5436e64b-5bc4-4889-804d-fd42e5701743_6",
  "5436e64b-5bc4-4889-804d-fd42e5701743_7",
  "5436e64b-5bc4-4889-804d-fd42e5701743_8",
];

const require = createRequire(import.meta.url);
const admin = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/firebase-admin",
));

function parseArgs(argv) {
  const args = { ids: [...DEFAULT_DOC_IDS] };
  for (let index = 2; index < argv.length; index += 1) {
    const value = String(argv[index] || "").trim();
    if (value === "--ids") {
      args.ids = String(argv[index + 1] || "")
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean);
      index += 1;
    }
  }
  return args;
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

function asString(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();

  const out = {
    generatedAt: new Date().toISOString(),
    posts: [],
  };

  for (const docId of options.ids) {
    const snap = await db.collection("Posts").doc(docId).get();
    out.posts.push({
      docId,
      exists: snap.exists,
      data: snap.exists ? {
        shortId: asString(snap.get("shortId")),
        shortUrl: asString(snap.get("shortUrl")),
        shortLinkStatus: asString(snap.get("shortLinkStatus")),
        hlsStatus: asString(snap.get("hlsStatus")),
        video: asString(snap.get("video")),
        hlsMasterUrl: asString(snap.get("hlsMasterUrl")),
        thumbnail: asString(snap.get("thumbnail")),
        isUploading: snap.get("isUploading") === true,
      } : null,
    });
  }

  console.log(JSON.stringify(out, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
