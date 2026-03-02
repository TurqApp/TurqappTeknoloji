const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const SRC_KEY_PATH = '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-94844a37a9.json';
const DST_KEY_PATH = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

const SRC_ROOT = 'Kitapciklar';
const DST_ROOT = 'books';
const COVER_FIELD = 'cover';

const SRC_BUCKET = 'burs-city.appspot.com';
const DST_BUCKET = 'turqappteknoloji.firebasestorage.app';

const CONCURRENCY = Number(process.env.MIGRATE_CONCURRENCY || 6);
const STATE_FILE = path.join(__dirname, 'migrate_kitapciklar_to_books_webp.state.json');

function readMaybeBrokenJson(p) {
  const raw = fs.readFileSync(p, 'utf8');
  const idx = raw.indexOf('{');
  return JSON.parse(idx > 0 ? raw.slice(idx) : raw);
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      done: {},
      failed: {},
      rootDone: {},
      processed: 0,
      uploaded: 0,
      copiedSubDocs: 0,
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
    const encoded = u.pathname.slice(i + marker.length);
    return decodeURIComponent(encoded);
  } catch {
    return null;
  }
}

async function downloadFromSourceBucket(srcBucket, objectPath) {
  const [buffer] = await srcBucket.file(objectPath).download();
  return buffer;
}

async function uploadWebpAndGetUrl(dstBucket, dstPath, buffer) {
  const file = dstBucket.file(dstPath);
  await file.save(buffer, {
    metadata: { contentType: 'image/webp', cacheControl: 'public,max-age=31536000' },
    resumable: false,
  });
  const [url] = await file.getSignedUrl({ action: 'read', expires: '03-01-2500' });
  return url;
}

async function runPool(items, worker, concurrency) {
  const queue = [...items];
  const workers = Array.from({ length: Math.max(1, concurrency) }, async () => {
    while (queue.length) {
      const item = queue.shift();
      await worker(item);
    }
  });
  await Promise.all(workers);
}

async function main() {
  const srcCred = readMaybeBrokenJson(SRC_KEY_PATH);
  const dstCred = JSON.parse(fs.readFileSync(DST_KEY_PATH, 'utf8'));

  const srcApp = admin.initializeApp({ credential: admin.credential.cert(srcCred), storageBucket: SRC_BUCKET }, 'src-books');
  const dstApp = admin.initializeApp({ credential: admin.credential.cert(dstCred), storageBucket: DST_BUCKET }, 'dst-books');

  const srcDb = srcApp.firestore();
  const dstDb = dstApp.firestore();
  const srcBucket = srcApp.storage().bucket(SRC_BUCKET);
  const dstBucket = dstApp.storage().bucket(DST_BUCKET);

  const state = loadState();

  const roots = await srcDb.collection(SRC_ROOT).get();
  console.log('Root docs:', roots.size);

  for (const rootDoc of roots.docs) {
    const rootId = rootDoc.id;
    const srcRootData = rootDoc.data() || {};

    const dstRootRef = dstDb.collection(DST_ROOT).doc(rootId);
    const rootPatch = { ...srcRootData };

    // cover -> webp
    try {
      const coverUrl = srcRootData[COVER_FIELD];
      if (typeof coverUrl === 'string' && coverUrl.includes('http')) {
        const srcPath = decodeStoragePathFromUrl(coverUrl);
        if (srcPath) {
          const key = `${rootId}/__cover__`;
          if (!state.done[key]) {
            const original = await downloadFromSourceBucket(srcBucket, srcPath);
            if (!original || original.length === 0) throw new Error('empty_cover_buffer');
            const webp = await sharp(original).webp({ quality: 82 }).toBuffer();
            const dstPath = `${DST_ROOT}/${rootId}/cover.webp`;
            const newUrl = await uploadWebpAndGetUrl(dstBucket, dstPath, webp);
            rootPatch[COVER_FIELD] = newUrl;
            rootPatch.coverStoragePath = dstPath;
            rootPatch.coverFormat = 'webp';
            state.done[key] = true;
            state.uploaded += 1;
          }
        }
      }
    } catch (e) {
      const k = `${rootId}/__cover__`;
      state.failed[k] = String(e.message || e);
      console.error('cover_fail', k, state.failed[k]);
    }

    await dstRootRef.set({
      ...rootPatch,
      migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      migrationSource: 'Kitapciklar->books',
    }, { merge: true });

    // copy all subcollections as-is
    const subcols = await rootDoc.ref.listCollections();
    for (const sub of subcols) {
      const subSnap = await sub.get();
      console.log(`[${rootId}] sub ${sub.id}:`, subSnap.size);
      await runPool(subSnap.docs, async (sd) => {
        const key = `${rootId}/${sub.id}/${sd.id}`;
        if (state.done[key]) return;
        try {
          await dstRootRef.collection(sub.id).doc(sd.id).set(sd.data() || {}, { merge: true });
          state.done[key] = true;
          state.copiedSubDocs += 1;
        } catch (e) {
          state.failed[key] = String(e.message || e);
          console.error('sub_fail', key, state.failed[key]);
        } finally {
          state.processed += 1;
          if (state.processed % 20 === 0) {
            console.log(`progress processed=${state.processed} uploaded=${state.uploaded} subCopied=${state.copiedSubDocs} failed=${Object.keys(state.failed).length}`);
            saveState(state);
          }
        }
      }, CONCURRENCY);
    }

    state.rootDone[rootId] = true;
    saveState(state);
  }

  saveState(state);
  console.log('DONE', {
    processed: state.processed,
    uploaded: state.uploaded,
    copiedSubDocs: state.copiedSubDocs,
    failed: Object.keys(state.failed).length,
    roots: Object.keys(state.rootDone).length,
  });
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
