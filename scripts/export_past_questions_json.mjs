#!/usr/bin/env node
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const overwrite = args.includes('--overwrite');
const limitArg = args.find((arg) => arg.startsWith('--limit='));
const startAfterArg = args.find((arg) => arg.startsWith('--start-after='));
const limit = limitArg ? Number(limitArg.split('=')[1]) : null;
const startAfterId = startAfterArg ? startAfterArg.split('=')[1] : null;
const BATCH_SIZE = 100;

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    storageBucket: 'turqappteknoloji.firebasestorage.app',
  });
}

const db = admin.firestore();
const bucket = admin.storage().bucket('turqappteknoloji.firebasestorage.app');
const rootCol = db.collection('questions');

function asString(value) {
  return String(value ?? '').trim();
}

function asBool(value) {
  return value === true;
}

function asInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
}

function buildQuestionItem(doc) {
  const data = doc.data() || {};
  return {
    _docId: doc.id,
    ders: asString(data.ders),
    dogruCevap: asString(data.dogruCevap),
    iptal: asBool(data.iptal),
    kacCevap: asInt(data.kacCevap),
    soru: asString(data.soru),
    soruNo: asString(data.soruNo),
    soruStoragePath: asString(data.soruStoragePath),
  };
}

async function readQuestionDocs(rootRef) {
  let snap = await rootRef.collection('questions').orderBy(admin.firestore.FieldPath.documentId()).get();
  if (snap.empty) {
    snap = await rootRef.collection('Sorular').orderBy(admin.firestore.FieldPath.documentId()).get();
  }
  return snap.docs.map(buildQuestionItem);
}

async function remoteJsonExists(path) {
  const [exists] = await bucket.file(path).exists();
  return exists;
}

async function writeJson(path, payload) {
  const file = bucket.file(path);
  await file.save(JSON.stringify(payload), {
    contentType: 'application/json; charset=utf-8',
    resumable: false,
    metadata: {
      cacheControl: 'public,max-age=3600',
    },
  });
}

async function run() {
  let scanned = 0;
  let exported = 0;
  let skipped = 0;
  let lastDoc = null;

  if (startAfterId) {
    const startDoc = await rootCol.doc(startAfterId).get();
    if (!startDoc.exists) throw new Error(`start-after doc not found: ${startAfterId}`);
    lastDoc = startDoc;
  }

  while (true) {
    let query = rootCol.orderBy(admin.firestore.FieldPath.documentId()).limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      scanned += 1;
      const path = `questions/${doc.id}/questions.json`;
      const exists = overwrite ? false : await remoteJsonExists(path);
      if (exists) {
        skipped += 1;
      } else {
        const items = await readQuestionDocs(doc.ref);
        if (!isDryRun) {
          await writeJson(path, {
            docId: doc.id,
            itemCount: items.length,
            exportedAt: Date.now(),
            items,
          });
        }
        exported += 1;
      }

      lastDoc = doc;
      console.log(
        `[export_past_questions_json] scanned=${scanned} exported=${exported} skipped=${skipped} last=${doc.id}`
      );

      if (limit && scanned >= limit) {
        console.log('Limit reached.');
        return;
      }
    }
  }

  console.log(
    isDryRun
      ? `Dry run complete. Would export ${exported} question sets, skipped ${skipped}, scanned ${scanned}.`
      : `Export complete. Exported ${exported} question sets, skipped ${skipped}, scanned ${scanned}.`
  );
}

run().catch((error) => {
  console.error('export_past_questions_json failed:', error);
  process.exit(1);
});
