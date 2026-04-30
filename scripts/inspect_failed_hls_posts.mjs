#!/usr/bin/env node

import path from "node:path";
import { createRequire } from "node:module";
import fs from "node:fs";

const DEFAULT_POST_IDS = [
  "a73bca4e-2d4e-41b6-9c6a-acf5c3d0376f_0",
  "d98dae47-c824-4814-a338-df6c6f408b6d_0",
];

const THUMB_EXTENSIONS = ["webp", "jpg", "jpeg", "png"];
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
  const args = { ids: [] };
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
  if (args.ids.length === 0) {
    args.ids = [...DEFAULT_POST_IDS];
  }
  return args;
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

async function fileStat(bucket, filePath) {
  const file = bucket.file(filePath);
  const [exists] = await file.exists();
  if (!exists) {
    return { path: filePath, exists: false };
  }
  const [metadata] = await file.getMetadata();
  return {
    path: filePath,
    exists: true,
    size: Number(metadata.size || 0),
    contentType: asString(metadata.contentType),
    updated: asString(metadata.updated),
  };
}

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();
  const bucket = admin.storage().bucket(STORAGE_BUCKET);

  const result = {
    generatedAt: new Date().toISOString(),
    posts: [],
  };

  for (const postId of options.ids) {
    const postSnap = await db.collection("Posts").doc(postId).get();
    const postData = postSnap.exists ? postSnap.data() || {} : null;
    const thumbStats = [];
    for (const ext of THUMB_EXTENSIONS) {
      thumbStats.push(await fileStat(bucket, `Posts/${postId}/thumbnail.${ext}`));
    }
    const [hlsFiles] = await bucket.getFiles({
      prefix: `Posts/${postId}/hls/`,
      autoPaginate: false,
      maxResults: 20,
    });

    result.posts.push({
      postId,
      exists: postSnap.exists,
      firestore: postData
        ? {
            hlsStatus: asString(postData.hlsStatus),
            video: asString(postData.video),
            hlsMasterUrl: asString(postData.hlsMasterUrl),
            thumbnail: asString(postData.thumbnail),
            sourceVideoUrl: asString(postData.sourceVideoUrl),
            isUploading: postData.isUploading === true,
          }
        : null,
      storage: {
        video: await fileStat(bucket, `Posts/${postId}/video.mp4`),
        hlsMaster: await fileStat(bucket, `Posts/${postId}/hls/master.m3u8`),
        thumbnails: thumbStats,
        hlsFiles: hlsFiles.map((file) => file.name).sort(),
      },
    });
  }

  console.log(JSON.stringify(result, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
