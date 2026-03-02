const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const SRC_KEY = '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-c11948e622.json';
const DST_KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

const SRC_COLLECTION = 'Sinavlar';
const DST_COLLECTION = 'practiceExams';
const BATCH = Number(process.env.MIGRATE_BATCH || 100);
const STATE_FILE = path.join(__dirname, 'migrate_sinavlar_to_practiceexams.state.json');

function readMaybeBrokenJson(p) {
  const raw = fs.readFileSync(p, 'utf8');
  const i = raw.indexOf('{');
  return JSON.parse(i > 0 ? raw.slice(i) : raw);
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      lastDocId: null,
      processed: 0,
      rootCopied: 0,
      subCopied: 0,
      failed: {},
      startedAt: Date.now(),
      finishedAt: null,
    };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(s) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(s, null, 2));
}

async function copySubcollectionsRecursive(srcDocRef, dstDocRef, state) {
  const subCols = await srcDocRef.listCollections();
  for (const subCol of subCols) {
    const snap = await subCol.get();
    for (const subDoc of snap.docs) {
      const dstSubDoc = dstDocRef.collection(subCol.id).doc(subDoc.id);
      await dstSubDoc.set(subDoc.data() || {}, { merge: true });
      state.subCopied += 1;
      await copySubcollectionsRecursive(subDoc.ref, dstSubDoc, state);
    }
  }
}

async function main() {
  const srcCred = readMaybeBrokenJson(SRC_KEY);
  const dstCred = JSON.parse(fs.readFileSync(DST_KEY, 'utf8'));

  const srcApp = admin.initializeApp({ credential: admin.credential.cert(srcCred) }, 'src-sinav-mig');
  const dstApp = admin.initializeApp({ credential: admin.credential.cert(dstCred) }, 'dst-sinav-mig');

  const srcDb = srcApp.firestore();
  const dstDb = dstApp.firestore();

  const total = (await srcDb.collection(SRC_COLLECTION).count().get()).data().count;
  const state = loadState();
  console.log('total', total, 'resumeFrom', state.lastDocId);

  while (true) {
    let q = srcDb.collection(SRC_COLLECTION).orderBy(admin.firestore.FieldPath.documentId()).limit(BATCH);
    if (state.lastDocId) q = q.startAfter(state.lastDocId);
    const snap = await q.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      state.lastDocId = doc.id;
      try {
        const dstDocRef = dstDb.collection(DST_COLLECTION).doc(doc.id);
        await dstDocRef.set(doc.data() || {}, { merge: true });
        state.rootCopied += 1;
        await copySubcollectionsRecursive(doc.ref, dstDocRef, state);
      } catch (e) {
        state.failed[doc.id] = String(e && e.message ? e.message : e);
      } finally {
        state.processed += 1;
      }
    }

    saveState(state);
    console.log('progress', {
      processed: state.processed,
      rootCopied: state.rootCopied,
      subCopied: state.subCopied,
      failed: Object.keys(state.failed).length,
      lastDocId: state.lastDocId,
    });
  }

  state.finishedAt = Date.now();
  saveState(state);
  console.log('DONE', {
    processed: state.processed,
    rootCopied: state.rootCopied,
    subCopied: state.subCopied,
    failed: Object.keys(state.failed).length,
    lastDocId: state.lastDocId,
  });
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
