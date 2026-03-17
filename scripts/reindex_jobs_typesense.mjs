#!/usr/bin/env node
import fs from 'fs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const typesenseHost = String(process.env.TYPESENSE_HOST || '').trim();
const typesenseApiKey = String(process.env.TYPESENSE_API_KEY || '').trim();
const collection = 'education_jobs_search';

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
  'logo',
  'cover',
  'updatedAt',
  'timeStamp',
  'userID',
  'viewCount',
  'applicationCount',
  'endedAt',
  'lat',
  'long',
]);

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

function asDouble(value) {
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
      if (k.trim()) out.push(k.trim());
      flattenForSearch(v, out, depth + 1);
    }
  }
}

function buildDetailsText(data) {
  const out = [];
  flattenForSearch(data, out);
  return truncateText(dedupe(out).join(' '), 24000);
}

function safeStringify(value) {
  try {
    return truncateText(JSON.stringify(value) || '', 32000);
  } catch {
    return '';
  }
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
    { name: 'brand', type: 'string', optional: true },
    { name: 'yanHaklar', type: 'string[]', optional: true },
    { name: 'calismaGunleri', type: 'string[]', optional: true },
    { name: 'calismaSaatiBaslangic', type: 'string', optional: true },
    { name: 'calismaSaatiBitis', type: 'string', optional: true },
    { name: 'calismaTuru', type: 'string[]', optional: true },
    { name: 'ended', type: 'bool', optional: true },
    { name: 'isTanimi', type: 'string', optional: true },
    { name: 'lat', type: 'float', optional: true },
    { name: 'long', type: 'float', optional: true },
    { name: 'adres', type: 'string', optional: true },
    { name: 'maas1', type: 'int32', optional: true },
    { name: 'maas2', type: 'int32', optional: true },
    { name: 'meslek', type: 'string', optional: true },
    { name: 'ilanBasligi', type: 'string', optional: true },
    { name: 'deneyimSeviyesi', type: 'string', optional: true },
    { name: 'pozisyonSayisi', type: 'int32', optional: true },
    { name: 'viewCount', type: 'int32', optional: true },
    { name: 'applicationCount', type: 'int32', optional: true },
    { name: 'endedAt', type: 'int64', optional: true },
    { name: 'about', type: 'string', optional: true },
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

function buildJobDoc(docId, data, user = {}) {
  const nickname = asString(data.nickname) || asString(user.nickname);
  const displayName =
    asString(data.displayName) || buildDisplayName(user) || nickname;
  const avatarUrl =
    asString(data.avatarUrl) || asString(user.avatarUrl) || asString(user.pfImage);
  const rozet = asString(data.rozet) || asString(user.rozet);
  const imgs = asStringArray(data.imgs);
  const title = asString(data.ilanBasligi) || asString(data.meslek) || asString(data.brand);
  const description = truncateText(
    dedupe([
      asString(data.isTanimi),
      asString(data.ilanDetayi),
      asString(data.aciklama),
      asString(data.arananNitelikler),
      ...asStringArray(data.yanHaklar),
      ...asStringArray(data.calismaTuru),
    ]).join(' '),
    12000
  );
  const raw = {
    id: docId,
    docId,
    entity: 'job',
    title,
    subtitle: asString(data.brand),
    description,
    ownerId: asString(data.userID),
    timeStamp: asEpochMillis(data.timeStamp) || Date.now(),
    active: !asBool(data.ended),
    city: asString(data.city),
    town: asString(data.town),
    country: asString(data.country) || 'Türkiye',
    tags: dedupe([
      asString(data.meslek),
      asString(data.deneyimSeviyesi),
      ...asStringArray(data.calismaGunleri),
      ...asStringArray(data.calismaTuru),
      ...asStringArray(data.yanHaklar),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.logo) || imgs[0] || '',
    nickname,
    displayName,
    avatarUrl,
    rozet,
    detailsText: buildDetailsText(data),
    brand: asString(data.brand),
    yanHaklar: asStringArray(data.yanHaklar),
    calismaGunleri: asStringArray(data.calismaGunleri),
    calismaSaatiBaslangic: asString(data.calismaSaatiBaslangic),
    calismaSaatiBitis: asString(data.calismaSaatiBitis),
    calismaTuru: asStringArray(data.calismaTuru),
    ended: asBool(data.ended),
    isTanimi: asString(data.isTanimi),
    lat: asDouble(data.lat),
    long: asDouble(data.long),
    adres: asString(data.adres),
    maas1: asInt(data.maas1),
    maas2: asInt(data.maas2),
    meslek: asString(data.meslek),
    ilanBasligi: asString(data.ilanBasligi),
    deneyimSeviyesi: asString(data.deneyimSeviyesi),
    pozisyonSayisi: asInt(data.pozisyonSayisi) || 1,
    viewCount: asInt(data.viewCount),
    applicationCount: asInt(data.applicationCount),
    endedAt: asInt(data.endedAt),
    about: asString(data.about),
  };
  return raw;
}

async function recreateCollection() {
  try {
    await httpJson(`${typesenseHost}/collections/${collection}`, {
      method: 'DELETE',
      headers,
    });
    console.log(`[typesense] deleted ${collection}`);
  } catch (error) {
    if (error.status !== 404) throw error;
  }

  await httpJson(`${typesenseHost}/collections`, {
    method: 'POST',
    headers,
    body: JSON.stringify(collectionSchema()),
  });
  console.log(`[typesense] created ${collection}`);
}

async function importDocs(docs) {
  const payload = docs.map((doc) => JSON.stringify(doc)).join('\n');
  const response = await fetch(
    `${typesenseHost}/collections/${collection}/documents/import?action=upsert`,
    {
      method: 'POST',
      headers: {
        'X-TYPESENSE-API-KEY': typesenseApiKey,
        'Content-Type': 'text/plain',
      },
      body: payload,
    }
  );
  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `typesense import failed: ${response.status}`);
  }
  const text = await response.text();
  return text
    .split('\n')
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

async function run() {
  const snap = await db.collection('isBul').orderBy(admin.firestore.FieldPath.documentId()).get();
  const userIds = snap.docs.map((doc) => asString(doc.data().userID)).filter(Boolean);
  const usersById = await fetchUsersByIds(userIds);
  const docs = snap.docs.map((doc) => buildJobDoc(doc.id, doc.data() || {}, usersById.get(asString(doc.data().userID)) || {}));

  await recreateCollection();
  const importResults = await importDocs(docs);
  const successCount = importResults.filter((item) => item.success).length;
  const failed = importResults.filter((item) => item.success === false);
  console.log(JSON.stringify({
    collection,
    scanned: snap.size,
    imported: successCount,
    failed,
  }, null, 2));
}

run().catch((err) => {
  console.error('reindex_jobs_typesense failed:', err);
  process.exit(1);
});
