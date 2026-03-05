#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require("firebase-admin");
const fs = require("fs");
const os = require("os");
const path = require("path");
const crypto = require("crypto");

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

function extractStorage(rawUrl) {
  const text = String(rawUrl || "").trim();
  if (!text) return { bucket: "", objectPath: "", ext: ".bin" };
  try {
    const u = new URL(text);
    const m = u.pathname.match(/\/v0\/b\/([^/]+)\/o\/(.+)$/i);
    if (!m) return { bucket: "", objectPath: "", ext: ".bin" };
    const bucket = decodeURIComponent(m[1]);
    const objectPath = decodeURIComponent(m[2]);
    const ext = path.extname(objectPath).toLowerCase() || ".bin";
    return { bucket, objectPath, ext };
  } catch (_) {
    return { bucket: "", objectPath: "", ext: ".bin" };
  }
}

function variantsForObjectPath(objectPath, sourcePrefix = "scholarships") {
  const out = new Set();
  const p = String(objectPath || "").trim();
  if (!p) return [];
  const normalized = p.replace(/^BireyselBurslar\//, `${sourcePrefix}/`);
  out.add(normalized);
  if (!normalized.startsWith(`${sourcePrefix}/`)) {
    const tail = normalized.replace(/^[^/]+\//, "");
    out.add(`${sourcePrefix}/${tail}`);
  }
  return Array.from(out);
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

function buildFirebaseDownloadUrl(bucketName, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(
    objectPath
  )}?alt=media&token=${token}`;
}

async function deleteCollection(db, name) {
  const snap = await db.collection(name).get();
  let batch = db.batch();
  let count = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    count += 1;
    if (count % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (count % 400 !== 0) await batch.commit();
  return count;
}

async function findSourceFile(targetBucket, sourceBucket, parsed, sourcePrefix) {
  if (!parsed.objectPath) return null;
  const variants = variantsForObjectPath(parsed.objectPath, sourcePrefix);
  const candidateBuckets = [targetBucket, sourceBucket].filter(Boolean);
  for (const b of candidateBuckets) {
    for (const p of variants) {
      const f = b.file(p);
      const [exists] = await f.exists();
      if (exists) return { bucket: b, file: f, path: p };
    }
  }
  return null;
}

async function copyFileToTarget(targetBucket, src, targetPath) {
  const targetFile = targetBucket.file(targetPath);
  if (src.bucket.name === targetBucket.name) {
    await src.file.copy(targetFile);
    return;
  }
  const tmpPath = path.join(
    os.tmpdir(),
    `sch_clone_${Date.now()}_${Math.floor(Math.random() * 1e6)}${path.extname(targetPath)}`
  );
  try {
    await src.file.download({ destination: tmpPath });
    await targetFile.save(fs.readFileSync(tmpPath), { resumable: false });
  } finally {
    try {
      if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
    } catch (_) {}
  }
}

async function run() {
  const targetKey = arg(
    "target-key",
    "/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json"
  );
  const sourceKey = arg(
    "source-key",
    "/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-c11948e622.json"
  );
  const sourceBucketName = arg("source-bucket", "burs-city.appspot.com");
  const targetBucketName = arg("target-bucket", "turqappteknoloji.firebasestorage.app");
  const sourceCollection = arg("source-collection", "scholarships");
  const targetCollection = arg("target-collection", "scholarship");
  const targetStorageRoot = arg("target-storage-root", "scholarship");
  const sourcePrefix = arg("source-prefix", "scholarships");
  const disableSourceBucket = hasFlag("disable-source-bucket");
  const apply = hasFlag("apply");
  const resetTarget = hasFlag("reset-target");
  const copyShortLinks = !hasFlag("no-copy-shortlinks");
  const limit = Number(arg("limit", "0"));

  const targetApp = admin.initializeApp(
    {
      credential: admin.credential.cert(loadServiceAccount(targetKey)),
      storageBucket: targetBucketName,
    },
    "target-scholarship-clone"
  );
  const sourceApp = disableSourceBucket
    ? null
    : admin.initializeApp(
        {
          credential: admin.credential.cert(loadServiceAccount(sourceKey)),
          storageBucket: sourceBucketName,
        },
        "source-scholarship-clone"
      );

  const db = targetApp.firestore();
  const targetBucket = targetApp.storage().bucket(targetBucketName);
  const sourceBucket = sourceApp ? sourceApp.storage().bucket(sourceBucketName) : null;

  console.log(`Source collection   : ${sourceCollection}`);
  console.log(`Target collection   : ${targetCollection}`);
  console.log(`Target storage root : ${targetStorageRoot}`);
  console.log(`Source prefix       : ${sourcePrefix}`);
  console.log(`Target bucket       : ${targetBucket.name}`);
  console.log(`Source bucket       : ${sourceBucket ? sourceBucket.name : "(disabled)"}`);
  console.log(`Reset target        : ${resetTarget}`);
  console.log(`Copy shortLinks     : ${copyShortLinks}`);
  console.log(`Mode                : ${apply ? "APPLY" : "DRY-RUN"}`);

  if (apply && resetTarget) {
    const deleted = await deleteCollection(db, targetCollection);
    console.log(`Deleted target docs : ${deleted}`);
  }

  const snap = await db.collection(sourceCollection).get();
  const docs = limit > 0 ? snap.docs.slice(0, limit) : snap.docs;
  console.log(`Scanned docs        : ${docs.length}`);

  let copiedDocs = 0;
  let copiedFiles = 0;
  let keptOriginalUrls = 0;
  let copiedShortLinks = 0;
  let errors = 0;

  for (const doc of docs) {
    const srcData = doc.data() || {};
    const out = { ...srcData };
    try {
      for (const field of ["img", "img2", "logo"]) {
        const raw = String(srcData[field] || "").trim();
        if (!raw) continue;
        const parsed = extractStorage(raw);
        const targetPath = `${targetStorageRoot}/${folderForField(field)}/${doc.id}_${field}_${Date.now()}${parsed.ext}`;
        if (!apply) continue;

        const sourceFile = await findSourceFile(targetBucket, sourceBucket, parsed, sourcePrefix);
        if (!sourceFile) {
          keptOriginalUrls += 1;
          out[field] = raw;
          continue;
        }

        await copyFileToTarget(targetBucket, sourceFile, targetPath);
        const token = crypto.randomUUID();
        const targetFile = targetBucket.file(targetPath);
        await targetFile.setMetadata({
          cacheControl: "public,max-age=31536000",
          metadata: { firebaseStorageDownloadTokens: token },
        });
        out[field] = buildFirebaseDownloadUrl(targetBucket.name, targetPath, token);
        copiedFiles += 1;
      }

      if (!apply) {
        console.log(`[DRY] ${doc.id}`);
        continue;
      }

      const targetRef = db.collection(targetCollection).doc(doc.id);
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
  console.log(`Errors              : ${errors}`);
  console.log(`Done (${apply ? "APPLY" : "DRY-RUN"}).`);

  if (sourceApp) {
    await Promise.all([targetApp.delete(), sourceApp.delete()]);
  } else {
    await targetApp.delete();
  }
}

run().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
