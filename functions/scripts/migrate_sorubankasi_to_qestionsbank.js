const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const SRC_KEY = '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-94844a37a9.json';
const DST_KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

const SRC_COLLECTION = 'SoruBankasi';
const DST_COLLECTION = 'questionBank';
const SUBCOL = 'Cevaplayanlar';

const SRC_BUCKET = 'burs-city.appspot.com';
const DST_BUCKET = 'turqappteknoloji.firebasestorage.app';

const BATCH_SIZE = Number(process.env.MIGRATE_BATCH || 200);
const STATE_FILE = path.join(__dirname, 'migrate_sorubankasi_to_questionbank.state.json');

function readMaybeBrokenJson(p) {
  const raw = fs.readFileSync(p, 'utf8');
  const idx = raw.indexOf('{');
  return JSON.parse(idx > 0 ? raw.slice(idx) : raw);
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      lastDocId: null,
      processed: 0,
      firestoreWritten: 0,
      subWritten: 0,
      storageCopied: 0,
      failedDocs: {},
      copiedStorage: {},
      startedAt: Date.now(),
    };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function decodeStoragePathFromUrl(url) {
  try {
    const u = new URL(url);
    const marker = '/o/';
    const i = u.pathname.indexOf(marker);
    if (i < 0) return null;
    return decodeURIComponent(u.pathname.slice(i + marker.length));
  } catch {
    return null;
  }
}

function buildDstPath(srcPath) {
  if (srcPath.startsWith('SoruBankasi/')) {
    return 'questionBank/' + srcPath.slice('SoruBankasi/'.length);
  }
  return 'questionBank/' + srcPath;
}

function toWebpPath(dstPath) {
  const ext = path.posix.extname(dstPath);
  if (!ext) return `${dstPath}.webp`;
  return `${dstPath.slice(0, -ext.length)}.webp`;
}

async function copyStorageIfNeeded(srcBucket, dstBucket, srcPath, dstPath, state) {
  if (state.copiedStorage[srcPath]) return;
  const webpPath = toWebpPath(dstPath);
  const [alreadyExists] = await dstBucket.file(webpPath).exists();
  if (alreadyExists) {
    state.copiedStorage[srcPath] = webpPath;
    return;
  }
  const [buf] = await srcBucket.file(srcPath).download();
  const webp = await sharp(buf).rotate().webp({ quality: 84, effort: 5 }).toBuffer();
  await dstBucket.file(webpPath).save(webp, {
    resumable: false,
    metadata: {
      contentType: 'image/webp',
      cacheControl: 'public,max-age=31536000',
    },
  });
  state.copiedStorage[srcPath] = webpPath;
  state.storageCopied += 1;
}

async function signedUrlFor(dstBucket, dstPath) {
  const [url] = await dstBucket.file(dstPath).getSignedUrl({ action: 'read', expires: '03-01-2500' });
  return url;
}

async function main() {
  const srcCred = readMaybeBrokenJson(SRC_KEY);
  const dstCred = JSON.parse(fs.readFileSync(DST_KEY, 'utf8'));

  const srcApp = admin.initializeApp({ credential: admin.credential.cert(srcCred), storageBucket: SRC_BUCKET }, 'src-qb');
  const dstApp = admin.initializeApp({ credential: admin.credential.cert(dstCred), storageBucket: DST_BUCKET }, 'dst-qb');

  const srcDb = srcApp.firestore();
  const dstDb = dstApp.firestore();

  const srcBucket = srcApp.storage().bucket(SRC_BUCKET);
  const dstBucket = dstApp.storage().bucket(DST_BUCKET);

  const state = loadState();
  const total = (await srcDb.collection(SRC_COLLECTION).count().get()).data().count;
  console.log('total', total, 'resumeFrom', state.lastDocId);

  while (true) {
    let q = srcDb.collection(SRC_COLLECTION).orderBy(admin.firestore.FieldPath.documentId()).limit(BATCH_SIZE);
    if (state.lastDocId) q = q.startAfter(state.lastDocId);

    const snap = await q.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const docId = doc.id;
      state.lastDocId = docId;
      try {
        const srcData = doc.data() || {};
        const dstData = { ...srcData };

        if (typeof srcData.soru === 'string' && srcData.soru.includes('http')) {
          const srcPath = decodeStoragePathFromUrl(srcData.soru);
          if (srcPath) {
            const dstPath = buildDstPath(srcPath);
            await copyStorageIfNeeded(srcBucket, dstBucket, srcPath, dstPath, state);
            dstData.soru = await signedUrlFor(dstBucket, state.copiedStorage[srcPath]);
            dstData.soruFormat = 'webp';
          }
        }

        await dstDb.collection(DST_COLLECTION).doc(docId).set(dstData, { merge: true });
        state.firestoreWritten += 1;

        const subSnap = await doc.ref.collection(SUBCOL).get();
        for (const sdoc of subSnap.docs) {
          await dstDb.collection(DST_COLLECTION).doc(docId).collection(SUBCOL).doc(sdoc.id).set(sdoc.data() || {}, { merge: true });
          state.subWritten += 1;
        }
      } catch (e) {
        state.failedDocs[docId] = String(e && e.message ? e.message : e);
        console.error('doc_fail', docId, state.failedDocs[docId]);
      } finally {
        state.processed += 1;
        if (state.processed % 50 === 0) {
          console.log('progress', {
            processed: state.processed,
            firestoreWritten: state.firestoreWritten,
            subWritten: state.subWritten,
            storageCopied: state.storageCopied,
            failed: Object.keys(state.failedDocs).length,
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
    firestoreWritten: state.firestoreWritten,
    subWritten: state.subWritten,
    storageCopied: state.storageCopied,
    failed: Object.keys(state.failedDocs).length,
    lastDocId: state.lastDocId,
  });
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
