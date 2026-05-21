#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_INPUT =
  "/Users/turqapp/Desktop/turqapp_curated_user_import_ready_184.json";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp_Firebase/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";

const require = createRequire(import.meta.url);
const admin = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/firebase-admin",
));

function parseArgs(argv) {
  const options = {
    input: DEFAULT_INPUT,
    serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT,
    apply: false,
    limit: 0,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const arg = String(argv[index] || "").trim();
    if (!arg) continue;
    if (arg === "--input") {
      options.input = String(argv[index + 1] || "").trim() || options.input;
      index += 1;
      continue;
    }
    if (arg === "--service-account") {
      options.serviceAccount =
        String(argv[index + 1] || "").trim() || options.serviceAccount;
      index += 1;
      continue;
    }
    if (arg === "--apply") {
      options.apply = true;
      continue;
    }
    if (arg === "--limit") {
      options.limit = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
  }

  return options;
}

function normalizeEmail(value) {
  return String(value || "").trim().toLowerCase();
}

function normalizeHandle(value) {
  return String(value || "")
    .trim()
    .replace(/^@+/, "")
    .replace(/\s+/g, "")
    .toLowerCase();
}

function normalizeRecord(record) {
  const uid = String(record?.uid || record?.usersDoc?.userID || "").trim();
  const usersDoc = record?.usersDoc || {};
  const usersPublicDoc = record?.usersPublicDoc || {};
  const email = normalizeEmail(usersDoc.email);
  const usernameLower = normalizeHandle(usersDoc.usernameLower || usersDoc.nickname);
  const nickname = normalizeHandle(usersDoc.nickname || usernameLower);
  const displayName = String(usersDoc.displayName || nickname).trim();
  const mergedUsersDoc = {
    ...usersDoc,
    userID: uid,
    email,
    username: usernameLower,
    usernameLower,
    nickname,
    isBot: true,
    isSystemAccount: true,
    accountType: "curated",
    isApproved: true,
    rozet: "Mavi",
    updatedDate: Date.now(),
  };
  const mergedUsersPublicDoc = {
    ...usersPublicDoc,
    userID: uid,
    email,
    username: usernameLower,
    usernameLower,
    nickname,
    displayName,
    isBot: true,
    isSystemAccount: true,
    accountType: "curated",
    isApproved: true,
    rozet: "Mavi",
    updatedDate: Date.now(),
  };

  return {
    ...record,
    uid,
    email,
    usernameLower,
    nickname,
    displayName,
    usersDoc: mergedUsersDoc,
    usersPublicDoc: mergedUsersPublicDoc,
    subdocuments: record?.subdocuments || {},
  };
}

function readRecords(input, limit) {
  const raw = JSON.parse(fs.readFileSync(input, "utf8"));
  const records = Array.isArray(raw.records) ? raw.records : [];
  const selected = limit > 0 ? records.slice(0, limit) : records;
  return selected.map(normalizeRecord);
}

function initializeAdmin(serviceAccountPath) {
  if (admin.apps.length > 0) return;
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

function validateInput(records) {
  const errors = [];
  const seenUids = new Map();
  const seenEmails = new Map();
  const seenUsernames = new Map();

  for (const record of records) {
    if (!record.uid) errors.push({ type: "missing_uid", record });
    if (!record.email) errors.push({ type: "missing_email", uid: record.uid });
    if (!record.usernameLower) errors.push({ type: "missing_username", uid: record.uid });

    for (const [map, key, type] of [
      [seenUids, record.uid, "duplicate_uid"],
      [seenEmails, record.email, "duplicate_email"],
      [seenUsernames, record.usernameLower, "duplicate_username"],
    ]) {
      if (!key) continue;
      if (map.has(key)) {
        errors.push({ type, key, firstUid: map.get(key), uid: record.uid });
      } else {
        map.set(key, record.uid);
      }
    }
  }

  return errors;
}

async function getAuthUserByEmail(email) {
  try {
    return await admin.auth().getUserByEmail(email);
  } catch (error) {
    if (error?.code === "auth/user-not-found") return null;
    throw error;
  }
}

async function getAuthUserByUid(uid) {
  try {
    return await admin.auth().getUser(uid);
  } catch (error) {
    if (error?.code === "auth/user-not-found") return null;
    throw error;
  }
}

async function collectConflicts(db, records) {
  const conflicts = [];
  const existing = {
    authByUid: 0,
    authByEmail: 0,
    usersDoc: 0,
    usersPublicDoc: 0,
  };

  for (const record of records) {
    const [authByUid, authByEmail, userSnap, publicSnap, usernameSnap, nicknameSnap, emailSnap] =
      await Promise.all([
        getAuthUserByUid(record.uid),
        getAuthUserByEmail(record.email),
        db.collection("users").doc(record.uid).get(),
        db.collection("usersPublic").doc(record.uid).get(),
        db
          .collection("usersPublic")
          .where("usernameLower", "==", record.usernameLower)
          .limit(2)
          .get(),
        db
          .collection("usersPublic")
          .where("nickname", "==", record.nickname)
          .limit(2)
          .get(),
        db.collection("users").where("email", "==", record.email).limit(2).get(),
      ]);

    if (authByUid) existing.authByUid += 1;
    if (authByEmail) existing.authByEmail += 1;
    if (userSnap.exists) existing.usersDoc += 1;
    if (publicSnap.exists) existing.usersPublicDoc += 1;

    if (authByEmail && authByEmail.uid !== record.uid) {
      conflicts.push({
        type: "auth_email_taken",
        uid: record.uid,
        email: record.email,
        existingUid: authByEmail.uid,
      });
    }

    for (const doc of usernameSnap.docs) {
      if (doc.id !== record.uid) {
        conflicts.push({
          type: "username_taken",
          uid: record.uid,
          usernameLower: record.usernameLower,
          existingUid: doc.id,
        });
      }
    }

    for (const doc of nicknameSnap.docs) {
      if (doc.id !== record.uid) {
        conflicts.push({
          type: "nickname_taken",
          uid: record.uid,
          nickname: record.nickname,
          existingUid: doc.id,
        });
      }
    }

    for (const doc of emailSnap.docs) {
      if (doc.id !== record.uid) {
        conflicts.push({
          type: "firestore_email_taken",
          uid: record.uid,
          email: record.email,
          existingUid: doc.id,
        });
      }
    }
  }

  return { conflicts, existing };
}

async function upsertAuthUser(record) {
  const payload = {
    email: record.email,
    emailVerified: true,
    displayName: record.displayName,
    disabled: true,
  };
  const existing = await getAuthUserByUid(record.uid);
  if (existing) {
    await admin.auth().updateUser(record.uid, payload);
    return "updated";
  }
  await admin.auth().createUser({ uid: record.uid, ...payload });
  return "created";
}

async function commitFirestore(records, batchId) {
  const db = admin.firestore();
  let batch = db.batch();
  let pending = 0;
  let commits = 0;
  const now = Date.now();

  async function flush() {
    if (pending === 0) return;
    await batch.commit();
    commits += 1;
    batch = db.batch();
    pending = 0;
  }

  for (const record of records) {
    const usersRef = db.collection("users").doc(record.uid);
    const publicRef = db.collection("usersPublic").doc(record.uid);
    batch.set(
      usersRef,
      {
        ...record.usersDoc,
        curatedImportBatchId: batchId,
        curatedImportedAt: now,
      },
      { merge: true },
    );
    pending += 1;
    batch.set(
      publicRef,
      {
        ...record.usersPublicDoc,
        curatedImportBatchId: batchId,
        curatedImportedAt: now,
      },
      { merge: true },
    );
    pending += 1;

    for (const [subpath, data] of Object.entries(record.subdocuments)) {
      batch.set(
        usersRef.collection(subpath.split("/")[0]).doc(subpath.split("/")[1]),
        {
          ...data,
          curatedImportBatchId: batchId,
          curatedImportedAt: now,
        },
        { merge: true },
      );
      pending += 1;
    }

    if (pending >= 450) {
      await flush();
    }
  }

  await flush();
  return commits;
}

async function run() {
  const options = parseArgs(process.argv);
  const records = readRecords(options.input, options.limit);
  const inputErrors = validateInput(records);
  if (inputErrors.length > 0) {
    console.log(JSON.stringify({ ok: false, mode: "validate", inputErrors }, null, 2));
    process.exitCode = 1;
    return;
  }

  initializeAdmin(options.serviceAccount);
  const db = admin.firestore();
  const { conflicts, existing } = await collectConflicts(db, records);
  const phoneNumbers = new Set(
    records.map((record) => String(record.usersDoc.phoneNumber || "").trim()).filter(Boolean),
  );
  const report = {
    ok: conflicts.length === 0,
    mode: options.apply ? "apply" : "dry-run",
    input: options.input,
    recordCount: records.length,
    existing,
    phoneNumberNote:
      phoneNumbers.size === 1
        ? "Auth phoneNumber is intentionally skipped; shared phoneNumber is only kept in Firestore profile docs."
        : "Auth phoneNumber is intentionally skipped.",
    sharedProfilePhoneNumbers: Array.from(phoneNumbers),
    conflicts,
  };

  if (conflicts.length > 0) {
    console.log(JSON.stringify(report, null, 2));
    process.exitCode = 1;
    return;
  }

  if (!options.apply) {
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  const batchId = `curated_accounts_${new Date().toISOString()}`;
  const authResults = { created: 0, updated: 0 };
  for (const record of records) {
    const result = await upsertAuthUser(record);
    authResults[result] += 1;
  }
  const firestoreCommits = await commitFirestore(records, batchId);

  console.log(JSON.stringify({
    ...report,
    batchId,
    authResults,
    firestoreCommits,
  }, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
