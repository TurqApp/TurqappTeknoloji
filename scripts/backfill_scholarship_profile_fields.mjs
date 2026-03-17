#!/usr/bin/env node
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();
const scholarshipsCol = db
  .collection('catalog')
  .doc('education')
  .collection('scholarships');
const usersCol = db.collection('users');
const BATCH_SIZE = 200;

function asString(value) {
  return String(value ?? '').trim();
}

function buildDisplayName(user) {
  const displayName = asString(user.displayName);
  if (displayName) return displayName;
  const fullName = asString(user.fullName);
  if (fullName) return fullName;
  const combined = [asString(user.firstName), asString(user.lastName)]
    .filter(Boolean)
    .join(' ')
    .trim();
  return combined || asString(user.nickname);
}

function buildPatch(user) {
  const nickname = asString(user.nickname) || asString(user.username);
  const displayName = buildDisplayName(user) || nickname;
  const avatarUrl = asString(user.avatarUrl);
  const rozet = asString(user.rozet);
  return {
    nickname,
    displayName,
    avatarUrl,
    rozet,
  };
}

async function fetchUsers(userIds) {
  const ids = [...new Set(userIds.map(asString).filter(Boolean))];
  if (!ids.length) return new Map();
  const refs = ids.map((id) => usersCol.doc(id));
  const snaps = await db.getAll(...refs);
  const out = new Map();
  for (const snap of snaps) {
    if (snap.exists) out.set(snap.id, snap.data() || {});
  }
  return out;
}

function needsUpdate(data, patch) {
  return (
    asString(data.nickname) !== patch.nickname ||
    asString(data.displayName) !== patch.displayName ||
    asString(data.avatarUrl) !== patch.avatarUrl ||
    asString(data.rozet) !== patch.rozet
  );
}

async function run() {
  let scanned = 0;
  let updated = 0;
  let lastDoc = null;

  while (true) {
    let query = scholarshipsCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    const snap = await query.get();
    if (snap.empty) break;

    scanned += snap.size;
    const userIds = snap.docs.map((doc) => {
      const data = doc.data() || {};
      return asString(data.userID) || asString(data.ownerId);
    });
    const users = await fetchUsers(userIds);
    const batch = db.batch();
    let batchUpdates = 0;

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const uid = asString(data.userID) || asString(data.ownerId);
      const user = users.get(uid);
      if (!user) continue;
      const patch = buildPatch(user);
      if (!needsUpdate(data, patch)) continue;
      batch.update(doc.ref, {
        ...patch,
        updatedAt: Date.now(),
      });
      batchUpdates += 1;
      updated += 1;
    }

    if (batchUpdates > 0) {
      await batch.commit();
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    console.log(
      JSON.stringify({
        scanned,
        updated,
        last: lastDoc.id,
      })
    );
  }

  console.log(JSON.stringify({ done: true, scanned, updated }));
}

run().catch((err) => {
  console.error('backfill_scholarship_profile_fields failed:', err);
  process.exit(1);
});
