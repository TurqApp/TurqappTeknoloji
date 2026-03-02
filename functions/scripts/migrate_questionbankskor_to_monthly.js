const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const KEY_PATH =
  process.env.FIREBASE_ADMIN_KEY ||
  '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

const ROOT_COLLECTION = 'questionBankSkor';
const BATCH_SIZE = Number(process.env.MIGRATE_BATCH || 250);
const DELETE_OLD = process.env.DELETE_OLD === '1';
const STATE_FILE = path.join(
  __dirname,
  'migrate_questionbankskor_to_monthly.state.json',
);

function loadState(defaultMonthKey) {
  if (!fs.existsSync(STATE_FILE)) {
    return {
      monthKey: defaultMonthKey,
      lastDocId: null,
      processed: 0,
      migrated: 0,
      skipped: 0,
      deleted: 0,
      failed: {},
      startedAt: Date.now(),
    };
  }
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function resolveMonthKey() {
  const now = new Date();
  const month = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${now.getUTCFullYear()}-${month}`;
}

function isMonthDocId(docId) {
  return /^\d{4}-\d{2}$/.test(String(docId || ''));
}

async function main() {
  const cred = JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'));
  const app = admin.initializeApp(
    {
      credential: admin.credential.cert(cred),
      storageBucket: 'turqappteknoloji.firebasestorage.app',
    },
    'questionbankskor-monthly-migration',
  );
  const db = app.firestore();
  const monthKey = resolveMonthKey();
  const state = loadState(monthKey);

  if (state.monthKey !== monthKey) {
    state.monthKey = monthKey;
    state.lastDocId = null;
  }

  console.log('migration:start', {
    monthKey: state.monthKey,
    deleteOld: DELETE_OLD,
    resumeFrom: state.lastDocId,
  });

  while (true) {
    let query = db
      .collection(ROOT_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (state.lastDocId) {
      query = query.startAfter(state.lastDocId);
    }

    const snap = await query.get();
    if (snap.empty) break;

    let batch = db.batch();
    let pendingWrites = 0;

    for (const doc of snap.docs) {
      state.lastDocId = doc.id;
      state.processed += 1;

      try {
        if (isMonthDocId(doc.id)) {
          state.skipped += 1;
          continue;
        }

        const data = doc.data() || {};
        const targetRef = db
          .collection(ROOT_COLLECTION)
          .doc(state.monthKey)
          .collection('items')
          .doc(doc.id);

        batch.set(
          targetRef,
          {
            ...data,
            userID: doc.id,
            migratedFromLegacyAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        pendingWrites += 1;
        state.migrated += 1;

        if (DELETE_OLD) {
          batch.delete(doc.ref);
          pendingWrites += 1;
          state.deleted += 1;
        }

        if (pendingWrites >= 400) {
          await batch.commit();
          batch = db.batch();
          pendingWrites = 0;
        }
      } catch (e) {
        state.failed[doc.id] = String(e && e.message ? e.message : e);
      } finally {
        if (state.processed % 100 === 0) {
          console.log('migration:progress', {
            processed: state.processed,
            migrated: state.migrated,
            skipped: state.skipped,
            deleted: state.deleted,
            failed: Object.keys(state.failed).length,
            lastDocId: state.lastDocId,
          });
          saveState(state);
        }
      }
    }

    if (pendingWrites > 0) {
      await batch.commit();
    }

    saveState(state);
  }

  saveState(state);
  console.log('migration:done', {
    monthKey: state.monthKey,
    processed: state.processed,
    migrated: state.migrated,
    skipped: state.skipped,
    deleted: state.deleted,
    failed: Object.keys(state.failed).length,
    lastDocId: state.lastDocId,
  });
}

main().catch((e) => {
  console.error('migration:fatal', e);
  process.exit(1);
});
