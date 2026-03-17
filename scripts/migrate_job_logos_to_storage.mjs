#!/usr/bin/env node
import crypto from 'crypto';
import fs from 'fs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const bucketName =
  process.env.FIREBASE_STORAGE_BUCKET || 'turqappteknoloji.firebasestorage.app';

if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
  throw new Error('GOOGLE_APPLICATION_CREDENTIALS missing');
}

const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: bucketName,
  });
}

const db = admin.firestore();
const bucket = admin.storage().bucket(bucketName);
const isDryRun = process.argv.includes('--dry-run');

function asString(value) {
  return String(value ?? '').trim();
}

function isExternalUrl(value) {
  const url = asString(value);
  if (!url) return false;
  return /^https?:\/\//i.test(url) && !url.includes(bucketName);
}

function extFromContentType(contentType) {
  const normalized = asString(contentType).toLowerCase();
  if (normalized.includes('png')) return 'png';
  if (normalized.includes('webp')) return 'webp';
  if (normalized.includes('gif')) return 'gif';
  return 'jpg';
}

function buildDownloadUrl(objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(
    objectPath
  )}?alt=media&token=${token}`;
}

async function uploadRemoteToStorage({ sourceUrl, userId, jobId }) {
  const response = await fetch(sourceUrl);
  if (!response.ok) {
    throw new Error(`download failed ${response.status} ${response.statusText}`);
  }
  const contentType = response.headers.get('content-type') || 'image/jpeg';
  const bytes = Buffer.from(await response.arrayBuffer());
  const ext = extFromContentType(contentType);
  const token = crypto.randomUUID();
  const objectPath = `users/${userId}/isBul/${jobId}/logo_migrated.${ext}`;
  const file = bucket.file(objectPath);

  await file.save(bytes, {
    resumable: false,
    metadata: {
      contentType,
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  });

  return buildDownloadUrl(objectPath, token);
}

async function run() {
  const snap = await db.collection('isBul').get();
  let scanned = 0;
  let migrated = 0;
  let skipped = 0;
  const failed = [];

  for (const doc of snap.docs) {
    scanned += 1;
    const data = doc.data() || {};
    const sourceUrl = asString(data.logo);
    const userId = asString(data.userID);

    if (!sourceUrl || !userId || !isExternalUrl(sourceUrl)) {
      skipped += 1;
      continue;
    }

    try {
      const storageUrl = await uploadRemoteToStorage({
        sourceUrl,
        userId,
        jobId: doc.id,
      });

      if (!isDryRun) {
        await doc.ref.set(
          {
            logo: storageUrl,
            updatedAt: Date.now(),
          },
          { merge: true }
        );
      }

      migrated += 1;
      console.log(`[migrate_job_logos] ${doc.id} -> storage`);
    } catch (error) {
      failed.push({
        docId: doc.id,
        logo: sourceUrl,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  console.log(
    JSON.stringify(
      {
        bucket: bucketName,
        scanned,
        migrated,
        skipped,
        failed,
      },
      null,
      2
    )
  );
}

run().catch((error) => {
  console.error('migrate_job_logos_to_storage failed:', error);
  process.exit(1);
});
