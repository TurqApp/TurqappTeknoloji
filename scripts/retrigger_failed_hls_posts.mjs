#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const DEFAULT_POST_IDS = [
  "a73bca4e-2d4e-41b6-9c6a-acf5c3d0376f_0",
  "d98dae47-c824-4814-a338-df6c6f408b6d_0",
];

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
    ids: [],
  };
  for (let index = 2; index < argv.length; index += 1) {
    const value = String(argv[index] || "").trim();
    if (!value) continue;
    if (value === "--apply") {
      args.apply = true;
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
  if (args.ids.length === 0) {
    args.ids = [...DEFAULT_POST_IDS];
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

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();
  const bucket = admin.storage().bucket(STORAGE_BUCKET);

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    posts: [],
  };

  for (const postId of options.ids) {
    const postRef = db.collection("Posts").doc(postId);
    const sourcePath = `Posts/${postId}/video.mp4`;
    const sourceFile = bucket.file(sourcePath);
    const [sourceExists] = await sourceFile.exists();
    const tempPath = `repairTmp/hls-retrigger/${postId}-${Date.now()}.mp4`;

    const postSnap = await postRef.get();
    const postData = postSnap.exists ? postSnap.data() || {} : {};
    const row = {
      postId,
      postExists: postSnap.exists,
      sourcePath,
      sourceExists,
      hlsStatusBefore: String(postData.hlsStatus || ""),
      tempPath,
      triggered: false,
    };

    if (!sourceExists || !postSnap.exists) {
      summary.posts.push(row);
      continue;
    }

    if (options.apply) {
      await postRef.set(
        {
          hlsStatus: "processing",
          isUploading: true,
          hlsUpdatedAt: Date.now(),
        },
        { merge: true },
      );
      await sourceFile.copy(bucket.file(tempPath));
      await bucket.file(tempPath).copy(sourceFile);
      await bucket.file(tempPath).delete({ ignoreNotFound: true });
      row.triggered = true;
    }

    summary.posts.push(row);
  }

  console.log(JSON.stringify(summary, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
