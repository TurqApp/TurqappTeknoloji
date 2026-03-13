import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldPath, getFirestore } from "firebase-admin/firestore";
import axios, { AxiosError } from "axios";
import { enforceRateLimitForKey, RateLimits } from "./rateLimiter";

const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "posts_search";
const USERS_COLLECTION = "users_search";
const TAGS_COLLECTION = "tags_search";
const MAX_LIMIT = 50;

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

function asString(x: unknown): string {
  return typeof x === "string" ? x : "";
}

function asBool(x: unknown): boolean {
  return x === true;
}

function asStringArray(x: unknown): string[] {
  if (!Array.isArray(x)) return [];
  return x.map((v) => String(v || "").trim()).filter(Boolean);
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

let collectionEnsurePromise: Promise<void> | null = null;
let usersCollectionEnsurePromise: Promise<void> | null = null;
let tagsCollectionEnsurePromise: Promise<void> | null = null;

async function ensurePostsCollection() {
  if (collectionEnsurePromise) return collectionEnsurePromise;

  collectionEnsurePromise = (async () => {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl) return;

    try {
      const existing = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}`, {
        headers: headers(),
        timeout: 8000,
      });
      const fields: Array<{ name?: string }> = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
      const required = [
        { name: "paylasGizliligi", type: "int32", optional: true },
        { name: "arsiv", type: "bool", optional: true },
        { name: "deletedPost", type: "bool", optional: true },
        { name: "gizlendi", type: "bool", optional: true },
        { name: "isUploading", type: "bool", optional: true },
        { name: "hlsStatus", type: "string", optional: true },
        { name: "imageURL", type: "string", optional: true },
        { name: "timeStamp", type: "int64", optional: true },
      ];
      const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
      if (missing.length) {
        await axios.patch(
          `${baseUrl}/collections/${POSTS_COLLECTION}`,
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
        name: POSTS_COLLECTION,
        fields: [
          { name: "id", type: "string" },
          { name: "authorId", type: "string", optional: true },
          { name: "caption", type: "string", optional: true },
          { name: "hashtags", type: "string[]", optional: true },
          { name: "mentions", type: "string[]", optional: true },
          { name: "hlsUrl", type: "string", optional: true },
          { name: "hlsThumbnailUrl", type: "string", optional: true },
          { name: "rawVideoUrl", type: "string", optional: true },
          { name: "imageURL", type: "string", optional: true },
          { name: "previewUrl", type: "string", optional: true },
          { name: "paylasGizliligi", type: "int32", optional: true },
          { name: "arsiv", type: "bool", optional: true },
          { name: "deletedPost", type: "bool", optional: true },
          { name: "gizlendi", type: "bool", optional: true },
          { name: "isUploading", type: "bool", optional: true },
          { name: "hlsStatus", type: "string", optional: true },
          { name: "timeStamp", type: "int64", optional: true },
        ],
        default_sorting_field: "timeStamp",
      },
      {
        headers: headers(),
        timeout: 8000,
      }
    );
  })().catch((err) => {
    collectionEnsurePromise = null;
    throw err;
  });

  return collectionEnsurePromise;
}

async function ensureUsersCollection() {
  if (usersCollectionEnsurePromise) return usersCollectionEnsurePromise;

  usersCollectionEnsurePromise = (async () => {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl) return;

    try {
      const existing = await axios.get(`${baseUrl}/collections/${USERS_COLLECTION}`, {
        headers: headers(),
        timeout: 8000,
      });
      const fields: Array<{ name?: string }> = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
      const required = [
        { name: "nickname", type: "string", optional: true },
        { name: "firstName", type: "string", optional: true },
        { name: "lastName", type: "string", optional: true },
        { name: "avatarUrl", type: "string", optional: true },
        { name: "rozet", type: "string", optional: true },
        { name: "isPrivate", type: "bool", optional: true },
        { name: "isDeleted", type: "bool", optional: true },
        { name: "isApproved", type: "bool", optional: true },
      ];
      const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
      if (missing.length) {
        await axios.patch(
          `${baseUrl}/collections/${USERS_COLLECTION}`,
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
        name: USERS_COLLECTION,
        fields: [
          { name: "id", type: "string" },
          { name: "nickname", type: "string", optional: true },
          { name: "firstName", type: "string", optional: true },
          { name: "lastName", type: "string", optional: true },
          { name: "avatarUrl", type: "string", optional: true },
          { name: "rozet", type: "string", optional: true },
          { name: "isPrivate", type: "bool", optional: true },
          { name: "isDeleted", type: "bool", optional: true },
          { name: "isApproved", type: "bool", optional: true },
          { name: "updatedAtTs", type: "int32" },
        ],
        default_sorting_field: "updatedAtTs",
      },
      {
        headers: headers(),
        timeout: 8000,
      }
    );
  })().catch((err) => {
    usersCollectionEnsurePromise = null;
    throw err;
  });

  return usersCollectionEnsurePromise;
}

async function ensureTagsCollection() {
  if (tagsCollectionEnsurePromise) return tagsCollectionEnsurePromise;

  tagsCollectionEnsurePromise = (async () => {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl) return;

    try {
      const existing = await axios.get(`${baseUrl}/collections/${TAGS_COLLECTION}`, {
        headers: headers(),
        timeout: 8000,
      });
      const fields: Array<{ name?: string }> = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
      const required = [
        { name: "count", type: "int32", optional: true },
        { name: "lastSeenTs", type: "int64", optional: true },
        { name: "hasHashtag", type: "bool", optional: true },
        { name: "hashtagCount", type: "int32", optional: true },
        { name: "plainCount", type: "int32", optional: true },
      ];
      const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
      if (missing.length) {
        await axios.patch(
          `${baseUrl}/collections/${TAGS_COLLECTION}`,
          {
            fields: missing,
          },
          {
            headers: headers(),
            timeout: 8000,
          }
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
        name: TAGS_COLLECTION,
        fields: [
          { name: "id", type: "string" },
          { name: "tag", type: "string" },
          { name: "authorId", type: "string", optional: true },
          { name: "count", type: "int32", optional: true },
          { name: "lastSeenTs", type: "int64", optional: true },
          { name: "hasHashtag", type: "bool", optional: true },
          { name: "hashtagCount", type: "int32", optional: true },
          { name: "plainCount", type: "int32", optional: true },
          { name: "createdAtTs", type: "int64" },
        ],
        default_sorting_field: "createdAtTs",
      },
      {
        headers: headers(),
        timeout: 8000,
      }
    );
  })().catch((err) => {
    tagsCollectionEnsurePromise = null;
    throw err;
  });

  return tagsCollectionEnsurePromise;
}

type PostSearchDoc = {
  id: string;
  authorId: string;
  caption: string;
  hashtags: string[];
  mentions: string[];
  hlsUrl: string;
  hlsThumbnailUrl: string;
  rawVideoUrl: string;
  imageURL: string;
  previewUrl: string;
  paylasGizliligi: number;
  arsiv: boolean;
  deletedPost: boolean;
  gizlendi: boolean;
  isUploading: boolean;
  hlsStatus: string;
  timeStamp: number;
  createdAtTs: number;
};

function buildSearchDoc(postId: string, data: Record<string, unknown>): PostSearchDoc {
  const analysis = (data.analysis as Record<string, unknown> | undefined) || {};
  const paylas = Number((data as any).paylasGizliligi);
  const paylasGizliligi = Number.isFinite(paylas) ? paylas : 0;
  const deletedPost = asBool((data as any).deletedPost) || asBool(data.isDeleted);
  const arsiv = asBool((data as any).arsiv) || asBool((data as any).isArchived);
  const gizlendi = asBool((data as any).gizlendi) || asBool((data as any).isHidden);
  const isUploading = asBool((data as any).isUploading);
  const caption = asString((data as any).metin) || asString(data.caption);
  const imgList = Array.isArray((data as any).img) ? (data as any).img : [];
  const firstImg = imgList.length ? String(imgList[0] || "") : "";
  const hlsMasterUrl = asString((data as any).hlsMasterUrl) || asString(data.hlsUrl);
  const thumbnailUrl = asString((data as any).thumbnail) || asString(data.hlsThumbnailUrl);
  const rawVideoUrl = asString(data.rawVideoUrl) || asString((data as any).video);
  const hlsStatusRaw = asString((data as any).hlsStatus).toLowerCase();
  const hlsStatus = hlsStatusRaw || (asBool(data.hlsReady) ? "ready" : "none");
  const timeStamp =
    Number((data as any).timeStamp || 0) ||
    asEpochMillis(data.createdAt) ||
    Date.now();
  const createdAtTs = timeStamp;

  return {
    id: postId,
    authorId: asString(data.authorId) || asString((data as any).userID),
    caption,
    hashtags: asStringArray(analysis.hashtags),
    mentions: asStringArray(analysis.mentions),
    hlsUrl: hlsMasterUrl,
    hlsThumbnailUrl: thumbnailUrl,
    rawVideoUrl,
    imageURL: asString(data.imageURL) || firstImg,
    previewUrl:
      thumbnailUrl ||
      asString(data.imageURL) ||
      firstImg ||
      asString((Array.isArray(data.images) ? data.images[0] : "")) ||
      "",
    paylasGizliligi,
    arsiv,
    deletedPost,
    gizlendi,
    isUploading,
    hlsStatus,
    timeStamp,
    createdAtTs,
  };
}

function shouldIndex(doc: PostSearchDoc): boolean {
  return true;
}

async function upsertDoc(doc: PostSearchDoc) {
  await ensurePostsCollection();
  const baseUrl = getTypesenseBaseUrl();
  await axios.post(
    `${baseUrl}/collections/${POSTS_COLLECTION}/documents?action=upsert`,
    doc,
    {
      headers: headers(),
      timeout: 8000,
    }
  );
}

async function deleteDoc(postId: string) {
  await ensurePostsCollection();
  const baseUrl = getTypesenseBaseUrl();
  try {
    await axios.delete(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/${encodeURIComponent(postId)}`, {
      headers: headers(),
      timeout: 8000,
    });
  } catch (err) {
    const status = (err as AxiosError)?.response?.status;
    if (status !== 404) throw err;
  }
}

type UserSearchDoc = {
  id: string;
  nickname: string;
  firstName: string;
  lastName: string;
  avatarUrl: string;
  rozet: string;
  isPrivate: boolean;
  isDeleted: boolean;
  isApproved: boolean;
  updatedAtTs: number;
};

function buildUserSearchDoc(userId: string, data: Record<string, unknown>): UserSearchDoc {
  const createdDateRaw = Number((data as any).createdDate || 0);
  const createdDateTs = Number.isFinite(createdDateRaw) && createdDateRaw > 0
    ? Math.floor(createdDateRaw / 1000)
    : 0;
  const accountStatus = asString((data as any).accountStatus).toLowerCase();
  const isPendingOrDeleted = accountStatus === "pending_deletion" || accountStatus === "deleted";
  return {
    id: userId,
    nickname: asString(data.nickname) || asString((data as any).username),
    firstName: asString(data.firstName),
    lastName: asString(data.lastName),
    avatarUrl: asString((data as any).avatarUrl),
    rozet: asString((data as any).rozet),
    isPrivate: asBool((data as any).isPrivate),
    isDeleted:
      asBool((data as any).isDeleted) ||
      isPendingOrDeleted,
    isApproved: asBool((data as any).isApproved) || asBool((data as any).isVerified),
    updatedAtTs:
      asEpochSeconds(data.updatedAt) ||
      asEpochSeconds(data.createdAt) ||
      createdDateTs ||
      Math.floor(Date.now() / 1000),
  };
}

function shouldIndexUser(doc: UserSearchDoc): boolean {
  return true;
}

type TagAggregateDoc = {
  id: string;
  tag: string;
  count: number;
  lastSeenTs: number;
  hasHashtag: boolean;
  hashtagCount: number;
  plainCount: number;
  createdAtTs: number;
};

function normalizeTag(raw: string): string {
  const t = String(raw || "").trim().toLocaleLowerCase("tr-TR");
  if (!t) return "";
  return t.startsWith("#") ? t.slice(1) : t;
}

function buildTagAggregateDoc(tagId: string, data: Record<string, unknown>): TagAggregateDoc {
  const tag = normalizeTag(asString(data.name) || tagId);
  const count = Math.max(0, Number(data.count || 0) || 0);
  const lastSeenTs = asEpochMillis(data.lastSeenAt) || Date.now();
  const hashtagCount = Math.max(0, Number(data.hashtagCount || 0) || 0);
  const plainCount = Math.max(0, Number(data.plainCount || 0) || Math.max(0, count - hashtagCount));

  return {
    id: `agg__${tag}`,
    tag,
    count,
    lastSeenTs,
    hasHashtag: hashtagCount > 0 || data.hasHashtag === true,
    hashtagCount,
    plainCount,
    createdAtTs: lastSeenTs,
  };
}

async function upsertTagAggregateDoc(doc: TagAggregateDoc) {
  await ensureTagsCollection();
  const baseUrl = getTypesenseBaseUrl();
  await axios.post(
    `${baseUrl}/collections/${TAGS_COLLECTION}/documents?action=upsert`,
    doc,
    {
      headers: headers(),
      timeout: 8000,
    }
  );
}

async function deleteTagAggregateDoc(tagId: string, rawName?: string) {
  await ensureTagsCollection();
  const baseUrl = getTypesenseBaseUrl();
  const normalized = normalizeTag(rawName || tagId);
  if (!normalized) return;
  try {
    await axios.delete(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/${encodeURIComponent(`agg__${normalized}`)}`, {
      headers: headers(),
      timeout: 8000,
    });
  } catch (err) {
    const status = (err as AxiosError)?.response?.status;
    if (status !== 404) throw err;
  }
}

async function upsertUserDoc(doc: UserSearchDoc) {
  await ensureUsersCollection();
  const baseUrl = getTypesenseBaseUrl();
  try {
    await axios.post(
      `${baseUrl}/collections/${USERS_COLLECTION}/documents?action=upsert`,
      doc,
      {
        headers: headers(),
        timeout: 8000,
      }
    );
  } catch (err: any) {
    console.error("typesense_upsert_user_failed", err?.response?.status, err?.response?.data || err?.message);
    throw err;
  }
}

async function deleteUserDoc(userId: string) {
  await ensureUsersCollection();
  const baseUrl = getTypesenseBaseUrl();
  try {
    await axios.delete(`${baseUrl}/collections/${USERS_COLLECTION}/documents/${encodeURIComponent(userId)}`, {
      headers: headers(),
      timeout: 8000,
    });
  } catch (err) {
    const status = (err as AxiosError)?.response?.status;
    if (status !== 404) throw err;
  }
}

async function searchPostsFromTypesense(q: string, limit: number, page: number) {
  await ensurePostsCollection();

  const baseUrl = getTypesenseBaseUrl();
  const resp = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q,
      query_by: "caption,hashtags,mentions",
      per_page: limit,
      page,
      sort_by: "timeStamp:desc",
      filter_by: "paylasGizliligi:=0 && arsiv:=false && deletedPost:=false && gizlendi:=false && isUploading:=false",
      prefix: "true,true,true",
      typo_tokens_threshold: 1,
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];

  return {
    q,
    page,
    limit,
    found: Number(body.found || 0),
    out_of: Number(body.out_of || 0),
    search_time_ms: Number(body.search_time_ms || 0),
    hits: hits.map((h: any) => ({
      id: h?.document?.id,
      authorId: h?.document?.authorId,
      caption: h?.document?.caption,
      hashtags: h?.document?.hashtags || [],
      mentions: h?.document?.mentions || [],
      hlsUrl: h?.document?.hlsUrl || "",
      hlsThumbnailUrl: h?.document?.hlsThumbnailUrl || "",
      rawVideoUrl: h?.document?.rawVideoUrl || "",
      imageURL: h?.document?.imageURL || "",
      previewUrl: h?.document?.previewUrl || "",
      timeStamp: h?.document?.timeStamp || 0,
      text_match: h?.text_match || 0,
    })),
  };
}

async function searchUsersFromTypesense(q: string, limit: number, page: number) {
  await ensureUsersCollection();

  const baseUrl = getTypesenseBaseUrl();
  const resp = await axios.get(`${baseUrl}/collections/${USERS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q,
      query_by: "nickname,firstName,lastName",
      per_page: limit,
      page,
      sort_by: "updatedAtTs:desc",
      filter_by: "isDeleted:=false && isPrivate:=false",
      prefix: "true,true,true",
      typo_tokens_threshold: 1,
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];

  return {
    q,
    page,
    limit,
    found: Number(body.found || 0),
    out_of: Number(body.out_of || 0),
    search_time_ms: Number(body.search_time_ms || 0),
    hits: hits
      .filter((h: any) => h?.document?.isDeleted !== true && h?.document?.isPrivate !== true)
      .map((h: any) => ({
        id: h?.document?.id,
        nickname: h?.document?.nickname || "",
        firstName: h?.document?.firstName || "",
        lastName: h?.document?.lastName || "",
        avatarUrl: h?.document?.avatarUrl || "",
        rozet: h?.document?.rozet || "",
        isPrivate: h?.document?.isPrivate === true,
        isDeleted: h?.document?.isDeleted === true,
        isApproved: h?.document?.isApproved === true,
        text_match: h?.text_match || 0,
      })),
  };
}

async function searchTagsFromTypesense(q: string, limit: number, page: number) {
  await ensureTagsCollection();
  const baseUrl = getTypesenseBaseUrl();
  const normalizedQuery = String(q || "").trim().toLocaleLowerCase("tr-TR").replace(/^#/, "");
  const perPage = Math.max(20, Math.min(250, limit));
  const resp = await axios.get(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q: normalizedQuery,
      query_by: "tag",
      per_page: perPage,
      page,
      prefix: "true",
      sort_by: "count:desc,lastSeenTs:desc",
      filter_by: "count:>=1",
      typo_tokens_threshold: 1,
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];
  type TagSearchHit = { tag: string; count: number; lastSeenTs: number; hasHashtag: boolean };
  const tags = hits
    .map((h: any) => {
      const tag = String(h?.document?.tag || "").trim().toLocaleLowerCase("tr-TR");
      const count = Math.max(0, Number(h?.document?.count || 0) || 0);
      const lastSeenTs = Math.max(0, Number(h?.document?.lastSeenTs || 0) || 0);
      const hashtagCount = Math.max(0, Number(h?.document?.hashtagCount || 0) || 0);
      const hasHashtag = h?.document?.hasHashtag === true || hashtagCount > 0;
      return { tag, count, lastSeenTs, hasHashtag };
    })
    .filter((item: TagSearchHit) => !!item.tag)
    .filter((item: TagSearchHit) => !normalizedQuery || item.tag.startsWith(normalizedQuery))
    .sort((a: TagSearchHit, b: TagSearchHit) => {
      if (a.hasHashtag !== b.hasHashtag) return a.hasHashtag ? -1 : 1;
      if (b.count !== a.count) return b.count - a.count;
      return b.lastSeenTs - a.lastSeenTs;
    })
    .slice(0, limit)
    .map(({ tag, count, hasHashtag, lastSeenTs }: TagSearchHit) => ({ tag, count, hasHashtag, lastSeenTs }));

  return {
    q,
    page,
    limit,
    found: Number(body.found || tags.length),
    out_of: Number(body.out_of || tags.length),
    search_time_ms: Number(body.search_time_ms || 0),
    hits: tags,
  };
}

async function getTrendingTagsFromTypesense(
  limit: number,
  windowHours: number,
  trendThreshold: number,
  tagMinLength: number,
  tagMaxLength: number
) {
  await ensureTagsCollection();
  const baseUrl = getTypesenseBaseUrl();
  const nowTs = Date.now();
  const safeWindowHours = Math.max(1, Math.min(24 * 14, windowHours));
  const cutoffTs = nowTs - safeWindowHours * 3600 * 1000;
  const perPage = Math.max(100, Math.min(500, limit * 12));
  const safeThreshold = Math.max(1, trendThreshold);
  const safeMinLength = Math.max(1, tagMinLength);
  const safeMaxLength = Math.max(safeMinLength, tagMaxLength);

  const resp = await axios.get(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q: "*",
      query_by: "tag",
      per_page: perPage,
      page: 1,
      sort_by: "count:desc,lastSeenTs:desc",
      filter_by: `count:>=${safeThreshold} && lastSeenTs:>=${cutoffTs}`,
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];
  type TrendingHit = {
    tag: string;
    count: number;
    hasHashtag: boolean;
    lastSeenTs: number;
    hashtagCount: number;
    plainCount: number;
  };
  const tags = hits
    .map((h: any): TrendingHit => ({
      tag: String(h?.document?.tag || "").trim().toLocaleLowerCase("tr-TR"),
      count: Math.max(0, Number(h?.document?.count || 0) || 0),
      hasHashtag:
        h?.document?.hasHashtag === true ||
        Math.max(0, Number(h?.document?.hashtagCount || 0) || 0) > 0,
      lastSeenTs: Math.max(0, Number(h?.document?.lastSeenTs || 0) || 0),
      hashtagCount: Math.max(0, Number(h?.document?.hashtagCount || 0) || 0),
      plainCount: Math.max(0, Number(h?.document?.plainCount || 0) || 0),
    }))
    .filter((item: TrendingHit) => !!item.tag)
    .filter((item: TrendingHit) =>
      item.count >= safeThreshold &&
      item.tag.length >= safeMinLength &&
      item.tag.length <= safeMaxLength &&
      item.lastSeenTs >= cutoffTs
    )
    .sort((a: TrendingHit, b: TrendingHit) => {
      if (a.hasHashtag !== b.hasHashtag) return a.hasHashtag ? -1 : 1;
      if (b.count !== a.count) return b.count - a.count;
      return b.lastSeenTs - a.lastSeenTs;
    })
    .slice(0, limit);

  return {
    limit,
    window_hours: safeWindowHours,
    trend_threshold: safeThreshold,
    tag_min_length: safeMinLength,
    tag_max_length: safeMaxLength,
    found: tags.length,
    out_of: Number(body.found || hits.length),
    search_time_ms: Number(body.search_time_ms || 0),
    hits: tags,
  };
}

const f14_syncPostsToTypesense = onDocumentWritten(
  {
    document: "Posts/{postId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();

    if (!typesenseReady()) {
      console.log("Typesense env missing, skipping sync.");
      return;
    }

    const postId = event.params.postId;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;

    if (!afterData) {
      await deleteDoc(postId);
      return;
    }

    const doc = buildSearchDoc(postId, afterData);
    if (!shouldIndex(doc)) {
      await deleteDoc(postId);
      return;
    }

    await upsertDoc(doc);
  }
);

export const f15_syncTagsToTypesense = onDocumentWritten(
  {
    document: "tags/{tagId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();

    if (!typesenseReady()) {
      console.log("Typesense env missing, skipping tag sync.");
      return;
    }

    const tagId = String(event.params.tagId || "").trim();
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;

    if (!afterData) {
      await deleteTagAggregateDoc(tagId, asString(beforeData?.name));
      return;
    }

    const doc = buildTagAggregateDoc(tagId, afterData);
    if (!doc.tag) return;
    await upsertTagAggregateDoc(doc);
  }
);

export const f14_syncUsersToTypesense = onDocumentWritten(
  {
    document: "users/{userId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (event) => {
    ensureAdmin();

    if (!typesenseReady()) {
      console.log("Typesense env missing, skipping user sync.");
      return;
    }

    const userId = event.params.userId;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;

    if (!afterData) {
      await deleteUserDoc(userId);
      return;
    }

    const doc = buildUserSearchDoc(userId, afterData);
    if (!shouldIndexUser(doc)) {
      await deleteUserDoc(userId);
      return;
    }

    await upsertUserDoc(doc);
  }
);

const f14_searchPosts = onRequest(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "GET") {
      res.status(405).json({ error: "method_not_allowed" });
      return;
    }

    const rateKey = String(req.headers["cf-connecting-ip"] || req.ip || "unknown");
    enforceRateLimitForKey(rateKey, "typesense_http_search", 240, 60);

    if (!typesenseReady()) {
      res.status(503).json({ error: "typesense_not_configured" });
      return;
    }

    const q = String(req.query.q || "").trim();
    if (q.length < 2) {
      res.status(400).json({ error: "query_too_short", minLength: 2 });
      return;
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(req.query.limit || 20)));
    const page = Math.max(1, Number(req.query.page || 1));

    try {
      res.json(await searchPostsFromTypesense(q, limit, page));
    } catch (err: any) {
      const status = err?.response?.status || 500;
      const detail = err?.response?.data || err?.message || "unknown_error";
      res.status(status).json({ error: "typesense_search_failed", detail });
    }
  }
);

const f14_searchPostsCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    const uid = requireAuth(request);
    RateLimits.general(uid);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const q = String(request.data?.q || "").trim();
    if (q.length < 2) {
      throw new HttpsError("invalid-argument", "query_too_short");
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));

    try {
      return await searchPostsFromTypesense(q, limit, page);
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f15_searchUsersCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    const uid = requireAuth(request);
    RateLimits.general(uid);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const q = String(request.data?.q || "").trim();
    if (q.length < 2) {
      throw new HttpsError("invalid-argument", "query_too_short");
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));

    try {
      return await searchUsersFromTypesense(q, limit, page);
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f15_searchTagsCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    const uid = requireAuth(request);
    RateLimits.general(uid);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const q = String(request.data?.q || "").trim().toLocaleLowerCase("tr-TR");
    if (q.length < 1) {
      throw new HttpsError("invalid-argument", "query_too_short");
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));

    try {
      return await searchTagsFromTypesense(q, limit, page);
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f15_getPostIdsByTagCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    const uid = requireAuth(request);
    RateLimits.general(uid);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const rawTag = String(request.data?.tag || request.data?.q || "").trim().toLocaleLowerCase("tr-TR");
    const tag = rawTag.startsWith("#") ? rawTag.slice(1) : rawTag;
    if (tag.length < 1) {
      throw new HttpsError("invalid-argument", "query_too_short");
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));

    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    try {
      const resp = await axios.get(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 10000,
        params: {
          q: "*",
          query_by: "tag",
          per_page: limit,
          page,
          sort_by: "timeStamp:desc",
          filter_by: `tag:=${tag}`,
        },
      });

      const body = resp.data || {};
      const hits = Array.isArray(body.hits) ? body.hits : [];
      const postHits = hits.map((h: any) => ({
        postId: String(h?.document?.postId || ""),
        timeStamp: Number(h?.document?.timeStamp || 0),
      })).filter((x: any) => !!x.postId);

      // Fallback: if tags_search has only aggregate docs for this tag, resolve post ids from posts_search.
      if (postHits.length === 0) {
        const postsResp = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
          headers: headers(),
          timeout: 10000,
          params: {
            q: tag,
            query_by: "hashtags",
            per_page: limit,
            page,
            sort_by: "timeStamp:desc",
            filter_by: "paylasGizliligi:=0 && arsiv:=false && deletedPost:=false && gizlendi:=false && isUploading:=false",
            prefix: "true",
            typo_tokens_threshold: 1,
          },
        });

        const postsBody = postsResp.data || {};
        const postsHits = Array.isArray(postsBody.hits) ? postsBody.hits : [];
        for (const h of postsHits) {
          const postId = String(h?.document?.id || "").trim();
          if (!postId) continue;
          postHits.push({
            postId,
            timeStamp: Number(h?.document?.timeStamp || 0),
          });
        }
      }

      // Shuffle to randomize listing order for the selected tag.
      for (let i = postHits.length - 1; i > 0; i -= 1) {
        const j = Math.floor(Math.random() * (i + 1));
        const tmp = postHits[i];
        postHits[i] = postHits[j];
        postHits[j] = tmp;
      }

      return {
        tag,
        page,
        limit,
        found: Number(body.found || 0),
        out_of: Number(body.out_of || 0),
        search_time_ms: Number(body.search_time_ms || 0),
        hits: postHits,
      };
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f15_getTrendingTagsCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    requireAuth(request);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 30)));
    const db = getFirestore();
    const settingsSnap = await db.collection("adminConfig").doc("tagSettings").get();
    const settings = settingsSnap.data() || {};

    const windowHoursDefault = Number(settings.trendWindowHours || 24);
    const trendThresholdDefault = Number(settings.trendThreshold || 1);
    const tagMinLengthDefault = Number(settings.tagMinLength || 1);
    const tagMaxLengthDefault = Number(settings.tagMaxLength || 64);

    const windowHours = Math.max(1, Math.min(24 * 14, Number(request.data?.windowHours || windowHoursDefault)));
    const trendThreshold = Math.max(1, Number(request.data?.trendThreshold || trendThresholdDefault));
    const tagMinLength = Math.max(1, Number(request.data?.tagMinLength || tagMinLengthDefault));
    const tagMaxLength = Math.max(tagMinLength, Number(request.data?.tagMaxLength || tagMaxLengthDefault));

    try {
      return await getTrendingTagsFromTypesense(limit, windowHours, trendThreshold, tagMinLength, tagMaxLength);
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

// New numbered names (15_*).
export const f15_syncUsersToTypesense = f14_syncUsersToTypesense;

type ReindexUsersInput = {
  limit?: number;
  cursor?: string;
  dryRun?: boolean;
};

type ReindexUsersOutput = {
  scanned: number;
  upserted: number;
  skipped: number;
  nextCursor: string | null;
  done: boolean;
};

export const f15_reindexUsersToTypesenseCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<ReindexUsersInput>): Promise<ReindexUsersOutput> => {
    ensureAdmin();
    requireAdminAuth(request);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
    const cursor = String(request.data?.cursor || "").trim();
    const dryRun = request.data?.dryRun === true;

    const db = getFirestore();
    let q = db.collection("users").orderBy(FieldPath.documentId()).limit(limit);
    if (cursor) q = q.startAfter(cursor);

    const snap = await q.get();
    let scanned = 0;
    let upserted = 0;
    let skipped = 0;

    for (const docSnap of snap.docs) {
      scanned += 1;
      const doc = buildUserSearchDoc(docSnap.id, docSnap.data() as Record<string, unknown>);
      if (!shouldIndexUser(doc)) {
        skipped += 1;
        continue;
      }
      if (!dryRun) {
        await upsertUserDoc(doc);
      }
      upserted += 1;
    }

    const last = snap.docs[snap.docs.length - 1];
    const nextCursor = last ? last.id : null;
    const done = snap.docs.length < limit;

    return { scanned, upserted, skipped, nextCursor, done };
  }
);

export const f15_reindexUsersToTypesenseScheduled = onSchedule(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    schedule: "every 5 minutes",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async () => {
    ensureAdmin();

    if (!typesenseReady()) {
      console.log("Typesense env missing, skipping scheduled reindex.");
      return;
    }

    const db = getFirestore();
    const stateRef = db.collection("adminConfig").doc("typesenseUsersReindex");
    const stateSnap = await stateRef.get();
    const state = (stateSnap.data() || {}) as Record<string, unknown>;
    const cursor = String(state.cursor || "").trim();
    const batchSize = 300;

    let q = db.collection("users").orderBy(FieldPath.documentId()).limit(batchSize);
    if (cursor) q = q.startAfter(cursor);

    const snap = await q.get();
    if (snap.empty) {
      await stateRef.set(
        {
          cursor: "",
          doneAt: Date.now(),
          done: true,
        },
        { merge: true }
      );
      console.log("typesense_users_reindex_scheduled_done");
      return;
    }

    let scanned = 0;
    let upserted = 0;
    let skipped = 0;

    for (const docSnap of snap.docs) {
      scanned += 1;
      const doc = buildUserSearchDoc(docSnap.id, docSnap.data() as Record<string, unknown>);
      if (!shouldIndexUser(doc)) {
        skipped += 1;
        continue;
      }
      await upsertUserDoc(doc);
      upserted += 1;
    }

    const last = snap.docs[snap.docs.length - 1];
    const done = snap.docs.length < batchSize;

    await stateRef.set(
      {
        cursor: done ? "" : (last?.id || ""),
        lastRunAt: Date.now(),
        done,
        scanned,
        upserted,
        skipped,
      },
      { merge: true }
    );

    console.log("typesense_users_reindex_scheduled_progress", {
      scanned,
      upserted,
      skipped,
      done,
      nextCursor: done ? "" : (last?.id || ""),
    });
  }
);
