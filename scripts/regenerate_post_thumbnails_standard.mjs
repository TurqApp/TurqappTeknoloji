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
const DEFAULT_REPORT_DIR =
  "/Users/turqapp/Desktop/TurqApp/artifacts/thumbnail_regen";
const THUMBNAIL_VERSION = 2;
const CANDIDATE_MS = [0, 33, 67, 100];
const MIN_ACCEPTABLE_SCORE = 18;

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
    limit: 0,
    cursor: "",
    pageSize: 200,
    concurrency: 4,
    reportDir: DEFAULT_REPORT_DIR,
    docId: "",
    onlyMissingMetadata: false,
    force: false,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = String(argv[index] || "").trim();
    if (!value) continue;
    if (value === "--apply") {
      args.apply = true;
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
      args.pageSize = Math.max(1, Number(argv[index + 1] || 200));
      index += 1;
      continue;
    }
    if (value === "--concurrency") {
      args.concurrency = Math.max(1, Number(argv[index + 1] || 4));
      index += 1;
      continue;
    }
    if (value === "--report-dir") {
      args.reportDir = String(argv[index + 1] || "").trim() || DEFAULT_REPORT_DIR;
      index += 1;
      continue;
    }
    if (value === "--doc-id") {
      args.docId = String(argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
    if (value === "--only-missing-metadata") {
      args.onlyMissingMetadata = true;
      continue;
    }
    if (value === "--force") {
      args.force = true;
    }
  }
  return args;
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function initializeAdmin() {
  if (admin.apps.length > 0) return;
  const serviceAccountPath =
    process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT;
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

function canonicalThumbnailUrl(postId) {
  return `https://cdn.turqapp.com/Posts/${postId}/thumbnail.webp`;
}

function currentThumbnailGeneration(data) {
  const raw = data?.thumbnailGeneration;
  if (!raw || typeof raw !== "object") return null;
  return raw;
}

function shouldProcessPost(docId, data, options) {
  const video = asString(data.video);
  if (!video || !video.includes("/hls/") && !video.includes("video.mp4") && !video.includes(".m3u8")) {
    return { ok: false, reason: "missing_video_field" };
  }
  const thumbGen = currentThumbnailGeneration(data);
  if (options.force) return { ok: true, reason: "forced" };
  if (options.onlyMissingMetadata) {
    if (!thumbGen) return { ok: true, reason: "missing_thumbnail_generation" };
    return { ok: false, reason: "has_thumbnail_generation" };
  }
  if (!thumbGen) return { ok: true, reason: "missing_thumbnail_generation" };
  const version = Number(thumbGen.version || 0);
  const strategy = asString(thumbGen.strategy);
  if (version < THUMBNAIL_VERSION) {
    return { ok: true, reason: `version_lt_${THUMBNAIL_VERSION}` };
  }
  if (strategy !== "auto_early_frame" && strategy !== "manual_custom") {
    return { ok: true, reason: `strategy_${strategy || "unknown"}` };
  }
  return { ok: false, reason: "already_standard" };
}

async function fileExists(file) {
  const [exists] = await file.exists();
  return exists;
}

async function extractFrame(localVideoPath, framePath, timeMs) {
  await execFileAsync(
    "ffmpeg",
    [
      "-y",
      "-ss",
      (timeMs / 1000).toFixed(3),
      "-i",
      localVideoPath,
      "-vframes",
      "1",
      "-vf",
      "scale=600:-2",
      "-q:v",
      "2",
      framePath,
    ],
    { maxBuffer: 20 * 1024 * 1024 },
  );
}

async function scoreFrame(framePath) {
  const { data, info } = await sharp(framePath)
    .resize(24, 24, { fit: "cover" })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  if (!data || !info || info.channels < 3) return Number.NEGATIVE_INFINITY;

  let sum = 0;
  let sumSquares = 0;
  let count = 0;

  for (let i = 0; i + 2 < data.length; i += info.channels) {
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    const luma = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
    sum += luma;
    sumSquares += luma * luma;
    count += 1;
  }

  if (count === 0) return Number.NEGATIVE_INFINITY;
  const mean = sum / count;
  const variance = (sumSquares / count) - (mean * mean);
  if (mean < 14) return mean - 1000;
  return variance + (mean * 0.15);
}

async function generateStandardThumbnail(localVideoPath, tempDir) {
  let best = null;

  for (const timeMs of CANDIDATE_MS) {
    const framePath = path.join(tempDir, `frame_${timeMs}.jpg`);
    try {
      await extractFrame(localVideoPath, framePath, timeMs);
      const score = await scoreFrame(framePath);
      if (Number.isFinite(score) && score >= MIN_ACCEPTABLE_SCORE) {
        const webpPath = path.join(tempDir, "thumbnail.webp");
        await sharp(framePath).webp({ quality: 85 }).toFile(webpPath);
        return { webpPath, frameMs: timeMs, score, accepted: true };
      }
      if (!best || score > best.score) {
        best = { framePath, frameMs: timeMs, score };
      }
    } catch {
      // ignore candidate failure; try next candidate
    }
  }

  if (!best) return null;
  const webpPath = path.join(tempDir, "thumbnail.webp");
  await sharp(best.framePath).webp({ quality: 85 }).toFile(webpPath);
  return { webpPath, frameMs: best.frameMs, score: best.score, accepted: false };
}

function appendJsonl(filePath, entry) {
  fs.appendFileSync(filePath, `${JSON.stringify(entry)}\n`);
}

function writeJson(filePath, payload) {
  fs.writeFileSync(filePath, JSON.stringify(payload, null, 2));
}

async function processPost({ bucket, db, doc, options, progress, files }) {
  const docId = doc.id;
  const data = doc.data() || {};
  const decision = shouldProcessPost(docId, data, options);
  const baseLog = {
    docId,
    startedAt: new Date().toISOString(),
    decision: decision.reason,
  };

  if (!decision.ok) {
    progress.skipped += 1;
    appendJsonl(files.actions, { ...baseLog, status: "skipped" });
    return;
  }

  const videoPath = `Posts/${docId}/video.mp4`;
  const thumbnailPath = `Posts/${docId}/thumbnail.webp`;
  const videoFile = bucket.file(videoPath);
  const thumbFile = bucket.file(thumbnailPath);
  const exists = await fileExists(videoFile);
  if (!exists) {
    progress.failed += 1;
    appendJsonl(files.actions, {
      ...baseLog,
      status: "failed",
      reason: "missing_video_mp4",
    });
    return;
  }

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), `turq-thumb-${docId}-`));
  const localVideo = path.join(tempDir, "video.mp4");

  try {
    await videoFile.download({ destination: localVideo });
    const generated = await generateStandardThumbnail(localVideo, tempDir);
    if (!generated) {
      progress.failed += 1;
      appendJsonl(files.actions, {
        ...baseLog,
        status: "failed",
        reason: "thumbnail_generation_failed",
      });
      return;
    }

    if (options.apply) {
      await bucket.upload(generated.webpPath, {
        destination: thumbnailPath,
        metadata: {
          contentType: "image/webp",
          cacheControl: "public, max-age=86400",
          metadata: {
            thumbnailVersion: String(THUMBNAIL_VERSION),
            thumbnailStrategy: "auto_early_frame",
            thumbnailFrameMs: String(generated.frameMs),
          },
        },
      });

      await doc.ref.set({
        thumbnail: canonicalThumbnailUrl(docId),
        thumbnailGeneration: {
          strategy: "auto_early_frame",
          frameMs: generated.frameMs,
          version: THUMBNAIL_VERSION,
          generatedAt: Date.now(),
          source: "batch_regen",
        },
      }, { merge: true });
    }

    progress.updated += 1;
    appendJsonl(files.actions, {
      ...baseLog,
      status: options.apply ? "updated" : "would_update",
      frameMs: generated.frameMs,
      score: generated.score,
      accepted: generated.accepted,
      thumbnailPath,
      completedAt: new Date().toISOString(),
    });
  } catch (error) {
    progress.failed += 1;
    appendJsonl(files.actions, {
      ...baseLog,
      status: "failed",
      reason: "exception",
      error: String(error?.message || error),
    });
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

async function runBatch(items, workerCount, worker, shouldStop) {
  let cursor = 0;
  const runners = Array.from({ length: workerCount }, async () => {
    while (cursor < items.length) {
      if (shouldStop?.() === true) break;
      const index = cursor;
      cursor += 1;
      await worker(items[index], index);
    }
  });
  await Promise.all(runners);
}

async function run() {
  const options = parseArgs(process.argv);
  initializeAdmin();
  const db = admin.firestore();
  const bucket = admin.storage().bucket(STORAGE_BUCKET);

  ensureDir(options.reportDir);
  const runStamp = new Date().toISOString().replace(/[:.]/g, "-");
  const files = {
    progress: path.join(options.reportDir, `progress_${runStamp}.json`),
    summary: path.join(options.reportDir, `summary_${runStamp}.json`),
    actions: path.join(options.reportDir, `actions_${runStamp}.jsonl`),
  };

  const progress = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    updated: 0,
    skipped: 0,
    failed: 0,
    scanned: 0,
    lastDocId: "",
    options,
  };
  writeJson(files.progress, progress);

  let processed = 0;
  let query;
  if (options.docId) {
    query = db.collection("Posts")
      .where(admin.firestore.FieldPath.documentId(), "==", options.docId)
      .limit(1);
  } else {
    query = db.collection("Posts")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(options.pageSize);
    if (options.cursor) query = query.startAfter(options.cursor);
  }

  while (true) {
    const snap = await query.get();
    if (snap.empty) break;

    await runBatch(snap.docs, options.concurrency, async (doc) => {
      if (options.limit > 0 && processed >= options.limit) return;
      progress.scanned += 1;
      progress.lastDocId = doc.id;
      await processPost({ bucket, db, doc, options, progress, files });
      writeJson(files.progress, progress);
      processed += 1;
      if (processed % 25 === 0) {
        console.log(JSON.stringify({
          scanned: progress.scanned,
          updated: progress.updated,
          skipped: progress.skipped,
          failed: progress.failed,
          lastDocId: progress.lastDocId,
        }));
      }
    }, () => options.limit > 0 && processed >= options.limit);

    if (options.docId) break;
    if (options.limit > 0 && processed >= options.limit) break;

    const lastDoc = snap.docs[snap.docs.length - 1];
    query = db.collection("Posts")
      .orderBy(admin.firestore.FieldPath.documentId())
      .startAfter(lastDoc.id)
      .limit(options.pageSize);
  }

  const summary = {
    ...progress,
    finishedAt: new Date().toISOString(),
    files,
  };
  writeJson(files.summary, summary);
  console.log(JSON.stringify(summary, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
