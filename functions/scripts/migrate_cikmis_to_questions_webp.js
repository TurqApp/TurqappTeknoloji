const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const sharp = require('sharp');

const SOURCE_KEY_PATH = '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-94844a37a9.json';
const TARGET_KEY_PATH = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

const SRC_ROOT = 'CikmisSorular';
const SRC_SUB = 'Sorular';

const DST_ROOT = 'questions';
const DST_SUB = 'questions';

const CONCURRENCY = Number(process.env.MIGRATE_CONCURRENCY || 8);
const STATE_FILE = path.join(__dirname, 'migrate_cikmis_to_questions_webp.state.json');

function readJsonWithPossiblePrefix(filePath) {
  let raw = fs.readFileSync(filePath, 'utf8');
  const firstBrace = raw.indexOf('{');
  if (firstBrace > 0) raw = raw.slice(firstBrace);
  return JSON.parse(raw);
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return { done: {}, failed: {}, processed: 0, uploaded: 0, skipped: 0, startedAt: Date.now() };
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
    const idx = u.pathname.indexOf(marker);
    if (idx === -1) return null;
    const encoded = u.pathname.slice(idx + marker.length);
    return decodeURIComponent(encoded);
  } catch {
    return null;
  }
}

async function fetchBuffer(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Download failed ${res.status} ${url}`);
  const arr = await res.arrayBuffer();
  return Buffer.from(arr);
}

async function run() {
  const srcKey = readJsonWithPossiblePrefix(SOURCE_KEY_PATH);
  const dstKey = readJsonWithPossiblePrefix(TARGET_KEY_PATH);

  const srcApp = admin.initializeApp({
    credential: admin.credential.cert(srcKey),
    projectId: srcKey.project_id,
    storageBucket: 'burs-city.appspot.com',
  }, 'src-cikmis');

  const dstApp = admin.initializeApp({
    credential: admin.credential.cert(dstKey),
    projectId: dstKey.project_id,
    storageBucket: 'turqappteknoloji.firebasestorage.app',
  }, 'dst-questions');

  const srcDb = srcApp.firestore();
  const dstDb = dstApp.firestore();
  const dstBucket = dstApp.storage().bucket();

  const state = loadState();
  let flushCounter = 0;

  const rootSnap = await srcDb.collection(SRC_ROOT).get();
  console.log(`Root docs: ${rootSnap.size}`);

  for (const rootDoc of rootSnap.docs) {
    const rootId = rootDoc.id;

    const rootData = rootDoc.data() || {};
    await dstDb.collection(DST_ROOT).doc(rootId).set(rootData, { merge: true });

    const subSnap = await rootDoc.ref.collection(SRC_SUB).get();
    console.log(`[${rootId}] sub docs: ${subSnap.size}`);

    let index = 0;
    while (index < subSnap.docs.length) {
      const slice = subSnap.docs.slice(index, index + CONCURRENCY);
      await Promise.all(slice.map(async (subDoc) => {
        const subId = subDoc.id;
        const key = `${rootId}/${subId}`;

        if (state.done[key]) {
          state.skipped++;
          return;
        }

        const data = subDoc.data() || {};
        const out = { ...data };

        try {
          const sourceUrl = data.soru;
          if (typeof sourceUrl === 'string' && sourceUrl.startsWith('http')) {
            const sourcePath = decodeStoragePathFromUrl(sourceUrl) || 'unknown';
            const bin = await fetchBuffer(sourceUrl);
            const webp = await sharp(bin)
              .rotate()
              .webp({ quality: 84, effort: 5 })
              .toBuffer();

            const targetPath = `${DST_ROOT}/${rootId}/${DST_SUB}/${subId}.webp`;
            const file = dstBucket.file(targetPath);
            await file.save(webp, {
              metadata: {
                contentType: 'image/webp',
                metadata: {
                  sourcePath,
                  sourceProject: srcKey.project_id,
                },
              },
              resumable: false,
            });

            const [signedUrl] = await file.getSignedUrl({
              action: 'read',
              expires: '03-01-2500',
            });

            out.soru = signedUrl;
            out.soruStoragePath = targetPath;
            out.soruFormat = 'webp';
            out.migratedAt = Date.now();
            out.migrationSource = sourceUrl;
            state.uploaded++;
          }

          await dstDb
            .collection(DST_ROOT)
            .doc(rootId)
            .collection(DST_SUB)
            .doc(subId)
            .set(out, { merge: true });

          state.done[key] = true;
          state.processed++;
        } catch (e) {
          state.failed[key] = String(e?.message || e);
          state.processed++;
        }

        flushCounter++;
        if (flushCounter % 50 === 0) {
          saveState(state);
          console.log(`progress processed=${state.processed} uploaded=${state.uploaded} skipped=${state.skipped} failed=${Object.keys(state.failed).length}`);
        }
      }));
      index += CONCURRENCY;
    }

    saveState(state);
  }

  saveState(state);
  console.log('DONE', {
    processed: state.processed,
    uploaded: state.uploaded,
    skipped: state.skipped,
    failed: Object.keys(state.failed).length,
  });

  await srcApp.delete();
  await dstApp.delete();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
