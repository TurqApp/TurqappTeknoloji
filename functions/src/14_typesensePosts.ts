import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldPath, getFirestore } from "firebase-admin/firestore";
import axios, { AxiosError } from "axios";
import { enforceRateLimitForKey, RateLimits } from "./rateLimiter";

const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "posts_search";
const USERS_COLLECTION = "users_search";
const TAGS_COLLECTION = "tags_search";
const MAX_LIMIT = 50;
const MOTOR_CANDIDATE_MAX_LIMIT = 120;
const SHORT_SURFACE_LANDSCAPE_ASPECT_THRESHOLD = 1.2;
const FEED_MOTOR_CANDIDATE_MAX_PER_USER = 2;
const FEED_MOTOR_CANDIDATE_MAX_PER_FLOOD_ROOT = 1;

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

function asNumber(x: unknown, fallback = 0): number {
  if (typeof x === "number" && Number.isFinite(x)) return x;
  if (typeof x === "string") {
    const parsed = Number(x);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function clipText(value: string, maxLen: number): string {
  const text = String(value || "").trim();
  if (text.length <= maxLen) return text;
  return `${text.slice(0, Math.max(0, maxLen - 1)).trimEnd()}…`;
}

function resolveHandle(
  nickname: unknown,
  username: unknown,
  usernameLower?: unknown
): string {
  const n = asString(nickname).trim();
  const u = asString(username).trim();
  const ul = asString(usernameLower).trim();
  const hasSpace = /\s/.test(n);
  if (n && !hasSpace) return n;
  if (u) return u;
  if (ul) return ul;
  return n;
}

function typesenseStringLiteral(value: string): string {
  return `\`${String(value || "").replace(/`/g, "\\`")}\``;
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
        { name: "userID", type: "string", optional: true },
        { name: "authorNickname", type: "string", optional: true },
        { name: "authorDisplayName", type: "string", optional: true },
        { name: "authorAvatarUrl", type: "string", optional: true },
        { name: "rozet", type: "string", optional: true },
        { name: "metin", type: "string", optional: true },
        { name: "hashtags", type: "string[]", optional: true },
        { name: "mentions", type: "string[]", optional: true },
        { name: "img", type: "string[]", optional: true },
        { name: "thumbnail", type: "string", optional: true },
        { name: "video", type: "string", optional: true },
        { name: "hlsMasterUrl", type: "string", optional: true },
        { name: "paylasGizliligi", type: "int32", optional: true },
        { name: "arsiv", type: "bool", optional: true },
        { name: "deletedPost", type: "bool", optional: true },
        { name: "gizlendi", type: "bool", optional: true },
        { name: "isUploading", type: "bool", optional: true },
        { name: "hlsStatus", type: "string", optional: true },
        { name: "hasPlayableVideo", type: "bool", optional: true },
        { name: "aspectRatio", type: "float", optional: true },
        { name: "likeCount", type: "int32", optional: true },
        { name: "commentCount", type: "int32", optional: true },
        { name: "savedCount", type: "int32", optional: true },
        { name: "retryCount", type: "int32", optional: true },
        { name: "statsCount", type: "int32", optional: true },
        { name: "flood", type: "bool", optional: true },
        { name: "floodCount", type: "int32", optional: true },
        { name: "locationCity", type: "string", optional: true },
        { name: "originalPostID", type: "string", optional: true },
        { name: "originalUserID", type: "string", optional: true },
        { name: "shortId", type: "string", optional: true },
        { name: "shortUrl", type: "string", optional: true },
        { name: "ctaLabel", type: "string", optional: true },
        { name: "ctaUrl", type: "string", optional: true },
        { name: "ctaType", type: "string", optional: true },
        { name: "ctaDocId", type: "string", optional: true },
        { name: "quotedPost", type: "bool", optional: true },
        { name: "mainFlood", type: "string", optional: true },
        { name: "contentType", type: "string", optional: true },
        { name: "editTime", type: "int64", optional: true },
        { name: "minuteOfHour", type: "int32", optional: true },
        { name: "surfaceTargets", type: "string[]", optional: true },
        { name: "timeStamp", type: "int64" },
        { name: "createdAtTs", type: "int64" },
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
          { name: "userID", type: "string", optional: true },
          { name: "authorNickname", type: "string", optional: true },
          { name: "authorDisplayName", type: "string", optional: true },
          { name: "authorAvatarUrl", type: "string", optional: true },
          { name: "rozet", type: "string", optional: true },
          { name: "metin", type: "string", optional: true },
          { name: "hashtags", type: "string[]", optional: true },
          { name: "mentions", type: "string[]", optional: true },
          { name: "img", type: "string[]", optional: true },
          { name: "thumbnail", type: "string", optional: true },
          { name: "video", type: "string", optional: true },
          { name: "hlsMasterUrl", type: "string", optional: true },
          { name: "paylasGizliligi", type: "int32", optional: true },
          { name: "arsiv", type: "bool", optional: true },
          { name: "deletedPost", type: "bool", optional: true },
          { name: "gizlendi", type: "bool", optional: true },
          { name: "isUploading", type: "bool", optional: true },
          { name: "hlsStatus", type: "string", optional: true },
          { name: "hasPlayableVideo", type: "bool", optional: true },
          { name: "aspectRatio", type: "float", optional: true },
          { name: "likeCount", type: "int32", optional: true },
          { name: "commentCount", type: "int32", optional: true },
          { name: "savedCount", type: "int32", optional: true },
          { name: "retryCount", type: "int32", optional: true },
          { name: "statsCount", type: "int32", optional: true },
          { name: "flood", type: "bool", optional: true },
          { name: "floodCount", type: "int32", optional: true },
          { name: "locationCity", type: "string", optional: true },
          { name: "originalPostID", type: "string", optional: true },
          { name: "originalUserID", type: "string", optional: true },
          { name: "shortId", type: "string", optional: true },
          { name: "shortUrl", type: "string", optional: true },
          { name: "ctaLabel", type: "string", optional: true },
          { name: "ctaUrl", type: "string", optional: true },
          { name: "ctaType", type: "string", optional: true },
          { name: "ctaDocId", type: "string", optional: true },
          { name: "quotedPost", type: "bool", optional: true },
          { name: "mainFlood", type: "string", optional: true },
          { name: "contentType", type: "string", optional: true },
          { name: "editTime", type: "int64", optional: true },
          { name: "minuteOfHour", type: "int32", optional: true },
          { name: "surfaceTargets", type: "string[]", optional: true },
          { name: "timeStamp", type: "int64" },
          { name: "createdAtTs", type: "int64" },
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
      const missingFields = [];
      if (!fields.some((f) => f?.name === "docType")) {
        missingFields.push({ name: "docType", type: "string", optional: true });
      }
      if (!fields.some((f) => f?.name === "hasHashtag")) {
        missingFields.push({ name: "hasHashtag", type: "bool", optional: true });
      }
      if (missingFields.length) {
        await axios.patch(
          `${baseUrl}/collections/${TAGS_COLLECTION}`,
          {
            fields: missingFields,
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
          { name: "docType", type: "string", optional: true },
          { name: "tag", type: "string" },
          { name: "postId", type: "string", optional: true },
          { name: "authorId", type: "string", optional: true },
          { name: "hasHashtag", type: "bool", optional: true },
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
  userID: string;
  authorNickname: string;
  authorDisplayName: string;
  authorAvatarUrl: string;
  rozet: string;
  metin: string;
  hashtags: string[];
  mentions: string[];
  img: string[];
  thumbnail: string;
  video: string;
  hlsMasterUrl: string;
  paylasGizliligi: number;
  arsiv: boolean;
  deletedPost: boolean;
  gizlendi: boolean;
  isUploading: boolean;
  hlsStatus: string;
  hasPlayableVideo: boolean;
  aspectRatio: number;
  likeCount: number;
  commentCount: number;
  savedCount: number;
  retryCount: number;
  statsCount: number;
  flood: boolean;
  floodCount: number;
  locationCity: string;
  originalPostID: string;
  originalUserID: string;
  shortId: string;
  shortUrl: string;
  ctaLabel: string;
  ctaUrl: string;
  ctaType: string;
  ctaDocId: string;
  quotedPost: boolean;
  mainFlood: string;
  contentType: string;
  editTime: number;
  minuteOfHour: number;
  surfaceTargets: string[];
  timeStamp: number;
  createdAtTs: number;
};

type AuthorSummary = {
  authorNickname: string;
  authorDisplayName: string;
  authorAvatarUrl: string;
  rozet: string;
};

function resolveMinuteOfHour(timeStamp: number): number {
  if (!Number.isFinite(timeStamp) || timeStamp <= 0) return 0;
  return new Date(timeStamp).getUTCMinutes();
}

type MotorCandidateDiversityOptions = {
  surface: string;
  limit: number;
};

type MotorCandidateDiversityResult = {
  preferredHits: Record<string, any>[];
  relaxedHits: Record<string, any>[];
};

function resolveMotorCandidateFloodRootId(candidate: Record<string, any>): string {
  const mainFlood = asString(candidate.mainFlood).trim();
  if (mainFlood) {
    return mainFlood;
  }
  const candidateId = asString(candidate.id).trim();
  const floodCount = Math.max(0, Math.floor(asNumber(candidate.floodCount)));
  if (candidateId && floodCount > 1) {
    return candidateId;
  }
  return "";
}

export function rankMotorCandidateDiversity(
  hits: Array<Record<string, any>>,
  options: MotorCandidateDiversityOptions,
): MotorCandidateDiversityResult {
  const limit = Math.max(1, Math.floor(asNumber(options.limit, 1)));
  const surface = asString(options.surface).trim().toLowerCase();
  const dedupedHits: Record<string, any>[] = [];
  const seenIds = new Set<string>();

  for (const candidate of hits || []) {
    const candidateId = asString(candidate?.id).trim();
    if (!candidateId || seenIds.has(candidateId)) {
      continue;
    }
    seenIds.add(candidateId);
    dedupedHits.push(candidate);
  }

  if (surface !== "feed" || dedupedHits.length <= 1) {
    const sliced = dedupedHits.slice(0, limit);
    return {
      preferredHits: sliced,
      relaxedHits: sliced,
    };
  }

  const preferredHits: Record<string, any>[] = [];
  const overflowHits: Record<string, any>[] = [];
  const userCounts = new Map<string, number>();
  const floodRootCounts = new Map<string, number>();

  for (const candidate of dedupedHits) {
    const userId = asString(candidate.userID).trim();
    const floodRootId = resolveMotorCandidateFloodRootId(candidate);
    const nextUserCount = userId ? (userCounts.get(userId) || 0) + 1 : 0;
    const nextFloodRootCount = floodRootId
      ? (floodRootCounts.get(floodRootId) || 0) + 1
      : 0;
    const exceedsUserCap =
      userId.length > 0 && nextUserCount > FEED_MOTOR_CANDIDATE_MAX_PER_USER;
    const exceedsFloodRootCap =
      floodRootId.length > 0 &&
      nextFloodRootCount > FEED_MOTOR_CANDIDATE_MAX_PER_FLOOD_ROOT;

    if (exceedsUserCap || exceedsFloodRootCap) {
      overflowHits.push(candidate);
      continue;
    }

    preferredHits.push(candidate);
    if (userId) {
      userCounts.set(userId, nextUserCount);
    }
    if (floodRootId) {
      floodRootCounts.set(floodRootId, nextFloodRootCount);
    }
    if (preferredHits.length >= limit) {
      break;
    }
  }

  const relaxedHits = preferredHits.length >= limit
    ? preferredHits.slice(0, limit)
    : preferredHits.concat(overflowHits).slice(0, limit);

  return {
    preferredHits: preferredHits.slice(0, limit),
    relaxedHits,
  };
}

function resolveSurfaceTargets(doc: {
  paylasGizliligi: number;
  arsiv: boolean;
  deletedPost: boolean;
  gizlendi: boolean;
  isUploading: boolean;
  hasPlayableVideo: boolean;
  hlsStatus: string;
  aspectRatio: number;
  flood: boolean;
}): string[] {
  const isVisiblePublic =
    doc.paylasGizliligi === 0 &&
    !doc.arsiv &&
    !doc.deletedPost &&
    !doc.gizlendi &&
    !doc.isUploading;
  if (!isVisiblePublic) {
    return [];
  }

  const targets = ["feed"];
  const isShortEligible =
    doc.hasPlayableVideo &&
    doc.hlsStatus === "ready" &&
    doc.aspectRatio > 0 &&
    doc.aspectRatio <= SHORT_SURFACE_LANDSCAPE_ASPECT_THRESHOLD &&
    !doc.flood;
  if (isShortEligible) {
    targets.push("short", "quota");
  }
  return targets;
}

function buildSearchDoc(postId: string, data: Record<string, unknown>): PostSearchDoc {
  const analysis = (data.analysis as Record<string, unknown> | undefined) || {};
  const reshareMap =
    ((data as any).reshareMap as Record<string, unknown> | undefined) || {};
  const stats = (data.stats as Record<string, unknown> | undefined) || {};
  const paylas = Number((data as any).paylasGizliligi);
  const paylasGizliligi = Number.isFinite(paylas) ? paylas : 0;
  const deletedPost = asBool((data as any).deletedPost) || asBool(data.isDeleted);
  const arsiv = asBool((data as any).arsiv) || asBool((data as any).isArchived);
  const gizlendi = asBool((data as any).gizlendi) || asBool((data as any).isHidden);
  const isUploading = asBool((data as any).isUploading);
  const metin = asString((data as any).metin);
  const imgList = asStringArray((data as any).img);
  const hlsMasterUrl = asString((data as any).hlsMasterUrl);
  const thumbnailUrl = asString((data as any).thumbnail);
  const videoUrl = asString((data as any).video);
  const hlsStatusRaw = asString((data as any).hlsStatus).toLowerCase();
  const hlsStatus = hlsStatusRaw || (asBool(data.hlsReady) ? "ready" : "none");
  const hasPlayableVideo = hlsStatus === "ready" && hlsMasterUrl.length > 0;
  const timeStamp =
    Number((data as any).timeStamp || 0) ||
    asEpochMillis(data.createdAt) ||
    Date.now();
  const aspectRatio =
    asNumber((data as any).aspectRatio) ||
    asNumber((data as any).imgAspectRatio) ||
    1.77;
  const flood = asBool((data as any).flood);
  const floodCount = Math.max(0, Math.floor(asNumber((data as any).floodCount)));
  const likeCount = Math.max(0, Math.floor(asNumber(stats.likeCount ?? (data as any).likeCount ?? (data as any).begeniSayisi)));
  const commentCount = Math.max(0, Math.floor(asNumber(stats.commentCount ?? (data as any).commentCount ?? (data as any).yorumSayisi)));
  const savedCount = Math.max(0, Math.floor(asNumber(stats.savedCount ?? (data as any).savedCount)));
  const retryCount = Math.max(0, Math.floor(asNumber(stats.retryCount ?? (data as any).retryCount ?? (data as any).reshareCount)));
  const statsCount = Math.max(0, Math.floor(asNumber(stats.statsCount ?? (data as any).statsCount)));
  const contentType = (() => {
    if (flood) return "flood";
    if (hasPlayableVideo && metin) return "video_text";
    if (hasPlayableVideo) return "video";
    if (imgList.length > 0 && metin) return "photo_text";
    if (imgList.length > 0) return "photo";
    return "text";
  })();
  const createdAtTs = timeStamp;
  const userID = asString((data as any).userID);
  const authorNickname = asString((data as any).authorNickname);
  const authorDisplayName = asString((data as any).authorDisplayName) || authorNickname;
  const authorAvatarUrl = asString((data as any).authorAvatarUrl);
  const rozet = asString((data as any).rozet);
  const minuteOfHour = resolveMinuteOfHour(timeStamp);
  const surfaceTargets = resolveSurfaceTargets({
    paylasGizliligi,
    arsiv,
    deletedPost,
    gizlendi,
    isUploading,
    hasPlayableVideo,
    hlsStatus,
    aspectRatio,
    flood,
  });

  return {
    id: postId,
    userID,
    authorNickname,
    authorDisplayName,
    authorAvatarUrl,
    rozet,
    metin,
    hashtags: extractPostTags(data).map((x) => x.tag),
    mentions: asStringArray(analysis.mentions),
    img: imgList,
    thumbnail: thumbnailUrl,
    video: videoUrl,
    hlsMasterUrl,
    paylasGizliligi,
    arsiv,
    deletedPost,
    gizlendi,
    isUploading,
    hlsStatus,
    hasPlayableVideo,
    aspectRatio,
    likeCount,
    commentCount,
    savedCount,
    retryCount,
    statsCount,
    flood,
    floodCount,
    locationCity: asString((data as any).locationCity) || asString((data as any).konum),
    originalPostID: asString((data as any).originalPostID),
    originalUserID: asString((data as any).originalUserID),
    shortId: asString((data as any).shortId),
    shortUrl: asString((data as any).shortUrl),
    ctaLabel: asString(reshareMap.ctaLabel),
    ctaUrl: asString(reshareMap.ctaUrl),
    ctaType: asString(reshareMap.ctaType),
    ctaDocId: asString(reshareMap.ctaDocId),
    quotedPost: asBool((data as any).quotedPost),
    mainFlood: asString((data as any).mainFlood),
    contentType,
    editTime: asEpochMillis((data as any).editTime),
    minuteOfHour,
    surfaceTargets,
    timeStamp,
    createdAtTs,
  };
}

async function fetchAuthorSummary(authorId: string): Promise<AuthorSummary> {
  const normalizedAuthorId = String(authorId || "").trim();
  if (!normalizedAuthorId) {
    return { authorNickname: "", authorDisplayName: "", authorAvatarUrl: "", rozet: "" };
  }

  try {
    const snap = await getFirestore().collection("users").doc(normalizedAuthorId).get();
    if (!snap.exists) {
      return { authorNickname: "", authorDisplayName: "", authorAvatarUrl: "", rozet: "" };
    }
    const data = (snap.data() || {}) as Record<string, unknown>;
    const authorNickname = asString((data as any).nickname);
    const authorDisplayName =
      asString((data as any).displayName) ||
      asString((data as any).fullName) ||
      [asString((data as any).firstName), asString((data as any).lastName)]
        .filter(Boolean)
        .join(" ")
        .trim() ||
      authorNickname;
    return {
      authorNickname,
      authorDisplayName,
      authorAvatarUrl:
        asString((data as any).avatarUrl) ||
        asString((data as any).profileImage) ||
        asString((data as any).photoUrl) ||
        asString((data as any).imageUrl),
      rozet: asString((data as any).rozet),
    };
  } catch (err) {
    console.error("typesense_author_summary_fetch_failed", normalizedAuthorId, err);
    return { authorNickname: "", authorDisplayName: "", authorAvatarUrl: "", rozet: "" };
  }
}

async function buildSearchDocForIndexing(
  postId: string,
  data: Record<string, unknown>
): Promise<PostSearchDoc> {
  const doc = buildSearchDoc(postId, data);
  const summary = await fetchAuthorSummary(doc.userID);
  if (!summary.authorNickname && !summary.authorDisplayName && !summary.authorAvatarUrl && !summary.rozet) {
    return doc;
  }

  return {
    ...doc,
    userID: doc.userID,
    authorNickname: doc.authorNickname || summary.authorNickname,
    authorDisplayName: doc.authorDisplayName || summary.authorDisplayName,
    authorAvatarUrl: doc.authorAvatarUrl || summary.authorAvatarUrl,
    rozet: doc.rozet || summary.rozet,
  };
}

function postDocsEqual(
  left: PostSearchDoc | null | undefined,
  right: PostSearchDoc | null | undefined
): boolean {
  if (!left || !right) return false;
  return JSON.stringify(left) === JSON.stringify(right);
}

function normalizeTagEntries(entries: TagEntry[]): TagEntry[] {
  return entries
    .map((entry) => ({
      tag: normalizeTag(entry.tag),
      hasHashtag: entry.hasHashtag === true,
    }))
    .filter((entry) => entry.tag.length > 0)
    .sort((a, b) => a.tag.localeCompare(b.tag, "tr-TR"));
}

function tagEntriesEqual(left: TagEntry[], right: TagEntry[]): boolean {
  const normalizedLeft = normalizeTagEntries(left);
  const normalizedRight = normalizeTagEntries(right);
  if (normalizedLeft.length !== normalizedRight.length) return false;
  for (let i = 0; i < normalizedLeft.length; i += 1) {
    if (normalizedLeft[i].tag !== normalizedRight[i].tag) return false;
    if (normalizedLeft[i].hasHashtag !== normalizedRight[i].hasHashtag) {
      return false;
    }
  }
  return true;
}

function shouldIndex(doc: PostSearchDoc): boolean {
  if (!doc.id || !doc.userID) return false;
  if (doc.deletedPost || doc.gizlendi || doc.isUploading) return false;
  if (doc.timeStamp <= 0) return false;
  const hasVisual = doc.thumbnail.length > 0 || doc.img.length > 0;
  const hasVideoSignal = doc.video.length > 0 || doc.hlsMasterUrl.length > 0;
  if (hasVideoSignal) {
    return doc.hasPlayableVideo && hasVisual;
  }
  return doc.metin.length > 0 || hasVisual || doc.floodCount > 1;
}

function collectSkipReasons(doc: PostSearchDoc): string[] {
  const reasons: string[] = [];
  if (!doc.id) reasons.push("missing_id");
  if (!doc.userID) reasons.push("missing_author");
  if (doc.deletedPost) reasons.push("deleted");
  if (doc.gizlendi) reasons.push("hidden");
  if (doc.isUploading) reasons.push("uploading");
  if (doc.timeStamp <= 0) reasons.push("invalid_timestamp");

  const hasVisual = doc.thumbnail.length > 0 || doc.img.length > 0;
  const hasVideoSignal = doc.video.length > 0 || doc.hlsMasterUrl.length > 0;

  if (hasVideoSignal) {
    if (!doc.hasPlayableVideo) reasons.push("video_not_playable");
    if (!hasVisual) reasons.push("video_missing_visual");
  } else if (!(doc.metin.length > 0 || hasVisual || doc.floodCount > 1)) {
    reasons.push("empty_card");
  }

  return reasons;
}

function normalizeTag(tag: string): string {
  const t = String(tag || "").trim().toLocaleLowerCase("tr-TR");
  if (!t) return "";
  return t.startsWith("#") ? t.slice(1) : t;
}

type TagEntry = {
  tag: string;
  hasHashtag: boolean;
};

function hasExplicitHash(raw: string): boolean {
  return String(raw || "").trim().startsWith("#");
}

function extractHashtagsFromCaption(text: string): string[] {
  const out = new Set<string>();
  const re = /#([\p{L}\p{N}_]{2,40})/gu;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text || ""))) {
    const t = normalizeTag(m[1]);
    if (t) out.add(t);
  }
  return Array.from(out);
}

function extractPostTags(data: Record<string, unknown>): TagEntry[] {
  const analysis = (data.analysis as Record<string, unknown> | undefined) || {};
  const caption = asString((data as any).metin) || asString((data as any).caption);
  const fromAnalysis = [
    ...asStringArray(analysis.hashtags),
    ...asStringArray(analysis.captionTags),
    ...extractHashtagsFromCaption(caption),
  ];
  const fromRoot = asStringArray((data as any).hashtags);
  const merged: TagEntry[] = [];
  const seen = new Map<string, boolean>();

  for (const raw of fromAnalysis) {
    const normalized = normalizeTag(raw);
    if (!normalized) continue;
    const hasHashtag = hasExplicitHash(raw);
    seen.set(normalized, (seen.get(normalized) || false) || hasHashtag);
  }
  for (const raw of fromRoot) {
    const normalized = normalizeTag(raw);
    if (!normalized) continue;
    // Root hashtags parametresi explicit hashtag kaynagi kabul edilir.
    seen.set(normalized, true);
  }
  for (const [tag, hasHashtag] of seen.entries()) {
    merged.push({ tag, hasHashtag });
  }
  return merged;
}

async function upsertDoc(doc: PostSearchDoc) {
  await ensurePostsCollection();
  const baseUrl = getTypesenseBaseUrl();
  try {
    await axios.post(
      `${baseUrl}/collections/${POSTS_COLLECTION}/documents?action=upsert`,
      doc,
      {
        headers: headers(),
        timeout: 8000,
      }
    );
  } catch (err: any) {
    console.error("typesense_upsert_post_failed", err?.response?.status, err?.response?.data || err?.message);
    throw err;
  }
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

async function upsertTagDocs(postId: string, authorId: string, createdAtTs: number, tags: TagEntry[]) {
  if (!tags.length) return;
  await ensureTagsCollection();
  const baseUrl = getTypesenseBaseUrl();
  for (const entry of tags) {
    const tag = normalizeTag(entry.tag);
    if (!tag) continue;
    const hasHashtag = entry.hasHashtag === true;
    await axios.post(
      `${baseUrl}/collections/${TAGS_COLLECTION}/documents?action=upsert`,
      {
        id: `${tag}__${postId}`,
        docType: "post",
        tag,
        postId,
        authorId,
        hasHashtag,
        createdAtTs,
      },
      { headers: headers(), timeout: 8000 }
    );
  }
}

async function deleteTagDocs(postId: string, tags: string[]) {
  if (!tags.length) return;
  await ensureTagsCollection();
  const baseUrl = getTypesenseBaseUrl();
  for (const tagRaw of tags) {
    const tag = normalizeTag(tagRaw);
    if (!tag) continue;
    try {
      await axios.delete(
        `${baseUrl}/collections/${TAGS_COLLECTION}/documents/${encodeURIComponent(`${tag}__${postId}`)}`,
        { headers: headers(), timeout: 8000 }
      );
    } catch (err) {
      const status = (err as AxiosError)?.response?.status;
      if (status !== 404) throw err;
    }
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

async function upsertUserDoc(doc: UserSearchDoc) {
  await ensureUsersCollection();
  const baseUrl = getTypesenseBaseUrl();
  await axios.post(
    `${baseUrl}/collections/${USERS_COLLECTION}/documents?action=upsert`,
    doc,
    {
      headers: headers(),
      timeout: 8000,
    }
  );
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

async function searchPostsFromTypesense(
  q: string,
  limit: number,
  page: number,
  options?: {
    tag?: string;
    includeNonPublic?: boolean;
  }
) {
  await ensurePostsCollection();

  const normalizedTag = normalizeTag(options?.tag || "");
  const includeNonPublic = options?.includeNonPublic === true;
  const filterParts = [
    "arsiv:=false",
    "deletedPost:=false",
    "gizlendi:=false",
    "isUploading:=false",
  ];
  if (!includeNonPublic) {
    filterParts.unshift("paylasGizliligi:=0");
  }
  if (normalizedTag) {
    filterParts.push(`hashtags:=[${typesenseStringLiteral(normalizedTag)}]`);
  }

  const baseUrl = getTypesenseBaseUrl();
  const resp = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q: q.trim() !== "" ? q : "*",
      query_by: "metin,hashtags,mentions,authorNickname,authorDisplayName",
      per_page: limit,
      page,
      sort_by: "timeStamp:desc",
      filter_by: filterParts.join(" && "),
      prefix: "true,true,true,true,true",
      typo_tokens_threshold: 1,
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];

  return {
    q,
    tag: normalizedTag,
    page,
    limit,
    found: Number(body.found || 0),
    out_of: Number(body.out_of || 0),
    search_time_ms: Number(body.search_time_ms || 0),
    hits: hits.map((h: any) => ({
      ...(h?.document || {}),
      text_match: h?.text_match || 0,
    })),
  };
}

async function getPostCardsByIdsFromTypesense(ids: string[]) {
  await ensurePostsCollection();

  const uniqueIds = Array.from(new Set(ids.map((x) => String(x || "").trim()).filter(Boolean)));
  if (uniqueIds.length === 0) {
    return {
      requested: 0,
      found: 0,
      search_time_ms: 0,
      missingIds: [],
      hits: [],
    };
  }

  const baseUrl = getTypesenseBaseUrl();
  const resp = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q: "*",
      query_by: "metin",
      per_page: uniqueIds.length,
      page: 1,
      filter_by: `id:=[${uniqueIds.map(typesenseStringLiteral).join(",")}]`,
      sort_by: "timeStamp:desc",
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];
  const docs = hits.map((h: any) => h?.document || {}).filter((doc: any) => !!doc?.id);
  const foundIds = new Set(docs.map((doc: any) => String(doc.id)));

  return {
    requested: uniqueIds.length,
    found: docs.length,
    search_time_ms: Number(body.search_time_ms || 0),
    missingIds: uniqueIds.filter((id) => !foundIds.has(id)),
    hits: docs,
  };
}

async function getLatestPostIdsFromTypesense(limit: number, page: number) {
  await ensurePostsCollection();

  const baseUrl = getTypesenseBaseUrl();
  const resp = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
    headers: headers(),
    timeout: 10000,
    params: {
      q: "*",
      query_by: "metin",
      per_page: limit,
      page,
      sort_by: "timeStamp:desc",
      filter_by: "paylasGizliligi:=0 && arsiv:=false && deletedPost:=false && gizlendi:=false && isUploading:=false",
    },
  });

  const body = resp.data || {};
  const hits = Array.isArray(body.hits) ? body.hits : [];

  return {
    page,
    limit,
    found: Number(body.found || 0),
    out_of: Number(body.out_of || 0),
    search_time_ms: Number(body.search_time_ms || 0),
    hits: hits
      .map((h: any) => ({
        postId: String(h?.document?.id || ""),
        timeStamp: Number(h?.document?.timeStamp || 0),
      }))
      .filter((x: any) => !!x.postId),
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
    hits: hits.map((h: any) => ({
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

async function getMotorCandidatesFromTypesense(options: {
  surface: string;
  ownedMinutes: number[];
  limit: number;
  page: number;
  nowMs?: number;
  cutoffMs?: number;
}) {
  const surface = String(options.surface || "").trim().toLowerCase();
  const ownedMinutes = Array.from(
    new Set(
      (options.ownedMinutes || [])
        .map((value) => Number(value))
        .filter((value) => Number.isInteger(value) && value >= 0 && value <= 59)
        .map((value) => Math.trunc(value)),
    ),
  ).sort((left, right) => left - right);
  if (!surface) {
    throw new HttpsError("invalid-argument", "surface_required");
  }
  if (ownedMinutes.length === 0) {
    throw new HttpsError("invalid-argument", "owned_minutes_required");
  }

  const nowMs = Number(options.nowMs || Date.now());
  const cutoffMs =
    Number(options.cutoffMs || 0) ||
    nowMs - 7 * 24 * 60 * 60 * 1000;
  const limit = Math.max(
    1,
    Math.min(MOTOR_CANDIDATE_MAX_LIMIT, Number(options.limit || 40)),
  );
  const page = Math.max(1, Number(options.page || 1));

  const baseFilterParts = [
    "paylasGizliligi:=0",
    "arsiv:=false",
    "deletedPost:=false",
    "gizlendi:=false",
    "isUploading:=false",
    `timeStamp:>=${cutoffMs}`,
    `timeStamp:<=${nowMs}`,
  ];
  const surfaceFilterParts = [...baseFilterParts];
  const strictFilterParts = [
    `surfaceTargets:=[${typesenseStringLiteral(surface)}]`,
    ...baseFilterParts,
    `minuteOfHour:=[${ownedMinutes.join(",")}]`,
  ];
  if (surface === "short" || surface === "quota") {
    surfaceFilterParts.push("hasPlayableVideo:=true");
    surfaceFilterParts.push("hlsStatus:=ready");
    surfaceFilterParts.push(`aspectRatio:<=${SHORT_SURFACE_LANDSCAPE_ASPECT_THRESHOLD}`);
    surfaceFilterParts.push("flood:=false");
    strictFilterParts.push("hasPlayableVideo:=true");
    strictFilterParts.push("hlsStatus:=ready");
    strictFilterParts.push(`aspectRatio:<=${SHORT_SURFACE_LANDSCAPE_ASPECT_THRESHOLD}`);
    strictFilterParts.push("flood:=false");
  }

  const baseUrl = getTypesenseBaseUrl();
  const strictResp = await axios.get(
    `${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`,
    {
      headers: headers(),
      timeout: 10000,
      params: {
        q: "*",
        query_by: "metin",
        per_page: limit,
        page,
        sort_by: "timeStamp:desc",
        filter_by: strictFilterParts.join(" && "),
      },
    }
  );

  const strictBody = strictResp.data || {};
  const strictHits = Array.isArray(strictBody.hits) ? strictBody.hits : [];
  const strictCandidates = strictHits.map((h: any) => ({
    ...(h?.document || {}),
    text_match: h?.text_match || 0,
  }));
  const strictRanked = rankMotorCandidateDiversity(
    strictCandidates,
    {
      surface,
      limit,
    },
  );
  if (
    strictRanked.preferredHits.length >= limit ||
    Number(strictBody.found || 0) <= limit
  ) {
    return {
      surface,
      ownedMinutes,
      page,
      limit,
      found: Number(strictBody.found || 0),
      out_of: Number(strictBody.out_of || 0),
      search_time_ms: Number(strictBody.search_time_ms || 0),
      hits: strictRanked.preferredHits.length >= limit
        ? strictRanked.preferredHits
        : strictRanked.relaxedHits,
    };
  }

  const broadPerPage = Math.max(limit, Math.min(250, Math.max(limit * 4, 100)));
  const rawCandidates = new Map<string, any>();
  for (const candidate of strictCandidates) {
    const candidateId = String(candidate.id || "").trim();
    if (!candidateId || rawCandidates.has(candidateId)) {
      continue;
    }
    rawCandidates.set(candidateId, candidate);
  }
  let rankedCandidates = rankMotorCandidateDiversity(
    Array.from(rawCandidates.values()),
    {
      surface,
      limit,
    },
  );
  let lastScannedPage = page;
  let totalFound = Number(strictBody.found || 0);
  let totalOutOf = Number(strictBody.out_of || 0);
  let totalSearchTimeMs = Number(strictBody.search_time_ms || 0);

  for (
    let broadPage = page;
    broadPage < page + 6 && rankedCandidates.preferredHits.length < limit;
    broadPage += 1
  ) {
    const broadResp = await axios.get(
      `${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`,
      {
        headers: headers(),
        timeout: 10000,
        params: {
          q: "*",
          query_by: "metin",
          per_page: broadPerPage,
          page: broadPage,
          sort_by: "timeStamp:desc",
          filter_by: surfaceFilterParts.join(" && "),
        },
      }
    );

    const broadBody = broadResp.data || {};
    const broadHits = Array.isArray(broadBody.hits) ? broadBody.hits : [];
    lastScannedPage = broadPage;
    totalFound = Number(broadBody.found || totalFound || 0);
    totalOutOf = Number(broadBody.out_of || totalOutOf || 0);
    totalSearchTimeMs += Number(broadBody.search_time_ms || 0);

    for (const rawHit of broadHits) {
      const candidate = {
        ...(rawHit?.document || {}),
        text_match: rawHit?.text_match || 0,
      };
      const candidateId = String(candidate.id || "").trim();
      if (!candidateId) continue;
      if (!ownedMinutes.includes(resolveMinuteOfHour(Number(candidate.timeStamp || 0)))) {
        continue;
      }
      const targets = resolveSurfaceTargets({
        paylasGizliligi: Number(candidate.paylasGizliligi || 0),
        arsiv: candidate.arsiv === true,
        deletedPost: candidate.deletedPost === true,
        gizlendi: candidate.gizlendi === true,
        isUploading: candidate.isUploading === true,
        hasPlayableVideo: candidate.hasPlayableVideo === true,
        hlsStatus: String(candidate.hlsStatus || ""),
        aspectRatio: Number(candidate.aspectRatio || 0),
        flood: candidate.flood === true,
      });
      if (!targets.includes(surface)) {
        continue;
      }
      if (!rawCandidates.has(candidateId)) {
        rawCandidates.set(candidateId, candidate);
      }
      rankedCandidates = rankMotorCandidateDiversity(
        Array.from(rawCandidates.values()),
        {
          surface,
          limit,
        },
      );
      if (rankedCandidates.preferredHits.length >= limit) break;
    }

    if (broadHits.length < broadPerPage) {
      break;
    }
  }

  return {
    surface,
    ownedMinutes,
    page: lastScannedPage,
    limit,
    found: totalFound,
    out_of: totalOutOf,
    search_time_ms: totalSearchTimeMs,
    hits: rankedCandidates.preferredHits.length >= limit
      ? rankedCandidates.preferredHits
      : rankedCandidates.relaxedHits,
  };
}

async function searchTagsFromTypesense(q: string, limit: number, page: number) {
  // Build tags from hashtag arrays inside posts_search.
  const base = await searchPostsFromTypesense(q, Math.max(limit * 5, 100), page);
  const normalizedQuery = q.toLocaleLowerCase("tr-TR");
  const counts = new Map<string, number>();

  for (const hit of base.hits) {
    const hashtags = Array.isArray(hit.hashtags) ? hit.hashtags : [];
    for (const tagRaw of hashtags) {
      const tag = String(tagRaw || "").trim().toLocaleLowerCase("tr-TR");
      if (!tag) continue;
      if (!tag.startsWith(normalizedQuery)) continue;
      counts.set(tag, (counts.get(tag) || 0) + 1);
    }
  }

  const tags = Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([tag, count]) => ({ tag, count }));

  return {
    q,
    page,
    limit,
    found: tags.length,
    out_of: tags.length,
    search_time_ms: base.search_time_ms,
    hits: tags,
  };
}

export const f14_syncPostsToTypesense = onDocumentWritten(
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
    const beforeData = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterData = event.data?.after?.data() as Record<string, unknown> | undefined;

    const beforeComparable = beforeData ? buildSearchDoc(postId, beforeData) : null;
    const afterComparable = afterData ? buildSearchDoc(postId, afterData) : null;

    const beforeIndexed = !!beforeComparable && shouldIndex(beforeComparable);
    const afterIndexed = !!afterComparable && shouldIndex(afterComparable);

    const beforeTagEntries = beforeIndexed && beforeData ? extractPostTags(beforeData) : [];
    const afterTagEntries = afterIndexed && afterData ? extractPostTags(afterData) : [];
    const beforeTags = beforeTagEntries.map((x) => x.tag);
    const afterTags = afterTagEntries.map((x) => x.tag);

    if (!afterData || !afterIndexed) {
      if (!afterData) {
        if (!beforeIndexed) {
          return;
        }
        console.log("post_sync_delete", { postId });
      } else if (afterComparable) {
        console.log("post_sync_skip", {
          postId,
          reasons: collectSkipReasons(afterComparable),
          hlsStatus: afterComparable.hlsStatus,
          hasPlayableVideo: afterComparable.hasPlayableVideo,
          thumbnail: !!afterComparable.thumbnail,
          imgCount: afterComparable.img.length,
          video: !!afterComparable.video,
          hlsMasterUrl: !!afterComparable.hlsMasterUrl,
          arsiv: afterComparable.arsiv,
          deletedPost: afterComparable.deletedPost,
          gizlendi: afterComparable.gizlendi,
          isUploading: afterComparable.isUploading,
        });
        if (!beforeIndexed) {
          return;
        }
      } else if (!beforeIndexed) {
        return;
      }
      await deleteDoc(postId);
      if (beforeTags.length) await deleteTagDocs(postId, beforeTags);
      return;
    }

    const hasDocChanges = !beforeIndexed || !postDocsEqual(beforeComparable, afterComparable);
    const hasTagChanges = !tagEntriesEqual(beforeTagEntries, afterTagEntries);
    if (beforeIndexed &&
        postDocsEqual(beforeComparable, afterComparable) &&
        !hasTagChanges) {
      return;
    }

    const afterDoc = hasDocChanges
      ? await buildSearchDocForIndexing(postId, afterData)
      : afterComparable;
    if (hasDocChanges) {
      await upsertDoc(afterDoc);
      console.log("post_sync_upsert", {
        postId,
        hlsStatus: afterDoc.hlsStatus,
        hasPlayableVideo: afterDoc.hasPlayableVideo,
        thumbnail: !!afterDoc.thumbnail,
        imgCount: afterDoc.img.length,
        video: !!afterDoc.video,
        hlsMasterUrl: !!afterDoc.hlsMasterUrl,
        flood: afterDoc.flood,
        floodCount: afterDoc.floodCount,
      });
    }

    const beforeSet = new Set(beforeTags.map(normalizeTag).filter(Boolean));
    const afterSet = new Set(afterTags.map(normalizeTag).filter(Boolean));
    const toDelete = beforeTags.filter((t) => !afterSet.has(normalizeTag(t)));
    const beforeHashtagMap = new Map(
      beforeTagEntries.map((x) => [normalizeTag(x.tag), x.hasHashtag]),
    );
    const toUpsertEntries = afterTagEntries.filter((entry) => {
      const normalizedTag = normalizeTag(entry.tag);
      if (!beforeSet.has(normalizedTag)) return true;
      return beforeHashtagMap.get(normalizedTag) !== entry.hasHashtag;
    });

    if (toDelete.length) await deleteTagDocs(postId, toDelete);
    if (toUpsertEntries.length) {
      await upsertTagDocs(
        postId,
        afterDoc.userID || "",
        Number(afterDoc.timeStamp || Date.now()),
        toUpsertEntries
      );
    }
  }
);

const f14_syncUsersToTypesense = onDocumentWritten(
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

export const f14_searchPosts = onRequest(
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
    const tag = normalizeTag(String(req.query.tag || ""));
    const includeNonPublic = req.query.includeNonPublic === "true";
    if (!tag && q.length < 2) {
      res.status(400).json({ error: "query_too_short", minLength: 2 });
      return;
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(req.query.limit || 20)));
    const page = Math.max(1, Number(req.query.page || 1));

    try {
      res.json(
        await searchPostsFromTypesense(q, limit, page, {
          tag,
          includeNonPublic,
        })
      );
    } catch (err: any) {
      const status = err?.response?.status || 500;
      const detail = err?.response?.data || err?.message || "unknown_error";
      res.status(status).json({ error: "typesense_search_failed", detail });
    }
  }
);

export const f14_searchPostsCallable = onCall(
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
    const tag = normalizeTag(String(request.data?.tag || ""));
    const includeNonPublic = request.data?.includeNonPublic === true;
    if (!tag && q.length < 2) {
      throw new HttpsError("invalid-argument", "query_too_short");
    }

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));

    try {
      return await searchPostsFromTypesense(q, limit, page, {
        tag,
        includeNonPublic,
      });
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

const f14_searchUsersCallable = onCall(
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

const f14_searchTagsCallable = onCall(
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

type ReindexPostsInput = {
  limit?: number;
  cursor?: string;
  dryRun?: boolean;
};

type ReindexPostsOutput = {
  scanned: number;
  upserted: number;
  deleted: number;
  skipped: number;
  nextCursor: string | null;
  done: boolean;
};

export const f14_reindexPostsToTypesenseCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest<ReindexPostsInput>): Promise<ReindexPostsOutput> => {
    ensureAdmin();
    requireAdminAuth(request);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
    const cursor = String(request.data?.cursor || "").trim();
    const dryRun = request.data?.dryRun === true;

    const db = getFirestore();
    let q = db.collection("Posts").orderBy(FieldPath.documentId()).limit(limit);
    if (cursor) q = q.startAfter(cursor);

    const snap = await q.get();
    let scanned = 0;
    let upserted = 0;
    let deleted = 0;
    let skipped = 0;

    for (const docSnap of snap.docs) {
      scanned += 1;
      const postId = docSnap.id;
      const data = docSnap.data() as Record<string, unknown>;
      const doc = await buildSearchDocForIndexing(postId, data);
      const tags = extractPostTags(data);

      if (!shouldIndex(doc)) {
        if (!dryRun) {
          await deleteDoc(postId);
          if (tags.length) await deleteTagDocs(postId, tags.map((x) => x.tag));
        }
        deleted += 1;
        continue;
      }

      if (!dryRun) {
        await upsertDoc(doc);
        if (tags.length) {
          await upsertTagDocs(postId, doc.userID || "", Number(doc.timeStamp || Date.now()), tags);
        }
      }
      upserted += 1;
    }

    const last = snap.docs[snap.docs.length - 1];
    const nextCursor = last ? last.id : null;
    const done = snap.docs.length < limit;

    return { scanned, upserted, deleted, skipped, nextCursor, done };
  }
);

export const f15_syncPostToTypesenseCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    ensureAdmin();
    const uid = requireAuth(request);
    RateLimits.general(uid);

    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const postId = String(request.data?.postId || "").trim();
    if (!postId) {
      throw new HttpsError("invalid-argument", "post_id_required");
    }

    const db = getFirestore();
    const snap = await db.collection("Posts").doc(postId).get();
    if (!snap.exists) {
      await deleteDoc(postId);
      return {
        postId,
        found: false,
        indexed: false,
        deleted: true,
        reasons: ["missing_post"],
      };
    }

    const data = snap.data() as Record<string, unknown>;
    const ownerId = asString((data as any).userID) || asString(data.authorId);
    const isAdmin = (request.auth?.token as { admin?: unknown } | undefined)?.admin === true;
    if (!isAdmin && ownerId && ownerId !== uid) {
      throw new HttpsError("permission-denied", "post_owner_required");
    }

    const doc = await buildSearchDocForIndexing(postId, data);
    const tags = extractPostTags(data);

    if (!shouldIndex(doc)) {
      await deleteDoc(postId);
      if (tags.length) await deleteTagDocs(postId, tags.map((x) => x.tag));
      return {
        postId,
        found: true,
        indexed: false,
        deleted: true,
        reasons: collectSkipReasons(doc),
      };
    }

    await upsertDoc(doc);
    if (tags.length) {
      await upsertTagDocs(postId, doc.userID || "", Number(doc.timeStamp || Date.now()), tags);
    }

    return {
      postId,
      found: true,
      indexed: true,
      deleted: false,
      reasons: [],
    };
  }
);

export const f15_getLatestPostIdsCallable = onCall(
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

    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));

    try {
      return await getLatestPostIdsFromTypesense(limit, page);
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f15_getPostCardsByIdsCallable = onCall(
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

    const idsRaw = Array.isArray(request.data?.ids) ? request.data?.ids : [];
    const ids = idsRaw.map((x: unknown) => String(x || "").trim()).filter(Boolean);
    if (ids.length === 0) {
      throw new HttpsError("invalid-argument", "ids_required");
    }
    if (ids.length > MAX_LIMIT) {
      throw new HttpsError("invalid-argument", "too_many_ids");
    }

    try {
      return await getPostCardsByIdsFromTypesense(ids);
    } catch (err: any) {
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);

export const f15_getMotorCandidatesCallable = onCall(
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

    const surface = String(request.data?.surface || "").trim().toLowerCase();
    const ownedMinutesRaw = Array.isArray(request.data?.ownedMinutes)
      ? request.data?.ownedMinutes
      : [];
    const ownedMinutes = ownedMinutesRaw
      .map((value: unknown) => Number(value))
      .filter((value: number) => Number.isInteger(value) && value >= 0 && value <= 59)
      .map((value: number) => Math.trunc(value));
    const limit = Math.max(
      1,
      Math.min(MOTOR_CANDIDATE_MAX_LIMIT, Number(request.data?.limit || 40)),
    );
    const page = Math.max(1, Number(request.data?.page || 1));
    const nowMs = Number(request.data?.nowMs || Date.now());
    const cutoffMs = Number(request.data?.cutoffMs || 0);

    try {
      return await getMotorCandidatesFromTypesense({
        surface,
        ownedMinutes,
        limit,
        page,
        nowMs,
        cutoffMs,
      });
    } catch (err: any) {
      if (err instanceof HttpsError) throw err;
      const detail = err?.response?.data || err?.message || "unknown_error";
      throw new HttpsError("internal", "typesense_search_failed", detail);
    }
  }
);
