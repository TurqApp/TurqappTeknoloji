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
const jobsCol = db.collection('isBul');

function millisDaysAgo(days) {
  return Date.now() - days * 24 * 60 * 60 * 1000;
}

async function run() {
  const snap = await jobsCol
    .orderBy(admin.firestore.FieldPath.documentId())
    .get();

  let updated = 0;
  let offsetDays = 0;

  for (let i = 0; i < snap.docs.length; i += 200) {
    const batch = db.batch();
    let writes = 0;

    for (const doc of snap.docs.slice(i, i + 200)) {
      const ts = millisDaysAgo(offsetDays);
      offsetDays += 1;
      batch.update(doc.ref, {
        timeStamp: ts,
        updatedAt: ts,
      });
      writes += 1;
      updated += 1;
    }

    if (writes > 0) {
      await batch.commit();
    }
  }

  console.log(JSON.stringify({ done: true, scanned: snap.size, updated }));
}

run().catch((err) => {
  console.error('refresh_job_timestamps failed:', err);
  process.exit(1);
});
