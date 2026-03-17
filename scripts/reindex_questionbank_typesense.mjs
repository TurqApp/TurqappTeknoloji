#!/usr/bin/env node
import fs from 'fs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const typesenseHost = String(process.env.TYPESENSE_HOST || '').trim();
const typesenseApiKey = String(process.env.TYPESENSE_API_KEY || '').trim();
const collection = 'education_workouts_search';

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
  'dogruCevap',
  'diger1',
  'diger2',
  'diger3',
  'kacCevap',
  'begeniler',
  'paylasanlar',
  'goruntuleme',
  'soruCoz',
  'dogruCevapVerenler',
  'yanlisCevapVerenler',
  'viewers',
  'savedBy',
  'correctUsers',
  'wrongUsers',
  'updatedAt',
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

function pruneForSearch(value, depth = 0) {
  if (value == null || depth > 4) return undefined;
  if (typeof value === 'string') {
    const text = value.trim();
    if (!text) return undefined;
    if (/^https?:\/\//i.test(text)) return undefined;
    return truncateText(text, 500);
  }
  if (typeof value === 'number' || typeof value === 'boolean') return value;
  if (Array.isArray(value)) {
    const items = value
      .slice(0, 20)
      .map((item) => pruneForSearch(item, depth + 1))
      .filter((item) => item !== undefined);
    return items.length ? items : undefined;
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [key, raw] of Object.entries(value).slice(0, 120)) {
      const cleanKey = String(key).trim();
      if (!cleanKey || NOISY_DETAIL_KEYS.has(cleanKey)) continue;
      const clean = pruneForSearch(raw, depth + 1);
      if (clean !== undefined) out[cleanKey] = clean;
    }
    return Object.keys(out).length ? out : undefined;
  }
  return undefined;
}

function flattenForSearch(value, out, depth = 0) {
  if (value == null || depth > 4 || out.length >= 600) return;
  if (typeof value === 'string') {
    const text = value.trim();
    if (text) out.push(text);
    return;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    out.push(String(value));
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value.slice(0, 30)) {
      flattenForSearch(item, out, depth + 1);
    }
    return;
  }
  if (typeof value === 'object') {
    for (const [key, raw] of Object.entries(value).slice(0, 120)) {
      const cleanKey = String(key).trim();
      if (!cleanKey || NOISY_DETAIL_KEYS.has(cleanKey)) continue;
      out.push(cleanKey);
      flattenForSearch(raw, out, depth + 1);
    }
  }
}

function buildDetailsText(data) {
  const out = [];
  flattenForSearch(pruneForSearch(data), out);
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
    { name: 'tags', type: 'string[]', optional: true },
    { name: 'cover', type: 'string', optional: true },
    { name: 'detailsText', type: 'string', optional: true },
    { name: 'categoryKey', type: 'string', optional: true },
    { name: 'anaBaslik', type: 'string', optional: true },
    { name: 'ders', type: 'string', optional: true },
    { name: 'sinavTuru', type: 'string', optional: true },
    { name: 'soruNo', type: 'string', optional: true },
    { name: 'yil', type: 'string', optional: true },
    { name: 'seq', type: 'int32', optional: true },
    { name: 'viewCount', type: 'int32', optional: true },
    { name: 'correctCount', type: 'int32', optional: true },
    { name: 'wrongCount', type: 'int32', optional: true },
    { name: 'soru', type: 'string', optional: true },
    { name: 'dogruCevap', type: 'string', optional: true },
    { name: 'kacCevap', type: 'int32', optional: true },
    { name: 'diger1', type: 'string', optional: true },
    { name: 'diger2', type: 'bool', optional: true },
    { name: 'diger3', type: 'float', optional: true },
  ];
}

function collectionSchema() {
  return {
    name: collection,
    fields: requiredFields(),
    default_sorting_field: 'timeStamp',
  };
}

function buildQuestionDoc(docId, data) {
  const anaBaslik = asString(data.anaBaslik);
  const sinavTuru = asString(data.sinavTuru);
  const ders = asString(data.ders);
  const soruNo = asString(data.soruNo);
  const yil = asString(data.yil);
  return {
    id: docId,
    docId,
    entity: 'workout',
    title: [anaBaslik, sinavTuru, ders].filter(Boolean).join(' - '),
    subtitle: [ders, sinavTuru, soruNo ? `Soru ${soruNo}` : '', yil].filter(Boolean).join(' • '),
    description: [anaBaslik, sinavTuru, ders, soruNo ? `Soru ${soruNo}` : '', yil].filter(Boolean).join(' '),
    ownerId: asString(data.userID) || asString(data.ownerId),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate) || Date.now(),
    active: (data.active === false || asBool(data.iptal) || asBool(data.deleted)) ? false : true,
    tags: dedupe([anaBaslik, sinavTuru, ders, yil, ...asStringArray(data.tags)]),
    cover: asString(data.soru) || asString(data.cover) || asString(data.img),
    detailsText: buildDetailsText(data),
    categoryKey: asString(data.categoryKey),
    anaBaslik,
    ders,
    sinavTuru,
    soruNo,
    yil,
    seq: asInt(data.seq),
    viewCount: asInt(data.viewCount),
    correctCount: asInt(data.correctCount),
    wrongCount: asInt(data.wrongCount),
    soru: asString(data.soru),
    dogruCevap: asString(data.dogruCevap),
    kacCevap: asInt(data.kacCevap),
    diger1: asString(data.diger1),
    diger2: asBool(data.diger2),
    diger3: asFloat(data.diger3),
  };
}

async function ensureCollection() {
  const baseUrl = typesenseHost.replace(/\/+$/, '');
  try {
    await httpJson(`${baseUrl}/collections/${collection}`, {
      headers,
    });
  } catch (error) {
    if (error.status !== 404) throw error;
    await httpJson(`${baseUrl}/collections`, {
      method: 'POST',
      headers,
      body: JSON.stringify(collectionSchema()),
    });
  }
}

async function recreateCollection() {
  const baseUrl = typesenseHost.replace(/\/+$/, '');
  try {
    await fetch(`${baseUrl}/collections/${collection}`, {
      method: 'DELETE',
      headers,
    });
  } catch (_) {}
  await httpJson(`${baseUrl}/collections`, {
    method: 'POST',
    headers,
    body: JSON.stringify(collectionSchema()),
  });
}

async function main() {
  await ensureCollection();
  await recreateCollection();

  const snap = await db.collection('questionBank').get();
  const docs = snap.docs.map((doc) => buildQuestionDoc(doc.id, doc.data() || {}));
  const importBody = docs.map((doc) => JSON.stringify(doc)).join('\n');
  const baseUrl = typesenseHost.replace(/\/+$/, '');
  const response = await fetch(
    `${baseUrl}/collections/${collection}/documents/import?action=upsert`,
    {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'text/plain',
      },
      body: importBody,
    }
  );
  if (!response.ok) {
    throw new Error(await response.text());
  }
  const text = await response.text();
  const lines = text
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => JSON.parse(line));
  const failed = lines.filter((line) => line.success === false);
  console.log(
    JSON.stringify(
      {
        collection,
        scanned: docs.length,
        imported: docs.length - failed.length,
        failed,
      },
      null,
      2
    )
  );
}

main().catch((err) => {
  console.error('reindex_questionbank_typesense failed:', err);
  process.exit(1);
});
