#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');
const http = require('http');

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function loadServiceAccount(keyPath) {
  if (!keyPath || !fs.existsSync(keyPath)) {
    throw new Error(`Service account bulunamadi: ${keyPath}`);
  }
  return JSON.parse(fs.readFileSync(keyPath, 'utf8'));
}

function downloadToFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http;
    const req = mod.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(downloadToFile(res.headers.location, destPath));
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} (${url})`));
      }
      const ws = fs.createWriteStream(destPath);
      res.pipe(ws);
      ws.on('finish', () => ws.close(() => resolve(destPath)));
      ws.on('error', reject);
    });
    req.on('error', reject);
  });
}

function pickExt(url) {
  const clean = url.split('?')[0];
  const ext = path.extname(clean).toLowerCase();
  if (ext && ext.length <= 5) return ext;
  return '.jpg';
}

async function run() {
  const targetKey = arg('target-key');
  const usersCollection = arg('users-collection', 'users');
  const sourceBucketHint = arg('source-bucket-hint', 'burs-city.appspot.com');
  const targetBucket = arg('target-bucket');
  const apply = hasFlag('apply');
  const limit = Number(arg('limit', '0')); // 0 = hepsi

  if (!targetKey) {
    throw new Error(
      'Kullanim: node migrate_pfimage_urls_to_target_bucket.js --target-key /path/target.json [--source-bucket-hint burs-city.appspot.com] [--apply]'
    );
  }

  const targetApp = admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount(targetKey)),
  });
  const db = targetApp.firestore();
  const bucket = targetBucket
    ? targetApp.storage().bucket(targetBucket)
    : targetApp.storage().bucket();

  console.log(`Koleksiyon       : ${usersCollection}`);
  console.log(`Hedef bucket     : ${bucket.name}`);
  console.log(`Filtre hint      : ${sourceBucketHint}`);
  console.log(`Mod              : ${apply ? 'APPLY' : 'DRY-RUN'}`);

  const usersSnap = await db.collection(usersCollection).get();
  const docs = limit > 0 ? usersSnap.docs.slice(0, limit) : usersSnap.docs;
  console.log(`Taranan user     : ${docs.length}`);

  let candidates = 0;
  let migrated = 0;
  let failed = 0;

  for (const doc of docs) {
    const data = doc.data() || {};
    const pfImage = (data.pfImage || '').toString().trim();
    if (!pfImage) continue;

    if (sourceBucketHint && !pfImage.includes(sourceBucketHint)) continue;

    candidates += 1;
    const ext = pickExt(pfImage);
    const objectPath = `users/${doc.id}/pfImage${ext}`;
    const tmpPath = path.join(os.tmpdir(), `pf_${doc.id}_${Date.now()}${ext}`);

    try {
      if (!apply) {
        console.log(`[DRY] ${doc.id} -> ${objectPath}`);
        continue;
      }

      await downloadToFile(pfImage, tmpPath);
      await bucket.upload(tmpPath, {
        destination: objectPath,
        metadata: { cacheControl: 'public, max-age=3600' },
      });

      const [newUrl] = await bucket
        .file(objectPath)
        .getSignedUrl({ action: 'read', expires: '2500-01-01' });

      await doc.ref.set({ pfImage: newUrl }, { merge: true });

      try {
        fs.unlinkSync(tmpPath);
      } catch (_) {}
      migrated += 1;
      console.log(`[OK ] ${doc.id}`);
    } catch (e) {
      failed += 1;
      console.log(`[ERR] ${doc.id} -> ${e.message}`);
      try {
        if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
      } catch (_) {}
    }
  }

  console.log(`Aday             : ${candidates}`);
  console.log(`Tasindi          : ${migrated}`);
  console.log(`Hata             : ${failed}`);
  console.log('Bitti.');

  await targetApp.delete();
}

run().catch((e) => {
  console.error('HATA:', e.message);
  process.exit(1);
});
