#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require('firebase-admin');
const fs = require('fs');

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function loadServiceAccount(path) {
  if (!path || !fs.existsSync(path)) {
    throw new Error(`Service account bulunamadi: ${path}`);
  }
  return JSON.parse(fs.readFileSync(path, 'utf8'));
}

function normalizeDoc(data) {
  const out = { ...data };

  if (!out.firstName && out.ad) out.firstName = out.ad;
  if (!out.lastName && out.soyad) out.lastName = out.soyad;
  if (!out.nickname && out.kullaniciAdi) out.nickname = out.kullaniciAdi;
  if (!out.avatarUrl && out.profilResmi) out.avatarUrl = out.profilResmi;

  if (!Object.prototype.hasOwnProperty.call(out, 'gizliHesap')) {
    out.gizliHesap = false;
  }
  if (!Object.prototype.hasOwnProperty.call(out, 'rozet')) {
    out.rozet = '';
  }
  if (!Object.prototype.hasOwnProperty.call(out, 'createdDate')) {
    out.createdDate = Date.now();
  }

  return out;
}

async function run() {
  const sourceKey = arg('source-key');
  const targetKey = arg('target-key');
  const sourceCollection = arg('source-collection', 'Ogrenciler');
  const targetCollection = arg('target-collection', 'users');
  const batchSize = Number(arg('batch-size', '400'));
  const apply = hasFlag('apply');

  if (!sourceKey || !targetKey) {
    throw new Error(
      'Kullanim: node migrate_ogrenciler_to_users.js --source-key /path/source.json --target-key /path/target.json [--apply]'
    );
  }

  const sourceApp = admin.initializeApp(
    { credential: admin.credential.cert(loadServiceAccount(sourceKey)) },
    'source-app'
  );
  const targetApp = admin.initializeApp(
    { credential: admin.credential.cert(loadServiceAccount(targetKey)) },
    'target-app'
  );

  const sourceDb = sourceApp.firestore();
  const targetDb = targetApp.firestore();

  console.log(`Kaynak koleksiyon: ${sourceCollection}`);
  console.log(`Hedef koleksiyon : ${targetCollection}`);
  console.log(`Mod             : ${apply ? 'APPLY' : 'DRY-RUN'}`);

  const snap = await sourceDb.collection(sourceCollection).get();
  console.log(`Toplam dokuman  : ${snap.size}`);

  let migrated = 0;
  let skipped = 0;
  let batch = targetDb.batch();
  let batchOps = 0;

  for (const doc of snap.docs) {
    const source = doc.data() || {};
    const targetData = normalizeDoc(source);

    if (apply) {
      const ref = targetDb.collection(targetCollection).doc(doc.id);
      batch.set(ref, targetData, { merge: true });
      batchOps += 1;
      if (batchOps >= batchSize) {
        await batch.commit();
        batch = targetDb.batch();
        batchOps = 0;
      }
    }

    if (Object.keys(targetData).length === 0) {
      skipped += 1;
    } else {
      migrated += 1;
    }
  }

  if (apply && batchOps > 0) {
    await batch.commit();
  }

  console.log(`Hazirlanan      : ${migrated}`);
  console.log(`Atlanan         : ${skipped}`);
  console.log('Bitti.');

  await sourceApp.delete();
  await targetApp.delete();
}

run().catch((e) => {
  console.error('HATA:', e.message);
  process.exit(1);
});

