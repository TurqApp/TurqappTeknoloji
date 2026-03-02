#!/usr/bin/env node
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
// Resolve firebase-admin from functions/ node_modules to avoid root install.
const admin = require('../functions/node_modules/firebase-admin');

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const limitArg = args.find((a) => a.startsWith('--limit='));
const startAfterArg = args.find((a) => a.startsWith('--start-after='));
const limit = limitArg ? Number(limitArg.split('=')[1]) : null;
const startAfterId = startAfterArg ? startAfterArg.split('=')[1] : null;

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();
const sourceCol = db.collection('scholarships');
const listCol = db.collection('scholarships_list');
const detailsCol = db.collection('scholarships_details');
const BATCH_SIZE = 400; // Firestore batch write limit is 500

function makeShortDescription(raw, maxLength = 180) {
  const text = String(raw ?? '').trim();
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength).trimEnd()}…`;
}

function buildSummary(data) {
  const shortDescRaw = data.shortDescription || data.kisaAciklama || data.ozet || '';
  const summaryText = makeShortDescription(shortDescRaw || data.aciklama || '');
  return {
    baslik: data.baslik ?? '',
    aciklama: summaryText,
    shortDescription: summaryText,
    bursVeren: data.bursVeren ?? '',
    baslangicTarihi: data.baslangicTarihi ?? '',
    bitisTarihi: data.bitisTarihi ?? '',
    tutar: data.tutar ?? '',
    website: data.website ?? '',
    egitimKitlesi: data.egitimKitlesi ?? '',
    altEgitimKitlesi: Array.isArray(data.altEgitimKitlesi)
      ? data.altEgitimKitlesi
      : [],
    hedefKitle: data.hedefKitle ?? '',
    sehirler: Array.isArray(data.sehirler) ? data.sehirler : [],
    ilceler: Array.isArray(data.ilceler) ? data.ilceler : [],
    universiteler: Array.isArray(data.universiteler) ? data.universiteler : [],
    img: data.img ?? '',
    img2: data.img2 ?? '',
    timeStamp: data.timeStamp ?? 0,
    userID: data.userID ?? '',
    lisansTuru: data.lisansTuru ?? '',
    ulke: data.ulke ?? '',
    likesCount: Number(data.likesCount) || (Array.isArray(data.begeniler) ? data.begeniler.length : 0),
    bookmarksCount: Number(data.bookmarksCount) || (Array.isArray(data.kaydedenler) ? data.kaydedenler.length : 0),
  };
}

async function run() {
  let total = 0;
  let lastDoc = null;

  if (startAfterId) {
    const startDoc = await sourceCol.doc(startAfterId).get();
    if (!startDoc.exists) {
      throw new Error(`start-after doc not found: ${startAfterId}`);
    }
    lastDoc = startDoc;
  }

  while (true) {
    let query = sourceCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    if (isDryRun) {
      total += snap.size;
    } else {
      const batch = db.batch();
      snap.docs.forEach((doc) => {
        const data = doc.data();
        const summary = buildSummary(data);
        batch.set(detailsCol.doc(doc.id), data, { merge: true });
        batch.set(listCol.doc(doc.id), summary, { merge: true });
      });
      await batch.commit();
      total += snap.size;
    }

    lastDoc = snap.docs[snap.docs.length - 1];

    if (limit && total >= limit) break;
  }

  console.log(
    isDryRun
      ? `Dry run complete. Would process ${total} documents.`
      : `Migration complete. Processed ${total} documents.`
  );
}

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
