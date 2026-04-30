#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const DEFAULT_POST_IDS = [
  "2f0f1ed3-18fe-4ba4-90d1-5769fce0d0b0_0",
  "41a8330e-c63e-4c6b-8ff4-a148d5d9b48d_0",
  "525ffce0-a6ed-4249-a99d-249cd34d712c_0",
  "8451f47f-2c81-472f-a72f-ede269a3ea03_0",
  "893d02e6-bdb6-4792-981d-7782c1e34a07_0",
  "90a3d4d1-3192-4d19-858f-47e00135cfc5_0",
  "a8d82d5f-7796-49f2-92c6-5a866b9893cb_0",
];

const SHORT_LINK_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const SHORT_LINK_DOMAIN = "turqapp.com";
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
    report: "",
    ids: [],
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
      continue;
    }
  }

  if (args.ids.length === 0) {
    args.ids = [...DEFAULT_POST_IDS];
  }

  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

function normalizeText(value, maxLength) {
  return asString(value).slice(0, maxLength);
}

function clampPreviewDescription(value) {
  const text = asString(value).replace(/\s+/g, " ").trim();
  if (!text) return "";
  if (text.length <= 170) return text;
  return `${text.slice(0, 167).trimEnd()}...`;
}

function pickFirstUrl(value) {
  if (typeof value === "string") {
    return value.trim();
  }
  if (Array.isArray(value)) {
    const first = value[0];
    if (typeof first === "string") return first.trim();
    if (first && typeof first === "object") {
      return asString(first.url);
    }
  }
  return "";
}

function buildPublicUrl(shortId) {
  return `https://${SHORT_LINK_DOMAIN}/p/${shortId}`;
}

function validateShortId(shortId) {
  return /^[A-Za-z0-9_-]{4,12}$/.test(asString(shortId));
}

function randomShortId(length = 7) {
  let out = "";
  for (let i = 0; i < length; i += 1) {
    out += SHORT_LINK_ALPHABET[Math.floor(Math.random() * SHORT_LINK_ALPHABET.length)];
  }
  return out;
}

async function findExistingRouteForEntity(db, entityId) {
  const snap = await db
    .collection("shortRoutes")
    .where("entityId", "==", entityId)
    .limit(20)
    .get();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (
      asString(data.type) === "post" &&
      asString(data.status) === "active" &&
      validateShortId(data.shortId) &&
      asString(data.routeKind) === "p"
    ) {
      return { shortId: asString(data.shortId), routeDocId: doc.id };
    }
  }
  return null;
}

async function findFreeShortId(db) {
  for (let attempt = 0; attempt < 24; attempt += 1) {
    const candidate = randomShortId(7);
    const checks = await Promise.all([
      db.collection("shortRoutes").doc(`p:${candidate}`).get(),
      db.collection("shortRoutes").doc(`s:${candidate}`).get(),
      db.collection("shortRoutes").doc(`u:${candidate}`).get(),
      db.collection("shortRoutes").doc(`e:${candidate}`).get(),
      db.collection("shortRoutes").doc(`i:${candidate}`).get(),
      db.collection("shortRoutes").doc(`m:${candidate}`).get(),
    ]);
    if (checks.every((snap) => !snap.exists)) return candidate;
  }
  throw new Error("No free shortId could be generated");
}

function buildPostMeta(data) {
  const authorNickname = normalizeText(
    data.authorNickname || data.nickname || data.userNickname,
    60,
  );
  const caption = normalizeText(data.metin || data.caption, 280);
  const hasVideo =
    asString(data.video).length > 0 ||
    asString(data.hlsMasterUrl).length > 0;
  const thumbnail = normalizeText(data.thumbnail, 1024);
  const firstImage = normalizeText(pickFirstUrl(data.img), 1024);
  const imageUrl = hasVideo ? thumbnail : firstImage;
  return {
    title: authorNickname
      ? `${authorNickname} yeni bir gonderi paylasti`
      : "TurqApp Gonderisi",
    desc: clampPreviewDescription(caption),
    imageUrl,
  };
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

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    scannedPosts: 0,
    touchedPosts: 0,
    unchangedPosts: 0,
    missingPosts: [],
    samples: [],
  };

  const writer = options.apply ? db.bulkWriter() : null;

  for (const postId of options.ids) {
    summary.scannedPosts += 1;
    const postRef = db.collection("Posts").doc(postId);
    const postSnap = await postRef.get();
    if (!postSnap.exists) {
      summary.missingPosts.push(postId);
      continue;
    }

    const postData = postSnap.data() || {};
    const shortLinkRef = postRef.collection("shortLinks").doc("public");
    const shortLinkSnap = await shortLinkRef.get();
    const existingShortLink = shortLinkSnap.exists ? shortLinkSnap.data() || {} : {};
    const existingRoute = await findExistingRouteForEntity(db, postId);

    let shortId = "";
    if (validateShortId(existingShortLink.shortId)) {
      shortId = asString(existingShortLink.shortId);
    } else if (validateShortId(postData.shortId)) {
      shortId = asString(postData.shortId);
    } else if (existingRoute?.shortId) {
      shortId = existingRoute.shortId;
    } else {
      shortId = await findFreeShortId(db);
    }

    const publicUrl = buildPublicUrl(shortId);
    const now = Date.now();
    const meta = buildPostMeta(postData);
    const routePayload = {
      routeKind: "p",
      key: shortId,
      type: "post",
      entityId: postId,
      entityPath: `${postRef.path}/shortLinks/public`,
      shortId,
      shortUrl: publicUrl,
      status: "active",
      expiresAt: 0,
      updatedAt: now,
    };
    const entityPayload = {
      routeKind: "p",
      type: "post",
      entityId: postId,
      shortId,
      shortUrl: publicUrl,
      title: meta.title,
      desc: meta.desc,
      imageUrl: meta.imageUrl,
      status: "active",
      expiresAt: 0,
      updatedAt: now,
    };
    const rootPatch = {
      shortId,
      shortUrl: publicUrl,
      shortLinkUpdatedAt: now,
      shortLinkStatus: "active",
    };

    const currentRootShortUrl = asString(postData.shortUrl);
    const currentEntityShortId = asString(existingShortLink.shortId);
    const needsWrite =
      currentRootShortUrl !== publicUrl ||
      currentEntityShortId !== shortId ||
      !shortLinkSnap.exists ||
      !existingRoute;

    if (!needsWrite) {
      summary.unchangedPosts += 1;
      continue;
    }

    summary.touchedPosts += 1;
    if (summary.samples.length < 10) {
      summary.samples.push({
        postId,
        shortId,
        publicUrl,
        before: {
          rootShortUrl: currentRootShortUrl || null,
          entityShortId: currentEntityShortId || null,
          routeDocId: existingRoute?.routeDocId || null,
        },
      });
    }

    if (writer) {
      writer.set(postRef, rootPatch, { merge: true });
      writer.set(shortLinkRef, entityPayload, { merge: true });
      writer.set(db.collection("shortRoutes").doc(`p:${shortId}`), routePayload, { merge: true });
    }
  }

  if (writer) {
    await writer.close();
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
