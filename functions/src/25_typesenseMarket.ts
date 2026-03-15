import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldPath, getFirestore, Query } from "firebase-admin/firestore";
import axios, { AxiosError } from "axios";
import { RateLimits } from "./rateLimiter";

const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const COLLECTION = "market_search_v3";
const MAX_LIMIT = 100;
const MAX_FLATTEN_DEPTH = 4;
const MAX_FLATTEN_VALUES = 200;
const MAX_TEXT_LEN = 12000;

type MarketSearchDoc = {
  id: string;
  docId: string;
  title: string;
  description: string;
  categoryKey: string;
  categoryPath: string[];
  city: string;
  district: string;
  locationText: string;
  sellerName: string;
  cover: string;
  price: number;
  currency: string;
  publishedAt: number;
  createdAt: number;
  active: boolean;
  contactPreference: string;
  status: string;
  attributesText: string;
  searchText: string;
};

type SearchMarketInput = {
  q?: string;
  limit?: number;
  page?: number;
  categoryKey?: string;
  city?: string;
  district?: string;
};

type ReindexMarketInput = {
  limit?: number;
  cursor?: string;
  dryRun?: boolean;
};

type ReindexMarketOutput = {
  scanned: number;
  upserted: number;
  deleted: number;
  skipped: number;
  nextCursor: string | null;
  done: boolean;
};

type TypesenseMarketHitOutput = {
  id: string;
  docId: string;
  title: string;
  description: string;
  categoryKey: string;
  categoryPath: string[];
  city: string;
  district: string;
  locationText: string;
  sellerName: string;
  cover: string;
  price: number;
  currency: string;
  publishedAt: number;
  createdAt: number;
  active: boolean;
  status: string;
  score: number;
};

type TypesenseMarketSearchResult = {
  hits: TypesenseMarketHitOutput[];
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

function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const out = new Set<string>();
  for (const item of value) {
    const clean = String(item ?? "").trim();
    if (clean) out.add(clean);
  }
  return Array.from(out);
}

function firstString(value: unknown): string {
  return asStringArray(value)[0] || "";
}

function asNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

function asEpochMillis(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value > 1e12 ? Math.floor(value) : Math.floor(value * 1000);
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed > 1e12 ? Math.floor(parsed) : Math.floor(parsed * 1000);
    }
  }
  if (typeof value === "object" && value !== null) {
    const maybe = value as {
      seconds?: number;
      _seconds?: number;
      toMillis?: () => number;
    };
    if (typeof maybe.toMillis === "function") {
      const millis = maybe.toMillis();
      if (Number.isFinite(millis)) return Math.floor(millis);
    }
    if (typeof maybe.seconds === "number") return Math.floor(maybe.seconds * 1000);
    if (typeof maybe._seconds === "number") return Math.floor(maybe._seconds * 1000);
  }
  return 0;
}

function truncateText(value: string, maxLen: number): string {
  return value.length <= maxLen ? value : value.slice(0, maxLen);
}

function dedupe(values: string[]): string[] {
  const out = new Set<string>();
  for (const value of values) {
    const clean = value.trim();
    if (clean) out.add(clean);
  }
  return Array.from(out);
}

function normalizeSlugText(value: string): string {
  return value.replace(/[\/_-]+/g, " ").replace(/\s+/g, " ").trim();
}

function flattenForText(value: unknown, out: string[], depth = 0) {
  if (depth > MAX_FLATTEN_DEPTH || out.length >= MAX_FLATTEN_VALUES) return;
  if (value === null || value === undefined) return;

  if (typeof value === "string") {
    const clean = value.trim();
    if (clean) out.push(clean);
    return;
  }

  if (typeof value === "number" || typeof value === "boolean") {
    out.push(String(value));
    return;
  }

  if (Array.isArray(value)) {
    for (const item of value.slice(0, 20)) {
      flattenForText(item, out, depth + 1);
      if (out.length >= MAX_FLATTEN_VALUES) return;
    }
    return;
  }

  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>).slice(0, 80);
    for (const [key, nested] of entries) {
      const cleanKey = key.trim();
      if (cleanKey) out.push(cleanKey);
      flattenForText(nested, out, depth + 1);
      if (out.length >= MAX_FLATTEN_VALUES) return;
    }
  }
}

function buildAttributesText(value: unknown): string {
  const flattened: string[] = [];
  flattenForText(value, flattened);
  return truncateText(dedupe(flattened).join(" "), 8000);
}

function joinSearchText(parts: Array<string | string[]>): string {
  const merged = dedupe(
    parts
      .flatMap((part) => Array.isArray(part) ? part : [part])
      .map((part) => part.trim())
      .filter((part) => part.length > 0)
  );
  return truncateText(merged.join(" "), MAX_TEXT_LEN);
}

function isActiveMarketDoc(data: Record<string, unknown>): boolean {
  const status = asString(data.status).toLowerCase();
  return status === "active";
}

function requiredFields() {
  return [
    { name: "docId", type: "string", optional: true },
    { name: "title", type: "string", optional: true },
    { name: "description", type: "string", optional: true },
    { name: "categoryKey", type: "string", optional: true },
    { name: "categoryPath", type: "string[]", optional: true },
    { name: "city", type: "string", optional: true },
    { name: "district", type: "string", optional: true },
    { name: "locationText", type: "string", optional: true },
    { name: "sellerName", type: "string", optional: true },
    { name: "cover", type: "string", optional: true },
    { name: "price", type: "float", optional: true },
    { name: "currency", type: "string", optional: true },
    { name: "publishedAt", type: "int64", optional: false },
    { name: "createdAt", type: "int64", optional: false },
    { name: "active", type: "bool", optional: true },
    { name: "contactPreference", type: "string", optional: true },
    { name: "status", type: "string", optional: true },
    { name: "attributesText", type: "string", optional: true },
    { name: "searchText", type: "string", optional: true },
  ];
}

let ensureCollectionPromise: Promise<void> | undefined;

async function ensureMarketCollection() {
  if (ensureCollectionPromise) return ensureCollectionPromise;

  ensureCollectionPromise = (async () => {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl) return;

    try {
      const existing = await axios.get(`${baseUrl}/collections/${COLLECTION}`, {
        headers: headers(),
        timeout: 8000,
      });
      const fields: Array<{ name?: string }> = Array.isArray(existing.data?.fields)
        ? (existing.data.fields as Array<{ name?: string }>)
        : [];
      const missing = requiredFields().filter((field) => !fields.some((current) => current?.name === field.name));
      if (missing.length > 0) {
        await axios.patch(
          `${baseUrl}/collections/${COLLECTION}`,
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
        name: COLLECTION,
        fields: requiredFields(),
        default_sorting_field: "publishedAt",
      },
      { headers: headers(), timeout: 8000 }
    );
  })().catch((err) => {
    ensureCollectionPromise = undefined;
    throw err;
  });

  return ensureCollectionPromise;
}

async function upsertDoc(doc: MarketSearchDoc) {
  const baseUrl = getTypesenseBaseUrl();
  if (!baseUrl) return;
  await ensureMarketCollection();
  await axios.post(
    `${baseUrl}/collections/${COLLECTION}/documents?action=upsert`,
    doc,
    { headers: headers(), timeout: 12000 }
  );
}

async function deleteDoc(docId: string) {
  const baseUrl = getTypesenseBaseUrl();
  if (!baseUrl) return;
  await ensureMarketCollection();
  try {
    await axios.delete(
      `${baseUrl}/collections/${COLLECTION}/documents/${encodeURIComponent(docId)}`,
      { headers: headers(), timeout: 12000 }
    );
  } catch (err) {
    const status = (err as AxiosError)?.response?.status;
    if (status === 404) return;
    throw err;
  }
}

function buildSearchDoc(docId: string, data: Record<string, unknown>): MarketSearchDoc {
  const seller = (data.seller && typeof data.seller === "object")
    ? (data.seller as Record<string, unknown>)
    : {};
  const categoryPath = asStringArray(data.categoryPath);
  const categoryKey = asString(data.categoryKey);
  const attributesText = buildAttributesText(data.attributes);
  const createdAt = asEpochMillis(data.createdAt) || Date.now();
  const publishedAt = asEpochMillis(data.publishedAt) || createdAt;
  const title = asString(data.title);
  const description = asString(data.description);
  const city = asString(data.city);
  const district = asString(data.district);
  const locationText = asString(data.locationText);
  const sellerName = asString(seller.name) || asString(data.sellerName);
  const cover = asString(data.coverImageUrl) || firstString(data.imageUrls);
  const status = asString(data.status) || "draft";

  return {
    id: docId,
    docId,
    title,
    description,
    categoryKey,
    categoryPath,
    city,
    district,
    locationText,
    sellerName,
    cover,
    price: Math.max(0, asNumber(data.price)),
    currency: asString(data.currency) || "TRY",
    publishedAt,
    createdAt,
    active: isActiveMarketDoc(data),
    contactPreference: asString(data.contactPreference) || "message_only",
    status,
    attributesText,
    searchText: joinSearchText([
      title,
      description,
      normalizeSlugText(categoryKey),
      categoryPath,
      city,
      district,
      locationText,
      sellerName,
      attributesText,
    ]),
  };
}

function shouldIndex(doc: MarketSearchDoc): boolean {
  return doc.active && doc.title.trim().length > 0;
}

async function syncMarketDoc(docId: string, afterData?: Record<string, unknown>) {
  if (!afterData) {
    await deleteDoc(docId);
    return;
  }

  const doc = buildSearchDoc(docId, afterData);
  if (!shouldIndex(doc)) {
    await deleteDoc(docId);
    return;
  }

  await upsertDoc(doc);
}

function quoteFilterValue(value: string): string {
  return `\`${value.replace(/`/g, "\\`")}\``;
}

function buildFilterBy(input: SearchMarketInput): string {
  const filters = ["active:=true"];
  const categoryKey = asString(input.categoryKey);
  const city = asString(input.city);
  const district = asString(input.district);

  if (categoryKey) filters.push(`categoryKey:=${quoteFilterValue(categoryKey)}`);
  if (city) filters.push(`city:=${quoteFilterValue(city)}`);
  if (district) filters.push(`district:=${quoteFilterValue(district)}`);

  return filters.join(" && ");
}

function toHitOutput(hitRaw: unknown): TypesenseMarketHitOutput {
  const hit = (hitRaw && typeof hitRaw === "object")
    ? (hitRaw as { document?: Record<string, unknown>; text_match?: number })
    : {};
  const doc = (hit.document && typeof hit.document === "object")
    ? hit.document
    : {};
  return {
    id: String(doc.id || doc.docId || ""),
    docId: String(doc.docId || doc.id || ""),
    title: String(doc.title || ""),
    description: String(doc.description || ""),
    categoryKey: String(doc.categoryKey || ""),
    categoryPath: asStringArray(doc.categoryPath),
    city: String(doc.city || ""),
    district: String(doc.district || ""),
    locationText: String(doc.locationText || ""),
    sellerName: String(doc.sellerName || ""),
    cover: String(doc.cover || ""),
    price: Number(doc.price || 0),
    currency: String(doc.currency || "TRY"),
    publishedAt: Number(doc.publishedAt || 0),
    createdAt: Number(doc.createdAt || 0),
    active: doc.active === true,
    status: String(doc.status || ""),
    score: Number(hit.text_match || 0),
  };
}

async function searchMarketFromTypesense(
  input: SearchMarketInput
): Promise<TypesenseMarketSearchResult> {
  const baseUrl = getTypesenseBaseUrl();
  const q = asString(input.q) || "*";
  const limit = Math.max(1, Math.min(MAX_LIMIT, Number(input.limit || 20)));
  const page = Math.max(1, Number(input.page || 1));
  const queryFields = [
    "title",
    "description",
    "categoryPath",
    "categoryKey",
    "city",
    "district",
    "locationText",
    "sellerName",
    "attributesText",
    "searchText",
  ];

  await ensureMarketCollection();

  const response = await axios.get(`${baseUrl}/collections/${COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 12000,
    params: {
      q,
      query_by: queryFields.join(","),
      per_page: limit,
      page,
      sort_by: q === "*" ? "publishedAt:desc" : "_text_match:desc,publishedAt:desc",
      filter_by: buildFilterBy(input),
      prefix: new Array(queryFields.length).fill("true").join(","),
      num_typos: 2,
      exhaustive_search: true,
    },
  });

  const data = response.data || {};
  const rawHits = Array.isArray(data.hits) ? data.hits : [];
  const hits = rawHits.map((item: unknown) => toHitOutput(item));
  return {
    hits,
    found: Number(data.found || hits.length),
    outOf: Number(data.out_of || hits.length),
    searchTimeMs: Number(data.search_time_ms || 0),
  };
}

function marketQuery(limit: number, cursor: string): Query {
  let query: Query = getFirestore()
    .collection("marketStore")
    .orderBy(FieldPath.documentId())
    .limit(limit);
  if (cursor) query = query.startAfter(cursor);
  return query;
}

export const f25_syncMarketToTypesense = onDocumentWritten(
  {
    document: "marketStore/{docId}",
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
    await syncMarketDoc(docId, afterData);
  }
);

export const f25_ensureMarketTypesenseCollectionCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<Record<string, never>>) => {
    ensureAdmin();
    requireAdminAuth(request);
    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    await ensureMarketCollection();
    return {
      ok: true,
      collection: COLLECTION,
    };
  }
);

export const f25_searchMarketCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<SearchMarketInput>) => {
    const uid = requireAuth(request);
    RateLimits.general(uid);
    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    try {
      const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
      const page = Math.max(1, Number(request.data?.page || 1));
      const result = await searchMarketFromTypesense({
        q: request.data?.q,
        limit,
        page,
        categoryKey: request.data?.categoryKey,
        city: request.data?.city,
        district: request.data?.district,
      });

      return {
        q: asString(request.data?.q) || "*",
        page,
        limit,
        found: result.found,
        out_of: result.outOf,
        search_time_ms: result.searchTimeMs,
        hits: result.hits,
      };
    } catch (err: unknown) {
      const axiosErr = err as AxiosError;
      const detail = axiosErr?.response?.data || (err as Error)?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f25_reindexMarketToTypesenseCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<ReindexMarketInput>): Promise<ReindexMarketOutput> => {
    ensureAdmin();
    requireAdminAuth(request);
    try {
      if (!typesenseReady()) {
        throw new HttpsError("failed-precondition", "typesense_not_configured");
      }

      const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
      const cursor = String(request.data?.cursor || "").trim();
      const dryRun = request.data?.dryRun === true;

      await ensureMarketCollection();

      const snap = await marketQuery(limit, cursor).get();
      let scanned = 0;
      let upserted = 0;
      let deleted = 0;
      let skipped = 0;

      for (const docSnap of snap.docs) {
        scanned += 1;
        const docId = docSnap.id;
        const data = docSnap.data() as Record<string, unknown>;
        const doc = buildSearchDoc(docId, data);

        if (!shouldIndex(doc)) {
          if (!dryRun) {
            await deleteDoc(docId);
          }
          deleted += 1;
          continue;
        }

        if (!doc.title.trim()) {
          skipped += 1;
          continue;
        }

        if (!dryRun) {
          await upsertDoc(doc);
        }
        upserted += 1;
      }

      const last = snap.docs[snap.docs.length - 1];
      const nextCursor = last ? last.id : null;
      const done = snap.docs.length < limit;

      return {
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
      console.error("f25_reindex_market_failed", {
        detail,
        cursor: request.data?.cursor || null,
      });
      throw new HttpsError("internal", "typesense_reindex_failed", detail);
    }
  }
);
