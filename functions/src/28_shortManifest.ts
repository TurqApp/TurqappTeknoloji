import axios, { AxiosError } from "axios";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import { RateLimits } from "./rateLimiter";

const REGION = getEnv("SHORT_MANIFEST_REGION") || getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "posts_search";
const SHORT_MANIFEST_COLLECTION = "shortManifest";
const SCHEMA_VERSION = 1;
const SLOT_SIZE = 240;
const DEFAULT_MAX_SLOTS = 2;
const MAX_SLOTS = 12;
const MAX_SCAN_PAGES = 24;
const TYPESENSE_PAGE_SIZE = 250;
const TURQAPP_SHORT_DOMAIN = getEnv("SHORT_LINK_DOMAIN") || "turqapp.com";
const ISTANBUL_UTC_OFFSET = "+03:00";
const DAY_MS = 24 * 60 * 60 * 1000;
const SHORT_SOURCE_DAY_OFFSET = 4;

export type ShortManifestCandidate = {
  id?: unknown;
  userID?: unknown;
  authorNickname?: unknown;
  authorDisplayName?: unknown;
  authorAvatarUrl?: unknown;
  rozet?: unknown;
  metin?: unknown;
  thumbnail?: unknown;
  img?: unknown;
  video?: unknown;
  hlsMasterUrl?: unknown;
  hlsStatus?: unknown;
  hasPlayableVideo?: unknown;
  aspectRatio?: unknown;
  timeStamp?: unknown;
  createdAtTs?: unknown;
  shortId?: unknown;
  shortUrl?: unknown;
  likeCount?: unknown;
  commentCount?: unknown;
  savedCount?: unknown;
  retryCount?: unknown;
  statsCount?: unknown;
  paylasGizliligi?: unknown;
  deletedPost?: unknown;
  gizlendi?: unknown;
  arsiv?: unknown;
  isUploading?: unknown;
  flood?: unknown;
  floodCount?: unknown;
};

type ShortManifestItem = {
  docId: string;
  userID: string;
  authorNickname: string;
  authorDisplayName: string;
  authorAvatarUrl: string;
  rozet: string;
  metin: string;
  thumbnail: string;
  posterCandidates: string[];
  video: string;
  hlsMasterUrl: string;
  hlsStatus: "ready";
  hasPlayableVideo: true;
  aspectRatio: number;
  timeStamp: number;
  createdAtTs: number;
  shortId: string;
  shortUrl: string;
  stats: {
    likeCount: number;
    commentCount: number;
    savedCount: number;
    retryCount: number;
    statsCount: number;
  };
  flags: {
    deletedPost: false;
    gizlendi: false;
    arsiv: false;
    flood: false;
    floodCount: number;
    paylasGizliligi: 0;
  };
};

type ShortManifestSlot = {
  schemaVersion: number;
  date: string;
  manifestId: string;
  slotId: string;
  slotIndex: number;
  itemCount: number;
  items: ShortManifestItem[];
};

type ShortManifestIndex = {
  schemaVersion: number;
  date: string;
  manifestId: string;
  itemsPerSlot: number;
  slotCount: number;
  itemCount: number;
  generatedAt: number;
  slots: Array<{
    slotId: string;
    slotIndex: number;
    itemCount: number;
    path: string;
  }>;
};

type GenerateShortManifestParams = {
  actor: string;
  date: string;
  maxSlots: number;
  startMs: number;
  endMs: number;
  publish: boolean;
  generatedAt: number;
};

type GenerateShortManifestResult = {
  ok: true;
  published: boolean;
  date: string;
  manifestId: string;
  slotCount: number;
  itemCount: number;
  candidates: number;
  validItems: number;
  scannedPages: number;
  found: number;
  indexPath: string;
};

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

function requireAdminAuth(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "auth_required");
  }
  const token = request.auth?.token as { admin?: unknown } | undefined;
  if (token?.admin !== true) {
    throw new HttpsError("permission-denied", "admin_required");
  }
  RateLimits.admin(uid);
  return uid;
}

function getEnv(name: string): string {
  const fromProcess = String(process.env[name] || "").trim();
  if (fromProcess) return fromProcess;
  try {
    return String(functions.config?.()?.shortmanifest?.[name.toLowerCase()] || "").trim();
  } catch {
    return "";
  }
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

function asBool(value: unknown): boolean {
  return value === true;
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function asInt(value: unknown, fallback = 0): number {
  return Math.max(0, Math.floor(asNumber(value, fallback)));
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) => {
      if (typeof entry === "string") return entry.trim();
      if (entry && typeof entry === "object") {
        return asString((entry as Record<string, unknown>).url);
      }
      return "";
    })
    .filter(Boolean);
}

function clampInt(value: unknown, min: number, max: number, fallback: number): number {
  const raw = Math.floor(asNumber(value, fallback));
  if (!Number.isFinite(raw)) return fallback;
  return Math.max(min, Math.min(max, raw));
}

function envInt(name: string, min: number, max: number, fallback: number): number {
  return clampInt(getEnv(name), min, max, fallback);
}

function formatDateIstanbul(nowMs: number): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(nowMs));
  const get = (type: string) => parts.find((part) => part.type === type)?.value || "";
  return `${get("year")}-${get("month")}-${get("day")}`;
}

export function resolveShortManifestDateForNow(nowMs: number): string {
  return formatDateIstanbul(nowMs - SHORT_SOURCE_DAY_OFFSET * DAY_MS);
}

export function istanbulDayRangeForDate(date: string): { startMs: number; endMs: number } {
  const normalized = date.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(normalized)) {
    throw new Error(`invalid_manifest_date:${date}`);
  }
  const startMs = Date.parse(`${normalized}T00:00:00.000${ISTANBUL_UTC_OFFSET}`);
  const endMs = Date.parse(`${normalized}T23:59:59.999${ISTANBUL_UTC_OFFSET}`);
  if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) {
    throw new Error(`invalid_manifest_day_range:${date}`);
  }
  return { startMs, endMs };
}

function stableHash(input: string): number {
  let hash = 2166136261;
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function buildShortUrl(shortId: string, docId: string): string {
  const id = shortId || docId;
  return id ? `https://${TURQAPP_SHORT_DOMAIN}/p/${id}` : "";
}

function qualityScore(candidate: ShortManifestCandidate): number {
  return (
    asInt(candidate.likeCount) * 3 +
    asInt(candidate.savedCount) * 4 +
    asInt(candidate.commentCount) * 2 +
    asInt(candidate.statsCount) +
    asInt(candidate.retryCount)
  );
}

function normalizeManifestItem(candidate: ShortManifestCandidate): ShortManifestItem | null {
  const docId = asString(candidate.id);
  const userID = asString(candidate.userID);
  const authorNickname = asString(candidate.authorNickname);
  const authorDisplayName = asString(candidate.authorDisplayName) || authorNickname;
  const authorAvatarUrl = asString(candidate.authorAvatarUrl);
  const rozet = asString(candidate.rozet);
  const thumbnail = asString(candidate.thumbnail);
  const img = asStringArray(candidate.img);
  const hlsMasterUrl = asString(candidate.hlsMasterUrl);
  const hlsStatus = asString(candidate.hlsStatus).toLowerCase();
  const floodCount = asInt(candidate.floodCount, 1);
  const paylasGizliligi = Math.floor(asNumber(candidate.paylasGizliligi, 0));
  const shortId = asString(candidate.shortId);
  const shortUrl = asString(candidate.shortUrl) || buildShortUrl(shortId, docId);
  const posterCandidates = Array.from(new Set([thumbnail, ...img].filter(Boolean)));
  const timeStamp = Math.floor(asNumber(candidate.timeStamp));
  const createdAtTs = Math.floor(asNumber(candidate.createdAtTs, timeStamp));
  const aspectRatio = asNumber(candidate.aspectRatio);

  if (!docId || !userID) return null;
  if (!authorNickname || !authorDisplayName || !authorAvatarUrl || !rozet) return null;
  if (!thumbnail || posterCandidates.length === 0) return null;
  if (!hlsMasterUrl || hlsStatus !== "ready" || candidate.hasPlayableVideo !== true) return null;
  if (!Number.isFinite(aspectRatio) || aspectRatio <= 0) return null;
  if (!Number.isFinite(timeStamp) || timeStamp <= 0) return null;
  if (!shortUrl) return null;
  if (paylasGizliligi !== 0) return null;
  if (asBool(candidate.deletedPost) || asBool(candidate.gizlendi) || asBool(candidate.arsiv)) return null;
  if (asBool(candidate.isUploading) || asBool(candidate.flood) || floodCount > 1) return null;

  return {
    docId,
    userID,
    authorNickname,
    authorDisplayName,
    authorAvatarUrl,
    rozet,
    metin: asString(candidate.metin),
    thumbnail,
    posterCandidates,
    video: asString(candidate.video),
    hlsMasterUrl,
    hlsStatus: "ready",
    hasPlayableVideo: true,
    aspectRatio,
    timeStamp,
    createdAtTs,
    shortId,
    shortUrl,
    stats: {
      likeCount: asInt(candidate.likeCount),
      commentCount: asInt(candidate.commentCount),
      savedCount: asInt(candidate.savedCount),
      retryCount: asInt(candidate.retryCount),
      statsCount: asInt(candidate.statsCount),
    },
    flags: {
      deletedPost: false,
      gizlendi: false,
      arsiv: false,
      flood: false,
      floodCount,
      paylasGizliligi: 0,
    },
  };
}

export function buildShortManifestItems(
  candidates: ShortManifestCandidate[],
  options?: {
    seed?: string;
    maxItems?: number;
  },
): ShortManifestItem[] {
  const seed = String(options?.seed || "short_manifest");
  const maxItems = Math.max(0, Math.floor(asNumber(options?.maxItems, 0)));
  const seenDocIds = new Set<string>();
  const normalized: Array<{ item: ShortManifestItem; score: number; hash: number }> = [];

  for (const candidate of candidates) {
    const item = normalizeManifestItem(candidate);
    if (!item || seenDocIds.has(item.docId)) continue;
    seenDocIds.add(item.docId);
    normalized.push({
      item,
      score: qualityScore(candidate),
      hash: stableHash(`${seed}:${item.docId}`),
    });
  }

  normalized.sort((left, right) => {
    if (right.score !== left.score) return right.score - left.score;
    return left.hash - right.hash;
  });

  const ordered: ShortManifestItem[] = [];
  const pool = [...normalized];
  while (pool.length > 0 && (maxItems === 0 || ordered.length < maxItems)) {
    const previousUserId = ordered.length > 0 ? ordered[ordered.length - 1].userID : "";
    let pickedIndex = 0;
    if (previousUserId) {
      const diverseIndex = pool.findIndex((entry) => entry.item.userID !== previousUserId);
      if (diverseIndex >= 0 && diverseIndex < 24) {
        pickedIndex = diverseIndex;
      }
    }
    const [picked] = pool.splice(pickedIndex, 1);
    ordered.push(picked.item);
  }

  return ordered;
}

export function buildIndexAndSlots(params: {
  date: string;
  manifestId: string;
  generatedAt: number;
  items: ShortManifestItem[];
}): { index: ShortManifestIndex; slots: ShortManifestSlot[] } {
  const fullSlotCount = Math.floor(params.items.length / SLOT_SIZE);
  const slots: ShortManifestSlot[] = [];

  for (let slotIndex = 0; slotIndex < fullSlotCount; slotIndex += 1) {
    const slotId = `slot_${String(slotIndex + 1).padStart(3, "0")}`;
    const items = params.items.slice(slotIndex * SLOT_SIZE, (slotIndex + 1) * SLOT_SIZE);
    slots.push({
      schemaVersion: SCHEMA_VERSION,
      date: params.date,
      manifestId: params.manifestId,
      slotId,
      slotIndex,
      itemCount: items.length,
      items,
    });
  }

  const index: ShortManifestIndex = {
    schemaVersion: SCHEMA_VERSION,
    date: params.date,
    manifestId: params.manifestId,
    itemsPerSlot: SLOT_SIZE,
    slotCount: slots.length,
    itemCount: slots.length * SLOT_SIZE,
    generatedAt: params.generatedAt,
    slots: slots.map((slot) => ({
      slotId: slot.slotId,
      slotIndex: slot.slotIndex,
      itemCount: slot.itemCount,
      path: `${SHORT_MANIFEST_COLLECTION}/${params.date}/slots/${slot.slotId}.json`,
    })),
  };

  return { index, slots };
}

export async function generateShortManifest(
  params: GenerateShortManifestParams,
): Promise<GenerateShortManifestResult> {
  const manifestId = `short_${params.date}_v${params.generatedAt}`;
  const targetItemCount = params.maxSlots * SLOT_SIZE;
  const fetched = await fetchCandidatesFromTypesense({
    limit: targetItemCount * 3,
    startMs: params.startMs,
    endMs: params.endMs,
  });
  const items = buildShortManifestItems(fetched.candidates, {
    seed: manifestId,
    maxItems: targetItemCount,
  });
  const { index, slots } = buildIndexAndSlots({
    date: params.date,
    manifestId,
    generatedAt: params.generatedAt,
    items,
  });

  if (params.publish && slots.length > 0) {
    await publishManifest({
      index,
      slots,
      publishedAt: Date.now(),
    });
  }

  console.log("short_manifest_generate", {
    actor: params.actor,
    date: params.date,
    publish: params.publish,
    candidates: fetched.candidates.length,
    validItems: items.length,
    slotCount: slots.length,
    itemCount: index.itemCount,
    scannedPages: fetched.scannedPages,
    found: fetched.found,
  });

  return {
    ok: true,
    published: params.publish && slots.length > 0,
    date: params.date,
    manifestId,
    slotCount: slots.length,
    itemCount: index.itemCount,
    candidates: fetched.candidates.length,
    validItems: items.length,
    scannedPages: fetched.scannedPages,
    found: fetched.found,
    indexPath: `${SHORT_MANIFEST_COLLECTION}/${params.date}/index.json`,
  };
}

async function fetchCandidatesFromTypesense(params: {
  limit: number;
  startMs: number;
  endMs: number;
}): Promise<{ candidates: ShortManifestCandidate[]; scannedPages: number; found: number }> {
  const baseUrl = getTypesenseBaseUrl();
  const candidates: ShortManifestCandidate[] = [];
  let found = 0;
  let scannedPages = 0;

  const filterParts = [
    "paylasGizliligi:=0",
    "arsiv:=false",
    "deletedPost:=false",
    "gizlendi:=false",
    "isUploading:=false",
    "hasPlayableVideo:=true",
    "hlsStatus:=ready",
    "flood:=false",
    "floodCount:<=1",
    `timeStamp:>=${params.startMs}`,
    `timeStamp:<=${params.endMs}`,
  ];

  for (let page = 1; page <= MAX_SCAN_PAGES && candidates.length < params.limit; page += 1) {
    const resp = await axios.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
      headers: headers(),
      timeout: 12000,
      params: {
        q: "*",
        query_by: "metin,authorNickname,authorDisplayName",
        per_page: TYPESENSE_PAGE_SIZE,
        page,
        sort_by: "timeStamp:desc",
        filter_by: filterParts.join(" && "),
      },
    });
    const body = resp.data || {};
    const hits = Array.isArray(body.hits) ? body.hits : [];
    found = Number(body.found || found || 0);
    scannedPages = page;
    for (const hit of hits) {
      candidates.push((hit?.document || {}) as ShortManifestCandidate);
    }
    if (hits.length < TYPESENSE_PAGE_SIZE) break;
  }

  return { candidates, scannedPages, found };
}

async function publishManifest(params: {
  index: ShortManifestIndex;
  slots: ShortManifestSlot[];
  publishedAt: number;
}) {
  const bucket = getStorage().bucket();
  const cacheControl = "public, max-age=300";

  await bucket
    .file(`${SHORT_MANIFEST_COLLECTION}/${params.index.date}/index.json`)
    .save(JSON.stringify(params.index), {
      resumable: false,
      contentType: "application/json; charset=utf-8",
      metadata: { cacheControl },
    });

  for (const slot of params.slots) {
    await bucket
      .file(`${SHORT_MANIFEST_COLLECTION}/${params.index.date}/slots/${slot.slotId}.json`)
      .save(JSON.stringify(slot), {
        resumable: false,
        contentType: "application/json; charset=utf-8",
        metadata: { cacheControl },
      });
  }

  const firestorePayload = {
    schemaVersion: params.index.schemaVersion,
    date: params.index.date,
    manifestId: params.index.manifestId,
    status: "active",
    indexPath: `${SHORT_MANIFEST_COLLECTION}/${params.index.date}/index.json`,
    slotCount: params.index.slotCount,
    itemCount: params.index.itemCount,
    itemsPerSlot: params.index.itemsPerSlot,
    generatedAt: params.index.generatedAt,
    publishedAt: params.publishedAt,
  };
  const db = getFirestore();
  const batch = db.batch();
  batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc(params.index.date), firestorePayload, { merge: true });
  batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc("active"), firestorePayload, { merge: true });
  await batch.commit();
}

export const f28_generateShortManifestCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async (request: CallableRequest) => {
    ensureAdmin();
    const uid = requireAdminAuth(request);
    if (!typesenseReady()) {
      throw new HttpsError("failed-precondition", "typesense_not_configured");
    }

    const nowMs = Date.now();
    const requestedDate = asString(request.data?.date);
    const date = requestedDate || resolveShortManifestDateForNow(nowMs);
    const maxSlots = clampInt(request.data?.maxSlots, 1, MAX_SLOTS, DEFAULT_MAX_SLOTS);
    const defaultRange = istanbulDayRangeForDate(date);
    const startMs = Math.floor(asNumber(request.data?.startMs, defaultRange.startMs));
    const endMs = Math.floor(asNumber(request.data?.endMs, defaultRange.endMs));
    const publish = request.data?.publish === true;

    try {
      return await generateShortManifest({
        actor: uid,
        date,
        maxSlots,
        startMs,
        endMs,
        publish,
        generatedAt: nowMs,
      });
    } catch (err: any) {
      const status = (err as AxiosError)?.response?.status;
      const detail = (err as AxiosError)?.response?.data || err?.message || "unknown_error";
      console.error("short_manifest_generate_failed", { status, detail });
      throw new HttpsError("internal", "short_manifest_generate_failed", detail);
    }
  },
);

export const f28_generateShortManifestScheduled = onSchedule(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    schedule: getEnv("SHORT_MANIFEST_SCHEDULE") || "10 0 * * *",
    timeZone: "Europe/Istanbul",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
  },
  async () => {
    ensureAdmin();
    if (!typesenseReady()) {
      console.log("short_manifest_scheduled_skipped", { reason: "typesense_not_configured" });
      return;
    }

    const nowMs = Date.now();
    const date = resolveShortManifestDateForNow(nowMs);
    const defaultRange = istanbulDayRangeForDate(date);
    try {
      const result = await generateShortManifest({
        actor: "scheduled",
        date,
        maxSlots: envInt("SHORT_MANIFEST_MAX_SLOTS", 1, MAX_SLOTS, DEFAULT_MAX_SLOTS),
        startMs: defaultRange.startMs,
        endMs: defaultRange.endMs,
        publish: true,
        generatedAt: nowMs,
      });
      console.log("short_manifest_scheduled_done", result);
    } catch (err: any) {
      const status = (err as AxiosError)?.response?.status;
      const detail = (err as AxiosError)?.response?.data || err?.message || "unknown_error";
      console.error("short_manifest_scheduled_failed", { status, detail });
      throw err;
    }
  },
);
