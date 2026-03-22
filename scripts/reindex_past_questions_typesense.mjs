#!/usr/bin/env node
import fs from 'fs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const typesenseHost = String(process.env.TYPESENSE_HOST || '').trim();
const typesenseApiKey = String(process.env.TYPESENSE_API_KEY || '').trim();
const collection = 'education_past_questions_search';

if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
  throw new Error('GOOGLE_APPLICATION_CREDENTIALS missing');
}
if (!typesenseHost || !typesenseApiKey) {
  throw new Error('TYPESENSE_HOST or TYPESENSE_API_KEY missing');
}

const headers = {
  'X-TYPESENSE-API-KEY': typesenseApiKey,
  'Content-Type': 'application/json',
};

function asString(value) {
  return typeof value === 'string' ? value.trim() : String(value ?? '').trim();
}

function asBool(value) {
  return value === true;
}

function asInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
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

async function httpJson(url, init = {}) {
  const response = await fetch(url, init);
  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `${response.status} ${response.statusText}`);
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
    { name: 'anaBaslik', type: 'string', optional: true },
    { name: 'baslik2', type: 'string', optional: true },
    { name: 'baslik3', type: 'string', optional: true },
    { name: 'dil', type: 'string', optional: true },
    { name: 'sinavTuru', type: 'string', optional: true },
    { name: 'yil', type: 'string', optional: true },
    { name: 'seq', type: 'int32', optional: true },
  ];
}

function buildDetailsText(data) {
  return dedupe([
    asString(data.anaBaslik),
    asString(data.sinavTuru),
    asString(data.yil),
    asString(data.baslik2),
    asString(data.baslik3),
    asString(data.dil),
  ]).join(' ');
}

function buildDoc(docId, data) {
  const anaBaslik = asString(data.anaBaslik);
  const sinavTuru = asString(data.sinavTuru);
  const yil = asString(data.yil);
  const baslik2 = asString(data.baslik2);
  const baslik3 = asString(data.baslik3);
  const dil = asString(data.dil);
  return {
    id: docId,
    docId,
    entity: 'past_question',
    title: [anaBaslik, sinavTuru, yil].filter(Boolean).join(' - '),
    subtitle: [baslik2, baslik3, dil].filter(Boolean).join(' • '),
    description: [anaBaslik, sinavTuru, yil, baslik2, baslik3, dil].filter(Boolean).join(' | '),
    ownerId: asString(data.userID) || asString(data.ownerId),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate) || Date.now(),
    active: data.active === false ? false : !asBool(data.deleted) && !asBool(data.iptal),
    tags: dedupe([anaBaslik, sinavTuru, yil, baslik2, baslik3, dil]),
    cover: asString(data.cover) || '',
    detailsText: buildDetailsText(data),
    anaBaslik,
    baslik2,
    baslik3,
    dil,
    sinavTuru,
    yil,
    seq: asInt(data.sira),
  };
}

async function ensureCollection() {
  try {
    await httpJson(`${typesenseHost}/collections/${collection}`, {
      headers,
      method: 'GET',
    });
  } catch {
    await httpJson(`${typesenseHost}/collections`, {
      headers,
      method: 'POST',
      body: JSON.stringify({
        name: collection,
        fields: requiredFields(),
        default_sorting_field: 'timeStamp',
      }),
    });
    return;
  }

  await httpJson(`${typesenseHost}/collections/${collection}`, {
    headers,
    method: 'PATCH',
    body: JSON.stringify({ fields: requiredFields() }),
  });
}

async function run() {
  if (!admin.apps.length) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
  const db = admin.firestore();

  await ensureCollection();

  try {
    await fetch(`${typesenseHost}/collections/${collection}`, {
      headers,
      method: 'DELETE',
    });
  } catch {}
  await ensureCollection();

  const snap = await db.collection('questions').get();
  const lines = [];
  for (const doc of snap.docs) {
    lines.push(JSON.stringify(buildDoc(doc.id, doc.data() || {})));
  }

  const response = await fetch(
    `${typesenseHost}/collections/${collection}/documents/import?action=upsert`,
    {
      headers: {
        ...headers,
        'Content-Type': 'text/plain',
      },
      method: 'POST',
      body: lines.join('\n'),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `Typesense import failed: ${response.status}`);
  }

  const text = await response.text();
  const rows = text
    .split('\n')
    .filter(Boolean)
    .map((line) => JSON.parse(line));
  const failed = rows.filter((row) => row.success === false);
  console.log(
    JSON.stringify(
      {
        collection,
        scanned: snap.size,
        imported: rows.length - failed.length,
        failed,
      },
      null,
      2
    )
  );
}

run().catch((error) => {
  console.error('reindex_past_questions_typesense failed:', error);
  process.exit(1);
});
