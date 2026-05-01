import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldPath, getFirestore, Query } from "firebase-admin/firestore";
import axios, { AxiosError } from "axios";
import { RateLimits } from "./rateLimiter";
import { canonicalizeKnownPublicUserAssetUrl } from "./postAssetUrlContract";

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
  "authorAvatarUrl",
  "authorDisplayName",
  "authorNickname",
  "avatarUrl",
  "displayName",
  "nickname",
  "logo",
  "cover",
  "updatedAt",
  "timeStamp",
  "userID",
  "viewCount",
  "applicationCount",
  "endedAt",
  "lat",
  "long",
  "dogruCevap",
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
  "workout",
  "past_question",
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

const JOB_TYPESENSE_REDUCED_FIELDS = new Set([
  "authorNickname",
  "authorDisplayName",
  "authorAvatarUrl",
  "detailsJson",
  "logo",
]);

const SCHOLARSHIP_TYPESENSE_REDUCED_FIELDS = new Set([
  "authorNickname",
  "authorDisplayName",
  "authorAvatarUrl",
  "detailsJson",
  "img",
]);

const TUTORING_TYPESENSE_REDUCED_FIELDS = new Set([
  "authorNickname",
  "authorDisplayName",
  "authorAvatarUrl",
  "shortDescription",
  "img2",
  "baslangicTarihi",
  "bitisTarihi",
  "basvuruKosullari",
  "basvuruURL",
  "basvuruYapilacakYer",
  "bursVeren",
  "egitimKitlesi",
  "geriOdemeli",
  "hedefKitle",
  "mukerrerDurumu",
  "ogrenciSayisi",
  "tutar",
  "website",
  "lisansTuru",
  "template",
  "ulke",
  "altEgitimKitlesi",
  "aylar",
  "belgeler",
  "sehirler",
  "ilceler",
  "universiteler",
  "liseOrtaOkulIlceler",
  "liseOrtaOkulSehirler",
  "likeCount",
  "bookmarkCount",
  "detailsJson",
  "brand",
  "yanHaklar",
  "calismaGunleri",
  "calismaSaatiBaslangic",
  "calismaSaatiBitis",
  "calismaTuru",
  "isTanimi",
  "adres",
  "maas1",
  "maas2",
  "meslek",
  "ilanBasligi",
  "deneyimSeviyesi",
  "basvuruSayisi",
  "pozisyonSayisi",
  "about",
]);

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
  logo?: string;
  nickname?: string;
  displayName?: string;
  avatarUrl?: string;
  rozet?: string;
  shortDescription?: string;
  aciklama?: string;
  img2?: string;
  baslangicTarihi?: string;
  bitisTarihi?: string;
  basvuruKosullari?: string;
  basvuruURL?: string;
  basvuruYapilacakYer?: string;
  bursVeren?: string;
  egitimKitlesi?: string;
  geriOdemeli?: string;
  hedefKitle?: string;
  mukerrerDurumu?: string;
  ogrenciSayisi?: string;
  tutar?: string;
  website?: string;
  lisansTuru?: string;
  template?: string;
  ulke?: string;
  altEgitimKitlesi?: string[];
  aylar?: string[];
  belgeler?: string[];
  sehirler?: string[];
  ilceler?: string[];
  universiteler?: string[];
  liseOrtaOkulIlceler?: string[];
  liseOrtaOkulSehirler?: string[];
  likeCount?: number;
  bookmarkCount?: number;
  detailsText?: string;
  detailsJson?: string;
  brand?: string;
  yanHaklar?: string[];
  calismaGunleri?: string[];
  calismaSaatiBaslangic?: string;
  calismaSaatiBitis?: string;
  calismaTuru?: string[];
  ended?: boolean;
  isTanimi?: string;
  lat?: number;
  long?: number;
  adres?: string;
  maas1?: number;
  maas2?: number;
  meslek?: string;
  ilanBasligi?: string;
  deneyimSeviyesi?: string;
  basvuruSayisi?: number;
  pozisyonSayisi?: number;
  viewCount?: number;
  applicationCount?: number;
  endedAt?: number;
  about?: string;
  dersYeri?: string[];
  cinsiyet?: string;
  fiyat?: number;
  telefon?: boolean;
  whatsapp?: boolean;
  averageRating?: number;
  reviewCount?: number;
  categoryKey?: string;
  anaBaslik?: string;
  baslik2?: string;
  baslik3?: string;
  dil?: string;
  ders?: string;
  sinavTuru?: string;
  soruNo?: string;
  yil?: string;
  seq?: number;
  correctCount?: number;
  wrongCount?: number;
  soru?: string;
  dogruCevap?: string;
  kacCevap?: number;
  diger1?: string;
  diger2?: boolean;
  diger3?: number;
};

type SearchEducationInput = {
  q?: string;
  entity?: EducationEntity;
  limit?: number;
  page?: number;
  filterBy?: string;
  sortBy?: string;
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
  nickname: string;
  displayName: string;
  avatarUrl: string;
  tags: string[];
  rozet: string;
  shortDescription: string;
  aciklama: string;
  img: string;
  img2: string;
  logo: string;
  baslangicTarihi: string;
  bitisTarihi: string;
  basvuruKosullari: string;
  basvuruURL: string;
  basvuruYapilacakYer: string;
  bursVeren: string;
  egitimKitlesi: string;
  geriOdemeli: string;
  hedefKitle: string;
  mukerrerDurumu: string;
  ogrenciSayisi: string;
  tutar: string;
  website: string;
  lisansTuru: string;
  template: string;
  ulke: string;
  altEgitimKitlesi: string[];
  aylar: string[];
  belgeler: string[];
  sehirler: string[];
  ilceler: string[];
  universiteler: string[];
  liseOrtaOkulIlceler: string[];
  liseOrtaOkulSehirler: string[];
  likeCount: number;
  bookmarkCount: number;
  detailsText: string;
  brand: string;
  yanHaklar: string[];
  calismaGunleri: string[];
  calismaSaatiBaslangic: string;
  calismaSaatiBitis: string;
  calismaTuru: string[];
  ended: boolean;
  isTanimi: string;
  lat: number;
  long: number;
  adres: string;
  maas1: number;
  maas2: number;
  meslek: string;
  ilanBasligi: string;
  deneyimSeviyesi: string;
  basvuruSayisi: number;
  pozisyonSayisi: number;
  viewCount: number;
  applicationCount: number;
  endedAt: number;
  about: string;
  dersYeri: string[];
  cinsiyet: string;
  fiyat: number;
  telefon: boolean;
  whatsapp: boolean;
  averageRating: number;
  reviewCount: number;
  categoryKey: string;
  anaBaslik: string;
  baslik2: string;
  baslik3: string;
  dil: string;
  ders: string;
  sinavTuru: string;
  soruNo: string;
  yil: string;
  seq: number;
  correctCount: number;
  wrongCount: number;
  soru: string;
  dogruCevap: string;
  kacCevap: number;
  diger1: string;
  diger2: boolean;
  diger3: number;
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

function resolveRateLimitSubject(request: CallableRequest<unknown>): string {
  const authUid = request.auth?.uid?.trim();
  if (authUid) return `uid:${authUid}`;
  const rawRequest = (request as { rawRequest?: { ip?: string; headers?: Record<string, string | string[] | undefined> } }).rawRequest;
  const ipHeader = rawRequest?.headers?.["cf-connecting-ip"] ?? rawRequest?.headers?.["x-forwarded-for"];
  const headerValue = Array.isArray(ipHeader) ? String(ipHeader[0] || "").trim() : String(ipHeader || "").trim();
  const ip = headerValue.length > 0 ? headerValue.split(",")[0].trim() : String(rawRequest?.ip || "").trim();
  if (ip) return `ip:${ip}`;
  return "guest:unknown";
}

function requireAdminAuth(request: CallableRequest<unknown>): string {
  const uid = requireAuth(request);
  const token = request.auth?.token as { admin?: unknown } | undefined;
  if (token?.admin !== true) {
    throw new HttpsError("permission-denied", "admin_required");
  }
  RateLimits.admin(uid);
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

function asInt(x: unknown): number {
  if (typeof x === "number" && Number.isFinite(x)) return Math.floor(x);
  if (typeof x === "string") {
    const n = Number(x);
    if (Number.isFinite(n)) return Math.floor(n);
  }
  return 0;
}

function asFloat(x: unknown): number {
  if (typeof x === "number" && Number.isFinite(x)) return x;
  if (typeof x === "string") {
    const n = Number(x);
    if (Number.isFinite(n)) return n;
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

function requiredFields(entity?: EducationEntity) {
  const fields = [
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
    { name: "logo", type: "string", optional: true },
    { name: "nickname", type: "string", optional: true },
    { name: "displayName", type: "string", optional: true },
    { name: "avatarUrl", type: "string", optional: true },
    { name: "rozet", type: "string", optional: true },
    { name: "shortDescription", type: "string", optional: true },
    { name: "aciklama", type: "string", optional: true },
    { name: "img2", type: "string", optional: true },
    { name: "baslangicTarihi", type: "string", optional: true },
    { name: "bitisTarihi", type: "string", optional: true },
    { name: "basvuruKosullari", type: "string", optional: true },
    { name: "basvuruURL", type: "string", optional: true },
    { name: "basvuruYapilacakYer", type: "string", optional: true },
    { name: "bursVeren", type: "string", optional: true },
    { name: "egitimKitlesi", type: "string", optional: true },
    { name: "geriOdemeli", type: "string", optional: true },
    { name: "hedefKitle", type: "string", optional: true },
    { name: "mukerrerDurumu", type: "string", optional: true },
    { name: "ogrenciSayisi", type: "string", optional: true },
    { name: "tutar", type: "string", optional: true },
    { name: "website", type: "string", optional: true },
    { name: "lisansTuru", type: "string", optional: true },
    { name: "template", type: "string", optional: true },
    { name: "ulke", type: "string", optional: true },
    { name: "altEgitimKitlesi", type: "string[]", optional: true },
    { name: "aylar", type: "string[]", optional: true },
    { name: "belgeler", type: "string[]", optional: true },
    { name: "sehirler", type: "string[]", optional: true },
    { name: "ilceler", type: "string[]", optional: true },
    { name: "universiteler", type: "string[]", optional: true },
    { name: "liseOrtaOkulIlceler", type: "string[]", optional: true },
    { name: "liseOrtaOkulSehirler", type: "string[]", optional: true },
    { name: "likeCount", type: "int32", optional: true },
    { name: "bookmarkCount", type: "int32", optional: true },
    { name: "detailsText", type: "string", optional: true },
    { name: "brand", type: "string", optional: true },
    { name: "yanHaklar", type: "string[]", optional: true },
    { name: "calismaGunleri", type: "string[]", optional: true },
    { name: "calismaSaatiBaslangic", type: "string", optional: true },
    { name: "calismaSaatiBitis", type: "string", optional: true },
    { name: "calismaTuru", type: "string[]", optional: true },
    { name: "ended", type: "bool", optional: true },
    { name: "isTanimi", type: "string", optional: true },
    { name: "lat", type: "float", optional: true },
    { name: "long", type: "float", optional: true },
    { name: "adres", type: "string", optional: true },
    { name: "maas1", type: "int64", optional: true },
    { name: "maas2", type: "int64", optional: true },
    { name: "meslek", type: "string", optional: true },
    { name: "ilanBasligi", type: "string", optional: true },
    { name: "deneyimSeviyesi", type: "string", optional: true },
    { name: "basvuruSayisi", type: "int32", optional: true },
    { name: "pozisyonSayisi", type: "int32", optional: true },
    { name: "viewCount", type: "int32", optional: true },
    { name: "applicationCount", type: "int32", optional: true },
    { name: "endedAt", type: "int64", optional: true },
    { name: "about", type: "string", optional: true },
    { name: "categoryKey", type: "string", optional: true },
    { name: "anaBaslik", type: "string", optional: true },
    { name: "baslik2", type: "string", optional: true },
    { name: "baslik3", type: "string", optional: true },
    { name: "dil", type: "string", optional: true },
    { name: "ders", type: "string", optional: true },
    { name: "sinavTuru", type: "string", optional: true },
    { name: "soruNo", type: "string", optional: true },
    { name: "yil", type: "string", optional: true },
    { name: "seq", type: "int32", optional: true },
    { name: "correctCount", type: "int32", optional: true },
    { name: "wrongCount", type: "int32", optional: true },
    { name: "soru", type: "string", optional: true },
    { name: "dogruCevap", type: "string", optional: true },
    { name: "kacCevap", type: "int32", optional: true },
    { name: "diger1", type: "string", optional: true },
    { name: "diger2", type: "bool", optional: true },
    { name: "diger3", type: "float", optional: true },
  ];
  if (entity === "job") {
    return fields.filter((field) => !JOB_TYPESENSE_REDUCED_FIELDS.has(field.name));
  }
  if (entity === "scholarship") {
    return fields.filter((field) => !SCHOLARSHIP_TYPESENSE_REDUCED_FIELDS.has(field.name));
  }
  if (entity === "tutoring") {
    return fields.filter((field) => !TUTORING_TYPESENSE_REDUCED_FIELDS.has(field.name));
  }
  return fields;
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
      const missing = requiredFields(entity).filter((rf) => !fields.some((f) => f?.name === rf.name));
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
        fields: requiredFields(entity),
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

type AuthorSummary = {
  nickname: string;
  displayName: string;
  avatarUrl: string;
  rozet: string;
};

async function fetchAuthorSummary(userId: string): Promise<AuthorSummary> {
  const normalizedUserId = asString(userId);
  if (!normalizedUserId) {
    return {
      nickname: "",
      displayName: "",
      avatarUrl: "",
      rozet: "",
    };
  }

  try {
    const snap = await getFirestore().collection("users").doc(normalizedUserId).get();
    if (!snap.exists) {
      return {
        nickname: "",
        displayName: "",
        avatarUrl: "",
        rozet: "",
      };
    }
    const data = (snap.data() || {}) as Record<string, unknown>;
    const nickname = asString((data as any).nickname) || asString((data as any).username);
    const displayName =
      asString((data as any).displayName) ||
      asString((data as any).fullName) ||
      [asString((data as any).firstName), asString((data as any).lastName)]
        .filter(Boolean)
        .join(" ")
        .trim() ||
      nickname;

    return {
      nickname,
      displayName,
      avatarUrl: canonicalizeKnownPublicUserAssetUrl(
        asString((data as any).avatarUrl) ||
          asString((data as any).photoUrl) ||
          asString((data as any).profileImage) ||
          asString((data as any).imageUrl),
        normalizedUserId,
      ),
      rozet: asString((data as any).rozet),
    };
  } catch (err) {
    console.error("typesense_education_author_summary_fetch_failed", normalizedUserId, err);
    return {
      nickname: "",
      displayName: "",
      avatarUrl: "",
      rozet: "",
    };
  }
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
  const base = baseDoc("scholarship", docId, data, {
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
  const nickname = asString(data.nickname) || asString(data.authorNickname);
  const displayName =
    asString(data.displayName) ||
    asString(data.authorDisplayName) ||
    nickname;
  const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
    asString(data.avatarUrl) || asString(data.authorAvatarUrl),
  );
  const begeniler = asStringArray(data.begeniler);
  const kaydedenler = asStringArray(data.kaydedenler);
  const { detailsJson: _detailsJson, ...rest } = base;
  return {
    ...rest,
    nickname,
    displayName,
    avatarUrl,
    rozet: asString(data.rozet),
    logo: asString(data.logo),
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
  };
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
  const base = baseDoc("tutoring", docId, data, {
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
  const { detailsJson: _detailsJson, ...rest } = base;
  return {
    ...rest,
    aciklama: asString(data.aciklama),
    dersYeri: asStringArray(data.dersYeri),
    cinsiyet: asString(data.cinsiyet),
    fiyat: asInt(data.fiyat),
    telefon: asBool(data.telefon),
    whatsapp: asBool(data.whatsapp),
    averageRating: asFloat(data.averageRating),
    reviewCount: asInt(data.reviewCount),
    ended: asBool(data.ended),
    endedAt: asInt(data.endedAt),
    viewCount: asInt(data.viewCount),
    applicationCount: asInt(data.applicationCount),
    lat: asFloat(data.lat),
    long: asFloat(data.long),
  };
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
  const base = baseDoc("job", docId, data, {
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
      ...asStringArray(data.calismaGunleri),
      ...asStringArray(data.calismaTuru),
      ...asStringArray(data.yanHaklar),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.logo) || imgs[0] || "",
  });
  const { detailsJson: _detailsJson, ...rest } = base;
  return rest;
}

function buildWorkoutDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  const anaBaslik = asString(data.anaBaslik);
  const sinavTuru = asString(data.sinavTuru);
  const ders = asString(data.ders);
  const soruNo = asString(data.soruNo);
  const yil = asString(data.yil);
  const title =
    asString(data.title) ||
    asString(data.baslik) ||
    composeDescription(anaBaslik, sinavTuru, ders).split(" | ").join(" - ");
  const subtitle = composeDescription(
    ders,
    sinavTuru,
    soruNo && yil ? `Soru ${soruNo} • ${yil}` : `Soru ${soruNo}`
  );
  const description =
    asString(data.aciklama) ||
    composeDescription(anaBaslik, sinavTuru, ders, soruNo.length === 0 ? "" : `Soru ${soruNo}`, yil);
  const base = baseDoc("workout", docId, data, {
    title,
    subtitle,
    description,
    ownerId: asString(data.userID) || asString(data.ownerId),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
    active: (data.active as boolean | undefined) ?? (asBool(data.iptal) ? false : !asBool(data.deleted)),
    tags: dedupe([
      anaBaslik,
      sinavTuru,
      ders,
      yil,
      asString(data.konu),
      asString(data.sinif),
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.soru) || asString(data.cover) || asString(data.img),
  });
  return {
    ...base,
    categoryKey: asString(data.categoryKey),
    anaBaslik,
    ders,
    sinavTuru,
    soruNo,
    yil,
    seq: asInt(data.seq),
    correctCount: asInt(data.correctCount),
    wrongCount: asInt(data.wrongCount),
    viewCount: asInt(data.viewCount),
    soru: asString(data.soru),
    dogruCevap: asString(data.dogruCevap),
    kacCevap: asInt(data.kacCevap),
    diger1: asString(data.diger1),
    diger2: asBool(data.diger2),
    diger3: asFloat(data.diger3),
  };
}

function buildPastQuestionDoc(docId: string, data: Record<string, unknown>): EducationSearchDoc {
  const anaBaslik = asString(data.anaBaslik);
  const baslik2 = asString(data.baslik2);
  const baslik3 = asString(data.baslik3);
  const sinavTuru = asString(data.sinavTuru);
  const yil = asString(data.yil);
  const dil = asString(data.dil);
  const title =
      asString(data.title) ||
      composeDescription(anaBaslik, sinavTuru, yil).split(" | ").join(" - ");
  const subtitle = composeDescription(baslik2, baslik3, dil);
  const description = composeDescription(
    asString(data.aciklama),
    anaBaslik,
    sinavTuru,
    yil,
    baslik2,
    baslik3,
    dil,
  );
  const base = baseDoc("past_question", docId, data, {
    title,
    subtitle,
    description,
    ownerId: asString(data.userID) || asString(data.ownerId),
    timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
    active: (data.active as boolean | undefined) ?? (asBool(data.iptal) ? false : !asBool(data.deleted)),
    tags: dedupe([
      anaBaslik,
      sinavTuru,
      yil,
      baslik2,
      baslik3,
      dil,
      ...asStringArray(data.tags),
    ]),
    cover: asString(data.cover) || asString(data.soru) || asString(data.img),
  });
  return {
    ...base,
    anaBaslik,
    baslik2,
    baslik3,
    dil,
    sinavTuru,
    yil,
    seq: asInt(data.sira),
  };
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

function buildComparableIndexedDoc(
  entity: EducationEntity,
  docId: string,
  data: Record<string, unknown>
): EducationSearchDoc {
  const doc = buildSearchDoc(entity, docId, data);
  if (entity === "scholarship") {
    const nickname =
      doc.nickname ||
      asString((data as any).nickname) ||
      asString((data as any).authorNickname);
    const displayName =
      doc.displayName ||
      asString((data as any).displayName) ||
      asString((data as any).authorDisplayName) ||
      nickname;
    const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
      doc.avatarUrl ||
      asString((data as any).avatarUrl) ||
      asString((data as any).authorAvatarUrl),
    );
    const rozet = doc.rozet || asString((data as any).rozet);
    return {
      ...doc,
      nickname,
      displayName,
      avatarUrl,
      rozet,
    };
  }

  if (entity === "tutoring") {
    const nickname = doc.nickname || asString((data as any).nickname);
    const displayName =
      doc.displayName ||
      asString((data as any).displayName) ||
      nickname;
    const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
      asString((data as any).avatarUrl) ||
      doc.avatarUrl ||
      "",
    );
    const rozet = doc.rozet || asString((data as any).rozet);
    return {
      ...doc,
      nickname,
      displayName,
      avatarUrl,
      rozet,
    };
  }

  if (entity !== "job") return doc;

  const nickname = doc.nickname || asString((data as any).nickname);
  const displayName =
    doc.displayName ||
    asString((data as any).displayName) ||
    nickname;
  const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
    asString((data as any).avatarUrl) ||
    doc.avatarUrl ||
    "",
  );
  const rozet = doc.rozet || asString((data as any).rozet);
  return {
    ...doc,
    nickname,
    displayName,
    avatarUrl,
    rozet,
  };
}

function educationDocsEqual(
  left: EducationSearchDoc | null | undefined,
  right: EducationSearchDoc | null | undefined
): boolean {
  if (!left || !right) return false;
  return JSON.stringify(left) === JSON.stringify(right);
}

async function buildSearchDocForIndexing(
  entity: EducationEntity,
  docId: string,
  data: Record<string, unknown>
): Promise<EducationSearchDoc> {
  const doc = buildSearchDoc(entity, docId, data);
  if (entity === "scholarship") {
    const summary = await fetchAuthorSummary(doc.ownerId || "");
    const nickname =
      doc.nickname ||
      asString((data as any).nickname) ||
      asString((data as any).authorNickname) ||
      summary.nickname;
    const displayName =
      doc.displayName ||
      asString((data as any).displayName) ||
      asString((data as any).authorDisplayName) ||
      summary.displayName ||
      nickname;
    const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
      doc.avatarUrl ||
      asString((data as any).avatarUrl) ||
      asString((data as any).authorAvatarUrl) ||
      summary.avatarUrl,
    );
    const rozet =
      doc.rozet ||
      asString((data as any).rozet) ||
      summary.rozet;
    return {
      ...doc,
      nickname,
      displayName,
      avatarUrl,
      rozet,
    };
  }

  if (entity === "tutoring") {
    const summary = await fetchAuthorSummary(doc.ownerId || "");
    const nickname =
      doc.nickname ||
      asString((data as any).nickname) ||
      summary.nickname;
    const displayName =
      doc.displayName ||
      asString((data as any).displayName) ||
      summary.displayName ||
      nickname;
    const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
      asString((data as any).avatarUrl) ||
      doc.avatarUrl ||
      summary.avatarUrl,
    );
    const rozet = doc.rozet || asString((data as any).rozet) || summary.rozet;
    return {
      ...doc,
      nickname,
      displayName,
      avatarUrl,
      rozet,
      aciklama: asString((data as any).aciklama),
      dersYeri: asStringArray((data as any).dersYeri),
      cinsiyet: asString((data as any).cinsiyet),
      fiyat: asInt((data as any).fiyat),
      telefon: asBool((data as any).telefon),
      whatsapp: asBool((data as any).whatsapp),
      averageRating: asFloat((data as any).averageRating),
      reviewCount: asInt((data as any).reviewCount),
      ended: asBool((data as any).ended),
      endedAt: asInt((data as any).endedAt),
      viewCount: asInt((data as any).viewCount),
      applicationCount: asInt((data as any).applicationCount),
      lat: asFloat((data as any).lat),
      long: asFloat((data as any).long),
    };
  }

  if (entity !== "job") return doc;

  const summary = await fetchAuthorSummary(doc.ownerId || "");
  const nickname = doc.nickname || asString((data as any).nickname) || summary.nickname;
  const displayName =
    doc.displayName ||
    asString((data as any).displayName) ||
    summary.displayName ||
    nickname;
  const avatarUrl = canonicalizeKnownPublicUserAssetUrl(
    asString((data as any).avatarUrl) ||
    doc.avatarUrl ||
    summary.avatarUrl,
  );
  const rozet = doc.rozet || asString((data as any).rozet) || summary.rozet;

  return {
    ...doc,
    nickname,
    displayName,
    avatarUrl,
    rozet,
    brand: asString((data as any).brand),
    yanHaklar: asStringArray((data as any).yanHaklar),
    calismaGunleri: asStringArray((data as any).calismaGunleri),
    calismaSaatiBaslangic: asString((data as any).calismaSaatiBaslangic),
    calismaSaatiBitis: asString((data as any).calismaSaatiBitis),
    calismaTuru: asStringArray((data as any).calismaTuru),
    ended: asBool((data as any).ended),
    isTanimi: asString((data as any).isTanimi),
    lat: Number((data as any).lat || 0),
    long: Number((data as any).long || 0),
    adres: asString((data as any).adres),
    maas1: asInt((data as any).maas1),
    maas2: asInt((data as any).maas2),
    meslek: asString((data as any).meslek),
    ilanBasligi: asString((data as any).ilanBasligi),
    deneyimSeviyesi: asString((data as any).deneyimSeviyesi),
    basvuruSayisi: asInt((data as any).basvuruSayisi),
    pozisyonSayisi: asInt((data as any).pozisyonSayisi) || 1,
    viewCount: asInt((data as any).viewCount),
    applicationCount: asInt((data as any).applicationCount),
    endedAt: asInt((data as any).endedAt),
    about: asString((data as any).about),
  };
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
  beforeData: Record<string, unknown> | undefined,
  afterData: Record<string, unknown> | undefined
) {
  const beforeComparable = beforeData
    ? buildComparableIndexedDoc(entity, rawDocId, beforeData)
    : null;
  const afterComparable = afterData
    ? buildComparableIndexedDoc(entity, rawDocId, afterData)
    : null;
  const beforeIndexed = !!beforeComparable && shouldIndex(beforeComparable);
  const afterIndexed = !!afterComparable && shouldIndex(afterComparable);

  if (!afterData) {
    if (!beforeIndexed) {
      return;
    }
    await deleteDoc(entity, rawDocId);
    return;
  }

  if (!afterIndexed) {
    if (!beforeIndexed) {
      return;
    }
    await deleteDoc(entity, rawDocId);
    return;
  }

  if (beforeIndexed && educationDocsEqual(beforeComparable, afterComparable)) {
    return;
  }

  const doc = await buildSearchDocForIndexing(entity, rawDocId, afterData);
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
    nickname: String(doc.nickname || ""),
    displayName: String(doc.displayName || ""),
    avatarUrl: String(doc.avatarUrl || ""),
    tags,
    rozet: String(doc.rozet || ""),
    shortDescription: String(doc.shortDescription || ""),
    aciklama: String(doc.aciklama || ""),
    img: String(doc.cover || ""),
    img2: String(doc.img2 || ""),
    logo: String(doc.logo || ""),
    baslangicTarihi: String(doc.baslangicTarihi || ""),
    bitisTarihi: String(doc.bitisTarihi || ""),
    basvuruKosullari: String(doc.basvuruKosullari || ""),
    basvuruURL: String(doc.basvuruURL || ""),
    basvuruYapilacakYer: String(doc.basvuruYapilacakYer || ""),
    bursVeren: String(doc.bursVeren || ""),
    egitimKitlesi: String(doc.egitimKitlesi || ""),
    geriOdemeli: String(doc.geriOdemeli || ""),
    hedefKitle: String(doc.hedefKitle || ""),
    mukerrerDurumu: String(doc.mukerrerDurumu || ""),
    ogrenciSayisi: String(doc.ogrenciSayisi || ""),
    tutar: String(doc.tutar || ""),
    website: String(doc.website || ""),
    lisansTuru: String(doc.lisansTuru || ""),
    template: String(doc.template || ""),
    ulke: String(doc.ulke || ""),
    altEgitimKitlesi: Array.isArray(doc.altEgitimKitlesi) ? doc.altEgitimKitlesi.map((x) => String(x || "")) : [],
    aylar: Array.isArray(doc.aylar) ? doc.aylar.map((x) => String(x || "")) : [],
    belgeler: Array.isArray(doc.belgeler) ? doc.belgeler.map((x) => String(x || "")) : [],
    sehirler: Array.isArray(doc.sehirler) ? doc.sehirler.map((x) => String(x || "")) : [],
    ilceler: Array.isArray(doc.ilceler) ? doc.ilceler.map((x) => String(x || "")) : [],
    universiteler: Array.isArray(doc.universiteler) ? doc.universiteler.map((x) => String(x || "")) : [],
    liseOrtaOkulIlceler: Array.isArray(doc.liseOrtaOkulIlceler) ? doc.liseOrtaOkulIlceler.map((x) => String(x || "")) : [],
    liseOrtaOkulSehirler: Array.isArray(doc.liseOrtaOkulSehirler) ? doc.liseOrtaOkulSehirler.map((x) => String(x || "")) : [],
    likeCount: Number(doc.likeCount || 0),
    bookmarkCount: Number(doc.bookmarkCount || 0),
    detailsText: String(doc.detailsText || ""),
    brand: String(doc.brand || ""),
    yanHaklar: Array.isArray(doc.yanHaklar) ? doc.yanHaklar.map((x) => String(x || "")) : [],
    calismaGunleri: Array.isArray(doc.calismaGunleri) ? doc.calismaGunleri.map((x) => String(x || "")) : [],
    calismaSaatiBaslangic: String(doc.calismaSaatiBaslangic || ""),
    calismaSaatiBitis: String(doc.calismaSaatiBitis || ""),
    calismaTuru: Array.isArray(doc.calismaTuru) ? doc.calismaTuru.map((x) => String(x || "")) : [],
    ended: doc.ended === true,
    isTanimi: String(doc.isTanimi || ""),
    lat: Number(doc.lat || 0),
    long: Number(doc.long || 0),
    adres: String(doc.adres || ""),
    maas1: Number(doc.maas1 || 0),
    maas2: Number(doc.maas2 || 0),
    meslek: String(doc.meslek || ""),
    ilanBasligi: String(doc.ilanBasligi || ""),
    deneyimSeviyesi: String(doc.deneyimSeviyesi || ""),
    basvuruSayisi: Number(doc.basvuruSayisi || 0),
    pozisyonSayisi: Number(doc.pozisyonSayisi || 0),
    viewCount: Number(doc.viewCount || 0),
    applicationCount: Number(doc.applicationCount || 0),
    endedAt: Number(doc.endedAt || 0),
    about: String(doc.about || ""),
    dersYeri: Array.isArray(doc.dersYeri) ? doc.dersYeri.map((x) => String(x || "")) : [],
    cinsiyet: String(doc.cinsiyet || ""),
    fiyat: Number(doc.fiyat || 0),
    telefon: doc.telefon === true,
    whatsapp: doc.whatsapp === true,
    averageRating: Number(doc.averageRating || 0),
    reviewCount: Number(doc.reviewCount || 0),
    categoryKey: String(doc.categoryKey || ""),
    anaBaslik: String(doc.anaBaslik || ""),
    baslik2: String(doc.baslik2 || ""),
    baslik3: String(doc.baslik3 || ""),
    dil: String(doc.dil || ""),
    ders: String(doc.ders || ""),
    sinavTuru: String(doc.sinavTuru || ""),
    soruNo: String(doc.soruNo || ""),
    yil: String(doc.yil || ""),
    seq: Number(doc.seq || 0),
    correctCount: Number(doc.correctCount || 0),
    wrongCount: Number(doc.wrongCount || 0),
    soru: String(doc.soru || ""),
    dogruCevap: String(doc.dogruCevap || ""),
    kacCevap: Number(doc.kacCevap || 0),
    diger1: String(doc.diger1 || ""),
    diger2: doc.diger2 === true,
    diger3: Number(doc.diger3 || 0),
    score: Number(hit.text_match || 0),
  };
}

async function searchFromCollection(
  entity: EducationEntity,
  qRaw: string,
  limit: number,
  page: number,
  filterByRaw = "",
  sortByRaw = ""
): Promise<TypesenseCollectionSearchResult> {
  const baseUrl = getTypesenseBaseUrl();
  const q = qRaw.trim().length === 0 ? "*" : qRaw.trim();
  const collection = getCollectionName(entity);
  await ensureEntityCollection(entity);

  const queryBy = (() => {
    switch (entity) {
      case "workout":
        return "title,subtitle,description,tags,detailsText,anaBaslik,sinavTuru,ders,soruNo,yil";
      case "past_question":
        return "title,subtitle,description,tags,detailsText,anaBaslik,sinavTuru,baslik2,baslik3,yil,dil";
      case "tutoring":
        return "title,subtitle,description,aciklama,tags,city,town,country,detailsText,nickname,displayName,cinsiyet,dersYeri";
      case "job":
        return "title,subtitle,description,aciklama,tags,city,town,country,detailsText,nickname,displayName,meslek,ilanBasligi,brand";
      default:
        return "title,subtitle,description,aciklama,tags,city,town,country,detailsText,nickname,displayName";
    }
  })();
  const filterBy = filterByRaw.trim();
  const sortBy = sortByRaw.trim();

  const response = await axios.get(`${baseUrl}/collections/${collection}/documents/search`, {
    headers: headers(),
    timeout: 12000,
    params: {
      q,
      query_by: queryBy,
      per_page: limit,
      page,
      sort_by: sortBy || "timeStamp:desc",
      filter_by: filterBy || "active:=true",
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
  entity?: EducationEntity,
  filterBy = "",
  sortBy = ""
) {
  const q = qRaw.trim().length === 0 ? "*" : qRaw.trim();

  if (entity) {
    const one = await searchFromCollection(entity, qRaw, limit, page, filterBy, sortBy);
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
    EDUCATION_ENTITIES.map((e) => searchFromCollection(e, qRaw, perCollectionLimit, page, filterBy, sortBy))
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
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("scholarship", docId, beforeData, afterData);
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
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("practice_exam", docId, beforeData, afterData);
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
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("answer_key", docId, beforeData, afterData);
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
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("tutoring", docId, beforeData, afterData);
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
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("job", docId, beforeData, afterData);
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
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("workout", docId, beforeData, afterData);
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
    ensureAdmin();
    if (!typesenseReady()) return;
    const docId = String(event.params.docId || "");
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;
    await syncEducationDoc("past_question", docId, beforeData, afterData);
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
    invoker: "public",
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<SearchEducationInput>) => {
    RateLimits.general(resolveRateLimitSubject(request));
    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const q = String(request.data?.q || "");
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    const filterBy = String(request.data?.filterBy || "").trim();
    const sortBy = String(request.data?.sortBy || "").trim();
    const entityRaw = request.data?.entity;
    const entity = isEducationEntity(entityRaw) ? entityRaw : undefined;

    try {
      return await searchEducationFromTypesense(q, limit, page, entity, filterBy, sortBy);
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
        const doc = await buildSearchDocForIndexing(entity, rawDocId, data);

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
