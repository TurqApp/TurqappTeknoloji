const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';
const BUCKET = 'turqappteknoloji.firebasestorage.app';
const SRC_COL = 'OzelDersVerenler';
const DST_COL = 'educators';
const SRC_PREFIX = 'OzelDersVerenler/';
const DST_PREFIX = 'educators/';
const STATE_FILE = path.join(__dirname, 'migrate_ozeldersverenler_to_educators.state.json');
const BATCH = Number(process.env.MIGRATE_BATCH || 300);

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      collections: { done: false, lastDocId: null, copied: 0, failed: 0 },
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

function replaceStrings(v) {
  if (typeof v === 'string') return v.replaceAll('OzelDersVerenler', 'educators');
  if (Array.isArray(v)) return v.map(replaceStrings);
  if (v && typeof v === 'object') {
    const out = {};
    for (const [k, val] of Object.entries(v)) out[k] = replaceStrings(val);
    return out;
  }
  return v;
}

async function migrateFirestore(db, state) {
  if (state.collections.done) return;
  while (true) {
    let q = db.collection(SRC_COL).orderBy(admin.firestore.FieldPath.documentId()).limit(BATCH);
    if (state.collections.lastDocId) q = q.startAfter(state.collections.lastDocId);
    const snap = await q.get();
    if (snap.empty) {
      state.collections.done = true;
      saveState(state);
      return;
    }
    for (const doc of snap.docs) {
      state.collections.lastDocId = doc.id;
      try {
        const data = replaceStrings(doc.data() || {});
        await db.collection(DST_COL).doc(doc.id).set(data, { merge: true });
        state.collections.copied += 1;
      } catch (e) {
        state.collections.failed += 1;
        state.errors[`fs:${doc.id}`] = String(e && e.message ? e.message : e);
      }
      if ((state.collections.copied + state.collections.failed) % 200 === 0) saveState(state);
    }
    saveState(state);
    console.log('firestore', {
      copied: state.collections.copied,
      failed: state.collections.failed,
      lastDocId: state.collections.lastDocId,
    });
  }
}

async function migrateStorage(bucket, state) {
  if (state.storage.done) return;
  while (true) {
    const [files, , resp] = await bucket.getFiles({
      prefix: SRC_PREFIX,
      autoPaginate: false,
      maxResults: 1000,
      pageToken: state.storage.pageToken || undefined,
    });

    for (const f of files) {
      const src = f.name;
      if (!src || src.endsWith('/')) continue;
      const dst = DST_PREFIX + src.slice(SRC_PREFIX.length);
      try {
        const dstFile = bucket.file(dst);
        const [exists] = await dstFile.exists();
        if (exists) {
          state.storage.skipped += 1;
        } else {
          await f.copy(dstFile);
          state.storage.copied += 1;
        }
      } catch (e) {
        state.storage.failed += 1;
        state.errors[`st:${src}`] = String(e && e.message ? e.message : e);
      }
      if ((state.storage.copied + state.storage.skipped + state.storage.failed) % 500 === 0) saveState(state);
    }

    state.storage.pageToken = resp && resp.nextPageToken ? resp.nextPageToken : null;
    saveState(state);
    console.log('storage', {
      copied: state.storage.copied,
      skipped: state.storage.skipped,
      failed: state.storage.failed,
      nextPageToken: state.storage.pageToken,
    });

    if (!state.storage.pageToken) {
      state.storage.done = true;
      saveState(state);
      return;
    }
  }
}

async function main() {
  const cred = JSON.parse(fs.readFileSync(KEY, 'utf8'));
  const app = admin.initializeApp({ credential: admin.credential.cert(cred), storageBucket: BUCKET }, 'migrate-educators');
  const db = app.firestore();
  const bucket = app.storage().bucket(BUCKET);

  const state = loadState();
  saveState(state);

  await migrateFirestore(db, state);
  await migrateStorage(bucket, state);

  state.finishedAt = Date.now();
  saveState(state);
  console.log('DONE', state);
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
