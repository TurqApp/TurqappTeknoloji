#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

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

function remapBucketInUrl(url, fromBucket, toBucket) {
  const value = String(url || "").trim();
  if (!value) return "";
  if (!fromBucket || !toBucket || fromBucket === toBucket) return value;

  // /v0/b/<bucket>/o/
  const escapedFrom = fromBucket.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const bucketRe = new RegExp(`/v0/b/${escapedFrom}/o/`, "i");
  if (bucketRe.test(value)) {
    return value.replace(bucketRe, `/v0/b/${toBucket}/o/`);
  }
  return value;
}

function toCdnUrl(url, cdnDomain, fromBucket, toBucket) {
  const value = String(url || "").trim();
  if (!value) return "";
  const bucketRemapped = remapBucketInUrl(value, fromBucket, toBucket);
  if (bucketRemapped.includes(cdnDomain)) return bucketRemapped;

  // https://firebasestorage.googleapis.com/v0/b/... -> https://cdn.turqapp.com/v0/b/...
  if (bucketRemapped.includes("firebasestorage.googleapis.com")) {
    return bucketRemapped.replace("firebasestorage.googleapis.com", cdnDomain);
  }

  // https://<project>.firebasestorage.app/v0/b/... -> https://cdn.turqapp.com/v0/b/...
  if (bucketRemapped.includes(".firebasestorage.app")) {
    return bucketRemapped.replace(
      /^https?:\/\/[^/]*\.firebasestorage\.app/i,
      `https://${cdnDomain}`
    );
  }

  return bucketRemapped;
}

function pickShareImage(data, cdnDomain, defaultOgImage, fromBucket, toBucket) {
  const img = toCdnUrl(data.img, cdnDomain, fromBucket, toBucket);
  if (img) return img;
  const img2 = toCdnUrl(data.img2, cdnDomain, fromBucket, toBucket);
  if (img2) return img2;
  const logo = toCdnUrl(data.logo, cdnDomain, fromBucket, toBucket);
  if (logo) return logo;
  return defaultOgImage;
}

async function run() {
  const targetKey = arg(
    "target-key",
    "/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json"
  );
  const collection = arg("collection", "scholarships");
  const cdnDomain = arg("cdn-domain", "cdn.turqapp.com");
  const defaultOgImage = arg("default-og-image", "https://cdn.turqapp.com/og/default.jpg");
  const fromBucket = arg("from-bucket", "burs-city.appspot.com");
  const toBucket = arg("to-bucket", "turqappteknoloji.firebasestorage.app");
  const limit = Number(arg("limit", "0"));
  const apply = hasFlag("apply");
  const syncShortLinks = !hasFlag("no-sync-shortlinks");

  const app = admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount(targetKey)),
  });
  const db = app.firestore();

  console.log(`Collection           : ${collection}`);
  console.log(`CDN Domain           : ${cdnDomain}`);
  console.log(`Bucket remap         : ${fromBucket} -> ${toBucket}`);
  console.log(`Sync shortLinks/public: ${syncShortLinks}`);
  console.log(`Mode                 : ${apply ? "APPLY" : "DRY-RUN"}`);

  const snap = await db.collection(collection).get();
  const docs = limit > 0 ? snap.docs.slice(0, limit) : snap.docs;
  console.log(`Scanned docs         : ${docs.length}`);

  let changedDocs = 0;
  let changedShortLinks = 0;
  let errors = 0;

  for (const doc of docs) {
    try {
      const data = doc.data() || {};
      const nextImg = toCdnUrl(data.img, cdnDomain, fromBucket, toBucket);
      const nextImg2 = toCdnUrl(data.img2, cdnDomain, fromBucket, toBucket);
      const nextLogo = toCdnUrl(data.logo, cdnDomain, fromBucket, toBucket);

      const patch = {};
      if (nextImg && nextImg !== (data.img || "")) patch.img = nextImg;
      if (nextImg2 && nextImg2 !== (data.img2 || "")) patch.img2 = nextImg2;
      if (nextLogo && nextLogo !== (data.logo || "")) patch.logo = nextLogo;

      const hasDocPatch = Object.keys(patch).length > 0;
      if (hasDocPatch) {
        changedDocs += 1;
      }

      if (!apply) {
        if (hasDocPatch) {
          console.log(`[DRY] ${doc.id} -> fields: ${Object.keys(patch).join(", ")}`);
        }
      } else if (hasDocPatch) {
        await doc.ref.set(patch, { merge: true });
        console.log(`[OK ] ${doc.id} fields updated`);
      }

      if (syncShortLinks) {
        const shortRef = doc.ref.collection("shortLinks").doc("public");
        const shortSnap = await shortRef.get();
        if (shortSnap.exists) {
          const shortData = shortSnap.data() || {};
          const nextImageUrl = pickShareImage(
            { ...data, ...patch },
            cdnDomain,
            defaultOgImage,
            fromBucket,
            toBucket
          );
          if (nextImageUrl && nextImageUrl !== String(shortData.imageUrl || "").trim()) {
            changedShortLinks += 1;
            if (!apply) {
              console.log(`[DRY] ${doc.id} shortLinks/public.imageUrl -> ${nextImageUrl}`);
            } else {
              await shortRef.set(
                {
                  imageUrl: nextImageUrl,
                  updatedAt: Date.now(),
                },
                { merge: true }
              );
              console.log(`[OK ] ${doc.id} shortLinks/public.imageUrl updated`);
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
  console.log(`Changed docs         : ${changedDocs}`);
  console.log(`Changed shortLinks   : ${changedShortLinks}`);
  console.log(`Errors               : ${errors}`);
  console.log(`Done (${apply ? "APPLY" : "DRY-RUN"}).`);

  await app.delete();
}

run().catch((e) => {
  console.error("FATAL:", e.message);
  process.exit(1);
});
