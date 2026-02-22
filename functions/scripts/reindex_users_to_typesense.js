#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require("firebase-admin");
const fs = require("fs");
const axios = require("axios");

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function loadServiceAccount(path) {
  if (!path || !fs.existsSync(path)) {
    throw new Error(`Service account bulunamadi: ${path}`);
  }
  return JSON.parse(fs.readFileSync(path, "utf8"));
}

function asString(x) {
  return typeof x === "string" ? x : "";
}

function asBool(x) {
  return x === true;
}

function asEpochSeconds(x) {
  if (!x) return 0;
  if (typeof x === "number" && Number.isFinite(x)) {
    return x > 1e12 ? Math.floor(x / 1000) : Math.floor(x);
  }
  if (typeof x === "object" && x !== null) {
    if (typeof x.seconds === "number") return Math.floor(x.seconds);
    if (typeof x._seconds === "number") return Math.floor(x._seconds);
    if (typeof x.toMillis === "function") {
      const ms = x.toMillis();
      if (Number.isFinite(ms)) return Math.floor(ms / 1000);
    }
  }
  return 0;
}

function buildUserDoc(userId, data) {
  const createdDateRaw = Number(data.createdDate || 0);
  const createdDateTs =
    Number.isFinite(createdDateRaw) && createdDateRaw > 0
      ? Math.floor(createdDateRaw / 1000)
      : 0;

  return {
    id: userId,
    nickname: asString(data.nickname) || asString(data.username),
    firstName: asString(data.firstName),
    lastName: asString(data.lastName),
    pfImage:
      asString(data.pfImage) ||
      asString(data.avatarUrl) ||
      asString(data.profileImageUrl),
    gizliHesap: asBool(data.gizliHesap),
    deletedAccount: asBool(data.deletedAccount) || asBool(data.isDeleted),
    hesapOnayi: asBool(data.hesapOnayi) || asBool(data.isVerified),
    updatedAtTs:
      asEpochSeconds(data.updatedAt) ||
      asEpochSeconds(data.createdAt) ||
      createdDateTs ||
      Math.floor(Date.now() / 1000),
  };
}

function shouldIndexUser(doc) {
  return true;
}

async function ensureUsersCollection(baseUrl, apiKey, collectionName) {
  const headers = { "X-TYPESENSE-API-KEY": apiKey, "Content-Type": "application/json" };
  const required = [
    { name: "nickname", type: "string", optional: true },
    { name: "firstName", type: "string", optional: true },
    { name: "lastName", type: "string", optional: true },
    { name: "pfImage", type: "string", optional: true },
    { name: "gizliHesap", type: "bool", optional: true },
    { name: "deletedAccount", type: "bool", optional: true },
    { name: "hesapOnayi", type: "bool", optional: true },
  ];

  try {
    const existing = await axios.get(`${baseUrl}/collections/${collectionName}`, {
      headers,
      timeout: 8000,
    });
    const fields = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
    const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
    if (missing.length) {
      await axios.patch(
        `${baseUrl}/collections/${collectionName}`,
        { fields: missing },
        { headers, timeout: 8000 }
      );
    }
    return;
  } catch (err) {
    if (err?.response?.status !== 404) throw err;
  }

  await axios.post(
    `${baseUrl}/collections`,
    {
      name: collectionName,
      fields: [
        { name: "id", type: "string" },
        ...required,
        { name: "updatedAtTs", type: "int32" },
      ],
      default_sorting_field: "updatedAtTs",
    },
    { headers, timeout: 8000 }
  );
}

async function run() {
  const targetKey = arg("target-key");
  const usersCollection = arg("users-collection", "users");
  const typesenseHost = arg("typesense-host");
  const typesenseApiKey = arg("typesense-api-key");
  const typesenseCollection = arg("typesense-collection", "users_search");
  const batchSize = Math.max(50, Math.min(500, Number(arg("batch-size", "200"))));
  const apply = hasFlag("apply");

  if (!targetKey || !typesenseHost || !typesenseApiKey) {
    throw new Error(
      "Kullanim: node reindex_users_to_typesense.js --target-key /path/target.json --typesense-host https://host --typesense-api-key KEY [--apply]"
    );
  }

  const baseUrl = typesenseHost.startsWith("http")
    ? typesenseHost.replace(/\/+$/g, "")
    : `https://${typesenseHost.replace(/\/+$/g, "")}`;
  const headers = { "X-TYPESENSE-API-KEY": typesenseApiKey, "Content-Type": "application/json" };

  const targetApp = admin.initializeApp(
    { credential: admin.credential.cert(loadServiceAccount(targetKey)) },
    "target-users-app"
  );
  const db = targetApp.firestore();

  console.log(`Users collection    : ${usersCollection}`);
  console.log(`Typesense collection: ${typesenseCollection}`);
  console.log(`Mode                : ${apply ? "APPLY" : "DRY-RUN"}`);

  await ensureUsersCollection(baseUrl, typesenseApiKey, typesenseCollection);

  let lastDoc = null;
  let scanned = 0;
  let upserted = 0;
  let skipped = 0;

  while (true) {
    let q = db.collection(usersCollection).orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
    if (lastDoc) q = q.startAfter(lastDoc.id);
    const snap = await q.get();
    if (snap.empty) break;

    for (const docSnap of snap.docs) {
      scanned += 1;
      const doc = buildUserDoc(docSnap.id, docSnap.data() || {});
      if (!shouldIndexUser(doc)) {
        skipped += 1;
        continue;
      }
      if (apply) {
        await axios.post(
          `${baseUrl}/collections/${typesenseCollection}/documents?action=upsert`,
          doc,
          { headers, timeout: 10000 }
        );
      }
      upserted += 1;
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < batchSize) break;
  }

  console.log(`Scanned : ${scanned}`);
  console.log(`Upserted: ${upserted}`);
  console.log(`Skipped : ${skipped}`);
  console.log("Bitti.");
  await targetApp.delete();
}

run().catch((e) => {
  console.error("HATA:", e?.response?.data || e.message || e);
  process.exit(1);
});
