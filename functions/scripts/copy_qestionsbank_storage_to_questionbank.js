const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const DST_KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';
const BUCKET = 'turqappteknoloji.firebasestorage.app';
const FROM_PREFIX = 'qestionsBank/';
const TO_PREFIX = 'questionBank/';
const STATE_FILE = path.join(__dirname, 'copy_qestionsbank_storage_to_questionbank.state.json');

function loadState() {
  if (!fs.existsSync(STATE_FILE)) {
    return { pageToken: null, copied: 0, skipped: 0, failed: 0, done: false, startedAt: Date.now(), errors: {} };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(s) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(s, null, 2));
}

async function main() {
  const cred = JSON.parse(fs.readFileSync(DST_KEY, 'utf8'));
  const app = admin.initializeApp({ credential: admin.credential.cert(cred), storageBucket: BUCKET }, 'storage-copy');
  const bucket = app.storage().bucket(BUCKET);

  const state = loadState();
  if (state.done) {
    console.log('already_done', state);
    return;
  }

  while (true) {
    const [files, , resp] = await bucket.getFiles({
      prefix: FROM_PREFIX,
      autoPaginate: false,
      maxResults: 1000,
      pageToken: state.pageToken || undefined,
    });

    for (const file of files) {
      const src = file.name;
      if (!src || src.endsWith('/')) continue;
      const dst = TO_PREFIX + src.slice(FROM_PREFIX.length);
      try {
        const dstFile = bucket.file(dst);
        const [exists] = await dstFile.exists();
        if (exists) {
          state.skipped += 1;
        } else {
          await file.copy(dstFile);
          state.copied += 1;
        }
      } catch (e) {
        state.failed += 1;
        state.errors[src] = String(e && e.message ? e.message : e);
      }

      if ((state.copied + state.skipped + state.failed) % 500 === 0) {
        saveState(state);
        console.log('progress', { copied: state.copied, skipped: state.skipped, failed: state.failed, pageToken: state.pageToken });
      }
    }

    state.pageToken = resp && resp.nextPageToken ? resp.nextPageToken : null;
    saveState(state);

    if (!state.pageToken) {
      state.done = true;
      state.finishedAt = Date.now();
      saveState(state);
      console.log('DONE', { copied: state.copied, skipped: state.skipped, failed: state.failed });
      break;
    }
  }
}

main().catch((e) => {
  console.error('fatal', e);
  process.exit(1);
});
