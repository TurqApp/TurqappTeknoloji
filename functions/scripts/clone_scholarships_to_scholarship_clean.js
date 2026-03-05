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

function parseStorageUrl(rawUrl) {
  const text = String(rawUrl || "").trim();
  if (!text) return { bucket: "", objectPath: "" };
  try {
    const parsed = new URL(text);
    const m = parsed.pathname.match(/\/v0\/b\/([^/]+)\/o\/(.+)$/i);
    if (!m) return { bucket: "", objectPath: "" };
    return {
      bucket: decodeURIComponent(m[1]),
      objectPath: decodeURIComponent(m[2]),
    };
  } catch (_) {
    return { bucket: "", objectPath: "" };
  }
}

function guessExtFromUrl(url) {
  const objectPath = extractStorageObjectPath(url);
  if (objectPath) {
    const ext = path.extname(objectPath).toLowerCase();
    if (ext) return ext;
  }
  try {
    const u = new URL(String(url || ""));
    const ext = path.extname(u.pathname).toLowerCase();
    if (ext) return ext;
  } catch (_) {}
  return ".webp";
}

function buildFirebaseDownloadUrl(bucketName, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(
    objectPath
  )}?alt=media&token=${token}`;
}

function folderForField(field) {
  if (field === "img") return "templates";
  if (field === "img2") return "images";
  return "logos";
}

function pickShareImage(data, fallback = "") {
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
  const sourceCollection = arg("source-collection", "scholarships");
  const targetCollection = arg("target-collection", "scholarship");
  const targetStorageRoot = arg("target-storage-root", "scholarship");
  const targetBucket = arg("target-bucket", "turqappteknoloji.firebasestorage.app");
  const limit = Number(arg("limit", "0"));
  const apply = hasFlag("apply");
  const copyShortLinks = !hasFlag("no-copy-shortlinks");
  const noMediaCopy = hasFlag("no-media-copy");
  const skipIfExists = hasFlag("skip-if-exists");

  const app = admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount(targetKey)),
    storageBucket: targetBucket,
  });
  const db = app.firestore();
  const bucket = app.storage().bucket(targetBucket);

  console.log(`Source collection    : ${sourceCollection}`);
  console.log(`Target collection    : ${targetCollection}`);
  console.log(`Target storage root  : ${targetStorageRoot}`);
  console.log(`Target bucket        : ${bucket.name}`);
  console.log(`Copy shortLinks      : ${copyShortLinks}`);
  console.log(`No media copy        : ${noMediaCopy}`);
  console.log(`Skip if exists       : ${skipIfExists}`);
  console.log(`Mode                 : ${apply ? "APPLY" : "DRY-RUN"}`);

  const sourceSnap = await db.collection(sourceCollection).get();
  const docs = limit > 0 ? sourceSnap.docs.slice(0, limit) : sourceSnap.docs;
  console.log(`Scanned docs         : ${docs.length}`);

  let copiedDocs = 0;
  let copiedFiles = 0;
  let keptOriginalUrls = 0;
  let copiedShortLinks = 0;
  let skipped = 0;
  let errors = 0;

  for (const doc of docs) {
    try {
      const targetRef = db.collection(targetCollection).doc(doc.id);
      if (skipIfExists) {
        const existing = await targetRef.get();
        if (existing.exists) {
          skipped += 1;
          continue;
        }
      }

      const src = doc.data() || {};
      const out = { ...src };

      for (const field of ["img", "img2", "logo"]) {
        const raw = String(src[field] || "").trim();
        if (!raw) continue;
        if (noMediaCopy) {
          out[field] = raw;
          continue;
        }
        const parsedStorage = parseStorageUrl(raw);
        const ext = guessExtFromUrl(raw);
        const objectPath = `${targetStorageRoot}/${folderForField(field)}/${doc.id}_${field}_${Date.now()}${ext}`;

        if (!apply) {
          out[field] = `[NEW:${objectPath}]`;
          continue;
        }

        const token = crypto.randomUUID();
        const file = bucket.file(objectPath);
        try {
          let copiedByStorage = false;

          if (
            parsedStorage.bucket &&
            parsedStorage.objectPath &&
            parsedStorage.bucket === bucket.name
          ) {
            const srcFile = bucket.file(parsedStorage.objectPath);
            const [exists] = await srcFile.exists();
            if (exists) {
              await srcFile.copy(file);
              copiedByStorage = true;
            }
          }

          if (!copiedByStorage) {
            const tmpPath = path.join(
              os.tmpdir(),
              `sch_clone_${doc.id}_${field}_${Date.now()}_${Math.floor(Math.random() * 1e6)}${ext}`
            );
            await downloadToFile(raw, tmpPath);
            await file.save(fs.readFileSync(tmpPath), {
              resumable: false,
            });
            try {
              if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
            } catch (_) {}
          }

          await file.setMetadata({
            cacheControl: "public,max-age=31536000",
            metadata: {
              firebaseStorageDownloadTokens: token,
            },
          });
          out[field] = buildFirebaseDownloadUrl(bucket.name, objectPath, token);
          copiedFiles += 1;
        } catch (e) {
          out[field] = raw;
          keptOriginalUrls += 1;
          console.log(`[WARN] ${doc.id} ${field} kept original (${e.message})`);
        }
      }

      if (!apply) {
        console.log(`[DRY] ${doc.id}`);
        continue;
      }

      await targetRef.set(
        {
          ...out,
          migratedFromCollection: sourceCollection,
          migratedAt: Date.now(),
        },
        { merge: false }
      );
      copiedDocs += 1;

      if (copyShortLinks) {
        const oldShortRef = doc.ref.collection("shortLinks").doc("public");
        const oldShortSnap = await oldShortRef.get();
        if (oldShortSnap.exists) {
          const oldShort = oldShortSnap.data() || {};
          await targetRef
            .collection("shortLinks")
            .doc("public")
            .set(
              {
                ...oldShort,
                entityId: `scholarship:${doc.id}`,
                imageUrl: pickShareImage(out, String(oldShort.imageUrl || "").trim()),
                updatedAt: Date.now(),
              },
              { merge: true }
            );
          copiedShortLinks += 1;
        }
      }

      console.log(`[OK ] ${doc.id}`);
    } catch (e) {
      errors += 1;
      console.log(`[ERR] ${doc.id}: ${e.message}`);
    }
  }

  console.log("------ SUMMARY ------");
  console.log(`Copied docs         : ${copiedDocs}`);
  console.log(`Copied files        : ${copiedFiles}`);
  console.log(`Kept original urls  : ${keptOriginalUrls}`);
  console.log(`Copied shortLinks   : ${copiedShortLinks}`);
  console.log(`Skipped docs        : ${skipped}`);
  console.log(`Errors              : ${errors}`);
  console.log(`Done (${apply ? "APPLY" : "DRY-RUN"}).`);

  await app.delete();
}

run().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
