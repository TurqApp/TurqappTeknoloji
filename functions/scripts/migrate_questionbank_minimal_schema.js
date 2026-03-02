const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const KEY_PATH =
  process.env.FIREBASE_ADMIN_KEY ||
  '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

const COLLECTION = 'questionBank';
const SUBCOL_OLD_ANSWERS = 'Cevaplayanlar';
const BATCH_SIZE = Number(process.env.MIGRATE_BATCH || 200);
const STATE_FILE = path.join(
  __dirname,
  'migrate_questionbank_minimal_schema.state.json',
);

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      lastDocId: null,
      processed: 0,
      updated: 0,
      deletedSubDocs: 0,
      failed: {},
      startedAt: Date.now(),
    };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function toCategoryKey(d) {
  const anaBaslik = String(d.anaBaslik || '').trim();
  const sinavTuru = String(d.sinavTuru || '').trim();
  const ders = String(d.ders || '').trim();
  return `${anaBaslik}|${sinavTuru}|${ders}`;
}

function toInt(v, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
}

function parseSeq(soruNo, fallback) {
  const raw = String(soruNo || '').trim();
  if (!raw) return fallback;
  const clean = raw.replace(/[^\d]/g, '');
  if (!clean) return fallback;
  const n = Number(clean);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
}

async function deleteOldAnswerSubcollection(docRef, state) {
  const snap = await docRef.collection(SUBCOL_OLD_ANSWERS).get();
  if (snap.empty) return;
  let batch = docRef.firestore.batch();
  let count = 0;
  for (const sdoc of snap.docs) {
    batch.delete(sdoc.ref);
    count++;
    if (count % 450 === 0) {
      await batch.commit();
      batch = docRef.firestore.batch();
    }
  }
  await batch.commit();
  state.deletedSubDocs += snap.size;
}

async function main() {
  const cred = JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'));
  const app = admin.initializeApp({
    credential: admin.credential.cert(cred),
    storageBucket: 'turqappteknoloji.firebasestorage.app',
  });
  const db = app.firestore();
  const FieldValue = admin.firestore.FieldValue;
  const state = loadState();

  const total = (await db.collection(COLLECTION).count().get()).data().count;
  console.log('total', total, 'resumeFrom', state.lastDocId);

  let fallbackSeq = 1000000 + state.processed;

  while (true) {
    let q = db
      .collection(COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);
    if (state.lastDocId) q = q.startAfter(state.lastDocId);

    const snap = await q.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      state.lastDocId = doc.id;
      try {
        const d = doc.data() || {};
        const correctCount = toInt(
          d.correctCount,
          Array.isArray(d.dogruCevapVerenler) ? d.dogruCevapVerenler.length : 0,
        );
        const wrongCount = toInt(
          d.wrongCount,
          Array.isArray(d.yanlisCevapVerenler) ? d.yanlisCevapVerenler.length : 0,
        );
        const viewCount = toInt(
          d.viewCount,
          Array.isArray(d.goruntuleme) ? d.goruntuleme.length : 0,
        );
        const seq = toInt(d.seq, parseSeq(d.soruNo, fallbackSeq++));
        const active =
          typeof d.active === 'boolean'
            ? d.active
            : !(d.iptal === true);

        await doc.ref.set(
          {
            categoryKey: d.categoryKey || toCategoryKey(d),
            seq,
            active,
            viewCount,
            correctCount,
            wrongCount,
            // legacy alanları kaldır
            goruntuleme: FieldValue.delete(),
            soruCoz: FieldValue.delete(),
            dogruCevapVerenler: FieldValue.delete(),
            yanlisCevapVerenler: FieldValue.delete(),
          },
          { merge: true },
        );

        await deleteOldAnswerSubcollection(doc.ref, state);
        state.updated += 1;
      } catch (e) {
        state.failed[doc.id] = String(e && e.message ? e.message : e);
      } finally {
        state.processed += 1;
        if (state.processed % 100 === 0) {
          console.log('progress', {
            processed: state.processed,
            updated: state.updated,
            deletedSubDocs: state.deletedSubDocs,
            failed: Object.keys(state.failed).length,
            lastDocId: state.lastDocId,
          });
          saveState(state);
        }
      }
    }
    saveState(state);
  }

  saveState(state);
  console.log('DONE', {
    processed: state.processed,
    updated: state.updated,
    deletedSubDocs: state.deletedSubDocs,
    failed: Object.keys(state.failed).length,
    lastDocId: state.lastDocId,
  });
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});

