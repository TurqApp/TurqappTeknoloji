#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";
const DEFAULT_DOC_IDS = [
  "8ec09dba-fdb5-4cb1-85e0-f68b461101d2",
  "a66c0823-62a9-4e15-8c5c-ac1448d06d3f",
];

const require = createRequire(import.meta.url);
const admin = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/firebase-admin",
));

function parseArgs(argv) {
  const args = {
    apply: false,
    report: "",
    ids: [...DEFAULT_DOC_IDS],
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

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

function toCdnDownloadUrl(rawUrl) {
  const text = asString(rawUrl);
  if (!text) return "";
  try {
    const parsed = new URL(text);
    if (
      parsed.hostname === "firebasestorage.googleapis.com" ||
      parsed.hostname === "turqappteknoloji.firebasestorage.app"
    ) {
      parsed.hostname = "cdn.turqapp.com";
      return parsed.toString();
    }
    return text;
  } catch {
    return text;
  }
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

function buildPatch(data) {
  const patch = {};
  const changed = {};

  const img = Array.isArray(data.img) ? data.img.map((value) => asString(value)) : [];
  if (img.length > 0) {
    const nextImg = img.map((value) => toCdnDownloadUrl(value));
    if (JSON.stringify(nextImg) !== JSON.stringify(img)) {
      patch.img = nextImg;
      changed.img = { before: img, after: nextImg };
    }
  }

  const thumbnail = asString(data.thumbnail);
  const nextThumbnail = toCdnDownloadUrl(thumbnail);
  if (nextThumbnail && nextThumbnail !== thumbnail) {
    patch.thumbnail = nextThumbnail;
    changed.thumbnail = { before: thumbnail, after: nextThumbnail };
  }

  const imgMap = Array.isArray(data.imgMap) ? data.imgMap : [];
  if (imgMap.length > 0) {
    const nextImgMap = imgMap.map((entry) => {
      if (!entry || typeof entry !== "object" || Array.isArray(entry)) return entry;
      const currentUrl = asString(entry.url);
      const nextUrl = toCdnDownloadUrl(currentUrl);
      return nextUrl && nextUrl !== currentUrl ? { ...entry, url: nextUrl } : entry;
    });
    if (JSON.stringify(nextImgMap) !== JSON.stringify(imgMap)) {
      patch.imgMap = nextImgMap;
      changed.imgMap = { before: imgMap, after: nextImgMap };
    }
  }

  return { patch, changed };
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
    samples: [],
  };

  const writer = options.apply ? db.bulkWriter() : null;

  for (const docId of options.ids) {
    const ref = db.collection("Posts").doc(docId);
    const snap = await ref.get();
    if (!snap.exists) continue;
    summary.scannedPosts += 1;
    const { patch, changed } = buildPatch(snap.data() || {});
    if (Object.keys(changed).length === 0) {
      summary.unchangedPosts += 1;
      continue;
    }
    summary.touchedPosts += 1;
    summary.samples.push({ docId, changed });
    if (writer) {
      writer.set(ref, patch, { merge: true });
    }
  }

  if (writer) await writer.close();
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
