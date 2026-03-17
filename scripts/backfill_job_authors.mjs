#!/usr/bin/env node
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const overwrite = args.includes('--overwrite');
const onlyMissing = !overwrite;
const limitArg = args.find((a) => a.startsWith('--limit='));
const startAfterArg = args.find((a) => a.startsWith('--start-after='));
const limit = limitArg ? Number(limitArg.split('=')[1]) : null;
const startAfterId = startAfterArg ? startAfterArg.split('=')[1] : null;

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();
const jobsCol = db.collection('isBul');
const usersCol = db.collection('users');
const BATCH_SIZE = 250;

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
  if (combined) return combined;
  return asString(user.nickname);
}

function buildAuthorPatch(user) {
  const nickname = asString(user.nickname);
  const displayName = buildDisplayName(user);
  const avatarUrl = asString(user.avatarUrl) || asString(user.pfImage);
  const rozet = asString(user.rozet);
  return {
    nickname,
    displayName: displayName || nickname,
    avatarUrl,
    authorNickname: nickname,
    authorDisplayName: displayName || nickname,
    authorAvatarUrl: avatarUrl,
    rozet,
  };
}

function needsPatch(data) {
  if (!onlyMissing) return true;
  return !asString(data.nickname) ||
    !asString(data.displayName) ||
    !asString(data.avatarUrl) ||
    !asString(data.authorNickname) ||
    !asString(data.authorDisplayName) ||
    !asString(data.authorAvatarUrl) ||
    !asString(data.rozet);
}

async function fetchUsersByIds(userIds) {
  const uniqueIds = [...new Set(userIds.map((id) => id.trim()).filter(Boolean))];
  if (uniqueIds.length === 0) return new Map();
  const refs = uniqueIds.map((id) => usersCol.doc(id));
  const snaps = await db.getAll(...refs);
  const out = new Map();
  snaps.forEach((snap) => {
    if (snap.exists) {
      out.set(snap.id, snap.data() || {});
    }
  });
  return out;
}

async function run() {
  let totalScanned = 0;
  let totalUpdated = 0;
  let lastDoc = null;

  if (startAfterId) {
    const startDoc = await jobsCol.doc(startAfterId).get();
    if (!startDoc.exists) {
      throw new Error(`start-after doc not found: ${startAfterId}`);
    }
    lastDoc = startDoc;
  }

  while (true) {
    let query = jobsCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    totalScanned += snap.size;
    const candidates = snap.docs.filter((doc) => needsPatch(doc.data() || {}));
    const userIds = candidates
      .map((doc) => asString(doc.data()?.userID))
      .filter(Boolean);
    const usersById = await fetchUsersByIds(userIds);

    if (!isDryRun && candidates.isNotEmpty) {
      const batch = db.batch();
      for (const doc of candidates) {
        const data = doc.data() || {};
        const userId = asString(data.userID);
        const user = usersById.get(userId);
        if (!user) continue;
        batch.update(doc.ref, {
          ...buildAuthorPatch(user),
          updatedAt: Date.now(),
        });
        totalUpdated += 1;
      }
      await batch.commit();
    } else if (isDryRun) {
      for (const doc of candidates) {
        const userId = asString(doc.data()?.userID);
        if (usersById.has(userId)) totalUpdated += 1;
      }
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    console.log(
      `[backfill_job_authors] scanned=${totalScanned} updated=${totalUpdated} last=${lastDoc.id}`
    );

    if (limit && totalScanned >= limit) break;
  }

  console.log(
    isDryRun
      ? `Dry run complete. Would update ${totalUpdated} jobs after scanning ${totalScanned}.`
      : `Backfill complete. Updated ${totalUpdated} jobs after scanning ${totalScanned}.`
  );
}

run().catch((err) => {
  console.error('backfill_job_authors failed:', err);
  process.exit(1);
});
