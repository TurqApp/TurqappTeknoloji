import { AxiosError } from "axios";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import { RateLimits } from "./rateLimiter";

const REGION = getEnv("SHORT_MANIFEST_REGION") || getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "Posts";
const SHORT_MANIFEST_COLLECTION = "shortManifest";
const SCHEMA_VERSION = 1;
const SLOT_SIZE = 240;
const DEFAULT_MAX_SLOTS = 1;
const MAX_SLOTS = 12;
const MAX_SCAN_PAGES = 24;
const TYPESENSE_PAGE_SIZE = 250;
const TURQAPP_SHORT_DOMAIN = getEnv("SHORT_LINK_DOMAIN") || "turqapp.com";
const ISTANBUL_UTC_OFFSET = "+03:00";
const DAY_MS = 24 * 60 * 60 * 1000;
const SHORT_SOURCE_DAY_OFFSET = 4;
const SHORT_ROLLING_SOURCE_DAY_OFFSETS = [6, 5, 4] as const;
const SHORT_ROLLING_PREPARE_DAY_OFFSETS = [6, 5, 4, 3] as const;

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
  imgMap?: unknown;
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
  mainFlood?: unknown;
  contentType?: unknown;
  surfaceTargets?: unknown;
};

type ShortManifestItem = {
  docId: string;
  canonicalId: string;
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
  contentType: string;
  source: "manifest";
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
    mainFlood: "";
    isFloodRoot: boolean;
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

type ShortManifestSlotRef = {
  slotId: string;
  slotIndex: number;
  itemCount: number;
  path: string;
  date?: string;
};

type GenerateShortManifestParams = {
  actor: string;
  date: string;
  maxSlots: number;
  startMs: number;
  endMs: number;
  publish: boolean;
  publishActive?: boolean;
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

function asImageEntries(value: unknown): Array<{ url: string; aspectRatio: number }> {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) => {
      if (!entry || typeof entry !== "object") return null;
      const record = entry as Record<string, unknown>;
      const url = asString(record.url);
      if (!url) return null;
      return {
        url,
        aspectRatio: asNumber(record.aspectRatio, 0),
      };
    })
    .filter((entry): entry is { url: string; aspectRatio: number } => Boolean(entry));
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

export function resolveRollingShortManifestDatesForNow(nowMs: number): string[] {
  return SHORT_ROLLING_SOURCE_DAY_OFFSETS.map((offsetDays) =>
    formatDateIstanbul(nowMs - offsetDays * DAY_MS),
  );
}

export function resolvePreparedRollingShortManifestDatesForNow(nowMs: number): string[] {
  return SHORT_ROLLING_PREPARE_DAY_OFFSETS.map((offsetDays) =>
    formatDateIstanbul(nowMs - offsetDays * DAY_MS),
  );
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

function resolveCanonicalId(candidate: ShortManifestCandidate): string {
  const mainFlood = asString(candidate.mainFlood);
  if (mainFlood) return mainFlood;
  const docId = asString(candidate.id);
  const floodCount = asInt(candidate.floodCount, 1);
  if (docId && floodCount > 1 && !asBool(candidate.flood)) return docId;
  if (docId && /_\\d+$/.test(docId)) return docId.replace(/_\\d+$/, "");
  return docId;
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
  const canonicalId = resolveCanonicalId(candidate);
  const userID = asString(candidate.userID);
  const authorNickname = asString(candidate.authorNickname);
  const authorDisplayName = asString(candidate.authorDisplayName) || authorNickname;
  const authorAvatarUrl = asString(candidate.authorAvatarUrl);
  const rozet = asString(candidate.rozet);
  const thumbnail = asString(candidate.thumbnail);
  const imgEntries = asImageEntries(candidate.imgMap);
  const img = imgEntries.length > 0
    ? imgEntries.map((entry) => entry.url)
    : asStringArray(candidate.img);
  const hlsMasterUrl = asString(candidate.hlsMasterUrl);
  const hlsStatus = asString(candidate.hlsStatus).toLowerCase();
  const floodCount = asInt(candidate.floodCount, 1);
  const mainFlood = asString(candidate.mainFlood);
  const isFloodRoot = !asBool(candidate.flood) && !mainFlood && floodCount > 1;
  const shortId = asString(candidate.shortId);
  const shortUrl = asString(candidate.shortUrl) || buildShortUrl(shortId, docId);
  const posterCandidates = Array.from(new Set([thumbnail, ...img].filter(Boolean)));
  const timeStamp = Math.floor(asNumber(candidate.timeStamp));
  const createdAtTs = Math.floor(asNumber(candidate.createdAtTs, timeStamp));
  const firstImageAspectRatio =
    imgEntries.length > 0 && Number.isFinite(imgEntries[0].aspectRatio) && imgEntries[0].aspectRatio > 0
      ? imgEntries[0].aspectRatio
      : 0;
  const aspectRatio = asNumber(candidate.aspectRatio, firstImageAspectRatio);

  if (!docId || !canonicalId || !userID) return null;
  if (!authorNickname || !authorDisplayName || !authorAvatarUrl || !rozet) return null;
  if (asBool(candidate.deletedPost) || asBool(candidate.gizlendi) || asBool(candidate.arsiv)) return null;
  if (asBool(candidate.isUploading)) return null;
  if (asBool(candidate.flood) || mainFlood || isFloodRoot) return null;
  if (!thumbnail || posterCandidates.length === 0) return null;
  if (!hlsMasterUrl || hlsStatus !== "ready") return null;
  if (!Number.isFinite(aspectRatio) || aspectRatio <= 0) return null;
  if (!Number.isFinite(timeStamp) || timeStamp <= 0) return null;
  if (!shortUrl) return null;

  return {
    docId,
    canonicalId,
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
    contentType: asString(candidate.contentType),
    source: "manifest",
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
      floodCount: asInt(candidate.floodCount, 1),
      mainFlood: "",
      isFloodRoot,
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
  const fetched = await fetchCandidatesFromFirestore({
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
      publishActive: params.publishActive !== false,
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

async function fetchCandidatesFromFirestore(params: {
  limit: number;
  startMs: number;
  endMs: number;
}): Promise<{ candidates: ShortManifestCandidate[]; scannedPages: number; found: number }> {
  const db = getFirestore();
  const candidates: ShortManifestCandidate[] = [];
  let found = 0;
  let scannedPages = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;

  for (let page = 1; page <= MAX_SCAN_PAGES && candidates.length < params.limit; page += 1) {
    let query = db
      .collection(POSTS_COLLECTION)
      .where("timeStamp", ">=", params.startMs)
      .where("timeStamp", "<=", params.endMs)
      .orderBy("timeStamp", "desc")
      .limit(TYPESENSE_PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snapshot = await query.get();
    scannedPages = page;
    if (snapshot.empty) break;
    found += snapshot.size;
    for (const doc of snapshot.docs) {
      candidates.push({
        id: doc.id,
        ...(doc.data() as ShortManifestCandidate),
      });
    }
    lastDoc = snapshot.docs[snapshot.docs.length - 1] || null;
    if (snapshot.docs.length < TYPESENSE_PAGE_SIZE) break;
  }

  return { candidates, scannedPages, found };
}

async function publishManifest(params: {
  index: ShortManifestIndex;
  slots: ShortManifestSlot[];
  publishActive?: boolean;
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
  if (params.publishActive !== false) {
    batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc("active"), firestorePayload, { merge: true });
  }
  await batch.commit();
}

async function publishRollingActiveManifest(params: {
  generatedAt: number;
  publishedAt: number;
  results: GenerateShortManifestResult[];
}): Promise<{
  ok: true;
  published: boolean;
  manifestId: string;
  slotCount: number;
  itemCount: number;
  dates: string[];
  indexPath: string;
}> {
  const usableResults = params.results
    .filter((result) => result.published && result.slotCount > 0);
  const startupResults = usableResults.slice(0, SHORT_ROLLING_SOURCE_DAY_OFFSETS.length);
  const tailResult = usableResults[SHORT_ROLLING_SOURCE_DAY_OFFSETS.length] || null;
  const manifestId = `short_rolling_${startupResults.map((result) => result.date).join("_")}_v${params.generatedAt}`;
  const slots = startupResults.map((result, index): ShortManifestSlotRef => ({
    slotId: `${result.date}_slot_001`,
    slotIndex: index,
    itemCount: SLOT_SIZE,
    path: `${SHORT_MANIFEST_COLLECTION}/${result.date}/slots/slot_001.json`,
    date: result.date,
  }));
  const tailSlot: ShortManifestSlotRef | null = tailResult
    ? {
        slotId: `${tailResult.date}_slot_001`,
        slotIndex: slots.length,
        itemCount: SLOT_SIZE,
        path: `${SHORT_MANIFEST_COLLECTION}/${tailResult.date}/slots/slot_001.json`,
        date: tailResult.date,
      }
    : null;
  const rollingDate = startupResults.map((result) => result.date).join("_");
  const indexPath = `${SHORT_MANIFEST_COLLECTION}/rolling/index.json`;
  const index: ShortManifestIndex = {
    schemaVersion: SCHEMA_VERSION,
    date: rollingDate,
    manifestId,
    itemsPerSlot: SLOT_SIZE,
    slotCount: slots.length,
    itemCount: slots.length * SLOT_SIZE,
    generatedAt: params.generatedAt,
    slots,
  };

  if (slots.length === 0) {
    return {
      ok: true,
      published: false,
      manifestId,
      slotCount: 0,
      itemCount: 0,
      dates: [],
      indexPath,
    };
  }

  const bucket = getStorage().bucket();
  const cacheControl = "public, max-age=300";
  await bucket.file(indexPath).save(JSON.stringify(index), {
    resumable: false,
    contentType: "application/json; charset=utf-8",
    metadata: { cacheControl },
  });

  const firestorePayload = {
    schemaVersion: index.schemaVersion,
    date: index.date,
    manifestId: index.manifestId,
    status: "active",
    indexPath,
    slotCount: index.slotCount,
    itemCount: index.itemCount,
    itemsPerSlot: index.itemsPerSlot,
    generatedAt: index.generatedAt,
    publishedAt: params.publishedAt,
    slots,
    tailSlot,
    tailSourceDate: tailResult?.date || "",
    rollingSourceDates: usableResults.map((result) => result.date),
  };
  const db = getFirestore();
  const batch = db.batch();
  batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc("rolling"), firestorePayload, { merge: true });
  batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc("active"), firestorePayload, { merge: true });
  await batch.commit();

  console.log("short_manifest_rolling_active_publish", {
    manifestId,
    slotCount: index.slotCount,
    itemCount: index.itemCount,
    dates: usableResults.map((result) => result.date),
    startupDates: startupResults.map((result) => result.date),
    tailDate: tailResult?.date || "",
  });

  return {
    ok: true,
    published: true,
    manifestId,
    slotCount: index.slotCount,
    itemCount: index.itemCount,
    dates: usableResults.map((result) => result.date),
    indexPath,
  };
}

export const f28_generateShortManifestCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (request: CallableRequest) => {
    ensureAdmin();
    const uid = requireAdminAuth(request);

    const nowMs = Date.now();
    const requestedDate = asString(request.data?.date);
    const date = requestedDate || resolveShortManifestDateForNow(nowMs);
    const maxSlots = clampInt(request.data?.maxSlots, 1, MAX_SLOTS, DEFAULT_MAX_SLOTS);
    const defaultRange = istanbulDayRangeForDate(date);
    const startMs = Math.floor(asNumber(request.data?.startMs, defaultRange.startMs));
    const endMs = Math.floor(asNumber(request.data?.endMs, defaultRange.endMs));
    const publish = request.data?.publish === true;
    const publishActive = request.data?.publishActive === true;

    try {
      return await generateShortManifest({
        actor: uid,
        date,
        maxSlots,
        startMs,
        endMs,
        publish,
        publishActive,
        generatedAt: nowMs,
      });
    } catch (err: any) {
      const detail = err?.message || "unknown_error";
      console.error("short_manifest_generate_failed", { detail });
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
  },
  async () => {
    ensureAdmin();
    const nowMs = Date.now();
    const dates = resolvePreparedRollingShortManifestDatesForNow(nowMs);
    try {
      const results: GenerateShortManifestResult[] = [];
      for (const date of dates) {
        const defaultRange = istanbulDayRangeForDate(date);
        results.push(await generateShortManifest({
          actor: "scheduled",
          date,
          maxSlots: 1,
          startMs: defaultRange.startMs,
          endMs: defaultRange.endMs,
          publish: true,
          publishActive: false,
          generatedAt: nowMs,
        }));
      }
      const result = await publishRollingActiveManifest({
        generatedAt: nowMs,
        publishedAt: Date.now(),
        results,
      });
      console.log("short_manifest_scheduled_done", {
        ...result,
        preparedDates: dates,
      });
    } catch (err: any) {
      const detail = err?.message || "unknown_error";
      console.error("short_manifest_scheduled_failed", { detail });
      throw err;
    }
  },
);
