#!/usr/bin/env node
/* eslint-disable no-console */
const { randomUUID } = require('crypto');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const bucket = admin.storage().bucket();
const CDN_DOMAIN = 'cdn.turqapp.com';
const POSTS_COLLECTION = 'Posts';

function asString(value) {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

function buildTokenizedCdnUrl(bucketName, storagePath, token) {
  return `https://${CDN_DOMAIN}/v0/b/${bucketName}/o/${encodeURIComponent(
    storagePath,
  )}?alt=media&token=${encodeURIComponent(token)}`;
}

function extractDownloadToken(metadata) {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return '';
  }
  const raw = asString(metadata.firebaseStorageDownloadTokens);
  if (!raw) return '';
  return raw
    .split(',')
    .map((item) => item.trim())
    .find(Boolean) || '';
}

async function buildProtectedAssetUrl(storagePath) {
  const file = bucket.file(storagePath);
  const [metadata] = await file.getMetadata();
  let token = extractDownloadToken(metadata.metadata);
  if (!token) {
    token = randomUUID();
    await file.setMetadata({
      metadata: {
        ...(metadata.metadata || {}),
        firebaseStorageDownloadTokens: token,
      },
    });
  }
  return buildTokenizedCdnUrl(bucket.name, storagePath, token);
}

function extractStoragePath(url) {
  const text = asString(url);
  if (!text.startsWith(`https://${CDN_DOMAIN}/Posts/`)) return '';
  if (text.includes('?token=')) return '';
  return text.replace(`https://${CDN_DOMAIN}/`, '');
}

async function run() {
  const snap = await db
    .collection(POSTS_COLLECTION)
    .where('hlsStatus', '==', 'ready')
    .get();

  let repaired = 0;
  let batch = db.batch();
  let opCount = 0;

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const storagePath = extractStoragePath(data.thumbnail);
    if (!storagePath) continue;

    const tokenizedUrl = await buildProtectedAssetUrl(storagePath);
    if (tokenizedUrl === asString(data.thumbnail)) continue;

    batch.set(doc.ref, { thumbnail: tokenizedUrl }, { merge: true });
    repaired += 1;
    opCount += 1;

    if (opCount >= 350) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  console.log(JSON.stringify({ repaired }, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
