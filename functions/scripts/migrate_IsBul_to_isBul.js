const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const KEY_PATH =
  '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';
const SRC_COLLECTION = 'IsBul';
const DST_COLLECTION = 'isBul';
const STATE_FILE = path.join(__dirname, 'migrate_isbul_to_isbul.state.json');
const BATCH_SIZE = Number(process.env.ISBUL_BATCH || 100);

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      startedAt: Date.now(),
      lastDocId: null,
      processed: 0,
      rootCopied: 0,
      subCopied: 0,
      failed: {},
      done: false,
    };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function copyDocRecursive(srcRef, dstRef) {
  const snap = await srcRef.get();
  if (!snap.exists) return { root: 0, sub: 0 };

  await dstRef.set(snap.data() || {}, { merge: true });
  let subCopied = 0;

  const subs = await srcRef.listCollections();
  for (const subCol of subs) {
    const subSnap = await subCol.get();
    for (const subDoc of subSnap.docs) {
      const child = await copyDocRecursive(
        subDoc.ref,
        dstRef.collection(subCol.id).doc(subDoc.id),
      );
      subCopied += 1 + child.sub;
    }
  }

  return { root: 1, sub: subCopied };
}

async function main() {
  const cred = JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'));
  const app = admin.initializeApp(
    { credential: admin.credential.cert(cred) },
    'migrate-isbul',
  );
  const db = app.firestore();

  const state = loadState();
  if (state.done) {
    console.log('Already done:', state);
    return;
  }

  while (true) {
    let query = db
      .collection(SRC_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (state.lastDocId) query = query.startAfter(state.lastDocId);

    const snap = await query.get();
    if (snap.empty) {
      state.done = true;
      state.finishedAt = Date.now();
      saveState(state);
      console.log('DONE', state);
      return;
    }

    for (const doc of snap.docs) {
      state.lastDocId = doc.id;
      state.processed += 1;
      try {
        const copied = await copyDocRecursive(
          doc.ref,
          db.collection(DST_COLLECTION).doc(doc.id),
        );
        state.rootCopied += copied.root;
        state.subCopied += copied.sub;
      } catch (e) {
        state.failed[doc.id] = String(e && e.message ? e.message : e);
      }

      if (state.processed % 20 === 0) {
        saveState(state);
        console.log({
          processed: state.processed,
          rootCopied: state.rootCopied,
          subCopied: state.subCopied,
          failed: Object.keys(state.failed).length,
          lastDocId: state.lastDocId,
        });
      }
    }

    saveState(state);
  }
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});

