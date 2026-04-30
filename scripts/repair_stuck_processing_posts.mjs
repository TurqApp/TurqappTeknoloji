#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createRequire } from "node:module";
import { promisify } from "node:util";
import { execFile } from "node:child_process";

const execFileAsync = promisify(execFile);

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";
const DEFAULT_DOC_IDS = [
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
const sharp = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/sharp",
));

function parseArgs(argv) {
  const args = {
    apply: false,
    ids: [...DEFAULT_DOC_IDS],
    report: "",
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
      continue;
    }
    if (value === "--report") {
      args.report = String(argv[index + 1] || "").trim();
      index += 1;
    }
  }
  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
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

function canonicalThumbnailUrl(postId) {
  return `https://cdn.turqapp.com/Posts/${postId}/thumbnail.webp`;
}

function canonicalHlsUrl(postId) {
  return `https://cdn.turqapp.com/Posts/${postId}/hls/master.m3u8`;
}

async function fileExists(file) {
  const [exists] = await file.exists();
  return exists;
}

async function generateThumbnail(localVideoPath, localThumbPath) {
  const localFramePath = localThumbPath.replace(/\.webp$/i, ".jpg");
  await execFileAsync("ffmpeg", [
    "-y",
    "-ss",
    "00:00:01.000",
    "-i",
    localVideoPath,
    "-vframes",
    "1",
    "-vf",
    "scale=600:-2",
    "-q:v",
    "2",
    localFramePath,
  ], { maxBuffer: 20 * 1024 * 1024 });
  await sharp(localFramePath)
    .webp({ quality: 85 })
    .toFile(localThumbPath);
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
    const postSnap = await postRef.get();
    const row = {
      postId,
      exists: postSnap.exists,
      repairedMaster: false,
      repairedThumbnail: false,
      repairedFirestore: false,
      notes: [],
    };

    if (!postSnap.exists) {
      row.notes.push("missing_firestore_doc");
      summary.posts.push(row);
      continue;
    }

    const videoPath = `Posts/${postId}/video.mp4`;
    const variantPlaylistPath = `Posts/${postId}/hls/0/playlist.m3u8`;
    const masterPath = `Posts/${postId}/hls/master.m3u8`;
    const thumbnailPath = `Posts/${postId}/thumbnail.webp`;

    const videoFile = bucket.file(videoPath);
    const variantFile = bucket.file(variantPlaylistPath);
    const masterFile = bucket.file(masterPath);
    const thumbFile = bucket.file(thumbnailPath);

    const [videoExists, variantExists, masterExists, thumbExists] = await Promise.all([
      fileExists(videoFile),
      fileExists(variantFile),
      fileExists(masterFile),
      fileExists(thumbFile),
    ]);

    if (!videoExists) row.notes.push("missing_video");
    if (!variantExists) row.notes.push("missing_variant_playlist");
    if (!videoExists || !variantExists) {
      summary.posts.push(row);
      continue;
    }

    if (options.apply) {
      if (!masterExists) {
        const masterBody = [
          "#EXTM3U",
          "#EXT-X-VERSION:3",
          "#EXT-X-STREAM-INF:BANDWIDTH=1400000",
          "0/playlist.m3u8",
          "",
        ].join("\n");
        await masterFile.save(masterBody, {
          resumable: false,
          metadata: {
            contentType: "application/vnd.apple.mpegurl",
            cacheControl: "public, max-age=300, s-maxage=300",
          },
        });
        row.repairedMaster = true;
      }

      if (!thumbExists) {
        const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "turq-thumb-"));
        const localVideo = path.join(tempDir, "video.mp4");
        const localThumb = path.join(tempDir, "thumbnail.webp");
        await videoFile.download({ destination: localVideo });
        await generateThumbnail(localVideo, localThumb);
        await bucket.upload(localThumb, {
          destination: thumbnailPath,
          metadata: {
            contentType: "image/webp",
            cacheControl: "public, max-age=86400",
          },
        });
        fs.rmSync(tempDir, { recursive: true, force: true });
        row.repairedThumbnail = true;
      }

      await postRef.set({
        hlsStatus: "ready",
        isUploading: false,
        hlsMasterUrl: canonicalHlsUrl(postId),
        video: canonicalHlsUrl(postId),
        thumbnail: canonicalThumbnailUrl(postId),
        hlsUpdatedAt: Date.now(),
      }, { merge: true });
      row.repairedFirestore = true;
    } else {
      if (!masterExists) row.repairedMaster = true;
      if (!thumbExists) row.repairedThumbnail = true;
      row.repairedFirestore = true;
    }

    summary.posts.push(row);
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
