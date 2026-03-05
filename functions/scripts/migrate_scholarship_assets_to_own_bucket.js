#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require("firebase-admin");
const fs = require("fs");
const os = require("os");
const path = require("path");
const crypto = require("crypto");
const https = require("https");
const http = require("http");

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function loadServiceAccount(keyPath) {
  if (!keyPath || !fs.existsSync(keyPath)) {
    throw new Error(`Service account bulunamadi: ${keyPath}`);
  }
  const raw = fs.readFileSync(keyPath, "utf8");
  const firstBrace = raw.indexOf("{");
  return JSON.parse(firstBrace > 0 ? raw.slice(firstBrace) : raw);
}

function downloadToFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith("https") ? https : http;
    const req = mod.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(downloadToFile(res.headers.location, destPath));
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode}: ${url}`));
      }
      const ws = fs.createWriteStream(destPath);
      res.pipe(ws);
      ws.on("finish", () => ws.close(() => resolve(destPath)));
      ws.on("error", reject);
    });
    req.on("error", reject);
  });
}

function extractStorageObjectPath(rawUrl) {
  const text = String(rawUrl || "").trim();
  if (!text) return "";

  try {
    const parsed = new URL(text);
    const oIdx = parsed.pathname.indexOf("/o/");
    if (oIdx === -1) return "";
    const encoded = parsed.pathname.slice(oIdx + 3);
    if (!encoded) return "";
    return decodeURIComponent(encoded);
  } catch (_) {
    return "";
  }
}

function extOfObjectPath(objectPath) {
  const clean = String(objectPath || "").split("?")[0];
  const ext = path.extname(clean).toLowerCase();
  return ext || "";
}

function buildFirebaseDownloadUrl(bucketName, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(
    objectPath
  )}?alt=media&token=${token}`;
}

function pickShareImage(data, fallback) {
  const img = String(data.img || "").trim();
  if (img) return img;
  const img2 = String(data.img2 || "").trim();
  if (img2) return img2;
  const logo = String(data.logo || "").trim();
  if (logo) return logo;
  return fallback;
}

async function run() {
  const targetKey = arg(
    "target-key",
    "/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json"
  );
  const collection = arg("collection", "scholarships");
  const sourceBucketHint = arg("source-bucket-hint", "burs-city.appspot.com");
  const targetBucket = arg("target-bucket", "turqappteknoloji.firebasestorage.app");
  const limit = Number(arg("limit", "0"));
  const apply = hasFlag("apply");
  const syncShortLinks = !hasFlag("no-sync-shortlinks");
  const fallbackOg = arg("default-og-image", "");
  const allowedExtCsv = arg("allowed-ext", ".webp");
  const allowedExt = new Set(
    allowedExtCsv
      .split(",")
      .map((x) => x.trim().toLowerCase())
      .filter(Boolean)
      .map((x) => (x.startsWith(".") ? x : `.${x}`))
  );

  const app = admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount(targetKey)),
    storageBucket: targetBucket,
  });
  const db = app.firestore();
  const bucket = app.storage().bucket(targetBucket);

  console.log(`Collection           : ${collection}`);
  console.log(`Source bucket hint   : ${sourceBucketHint}`);
  console.log(`Target bucket        : ${bucket.name}`);
  console.log(`Allowed ext          : ${Array.from(allowedExt).join(", ")}`);
  console.log(`Sync shortLinks/public: ${syncShortLinks}`);
  console.log(`Mode                 : ${apply ? "APPLY" : "DRY-RUN"}`);

  const snap = await db.collection(collection).get();
  const docs = limit > 0 ? snap.docs.slice(0, limit) : snap.docs;
  console.log(`Scanned docs         : ${docs.length}`);

  let candidateDocs = 0;
  let changedDocs = 0;
  let changedShortLinks = 0;
  let copiedFiles = 0;
  let errors = 0;

  for (const doc of docs) {
    try {
      const data = doc.data() || {};
      const next = {};
      let hasCandidate = false;

      for (const field of ["img", "img2", "logo"]) {
        const raw = String(data[field] || "").trim();
        if (!raw || !raw.includes(sourceBucketHint)) continue;
        hasCandidate = true;

        const objectPath = extractStorageObjectPath(raw);
        if (!objectPath) continue;
        const ext = extOfObjectPath(objectPath);
        if (!allowedExt.has(ext)) continue;

        if (!apply) {
          next[field] = `[NEW:${objectPath}]`;
          continue;
        }

        const tmpPath = path.join(
          os.tmpdir(),
          `sch_${doc.id}_${field}_${Date.now()}_${Math.floor(Math.random() * 1e6)}`
        );

        try {
          await downloadToFile(raw, tmpPath);
          const token = crypto.randomUUID();
          const file = bucket.file(objectPath);
          await file.save(fs.readFileSync(tmpPath), {
            resumable: false,
            metadata: {
              contentType: "application/octet-stream",
              cacheControl: "public,max-age=31536000",
              metadata: {
                firebaseStorageDownloadTokens: token,
              },
            },
          });
          next[field] = buildFirebaseDownloadUrl(bucket.name, objectPath, token);
          copiedFiles += 1;
        } finally {
          try {
            if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
          } catch (_) {}
        }
      }

      if (!hasCandidate) continue;
      candidateDocs += 1;

      if (!apply) {
        console.log(`[DRY] ${doc.id} fields: ${Object.keys(next).join(", ") || "-"}`);
      } else {
        const patch = {};
        for (const key of ["img", "img2", "logo"]) {
          if (next[key]) patch[key] = next[key];
        }
        if (Object.keys(patch).length > 0) {
          await doc.ref.set(patch, { merge: true });
          changedDocs += 1;
          console.log(`[OK ] ${doc.id} fields updated: ${Object.keys(patch).join(", ")}`);

          if (syncShortLinks) {
            const shortRef = doc.ref.collection("shortLinks").doc("public");
            const shortSnap = await shortRef.get();
            if (shortSnap.exists) {
              const merged = { ...data, ...patch };
              const imageUrl = pickShareImage(merged, fallbackOg);
              if (imageUrl) {
                await shortRef.set({ imageUrl, updatedAt: Date.now() }, { merge: true });
                changedShortLinks += 1;
                console.log(`[OK ] ${doc.id} shortLinks/public.imageUrl updated`);
              }
            }
          }
        }
      }
    } catch (e) {
      errors += 1;
      console.log(`[ERR] ${doc.id}: ${e.message}`);
    }
  }

  console.log("------ SUMMARY ------");
  console.log(`Candidate docs      : ${candidateDocs}`);
  console.log(`Changed docs        : ${changedDocs}`);
  console.log(`Changed shortLinks  : ${changedShortLinks}`);
  console.log(`Copied files        : ${copiedFiles}`);
  console.log(`Errors              : ${errors}`);
  console.log(`Done (${apply ? "APPLY" : "DRY-RUN"}).`);

  await app.delete();
}

run().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
