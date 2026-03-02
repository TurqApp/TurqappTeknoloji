const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const DST_KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';
const DST_BUCKET = 'turqappteknoloji.firebasestorage.app';

const STATE_FILE = path.join(__dirname, 'rename_live_collections_and_storage.state.json');
const BATCH_SIZE = Number(process.env.RENAME_BATCH || 300);

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      startedAt: Date.now(),
      collections: {
        qestionsBank_to_questionBank: { done: false, lastDocId: null, copied: 0, subCopied: 0 },
        questionsAnswer_to_questionsAnswers: { done: false, lastDocId: null, copied: 0, subCopied: 0 },
        Sikayetler_to_reports: { done: false, lastDocId: null, copied: 0, subCopied: 0 },
      },
      storage: {
        qestionsBank_to_questionBank: { done: false, pageToken: null, copied: 0, skippedExists: 0, failed: 0 },
      },
      errors: {},
      finishedAt: null,
    };
  }
  return readJson(STATE_FILE);
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function replaceAllInString(str) {
  return str
    .replaceAll('qestionsBank', 'questionBank')
    .replaceAll('questionsAnswer', 'questionsAnswers')
    .replaceAll('Sikayetler', 'reports');
}

function transformData(value) {
  if (typeof value === 'string') return replaceAllInString(value);
  if (Array.isArray(value)) return value.map(transformData);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = transformData(v);
    }
    return out;
  }
  return value;
}

async function copyCollection({ db, fromCol, toCol, subcollections = [], stateNode }) {
  if (stateNode.done) return;

  while (true) {
    let q = db.collection(fromCol).orderBy(admin.firestore.FieldPath.documentId()).limit(BATCH_SIZE);
    if (stateNode.lastDocId) q = q.startAfter(stateNode.lastDocId);
    const snap = await q.get();
    if (snap.empty) {
      stateNode.done = true;
      saveState(globalState);
      return;
    }

    for (const doc of snap.docs) {
      const docId = doc.id;
      stateNode.lastDocId = docId;
      try {
        const data = transformData(doc.data() || {});
        await db.collection(toCol).doc(docId).set(data, { merge: true });
        stateNode.copied += 1;

        for (const sub of subcollections) {
          const subSnap = await doc.ref.collection(sub).get();
          for (const subDoc of subSnap.docs) {
            const subData = transformData(subDoc.data() || {});
            await db.collection(toCol).doc(docId).collection(sub).doc(subDoc.id).set(subData, { merge: true });
            stateNode.subCopied += 1;
          }
        }
      } catch (e) {
        globalState.errors[`${fromCol}/${docId}`] = String(e && e.message ? e.message : e);
      }

      if ((stateNode.copied + stateNode.subCopied) % 200 === 0) saveState(globalState);
    }

    saveState(globalState);
    console.log(`${fromCol} -> ${toCol}`, {
      copied: stateNode.copied,
      subCopied: stateNode.subCopied,
      lastDocId: stateNode.lastDocId,
    });
  }
}

async function copyStoragePrefix({ bucket, fromPrefix, toPrefix, stateNode }) {
  if (stateNode.done) return;

  while (true) {
    const [files, , response] = await bucket.getFiles({
      prefix: fromPrefix,
      autoPaginate: false,
      maxResults: 500,
      pageToken: stateNode.pageToken || undefined,
    });

    for (const file of files) {
      const srcPath = file.name;
      if (!srcPath || srcPath.endsWith('/')) continue;
      const suffix = srcPath.slice(fromPrefix.length);
      const dstPath = `${toPrefix}${suffix}`;
      try {
        const dstFile = bucket.file(dstPath);
        const [exists] = await dstFile.exists();
        if (exists) {
          stateNode.skippedExists += 1;
        } else {
          await file.copy(dstFile);
          stateNode.copied += 1;
        }
      } catch (e) {
        stateNode.failed += 1;
        globalState.errors[`storage:${srcPath}`] = String(e && e.message ? e.message : e);
      }

      if ((stateNode.copied + stateNode.skippedExists + stateNode.failed) % 200 === 0) saveState(globalState);
    }

    stateNode.pageToken = response && response.nextPageToken ? response.nextPageToken : null;
    saveState(globalState);

    console.log('storage qestionsBank/ -> questionBank/', {
      copied: stateNode.copied,
      skippedExists: stateNode.skippedExists,
      failed: stateNode.failed,
      nextPageToken: stateNode.pageToken,
    });

    if (!stateNode.pageToken) {
      stateNode.done = true;
      saveState(globalState);
      return;
    }
  }
}

let globalState = null;

async function main() {
  const cred = readJson(DST_KEY);
  const app = admin.initializeApp({ credential: admin.credential.cert(cred), storageBucket: DST_BUCKET }, 'rename-live');
  const db = app.firestore();
  const bucket = app.storage().bucket(DST_BUCKET);

  globalState = loadState();
  saveState(globalState);

  await copyCollection({
    db,
    fromCol: 'qestionsBank',
    toCol: 'questionBank',
    subcollections: ['Cevaplayanlar'],
    stateNode: globalState.collections.qestionsBank_to_questionBank,
  });

  await copyCollection({
    db,
    fromCol: 'questionsAnswer',
    toCol: 'questionsAnswers',
    subcollections: [],
    stateNode: globalState.collections.questionsAnswer_to_questionsAnswers,
  });

  await copyCollection({
    db,
    fromCol: 'Sikayetler',
    toCol: 'reports',
    subcollections: [],
    stateNode: globalState.collections.Sikayetler_to_reports,
  });

  await copyStoragePrefix({
    bucket,
    fromPrefix: 'qestionsBank/',
    toPrefix: 'questionBank/',
    stateNode: globalState.storage.qestionsBank_to_questionBank,
  });

  globalState.finishedAt = Date.now();
  saveState(globalState);

  console.log('DONE', {
    collections: globalState.collections,
    storage: globalState.storage,
    errorCount: Object.keys(globalState.errors || {}).length,
  });
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
