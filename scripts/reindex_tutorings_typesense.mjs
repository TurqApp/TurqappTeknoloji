#!/usr/bin/env node
import fs from 'fs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const typesenseHost = String(process.env.TYPESENSE_HOST || '').trim();
const typesenseApiKey = String(process.env.TYPESENSE_API_KEY || '').trim();
const collection = 'education_tutoring_search';

if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
  throw new Error('GOOGLE_APPLICATION_CREDENTIALS missing');
}
if (!typesenseHost || !typesenseApiKey) {
  throw new Error('TYPESENSE_HOST or TYPESENSE_API_KEY missing');
}

const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

const headers = {
  'X-TYPESENSE-API-KEY': typesenseApiKey,
  'Content-Type': 'application/json',
};

const NOISY_DETAIL_KEYS = new Set([
  'authorAvatarUrl',
  'authorDisplayName',
  'authorNickname',
  'avatarUrl',
  'displayName',
  'nickname',
  'rozet',
  'updatedAt',
  'timeStamp',
  'userID',
  'viewCount',
  'applicationCount',
  'endedAt',
  'lat',
  'long',
]);

function asString(value) {
  return typeof value === 'string' ? value.trim() : String(value ?? '').trim();
}

function asStringArray(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((v) => String(v ?? '').trim()).filter(Boolean))];
}

function asBool(value) {
  return value === true;
}

function asInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const n = Number(value);
  return Number.isFinite(n) ? Math.trunc(n) : 0;
}

function asFloat(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function asEpochMillis(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value > 1e12 ? Math.trunc(value) : Math.trunc(value * 1000);
  }
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value && typeof value._seconds === 'number') return value._seconds * 1000;
  if (value && typeof value.seconds === 'number') return value.seconds * 1000;
  return 0;
}

function dedupe(values) {
  return [...new Set(values.map((v) => String(v ?? '').trim()).filter(Boolean))];
}

function truncateText(value, maxLen) {
  return value.length <= maxLen ? value : value.slice(0, maxLen);
}

function flattenForSearch(value, out, depth = 0) {
  if (depth > 4 || out.length >= 400 || value == null) return;
  if (typeof value === 'string') {
    const clean = value.trim();
    if (clean) out.push(clean);
    return;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    out.push(String(value));
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value.slice(0, 40)) flattenForSearch(item, out, depth + 1);
    return;
  }
  if (typeof value === 'object') {
    for (const [k, v] of Object.entries(value).slice(0, 120)) {
      if (NOISY_DETAIL_KEYS.has(String(k).trim())) continue;
      flattenForSearch(v, out, depth + 1);
    }
  }
}

function buildDetailsText(data) {
  const out = [];
  flattenForSearch(data, out);
  return truncateText(dedupe(out).join(' '), 24000);
}

async function httpJson(url, init = {}) {
  const response = await fetch(url, init);
  if (!response.ok) {
    const text = await response.text();
    const error = new Error(text || `${response.status} ${response.statusText}`);
    error.status = response.status;
    throw error;
  }
  const text = await response.text();
  return text ? JSON.parse(text) : {};
}

function requiredFields() {
  return [
    { name: 'docId', type: 'string', optional: true },
    { name: 'entity', type: 'string' },
    { name: 'title', type: 'string', optional: true },
    { name: 'subtitle', type: 'string', optional: true },
    { name: 'description', type: 'string', optional: true },
    { name: 'ownerId', type: 'string', optional: true },
    { name: 'timeStamp', type: 'int64', optional: false },
    { name: 'active', type: 'bool', optional: true },
    { name: 'city', type: 'string', optional: true },
    { name: 'town', type: 'string', optional: true },
    { name: 'country', type: 'string', optional: true },
    { name: 'tags', type: 'string[]', optional: true },
    { name: 'cover', type: 'string', optional: true },
    { name: 'nickname', type: 'string', optional: true },
    { name: 'displayName', type: 'string', optional: true },
    { name: 'avatarUrl', type: 'string', optional: true },
    { name: 'rozet', type: 'string', optional: true },
    { name: 'detailsText', type: 'string', optional: true },
    { name: 'aciklama', type: 'string', optional: true },
    { name: 'dersYeri', type: 'string[]', optional: true },
    { name: 'cinsiyet', type: 'string', optional: true },
    { name: 'fiyat', type: 'int32', optional: true },
    { name: 'telefon', type: 'bool', optional: true },
    { name: 'whatsapp', type: 'bool', optional: true },
    { name: 'ended', type: 'bool', optional: true },
    { name: 'endedAt', type: 'int64', optional: true },
    { name: 'viewCount', type: 'int32', optional: true },
    { name: 'applicationCount', type: 'int32', optional: true },
    { name: 'averageRating', type: 'float', optional: true },
    { name: 'reviewCount', type: 'int32', optional: true },
    { name: 'lat', type: 'float', optional: true },
    { name: 'long', type: 'float', optional: true },
  ];
}

function collectionSchema() {
  return {
    name: collection,
    fields: requiredFields(),
    default_sorting_field: 'timeStamp',
  };
}

function buildDisplayName(user) {
  const displayName = asString(user.displayName);
  if (displayName) return displayName;
  const fullName = asString(user.fullName);
  if (fullName) return fullName;
  const combined = [asString(user.firstName), asString(user.lastName)]
    .filter(Boolean)
    .join(' ')
    .trim();
  if (combined) return combined;
  return asString(user.nickname);
}

async function fetchUsersByIds(userIds) {
  const uniqueIds = [...new Set(userIds.map((id) => id.trim()).filter(Boolean))];
  if (uniqueIds.length === 0) return new Map();
  const refs = uniqueIds.map((id) => db.collection('users').doc(id));
  const snaps = await db.getAll(...refs);
  const out = new Map();
  snaps.forEach((snap) => {
    if (snap.exists) out.set(snap.id, snap.data() || {});
  });
  return out;
}

function buildTutoringDoc(docId, data, user = {}) {
  const nickname =
    asString(data.nickname) || asString(user.nickname) || asString(data.authorNickname);
  const displayName =
    asString(data.displayName) ||
    buildDisplayName(user) ||
    asString(data.authorDisplayName) ||
    nickname;
  const avatarUrl =
    asString(data.avatarUrl) ||
    asString(user.avatarUrl) ||
    asString(user.pfImage) ||
    asString(data.authorAvatarUrl);
  const rozet = asString(data.rozet) || asString(user.rozet);
  const imgs = asStringArray(data.imgs);
  const description = truncateText(
    dedupe([
      asString(data.aciklama),
      asString(data.detay),
      asString(data.ekAciklama),
      ...asStringArray(data.dersYeri),
      asString(data.cinsiyet),
    ]).join(' '),
    12000
  );
  return {
    id: docId,
    docId,
    entity: 'tutoring',
    title: asString(data.baslik),
    subtitle: asString(data.brans),
    description,
    ownerId: asString(data.userID) || asString(data.userId),
    timeStamp: asEpochMillis(data.timeStamp) || Date.now(),
    active: !asBool(data.ended),
    city: asString(data.sehir),
    town: asString(data.ilce),
    country: asString(data.country) || 'Türkiye',
    tags: dedupe([
      asString(data.brans),
      ...asStringArray(data.dersYeri),
      asString(data.cinsiyet),
      ...asStringArray(data.tags),
    ]),
    cover: imgs[0] || '',
    nickname,
    displayName,
    avatarUrl,
    rozet,
    detailsText: buildDetailsText(data),
    aciklama: asString(data.aciklama),
    dersYeri: asStringArray(data.dersYeri),
    cinsiyet: asString(data.cinsiyet),
    fiyat: asInt(data.fiyat),
    telefon: asBool(data.telefon),
    whatsapp: asBool(data.whatsapp),
    ended: asBool(data.ended),
    endedAt: asInt(data.endedAt),
    viewCount: asInt(data.viewCount),
    applicationCount: asInt(data.applicationCount),
    averageRating: asFloat(data.averageRating),
    reviewCount: asInt(data.reviewCount),
    lat: asFloat(data.lat),
    long: asFloat(data.long),
  };
}

async function ensureFreshCollection() {
  try {
    await httpJson(`${typesenseHost}/collections/${collection}`, {
      method: 'DELETE',
      headers,
    });
  } catch (err) {
    if (err.status !== 404) throw err;
  }
  await httpJson(`${typesenseHost}/collections`, {
    method: 'POST',
    headers,
    body: JSON.stringify(collectionSchema()),
  });
}

async function importDocuments(documents) {
  const payload = documents.map((doc) => JSON.stringify(doc)).join('\n');
  const response = await fetch(
    `${typesenseHost}/collections/${collection}/documents/import?action=upsert`,
    {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'text/plain',
      },
      body: payload,
    }
  );
  const text = await response.text();
  if (!response.ok) {
    throw new Error(text || `${response.status} ${response.statusText}`);
  }
  return text
    .split('\n')
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

async function run() {
  await ensureFreshCollection();

  const snapshot = await db.collection('educators').get();
  const docs = snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() || {} }));
  const usersById = await fetchUsersByIds(
    docs.map((entry) => asString(entry.data.userID)).filter(Boolean)
  );

  const documents = docs.map(({ id, data }) =>
    buildTutoringDoc(id, data, usersById.get(asString(data.userID)) || {})
  );
  const importResults = await importDocuments(documents);
  const failed = importResults.filter((row) => row.success === false);

  console.log(`collection=${collection}`);
  console.log(`scanned=${docs.length}`);
  console.log(`imported=${importResults.length - failed.length}`);
  console.log(`failed=${JSON.stringify(failed)}`);
}

run().catch((err) => {
  console.error('reindex_tutorings_typesense failed:', err);
  process.exit(1);
});
