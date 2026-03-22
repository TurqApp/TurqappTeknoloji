#!/usr/bin/env node
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const docId = String(process.argv[2] || '').trim();
if (!docId) {
  throw new Error('docId missing');
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

const ref = db
  .collection('catalog')
  .doc('education')
  .collection('scholarships')
  .doc(docId);

const snap = await ref.get();
if (!snap.exists) {
  console.log(JSON.stringify({ exists: false, docId }));
  process.exit(0);
}

const data = snap.data() || {};
console.log(
  JSON.stringify(
    {
      exists: true,
      docId,
      nickname: data.nickname ?? null,
      displayName: data.displayName ?? null,
      avatarUrl: data.avatarUrl ?? null,
      rozet: data.rozet ?? null,
      authorNickname: data.authorNickname ?? null,
      authorDisplayName: data.authorDisplayName ?? null,
      authorAvatarUrl: data.authorAvatarUrl ?? null,
    },
    null,
    2,
  ),
);
