import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldPath, getFirestore, Query } from "firebase-admin/firestore";
import axios, { AxiosError } from "axios";

const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const MAX_LIMIT = 100;
const MAX_DETAILS_TEXT_LEN = 24000;
const MAX_DETAILS_JSON_LEN = 32000;
const MAX_INDEX_DEPTH = 4;
const MAX_INDEX_ARRAY = 20;
const MAX_INDEX_OBJECT_KEYS = 120;

const NOISY_DETAIL_KEYS = new Set([
  "kaydedenler",
  "kaydedilenler",
  "begeniler",
  "goruntuleme",
  "basvurular",
  "token",
  "fcmToken",
  "fcm_token",
  "sifre",
  "password",
  "iban",
  "tc",
  "phoneNumber",
  "email",
  "mail",
  "device",
  "deviceID",
  "deviceVersion",
]);

type EducationEntity =
  | "scholarship"
  | "practice_exam"
  | "answer_key"
  | "tutoring"
  | "job"
  | "workout"
  | "past_question";

const EDUCATION_ENTITIES: EducationEntity[] = [
  "scholarship",
  "practice_exam",
  "answer_key",
  "tutoring",
  "job",
];

const EDUCATION_COLLECTIONS: Record<EducationEntity, string> = {
  scholarship: "education_scholarships_search",
  practice_exam: "education_online_exams_search",
  answer_key: "education_answer_keys_search",
  tutoring: "education_tutoring_search",
  job: "education_jobs_search",
  workout: "education_workouts_search",
  past_question: "education_past_questions_search",
};

type EducationSearchDoc = {
  id: string;
  docId: string;
  entity: EducationEntity;
  title: string;
  subtitle?: string;
  description?: string;
  ownerId?: string;
  timeStamp: number;
  active: boolean;
  city?: string;
  town?: string;
  country?: string;
  tags?: string[];
  cover?: string;
  detailsText?: string;
  detailsJson?: string;
};

type SearchEducationInput = {
  q?: string;
  entity?: EducationEntity;
  limit?: number;
  page?: number;
};

type EnsureEducationCollectionsInput = {
  entity?: EducationEntity;
};

type ReindexEducationInput = {
  entity?: EducationEntity;
  limit?: number;
  cursor?: string;
  dryRun?: boolean;
};

type ReindexEducationOutput = {
  entity: EducationEntity;
  scanned: number;
  upserted: number;
  deleted: number;
  skipped: number;
  nextCursor: string | null;
  done: boolean;
};

type TypesenseSearchHitOutput = {
  id: string;
  docId: string;
  entity: string;
  collection: string;
  title: string;
  subtitle: string;
  description: string;
  ownerId: string;
  timeStamp: number;
  city: string;
  town: string;
  country: string;
  cover: string;
  tags: string[];
  detailsText: string;
  detailsJson: string;
  score: number;
};

type TypesenseCollectionSearchResult = {
  hits: TypesenseSearchHitOutput[];
  found: number;
  outOf: number;
  searchTimeMs: number;
};

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

function requireAuth(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "auth_required");
  }
  return uid;
}

function requireAdminAuth(request: CallableRequest<unknown>): string {
  const uid = requireAuth(request);
  const token = request.auth?.token as { admin?: unknown } | undefined;
  if (token?.admin !== true) {
    throw new HttpsError("permission-denied", "admin_required");
  }
  return uid;
}

function getEnv(name: string): string {
  return String(process.env[name] || "").trim();
}

function getTypesenseBaseUrl(): string {
  const raw = getEnv("TYPESENSE_HOST");
  if (!raw) return "";
  const hasProtocol = raw.startsWith("http://") || raw.startsWith("https://");
  return (hasProtocol ? raw : `https://${raw}`).replace(/\/+$/g, "");
}

function getTypesenseApiKey(): string {
  return getEnv("TYPESENSE_API_KEY");
}

function typesenseReady(): boolean {
  return !!getTypesenseBaseUrl() && !!getTypesenseApiKey();
}

function headers() {
  return {
    "X-TYPESENSE-API-KEY": getTypesenseApiKey(),
    "Content-Type": "application/json",
  };
}

function asString(x: unknown): string {
  return typeof x === "string" ? x.trim() : "";
}

function asBool(x: unknown): boolean {
  return x === true;
}

function asStringArray(x: unknown): string[] {
  if (!Array.isArray(x)) return [];
  return x.map((v) => String(v ?? "").trim()).filter((v) => v.length > 0);
}

function firstString(x: unknown): string {
  return asStringArray(x)[0] || "";
}

function asEpochSeconds(x: unknown): number {
  if (!x) return 0;
  if (typeof x === "number" && Number.isFinite(x)) {
    return x > 1e12 ? Math.floor(x / 1000) : Math.floor(x);
  }
  if (typeof x === "object" && x !== null) {
    const maybe = x as { seconds?: number; _seconds?: number; toMillis?: () => number };
    if (typeof maybe.seconds === "number") return Math.floor(maybe.seconds);
    if (typeof maybe._seconds === "number") return Math.floor(maybe._seconds);
    if (typeof maybe.toMillis === "function") {
      const ms = maybe.toMillis();
      if (Number.isFinite(ms)) return Math.floor(ms / 1000);
    }
  }
  return 0;
}

function asEpochMillis(x: unknown): number {
  const sec = asEpochSeconds(x);
  if (sec > 0) return sec * 1000;
  if (typeof x === "number" && Number.isFinite(x)) return Math.floor(x);
  if (typeof x === "string") {
    const n = Number(x);
    if (Number.isFinite(n)) return Math.floor(n);
  }
  return 0;
}

function dedupe(values: string[]): string[] {
  const out = new Set<string>();
  for (const value of values) {
    const t = value.trim();
    if (t) out.add(t);
  }
  return Array.from(out);
}

function composeDescription(...parts: string[]): string {
  const merged = dedupe(parts.map((x) => x.trim()).filter((x) => x.length > 0)).join(" | ");
  return truncateText(merged, 8000);
}

function truncateText(value: string, maxLen: number): string {
  return value.length <= maxLen ? value : value.slice(0, maxLen);
}

function flattenForSearch(value: unknown, out: string[], depth = 0) {
  if (depth > MAX_INDEX_DEPTH || out.length > 1200) return;
  if (value === null || value === undefined) return;

  if (typeof value === "string") {
    const t = value.trim();
    if (t) out.push(truncateText(t, 300));
    return;
  }

  if (typeof value === "number" || typeof value === "boolean") {
    out.push(String(value));
    return;
  }

  if (Array.isArray(value)) {
    for (const item of value.slice(0, MAX_INDEX_ARRAY)) {
      flattenForSearch(item, out, depth + 1);
      if (out.length > 1200) return;
    }
    return;
  }

  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>).slice(0, MAX_INDEX_OBJECT_KEYS);
    for (const [key, v] of entries) {
      const keyText = key.trim();
      if (keyText) out.push(keyText);
      flattenForSearch(v, out, depth + 1);
      if (out.length > 1200) return;
    }
  }
}

function isNoisyDetailKey(keyRaw: string): boolean {
  const key = keyRaw.trim();
  if (!key) return true;
  if (NOISY_DETAIL_KEYS.has(key)) return true;
  if (/^(img\d+|image\d+|photo\d+)$/i.test(key)) return true;
  return false;
}

function pruneForSearch(value: unknown, depth = 0): unknown {
  if (value === undefined || value === null) return undefined;
  if (depth > MAX_INDEX_DEPTH) return undefined;

  if (typeof value === "string") {
    const text = value.trim();
    if (!text) return undefined;
    if (/^https?:\/\//i.test(text)) return undefined;
    return truncateText(text, 500);
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return value;
  }

  if (Array.isArray(value)) {
    const items = value
      .slice(0, MAX_INDEX_ARRAY)
      .map((item) => pruneForSearch(item, depth + 1))
      .filter((item) => item !== undefined);
    return items.length ? items : undefined;
  }

  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    const entries = Object.entries(value as Record<string, unknown>).slice(0, MAX_INDEX_OBJECT_KEYS);
    for (const [key, raw] of entries) {
      if (isNoisyDetailKey(key)) continue;
      const clean = pruneForSearch(raw, depth + 1);
      if (clean !== undefined) out[key] = clean;
    }
    return Object.keys(out).length ? out : undefined;
  }

  return undefined;
}

function buildDetailsText(data: Record<string, unknown>): string {
  const flattened: string[] = [];
  flattenForSearch(pruneForSearch(data), flattened);
  const normalized = dedupe(flattened);
  return truncateText(normalized.join(" "), MAX_DETAILS_TEXT_LEN);
}

function safeStringify(value: unknown): string {
  try {
    const raw = JSON.stringify(value);
    if (!raw) return "";
    return truncateText(raw, MAX_DETAILS_JSON_LEN);
  } catch {
    return "";
  }
}

function isEducationEntity(value: unknown): value is EducationEntity {
  return EDUCATION_ENTITIES.includes(value as EducationEntity);
}

function getCollectionName(entity: EducationEntity): string {
  return EDUCATION_COLLECTIONS[entity];
}

const ensureCollectionPromises: Partial<Record<EducationEntity, Promise<void>>> = {};

function requiredFields() {
  return [
    { name: "docId", type: "string", optional: true },
    { name: "entity", type: "string" },
    { name: "title", type: "string", optional: true },
    { name: "subtitle", type: "string", optional: true },
    { name: "description", type: "string", optional: true },
    { name: "ownerId", type: "string", optional: true },
    { name: "timeStamp", type: "int64", optional: false },
    { name: "active", type: "bool", optional: true },
    { name: "city", type: "string", optional: true },
    { name: "town", type: "string", optional: true },
    { name: "country", type: "string", optional: true },
    { name: "tags", type: "string[]", optional: true },
    { name: "cover", type: "string", optional: true },
    { name: "detailsText", type: "string", optional: true },
    { name: "detailsJson", type: "string", optional: true },
  ];
}

async function ensureEntityCollection(entity: EducationEntity) {
  if (ensureCollectionPromises[entity]) return ensureCollectionPromises[entity];

  ensureCollectionPromises[entity] = (async () => {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl) return;
    const collection = getCollectionName(entity);

    try {
      const existing = await axios.get(`${baseUrl}/collections/${collection}`, {
        headers: headers(),
        timeout: 8000,
      });
      const fields: Array<{ name?: string }> = Array.isArray(existing.data?.fields)
        ? (existing.data.fields as Array<{ name?: string }>)
        : [];
      const missing = requiredFields().filter((rf) => !fields.some((f) => f?.name === rf.name));
      if (missing.length) {
        await axios.patch(
          `${baseUrl}/collections/${collection}`,
          { fields: missing },
          { headers: headers(), timeout: 8000 }
        );
      }
      return;
    } catch (err) {
      const status = (err as AxiosError)?.response?.status;
      if (status !== 404) throw err;
    }

    await axios.post(
      `${baseUrl}/collections`,
      {
        name: collection,
        fields: requiredFields(),
        default_sorting_field: "timeStamp",
      },
      { headers: headers(), timeout: 8000 }
    );
  })().catch((err) => {
    ensureCollectionPromises[entity] = undefined;
    throw err;
  });

  return ensureCollectionPromises[entity];
}

async function ensureAllEntityCollections() {
  await Promise.all(EDUCATION_ENTITIES.map((entity) => ensureEntityCollection(entity)));
}

async function upsertDoc(entity: EducationEntity, doc: EducationSearchDoc) {
  const baseUrl = getTypesenseBaseUrl();
  if (!baseUrl) return;
  const collection = getCollectionName(entity);
  await ensureEntityCollection(entity);
  await axios.post(
    `${baseUrl}/collections/${collection}/documents?action=upsert`,
    doc,
    { headers: headers(), timeout: 12000 }
  );
}

async function deleteDoc(entity: EducationEntity, docId: string) {
  const baseUrl = getTypesenseBaseUrl();
  if (!baseUrl) return;
  const collection = getCollectionName(entity);
  await ensureEntityCollection(entity);
  try {
    await axios.delete(
      `${baseUrl}/collections/${collection}/documents/${encodeURIComponent(docId)}`,
      { headers: headers(), timeout: 12000 }
    );
  } catch (err) {
    const status = (err as AxiosError)?.response?.status;
    if (status === 404) return;
    throw err;
  }
}

function baseDoc(
  entity: EducationEntity,
  docId: string,
  data: Record<string, unknown>,
  partial: {
    title: string;
    subtitle?: string;
    description?: string;
    ownerId?: string;
    timeStamp?: number;
    active?: boolean;
    city?: string;
    town?: string;
    country?: string;
    tags?: string[];
    cover?: string;
  }
): EducationSearchDoc {
  const pruned = pruneForSearch(data);
  return {
    id: docId,
    docId,
    entity,
    title: partial.title.trim(),
    subtitle: partial.subtitle?.trim() || "",
    description: partial.description?.trim() || "",
    ownerId: partial.ownerId?.trim() || "",
    timeStamp: partial.timeStamp && partial.timeStamp > 0 ? partial.timeStamp : Date.now(),
    active: partial.active === false ? false : true,
    city: partial.city?.trim() || "",
    town: partial.town?.trim() || "",
    country: partial.country?.trim() || "",
    tags: dedupe(partial.tags || []),
    cover: partial.cover?.trim() || "",
    detailsText: buildDetailsText(data),
    detailsJson: safeStringify(pruned),
  };
}

function buildScholarshipDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  const description = composeDescription(
    asString(data.shortDescription),
    asString(data.aciklama),
    asString(data.basvuruKosullari),
    asString(data.basvuruYapilacakYer),
    asString(data.basvuruURL),
    asString(data.website),
    asString(data.baslangicTarihi),
    asString(data.bitisTarihi)
  );
  return baseDoc("scholarship", docId, data, {
    title: asString(data.baslik),
    subtitle: asString(data.bursVeren),
    description,
    ownerId: asString(data.userID),
    timeStamp: asEpochMillis(data.timeStamp),
    active: true,
    city: firstString(data.sehirler),
    town: firstString(data.ilceler),
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
  });
}

function buildPracticeExamDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  const isPublic = data.public === undefined ? true : asBool(data.public);
  const isDraft = asBool(data.taslak);
  return baseDoc("practice_exam", docId, data, {
    title: asString(data.sinavAdi),
    subtitle: asString(data.sinavTuru),
    description: asString(data.sinavAciklama),
    ownerId: asString(data.userID),
    timeStamp: asEpochMillis(data.timeStamp),
    active: isPublic && !isDraft,
    tags: dedupe([
      asString(data.sinavTuru),
      ...asStringArray(data.dersler),
      asString(data.kpssSecilenLisans),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.cover),
  });
}

function buildAnswerKeyDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  return baseDoc("answer_key", docId, data, {
    title: asString(data.baslik),
    subtitle: asString(data.yayinEvi),
    description: asString(data.sinavTuru),
    ownerId: asString(data.userID),
    timeStamp: asEpochMillis(data.timeStamp),
    active: true,
    tags: dedupe([
      asString(data.sinavTuru),
      asString(data.dil),
      asString(data.yayinEvi),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.cover),
  });
}

function buildTutoringDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  const imgs = asStringArray(data.imgs);
  const description = composeDescription(
    asString(data.aciklama),
    asString(data.detay),
    asString(data.ekAciklama),
    asString(data.ucret),
    ...asStringArray(data.dersYeri)
  );
  return baseDoc("tutoring", docId, data, {
    title: asString(data.baslik),
    subtitle: asString(data.brans),
    description,
    ownerId: asString(data.userID) || asString(data.userId),
    timeStamp: asEpochMillis(data.timeStamp),
    active: !asBool(data.ended),
    city: asString(data.sehir),
    town: asString(data.ilce),
    tags: dedupe([
      asString(data.brans),
      ...asStringArray(data.dersYeri),
      asString(data.cinsiyet),
      ...asStringArray(data.tags),
    ]),
    cover: imgs[0] || "",
  });
}

function buildJobDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  const imgs = asStringArray(data.imgs);
  const title = asString(data.ilanBasligi) || asString(data.meslek) || asString(data.brand);
  const description = composeDescription(
    asString(data.isTanimi),
    asString(data.ilanDetayi),
    asString(data.aciklama),
    asString(data.arananNitelikler),
    ...asStringArray(data.yanHaklar),
    ...asStringArray(data.calismaTuru)
  );
  return baseDoc("job", docId, data, {
    title,
    subtitle: asString(data.brand),
    description,
    ownerId: asString(data.userID),
    timeStamp: asEpochMillis(data.timeStamp),
    active: !asBool(data.ended),
    city: asString(data.city),
    town: asString(data.town),
    tags: dedupe([
      asString(data.meslek),
      asString(data.deneyimSeviyesi),
      ...asStringArray(data.calismaTuru),
      ...asStringArray(data.yanHaklar),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.logo) || imgs[0] || "",
  });
}

function buildWorkoutDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  return baseDoc("workout", docId, data, {
    title: asString(data.title) || asString(data.baslik) || asString(data.soru) || asString(data.name),
    subtitle: asString(data.ders) || asString(data.konu) || asString(data.category),
    description: asString(data.aciklama) || asString(data.description) || asString(data.soru),
    ownerId: asString(data.userID) || asString(data.ownerId),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
    active: asBool(data.deleted) ? false : true,
    tags: dedupe([
      asString(data.ders),
      asString(data.konu),
      asString(data.sinif),
      asString(data.zorluk),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.cover) || asString(data.img),
  });
}

function buildPastQuestionDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  return baseDoc("past_question", docId, data, {
    title: asString(data.title) || asString(data.baslik) || asString(data.soruAdi) || asString(data.soru),
    subtitle: asString(data.ders) || asString(data.sinav) || asString(data.sinavTuru),
    description: asString(data.aciklama) || asString(data.description),
    ownerId: asString(data.userID) || asString(data.ownerId),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
    active: asBool(data.deleted) ? false : true,
    tags: dedupe([
      asString(data.sinav),
      asString(data.sinavTuru),
      asString(data.ders),
      asString(data.yil),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.cover) || asString(data.img),
  });
}

function buildSearchDoc(entity: EducationEntity, docId: string, data: Record<string, unknown>): EducationSearchDoc {
  switch (entity) {
    case "scholarship":
      return buildScholarshipDoc(docId, data);
    case "practice_exam":
      return buildPracticeExamDoc(docId, data);
    case "answer_key":
      return buildAnswerKeyDoc(docId, data);
    case "tutoring":
      return buildTutoringDoc(docId, data);
    case "job":
      return buildJobDoc(docId, data);
    case "workout":
      return buildWorkoutDoc(docId, data);
    case "past_question":
      return buildPastQuestionDoc(docId, data);
  }
}

function shouldIndex(doc: EducationSearchDoc): boolean {
  const hasCoreText = doc.title.trim().length > 0 ||
    (doc.description || "").trim().length > 0 ||
    (doc.detailsText || "").trim().length > 0;
  return doc.active && hasCoreText;
}

async function syncEducationDoc(
  entity: EducationEntity,
  rawDocId: string,
  afterData: Record<string, unknown> | undefined
) {
  if (!afterData) {
    await deleteDoc(entity, rawDocId);
    return;
  }

  const doc = buildSearchDoc(entity, rawDocId, afterData);
  if (!shouldIndex(doc)) {
    await deleteDoc(entity, rawDocId);
    return;
  }
  await upsertDoc(entity, doc);
}

function toHitOutput(hitRaw: unknown, collection: string): TypesenseSearchHitOutput {
  const hit = (hitRaw || {}) as { document?: Record<string, unknown>; text_match?: number };
  const doc = (hit.document || {}) as Record<string, unknown>;
  const tags = Array.isArray(doc.tags) ? doc.tags.map((x) => String(x || "")) : [];
  return {
    id: String(doc.id || ""),
    docId: String(doc.docId || ""),
    entity: String(doc.entity || ""),
    collection,
    title: String(doc.title || ""),
    subtitle: String(doc.subtitle || ""),
    description: String(doc.description || ""),
    ownerId: String(doc.ownerId || ""),
    timeStamp: Number(doc.timeStamp || 0),
    city: String(doc.city || ""),
    town: String(doc.town || ""),
    country: String(doc.country || ""),
    cover: String(doc.cover || ""),
    tags,
    detailsText: String(doc.detailsText || ""),
    detailsJson: String(doc.detailsJson || ""),
    score: Number(hit.text_match || 0),
  };
}

async function searchFromCollection(
  entity: EducationEntity,
  qRaw: string,
  limit: number,
  page: number
): Promise<TypesenseCollectionSearchResult> {
  const baseUrl = getTypesenseBaseUrl();
  const q = qRaw.trim().length === 0 ? "*" : qRaw.trim();
  const collection = getCollectionName(entity);
  await ensureEntityCollection(entity);

  const response = await axios.get(`${baseUrl}/collections/${collection}/documents/search`, {
    headers: headers(),
    timeout: 12000,
    params: {
      q,
      query_by: "title,subtitle,description,tags,city,town,country,detailsText",
      per_page: limit,
      page,
      sort_by: "timeStamp:desc",
      filter_by: "active:=true",
      prefix: "true,true,true,true,true,true,true,true",
      num_typos: 2,
      exhaustive_search: true,
    },
  });

  const data = response.data || {};
  const rawHits = Array.isArray(data.hits) ? data.hits : [];
  const hits = rawHits.map((item: unknown) => toHitOutput(item, collection));
  return {
    hits,
    found: Number(data.found || hits.length),
    outOf: Number(data.out_of || hits.length),
    searchTimeMs: Number(data.search_time_ms || 0),
  };
}

async function searchEducationFromTypesense(
  qRaw: string,
  limit: number,
  page: number,
  entity?: EducationEntity
) {
  const q = qRaw.trim().length === 0 ? "*" : qRaw.trim();

  if (entity) {
    const one = await searchFromCollection(entity, qRaw, limit, page);
    return {
      q,
      page,
      limit,
      found: one.found,
      out_of: one.outOf,
      search_time_ms: one.searchTimeMs,
      hits: one.hits,
    };
  }

  const perCollectionLimit = Math.max(limit, 20);
  const results = await Promise.all(
    EDUCATION_ENTITIES.map((e) => searchFromCollection(e, qRaw, perCollectionLimit, page))
  );
  const merged = results.flatMap((x) => x.hits);
  merged.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return b.timeStamp - a.timeStamp;
  });

  return {
    q,
    page,
    limit,
    found: results.reduce((sum, x) => sum + x.found, 0),
    out_of: results.reduce((sum, x) => sum + x.outOf, 0),
    search_time_ms: results.reduce((sum, x) => sum + x.searchTimeMs, 0),
    hits: merged.slice(0, limit),
  };
}

function queryForEntity(entity: EducationEntity, limit: number, cursor: string): Query {
  const db = getFirestore();
  switch (entity) {
    case "scholarship": {
      let q: Query = db
        .collection("catalog")
        .doc("education")
        .collection("scholarships")
        .orderBy(FieldPath.documentId())
        .limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
    case "practice_exam": {
      let q: Query = db.collection("practiceExams").orderBy(FieldPath.documentId()).limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
    case "answer_key": {
      let q: Query = db.collection("books").orderBy(FieldPath.documentId()).limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
    case "tutoring": {
      let q: Query = db.collection("educators").orderBy(FieldPath.documentId()).limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
    case "job": {
      let q: Query = db.collection("isBul").orderBy(FieldPath.documentId()).limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
    case "workout": {
      let q: Query = db.collection("questionBank").orderBy(FieldPath.documentId()).limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
    case "past_question": {
      let q: Query = db.collection("questions").orderBy(FieldPath.documentId()).limit(limit);
      if (cursor) q = q.startAfter(cursor);
      return q;
    }
  }
}

export const f21_syncScholarshipsToTypesense = onDocumentWritten(
  {
    document: "catalog/education/scholarships/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("scholarship", docId, afterData);
  }
);

export const f21_syncPracticeExamsToTypesense = onDocumentWritten(
  {
    document: "practiceExams/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("practice_exam", docId, afterData);
  }
);

export const f21_syncAnswerKeysToTypesense = onDocumentWritten(
  {
    document: "books/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("answer_key", docId, afterData);
  }
);

export const f21_syncTutoringsToTypesense = onDocumentWritten(
  {
    document: "educators/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("tutoring", docId, afterData);
  }
);

export const f21_syncJobsToTypesense = onDocumentWritten(
  {
    document: "isBul/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("job", docId, afterData);
  }
);

export const f21_syncWorkoutsToTypesense = onDocumentWritten(
  {
    document: "questionBank/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    return;
  }
);

export const f21_syncPastQuestionsToTypesense = onDocumentWritten(
  {
    document: "questions/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    return;
  }
);

export const f21_ensureEducationTypesenseCollectionCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<EnsureEducationCollectionsInput>) => {
    ensureAdmin();
    requireAdminAuth(request);
    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const rawEntity = request.data?.entity;
    if (rawEntity !== undefined && !isEducationEntity(rawEntity)) {
      throw new HttpsError("invalid-argument", "invalid_entity");
    }

    if (rawEntity) {
      await ensureEntityCollection(rawEntity);
      return { ok: true, entity: rawEntity, collection: getCollectionName(rawEntity) };
    }

    await ensureAllEntityCollections();
    return {
      ok: true,
      entities: EDUCATION_ENTITIES.map((entity) => ({
        entity,
        collection: getCollectionName(entity),
      })),
    };
  }
);

export const f21_searchEducationCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<SearchEducationInput>) => {
    requireAuth(request);
    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const q = String(request.data?.q || "");
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    const entityRaw = request.data?.entity;
    const entity = isEducationEntity(entityRaw) ? entityRaw : undefined;

    try {
      return await searchEducationFromTypesense(q, limit, page, entity);
    } catch (err: unknown) {
      const axiosErr = err as AxiosError;
      const detail = axiosErr?.response?.data || (err as Error)?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f21_reindexEducationToTypesenseCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<ReindexEducationInput>): Promise<ReindexEducationOutput> => {
    ensureAdmin();
    requireAdminAuth(request);
    try {
      if (!typesenseReady()) {
        throw new HttpsError("failed-precondition", "typesense_not_configured");
      }

      const entityRaw = request.data?.entity;
      if (!isEducationEntity(entityRaw)) {
        throw new HttpsError("invalid-argument", "invalid_entity");
      }
      const entity = entityRaw;

      const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
      const cursor = String(request.data?.cursor || "").trim();
      const dryRun = request.data?.dryRun === true;

      await ensureEntityCollection(entity);

      const snap = await queryForEntity(entity, limit, cursor).get();
      let scanned = 0;
      let upserted = 0;
      let deleted = 0;
      let skipped = 0;

      for (const docSnap of snap.docs) {
        scanned += 1;
        const rawDocId = docSnap.id;
        const data = docSnap.data() as Record<string, unknown>;
        const doc = buildSearchDoc(entity, rawDocId, data);

        if (!shouldIndex(doc)) {
          if (!dryRun) {
            await deleteDoc(entity, rawDocId);
          }
          deleted += 1;
          continue;
        }

        if (!doc.title.trim() && !(doc.detailsText || "").trim()) {
          skipped += 1;
          continue;
        }

        if (!dryRun) {
          await upsertDoc(entity, doc);
        }
        upserted += 1;
      }

      const last = snap.docs[snap.docs.length - 1];
      const nextCursor = last ? last.id : null;
      const done = snap.docs.length < limit;

      return {
        entity,
        scanned,
        upserted,
        deleted,
        skipped,
        nextCursor,
        done,
      };
    } catch (err: unknown) {
      const axiosErr = err as AxiosError;
      const detail = axiosErr?.response?.data || (err as Error)?.message || "unknown_error";
      console.error("f21_reindex_education_failed", {
        detail,
        entity: request.data?.entity || null,
        cursor: request.data?.cursor || null,
      });
      throw new HttpsError("internal", "typesense_reindex_failed", detail);
    }
  }
);
