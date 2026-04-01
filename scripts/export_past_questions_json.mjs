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

function asEpochMillis(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value > 1e12 ? Math.trunc(value) : Math.trunc(value * 1000);
  }
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value && typeof value._seconds === 'number') return value._seconds * 1000;
  if (value && typeof value.seconds === 'number') return value.seconds * 1000;
  return 0;
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
    soruFormat: asString(data.soruFormat),
    soruNo: asString(data.soruNo),
    soruStoragePath: asString(data.soruStoragePath),
  };
}

function buildManifestItem(doc) {
  const data = doc.data() || {};
  return {
    _docId: doc.id,
    anaBaslik: asString(data.anaBaslik),
    sinavTuru: asString(data.sinavTuru),
    yil: asString(data.yil),
    baslik2: asString(data.baslik2),
    baslik3: asString(data.baslik3),
    dil: asString(data.dil),
    sira: asInt(data.sira),
    title: asString(data.title),
    subtitle: asString(data.subtitle),
    description: asString(data.description),
    cover: asString(data.cover) || asString(data.soru) || asString(data.img),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
    active: data.active === false ? false : true,
    iptal: asBool(data.iptal),
    deleted: asBool(data.deleted),
    questionJsonPath: `questions/${doc.id}/questions.json`,
  };
}

function compareManifestItems(a, b) {
  const seqA = asInt(a.sira);
  const seqB = asInt(b.sira);
  const bySeq = seqA - seqB;
  if (bySeq !== 0) return bySeq;
  return asInt(b.timeStamp) - asInt(a.timeStamp);
}

function isActiveManifestItem(item) {
  if (item.active === false) return false;
  return item.iptal !== true && item.deleted !== true;
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
  const manifestItems = [];

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
      const manifestItem = buildManifestItem(doc);
      if (isActiveManifestItem(manifestItem)) {
        manifestItems.push(manifestItem);
      }
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

  manifestItems.sort(compareManifestItems);

  const canWriteManifest = !isDryRun && !limit && !startAfterId;
  if (canWriteManifest) {
    await writeJson('questions/questions_manifest.json', {
      type: 'past_questions_root_manifest',
      exportedAt: Date.now(),
      count: manifestItems.length,
      items: manifestItems,
    });
  }

  console.log(
    isDryRun
      ? `Dry run complete. Would export ${exported} question sets, skipped ${skipped}, scanned ${scanned}.`
      : `Export complete. Exported ${exported} question sets, skipped ${skipped}, scanned ${scanned}.${canWriteManifest ? ` Wrote questions/questions_manifest.json (${manifestItems.length} items).` : ' Manifest write skipped (partial run or dry-run).'}`,
  );
}

run().catch((error) => {
  console.error('export_past_questions_json failed:', error);
  process.exit(1);
});
