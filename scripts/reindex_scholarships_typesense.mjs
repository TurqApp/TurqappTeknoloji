#!/usr/bin/env node
import fs from 'fs';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const typesenseHost = String(process.env.TYPESENSE_HOST || '').trim();
const typesenseApiKey = String(process.env.TYPESENSE_API_KEY || '').trim();
const collection = 'education_scholarships_search';

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
  'kaydedenler',
  'kaydedilenler',
  'begeniler',
  'goruntuleme',
  'basvurular',
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
  return typeof value === 'string' ? value.trim() : '';
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
      const key = k.trim();
      if (!key) continue;
      if (NOISY_DETAIL_KEYS.has(key)) continue;
      if (/^(img\d+|image\d+|photo\d+)$/i.test(key)) continue;
      out.push(key);
      flattenForSearch(v, out, depth + 1);
    }
  }
}

function buildDetailsText(data) {
  const out = [];
  flattenForSearch(data, out);
  return truncateText(dedupe(out).join(' '), 24000);
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
    { name: 'shortDescription', type: 'string', optional: true },
    { name: 'aciklama', type: 'string', optional: true },
    { name: 'img2', type: 'string', optional: true },
    { name: 'baslangicTarihi', type: 'string', optional: true },
    { name: 'bitisTarihi', type: 'string', optional: true },
    { name: 'basvuruKosullari', type: 'string', optional: true },
    { name: 'basvuruURL', type: 'string', optional: true },
    { name: 'basvuruYapilacakYer', type: 'string', optional: true },
    { name: 'bursVeren', type: 'string', optional: true },
    { name: 'egitimKitlesi', type: 'string', optional: true },
    { name: 'geriOdemeli', type: 'string', optional: true },
    { name: 'hedefKitle', type: 'string', optional: true },
    { name: 'mukerrerDurumu', type: 'string', optional: true },
    { name: 'ogrenciSayisi', type: 'string', optional: true },
    { name: 'tutar', type: 'string', optional: true },
    { name: 'website', type: 'string', optional: true },
    { name: 'lisansTuru', type: 'string', optional: true },
    { name: 'template', type: 'string', optional: true },
    { name: 'ulke', type: 'string', optional: true },
    { name: 'altEgitimKitlesi', type: 'string[]', optional: true },
    { name: 'aylar', type: 'string[]', optional: true },
    { name: 'belgeler', type: 'string[]', optional: true },
    { name: 'sehirler', type: 'string[]', optional: true },
    { name: 'ilceler', type: 'string[]', optional: true },
    { name: 'universiteler', type: 'string[]', optional: true },
    { name: 'liseOrtaOkulIlceler', type: 'string[]', optional: true },
    { name: 'liseOrtaOkulSehirler', type: 'string[]', optional: true },
    { name: 'likeCount', type: 'int32', optional: true },
    { name: 'bookmarkCount', type: 'int32', optional: true },
    { name: 'detailsText', type: 'string', optional: true },
  ];
}

function composeDescription(...parts) {
  return truncateText(dedupe(parts.map((p) => asString(p)).filter(Boolean)).join(' '), 12000);
}

function buildScholarshipDoc(docId, data) {
  const description = composeDescription(
    data.shortDescription,
    data.aciklama,
    data.basvuruKosullari,
    data.basvuruYapilacakYer,
    data.basvuruURL,
    data.website,
    data.baslangicTarihi,
    data.bitisTarihi,
  );
  const begeniler = asStringArray(data.begeniler);
  const kaydedenler = asStringArray(data.kaydedenler);
  return {
    id: docId,
    docId,
    entity: 'scholarship',
    title: asString(data.baslik),
    subtitle: asString(data.bursVeren),
    description,
    ownerId: asString(data.userID),
    timeStamp: asEpochMillis(data.timeStamp) || Date.now(),
    active: !asBool(data.deleted) && !asBool(data.ended),
    city: asStringArray(data.sehirler)[0] || '',
    town: asStringArray(data.ilceler)[0] || '',
    country: asString(data.ulke),
    tags: dedupe([
      asString(data.bursVeren),
      asString(data.egitimKitlesi),
      asString(data.lisansTuru),
      ...asStringArray(data.sehirler),
      ...asStringArray(data.ilceler),
      ...asStringArray(data.universiteler),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.img) || asString(data.logo),
    nickname: asString(data.nickname) || asString(data.authorNickname),
    displayName:
      asString(data.displayName) ||
      asString(data.authorDisplayName) ||
      asString(data.nickname) ||
      asString(data.authorNickname),
    avatarUrl: asString(data.avatarUrl) || asString(data.authorAvatarUrl),
    rozet: asString(data.rozet),
    shortDescription: asString(data.shortDescription),
    aciklama: asString(data.aciklama),
    img2: asString(data.img2),
    baslangicTarihi: asString(data.baslangicTarihi),
    bitisTarihi: asString(data.bitisTarihi),
    basvuruKosullari: asString(data.basvuruKosullari),
    basvuruURL: asString(data.basvuruURL),
    basvuruYapilacakYer: asString(data.basvuruYapilacakYer),
    bursVeren: asString(data.bursVeren),
    egitimKitlesi: asString(data.egitimKitlesi),
    geriOdemeli: asString(data.geriOdemeli),
    hedefKitle: asString(data.hedefKitle),
    mukerrerDurumu: asString(data.mukerrerDurumu),
    ogrenciSayisi: asString(data.ogrenciSayisi),
    tutar: asString(data.tutar),
    website: asString(data.website),
    lisansTuru: asString(data.lisansTuru),
    template: asString(data.template),
    ulke: asString(data.ulke),
    altEgitimKitlesi: asStringArray(data.altEgitimKitlesi),
    aylar: asStringArray(data.aylar),
    belgeler: asStringArray(data.belgeler),
    sehirler: asStringArray(data.sehirler),
    ilceler: asStringArray(data.ilceler),
    universiteler: asStringArray(data.universiteler),
    liseOrtaOkulIlceler: asStringArray(data.liseOrtaOkulIlceler),
    liseOrtaOkulSehirler: asStringArray(data.liseOrtaOkulSehirler),
    likeCount: asInt(data.likesCount) || begeniler.length,
    bookmarkCount: asInt(data.bookmarksCount) || kaydedenler.length,
    detailsText: buildDetailsText(data),
  };
}

async function recreateCollection() {
  try {
    await fetch(`${typesenseHost}/collections/${collection}`, {
      method: 'DELETE',
      headers,
    }).then(async (response) => {
      if (!response.ok && response.status !== 404) {
        throw new Error(await response.text());
      }
    });
  } catch (err) {
    if (err?.status !== 404) throw err;
  }

  await httpJson(
    `${typesenseHost}/collections`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({
      name: collection,
      fields: requiredFields(),
      default_sorting_field: 'timeStamp',
      }),
    },
  );
}

async function run() {
  await recreateCollection();
  const snap = await db
    .collection('catalog')
    .doc('education')
    .collection('scholarships')
    .get();

  let upserted = 0;
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const payload = buildScholarshipDoc(doc.id, data);
    if (!payload.active || (!payload.title && !payload.description && !payload.detailsText)) {
      continue;
    }
    await httpJson(
      `${typesenseHost}/collections/${collection}/documents?action=upsert`,
      {
        method: 'POST',
        headers,
        body: JSON.stringify(payload),
      },
    );
    upserted += 1;
    if (upserted % 100 === 0) {
      console.log(JSON.stringify({ upserted }));
    }
  }

  console.log(JSON.stringify({ done: true, scanned: snap.size, upserted }));
}

run().catch((err) => {
  console.error(err?.response?.data || err?.message || String(err));
  process.exit(1);
});
