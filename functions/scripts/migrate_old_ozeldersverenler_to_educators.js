const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const SRC_KEY = '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-c11948e622.json';
const DST_KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';
const SRC_BUCKET = 'burs-city.appspot.com';
const DST_BUCKET = 'turqappteknoloji.firebasestorage.app';

const SRC_COL = 'OzelDersVerenler';
const DST_COL = 'educators';
const SRC_PREFIX = 'OzelDersVerenler/';
const DST_PREFIX = 'educators/';
const STATE_FILE = path.join(__dirname, 'migrate_old_ozeldersverenler_to_educators.state.json');

function readMaybeBrokenJson(p) {
  const raw = fs.readFileSync(p, 'utf8');
  const i = raw.indexOf('{');
  return JSON.parse(i > 0 ? raw.slice(i) : raw);
}

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      firestore: { done: false, lastDocId: null, copied: 0, failed: 0 },
      storage: { done: false, pageToken: null, copied: 0, skipped: 0, failed: 0 },
      errors: {},
      startedAt: Date.now(),
      finishedAt: null,
    };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(s) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(s, null, 2));
}

function transform(v) {
  if (typeof v === 'string') return v.replaceAll('OzelDersVerenler', 'educators');
  if (Array.isArray(v)) return v.map(transform);
  if (v && typeof v === 'object') {
    const out = {};
    for (const [k, val] of Object.entries(v)) out[k] = transform(val);
    return out;
  }
  return v;
}

async function migrateFirestore(srcDb, dstDb, s) {
  if (s.firestore.done) return;
  while (true) {
    let q = srcDb.collection(SRC_COL).orderBy(admin.firestore.FieldPath.documentId()).limit(200);
    if (s.firestore.lastDocId) q = q.startAfter(s.firestore.lastDocId);
    const snap = await q.get();
    if (snap.empty) {
      s.firestore.done = true;
      saveState(s);
      return;
    }
    for (const doc of snap.docs) {
      s.firestore.lastDocId = doc.id;
      try {
        const data = transform(doc.data() || {});
        await dstDb.collection(DST_COL).doc(doc.id).set(data, { merge: true });
        s.firestore.copied += 1;
      } catch (e) {
        s.firestore.failed += 1;
        s.errors[`fs:${doc.id}`] = String(e && e.message ? e.message : e);
      }
    }
    saveState(s);
    console.log('firestore', s.firestore);
  }
}

async function migrateStorage(srcBucket, dstBucket, s) {
  if (s.storage.done) return;
  while (true) {
    const [files, , resp] = await srcBucket.getFiles({
      prefix: SRC_PREFIX,
      autoPaginate: false,
      maxResults: 1000,
      pageToken: s.storage.pageToken || undefined,
    });

    for (const file of files) {
      const src = file.name;
      if (!src || src.endsWith('/')) continue;
      const dst = DST_PREFIX + src.slice(SRC_PREFIX.length);
      try {
        const dstFile = dstBucket.file(dst);
        const [exists] = await dstFile.exists();
        if (exists) {
          s.storage.skipped += 1;
        } else {
          await file.copy(dstFile);
          s.storage.copied += 1;
        }
      } catch (e) {
        s.storage.failed += 1;
        s.errors[`st:${src}`] = String(e && e.message ? e.message : e);
      }
    }

    s.storage.pageToken = resp && resp.nextPageToken ? resp.nextPageToken : null;
    saveState(s);
    console.log('storage', s.storage);

    if (!s.storage.pageToken) {
      s.storage.done = true;
      saveState(s);
      return;
    }
  }
}

async function main() {
  const srcKey = readMaybeBrokenJson(SRC_KEY);
  const dstKey = JSON.parse(fs.readFileSync(DST_KEY, 'utf8'));

  const srcApp = admin.initializeApp({ credential: admin.credential.cert(srcKey), storageBucket: SRC_BUCKET }, 'src-educators-old');
  const dstApp = admin.initializeApp({ credential: admin.credential.cert(dstKey), storageBucket: DST_BUCKET }, 'dst-educators-new');

  const srcDb = srcApp.firestore();
  const dstDb = dstApp.firestore();
  const srcBucket = srcApp.storage().bucket(SRC_BUCKET);
  const dstBucket = dstApp.storage().bucket(DST_BUCKET);

  const s = loadState();
  saveState(s);

  await migrateFirestore(srcDb, dstDb, s);
  await migrateStorage(srcBucket, dstBucket, s);

  s.finishedAt = Date.now();
  saveState(s);
  console.log('DONE', s);
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
