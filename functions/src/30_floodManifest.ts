import { getApps, initializeApp } from "firebase-admin/app";
import { QueryDocumentSnapshot, getFirestore } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import { RateLimits } from "./rateLimiter";

const REGION = getEnv("FLOOD_MANIFEST_REGION") || "us-central1";
const POSTS_COLLECTION = "Posts";
const FLOOD_MANIFEST_COLLECTION = "floodManifest";
const SCHEMA_VERSION = 1;
const PAGE_SIZE = 180;

type FloodManifestSourcePost = {
  id: string;
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
  hlsUpdatedAt?: unknown;
  aspectRatio?: unknown;
  timeStamp?: unknown;
  izBirakYayinTarihi?: unknown;
  scheduledAt?: unknown;
  createdAtTs?: unknown;
  shortId?: unknown;
  shortUrl?: unknown;
  likeCount?: unknown;
  commentCount?: unknown;
  savedCount?: unknown;
  retryCount?: unknown;
  statsCount?: unknown;
  stats?: unknown;
  paylasGizliligi?: unknown;
  deletedPost?: unknown;
  gizlendi?: unknown;
  arsiv?: unknown;
  flood?: unknown;
  floodCount?: unknown;
  mainFlood?: unknown;
  konum?: unknown;
  locationCity?: unknown;
  yorum?: unknown;
  yorumMap?: unknown;
  reshareMap?: unknown;
  tags?: unknown;
  isUploading?: unknown;
  stabilized?: unknown;
};

type FloodManifestChild = {
  docId: string;
  userID: string;
  authorNickname: string;
  authorDisplayName: string;
  authorAvatarUrl: string;
  rozet: string;
  timeStamp: number;
  izBirakYayinTarihi: number;
  createdAtTs: number;
  shortId: string;
  shortUrl: string;
  thumbnail: string;
  img: string[];
  video: string;
  hlsMasterUrl: string;
  hlsStatus: string;
  hlsUpdatedAt: number;
  aspectRatio: number;
  metin: string;
  paylasGizliligi: number;
  flood: boolean;
  floodCount: number;
  mainFlood: string;
  konum: string;
  locationCity: string;
  yorum: boolean;
  yorumMap: Record<string, unknown>;
  reshareMap: Record<string, unknown>;
  tags: string[];
  isUploading: false;
  stabilized: boolean;
  deletedPost: false;
  gizlendi: false;
  arsiv: false;
  stats: {
    commentCount: number;
    likeCount: number;
    retryCount: number;
    savedCount: number;
    statsCount: number;
  };
};

type FloodManifestDoc = {
  kind: "flood";
  schemaVersion: number;
  status: "active";
  eligible: true;
  generatedAt: number;
  publishedAt: number;
  updatedAtMs: number;
  floodRootId: string;
  mainPostId: string;
  childPostIds: string[];
  floodCount: number;
  visibleChildCount: number;
  visibleItemCount: number;
  children: FloodManifestChild[];
  userID: string;
  authorNickname: string;
  authorDisplayName: string;
  authorAvatarUrl: string;
  rozet: string;
  metin: string;
  thumbnail: string;
  img: string[];
  video: string;
  hlsMasterUrl: string;
  hlsStatus: string;
  hlsUpdatedAt: number;
  aspectRatio: number;
  timeStamp: number;
  izBirakYayinTarihi: number;
  scheduledAt: number;
  createdAtTs: number;
  shortId: string;
  shortUrl: string;
  paylasGizliligi: number;
  deletedPost: false;
  gizlendi: false;
  arsiv: false;
  flood: false;
  mainFlood: "";
  konum: string;
  locationCity: string;
  yorum: boolean;
  yorumMap: Record<string, unknown>;
  reshareMap: Record<string, unknown>;
  tags: string[];
  isUploading: false;
  stabilized: boolean;
  stats: {
    commentCount: number;
    likeCount: number;
    retryCount: number;
    savedCount: number;
    statsCount: number;
  };
};

type GenerateFloodManifestResult = {
  ok: true;
  roots: number;
  publishedAt: number;
  generatedAt: number;
  deletedRoots: number;
};

type FloodManifestFetchResult = {
  ok: true;
  rootCount: number;
  updatedAtMs: number;
  generatedAt: number;
  publishedAt: number;
  items: FloodManifestDoc[];
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
    return String(functions.config?.()?.floodmanifest?.[name.toLowerCase()] || "").trim();
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
    const parsed = Number(value.trim());
    if (Number.isFinite(parsed)) return parsed;
  }
  if (value && typeof value === "object" && "toMillis" in (value as Record<string, unknown>)) {
    try {
      return Number((value as { toMillis: () => number }).toMillis());
    } catch {
      return fallback;
    }
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

function asJsonMap(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return { ...(value as Record<string, unknown>) };
}

function resolveFloodRootId(post: FloodManifestSourcePost): string {
  const mainFlood = asString(post.mainFlood);
  if (mainFlood) return mainFlood;
  const docId = post.id.trim();
  const floodCount = asInt(post.floodCount, 1);
  if (!asBool(post.flood) && docId && floodCount > 1) {
    return docId;
  }
  return "";
}

function baseIdForFloodRoot(rootId: string): string {
  return rootId.replace(/_\d+$/g, "");
}

function isVisibleFloodRoot(post: FloodManifestSourcePost, nowMs: number): boolean {
  const rootId = resolveFloodRootId(post);
  if (!rootId) return false;
  if (asBool(post.flood)) return false;
  if (asBool(post.deletedPost) || asBool(post.gizlendi) || asBool(post.arsiv)) {
    return false;
  }
  if (asInt(post.floodCount, 1) <= 1) return false;
  const timeStamp = asInt(post.timeStamp, 0);
  return timeStamp <= nowMs;
}

function isVisibleFloodChild(post: FloodManifestSourcePost, nowMs: number): boolean {
  if (asBool(post.deletedPost) || asBool(post.gizlendi) || asBool(post.arsiv)) {
    return false;
  }
  const timeStamp = asInt(post.timeStamp, 0);
  return timeStamp <= nowMs;
}

function buildChildEntry(post: FloodManifestSourcePost, rootId: string): FloodManifestChild {
  const statsMap = asJsonMap(post.stats);
  return {
    docId: post.id.trim(),
    userID: asString(post.userID),
    authorNickname: asString(post.authorNickname),
    authorDisplayName: asString(post.authorDisplayName) || asString(post.authorNickname),
    authorAvatarUrl: asString(post.authorAvatarUrl),
    rozet: asString(post.rozet),
    timeStamp: asInt(post.timeStamp, 0),
    izBirakYayinTarihi: asInt(post.izBirakYayinTarihi, asInt(post.timeStamp, 0)),
    createdAtTs: asInt(post.createdAtTs, asInt(post.timeStamp, 0)),
    shortId: asString(post.shortId),
    shortUrl: asString(post.shortUrl),
    thumbnail: asString(post.thumbnail),
    img: asStringArray(post.img),
    video: asString(post.video),
    hlsMasterUrl: asString(post.hlsMasterUrl),
    hlsStatus: asString(post.hlsStatus) || "none",
    hlsUpdatedAt: asInt(post.hlsUpdatedAt, 0),
    aspectRatio: asNumber(post.aspectRatio, 1),
    metin: asString(post.metin),
    paylasGizliligi: asInt(post.paylasGizliligi, 0),
    flood: post.id.trim() !== rootId,
    floodCount: asInt(post.floodCount, 1),
    mainFlood: post.id.trim() === rootId ? "" : rootId,
    konum: asString(post.konum),
    locationCity: asString(post.locationCity),
    yorum: post.yorum !== false,
    yorumMap: asJsonMap(post.yorumMap),
    reshareMap: asJsonMap(post.reshareMap),
    tags: asStringArray(post.tags),
    isUploading: false,
    stabilized: post.stabilized !== false,
    deletedPost: false,
    gizlendi: false,
    arsiv: false,
    stats: {
      commentCount: asInt(statsMap.commentCount ?? post.commentCount, 0),
      likeCount: asInt(statsMap.likeCount ?? post.likeCount, 0),
      retryCount: asInt(statsMap.retryCount ?? post.retryCount, 0),
      savedCount: asInt(statsMap.savedCount ?? post.savedCount, 0),
      statsCount: asInt(statsMap.statsCount ?? post.statsCount, 0),
    },
  };
}

function buildFloodManifestDoc(params: {
  root: FloodManifestSourcePost;
  children: FloodManifestSourcePost[];
  generatedAt: number;
  publishedAt: number;
}): FloodManifestDoc {
  const root = params.root;
  const rootId = resolveFloodRootId(root);
  const visibleChildren = params.children
    .filter((child) => child.id.trim() !== rootId)
    .map((child) => buildChildEntry(child, rootId));
  const statsMap = asJsonMap(root.stats);
  return {
    kind: "flood",
    schemaVersion: SCHEMA_VERSION,
    status: "active",
    eligible: true,
    generatedAt: params.generatedAt,
    publishedAt: params.publishedAt,
    updatedAtMs: asInt(root.timeStamp, params.generatedAt),
    floodRootId: rootId,
    mainPostId: rootId,
    childPostIds: visibleChildren.map((child) => child.docId),
    floodCount: asInt(root.floodCount, Math.max(1, params.children.length)),
    visibleChildCount: visibleChildren.length,
    visibleItemCount: visibleChildren.length + 1,
    children: visibleChildren,
    userID: asString(root.userID),
    authorNickname: asString(root.authorNickname),
    authorDisplayName: asString(root.authorDisplayName) || asString(root.authorNickname),
    authorAvatarUrl: asString(root.authorAvatarUrl),
    rozet: asString(root.rozet),
    metin: asString(root.metin),
    thumbnail: asString(root.thumbnail),
    img: asStringArray(root.img),
    video: asString(root.video),
    hlsMasterUrl: asString(root.hlsMasterUrl),
    hlsStatus: asString(root.hlsStatus) || "none",
    hlsUpdatedAt: asInt(root.hlsUpdatedAt, 0),
    aspectRatio: asNumber(root.aspectRatio, 1),
    timeStamp: asInt(root.timeStamp, 0),
    izBirakYayinTarihi: asInt(root.izBirakYayinTarihi, asInt(root.timeStamp, 0)),
    scheduledAt: asInt(root.scheduledAt, 0),
    createdAtTs: asInt(root.createdAtTs, asInt(root.timeStamp, 0)),
    shortId: asString(root.shortId),
    shortUrl: asString(root.shortUrl),
    paylasGizliligi: asInt(root.paylasGizliligi, 0),
    deletedPost: false,
    gizlendi: false,
    arsiv: false,
    flood: false,
    mainFlood: "",
    konum: asString(root.konum),
    locationCity: asString(root.locationCity),
    yorum: root.yorum !== false,
    yorumMap: asJsonMap(root.yorumMap),
    reshareMap: asJsonMap(root.reshareMap),
    tags: asStringArray(root.tags),
    isUploading: false,
    stabilized: root.stabilized !== false,
    stats: {
      commentCount: asInt(statsMap.commentCount ?? root.commentCount, 0),
      likeCount: asInt(statsMap.likeCount ?? root.likeCount, 0),
      retryCount: asInt(statsMap.retryCount ?? root.retryCount, 0),
      savedCount: asInt(statsMap.savedCount ?? root.savedCount, 0),
      statsCount: asInt(statsMap.statsCount ?? root.statsCount, 0),
    },
  };
}

async function fetchFloodRootCandidates(nowMs: number): Promise<FloodManifestSourcePost[]> {
  const db = getFirestore();
  let query = db
    .collection(POSTS_COLLECTION)
    .where("arsiv", "==", false)
    .where("flood", "==", false)
    .where("floodCount", ">", 1)
    .where("timeStamp", "<=", nowMs)
    .orderBy("floodCount")
    .orderBy("timeStamp", "desc")
    .limit(PAGE_SIZE);

  const roots: FloodManifestSourcePost[] = [];
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;

  while (true) {
    const snap = await query.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      const candidate = {
        ...(doc.data() as Record<string, unknown>),
        id: doc.id,
      } as FloodManifestSourcePost;
      if (!isVisibleFloodRoot(candidate, nowMs)) continue;
      roots.push(candidate);
    }
    if (snap.docs.length < PAGE_SIZE) break;
    lastDoc = snap.docs[snap.docs.length - 1];
    query = db
      .collection(POSTS_COLLECTION)
      .where("arsiv", "==", false)
      .where("flood", "==", false)
      .where("floodCount", ">", 1)
      .where("timeStamp", "<=", nowMs)
      .orderBy("floodCount")
      .orderBy("timeStamp", "desc")
      .startAfter(lastDoc)
      .limit(PAGE_SIZE);
  }

  roots.sort((a, b) => asInt(b.timeStamp, 0) - asInt(a.timeStamp, 0));
  return roots;
}

async function fetchFloodGroup(root: FloodManifestSourcePost, nowMs: number): Promise<FloodManifestSourcePost[]> {
  const rootId = resolveFloodRootId(root);
  const floodCount = asInt(root.floodCount, 1);
  if (!rootId || floodCount <= 1) return [];
  const baseId = baseIdForFloodRoot(rootId);
  const refs = Array.from({ length: floodCount }, (_, index) =>
    getFirestore().collection(POSTS_COLLECTION).doc(`${baseId}_${index}`),
  );
  const docs = await getFirestore().getAll(...refs);
  const visible = docs
    .filter((doc) => doc.exists)
    .map((doc) => ({
      ...(doc.data() as Record<string, unknown>),
      id: doc.id,
    }) as FloodManifestSourcePost)
    .filter((post) => isVisibleFloodChild(post, nowMs));

  visible.sort((a, b) => {
    const aIndex = asInt(a.id.split("_").pop(), 0);
    const bIndex = asInt(b.id.split("_").pop(), 0);
    return aIndex - bIndex;
  });
  return visible;
}

async function deleteStaleFloodManifestDocs(activeRootIds: Set<string>): Promise<number> {
  const db = getFirestore();
  let deleted = 0;
  let cursor: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;
  while (true) {
    let query = db
      .collection(FLOOD_MANIFEST_COLLECTION)
      .orderBy("updatedAtMs", "desc")
      .limit(200);
    if (cursor != null) {
      query = query.startAfter(cursor);
    }
    const snap = await query.get();
    if (snap.empty) break;
    const batch = db.batch();
    let batchDeletes = 0;
    for (const doc of snap.docs) {
      const kind = asString(doc.data()?.kind);
      if (kind !== "flood") continue;
      if (activeRootIds.has(doc.id)) continue;
      batch.delete(doc.ref);
      batchDeletes += 1;
    }
    if (batchDeletes > 0) {
      await batch.commit();
      deleted += batchDeletes;
    }
    if (snap.docs.length < 200) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  return deleted;
}

async function publishFloodManifestMeta(params: {
  roots: number;
  generatedAt: number;
  publishedAt: number;
}) {
  await getFirestore()
    .collection(FLOOD_MANIFEST_COLLECTION)
    .doc("active")
    .set(
      {
        kind: "meta",
        schemaVersion: SCHEMA_VERSION,
        status: "active",
        rootCount: params.roots,
        generatedAt: params.generatedAt,
        publishedAt: params.publishedAt,
        updatedAtMs: params.publishedAt,
      },
      { merge: true },
    );
}

async function fetchPublishedFloodManifest(): Promise<FloodManifestFetchResult> {
  ensureAdmin();
  const db = getFirestore();
  const activeSnap = await db.collection(FLOOD_MANIFEST_COLLECTION).doc("active").get();
  const activeData = activeSnap.data() || {};
  const rootCount = asInt(activeData.rootCount);
  const updatedAtMs = asInt(activeData.updatedAtMs, Date.now());
  const generatedAt = asInt(activeData.generatedAt, updatedAtMs);
  const publishedAt = asInt(activeData.publishedAt, updatedAtMs);

  const items: FloodManifestDoc[] = [];
  let lastDoc: QueryDocumentSnapshot | undefined;
  while (true) {
    let query = db
      .collection(FLOOD_MANIFEST_COLLECTION)
      .orderBy("updatedAtMs", "desc")
      .limit(200);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      if (doc.id === "active") continue;
      const data = doc.data();
      if (data.kind !== "flood" || data.eligible !== true) continue;
      items.push(data as FloodManifestDoc);
    }
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < 200) break;
    if (rootCount > 0 && items.length >= rootCount) break;
  }

  return {
    ok: true,
    rootCount: rootCount > 0 ? rootCount : items.length,
    updatedAtMs,
    generatedAt,
    publishedAt,
    items,
  };
}

export async function generateFloodManifest(params: {
  actor: string;
  generatedAt: number;
  publishedAt: number;
}): Promise<GenerateFloodManifestResult> {
  ensureAdmin();
  const roots = await fetchFloodRootCandidates(params.generatedAt);
  const db = getFirestore();
  const activeRootIds = new Set<string>();

  for (const root of roots) {
    const rootId = resolveFloodRootId(root);
    if (!rootId) continue;
    const group = await fetchFloodGroup(root, params.generatedAt);
    const visibleRoot = group.find((post) => post.id.trim() == rootId);
    if (visibleRoot == null) continue;
    if (group.length <= 1) continue;
    const payload = buildFloodManifestDoc({
      root: visibleRoot,
      children: group,
      generatedAt: params.generatedAt,
      publishedAt: params.publishedAt,
    });
    await db.collection(FLOOD_MANIFEST_COLLECTION).doc(rootId).set(payload, {
      merge: true,
    });
    activeRootIds.add(rootId);
  }

  const deletedRoots = await deleteStaleFloodManifestDocs(activeRootIds);
  await publishFloodManifestMeta({
    roots: activeRootIds.size,
    generatedAt: params.generatedAt,
    publishedAt: params.publishedAt,
  });

  return {
    ok: true,
    roots: activeRootIds.size,
    publishedAt: params.publishedAt,
    generatedAt: params.generatedAt,
    deletedRoots,
  };
}

export const f30_generateFloodManifestCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (request: CallableRequest) => {
    ensureAdmin();
    const uid = requireAdminAuth(request);
    try {
      return await generateFloodManifest({
        actor: uid,
        generatedAt: Date.now(),
        publishedAt: Date.now(),
      });
    } catch (error: any) {
      console.error("flood_manifest_generate_failed", {
        detail: error?.message || String(error),
      });
      throw new HttpsError("internal", "flood_manifest_generate_failed", error?.message || "unknown_error");
    }
  },
);

export const f30_getFloodManifestCallable = onCall(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    try {
      return await fetchPublishedFloodManifest();
    } catch (error: any) {
      console.error("flood_manifest_fetch_failed", {
        detail: error?.message || String(error),
      });
      throw new HttpsError("internal", "flood_manifest_fetch_failed", error?.message || "unknown_error");
    }
  },
);

export const f30_generateFloodManifestScheduled = onSchedule(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    schedule: getEnv("FLOOD_MANIFEST_SCHEDULE") || "10 10,19 * * *",
    timeZone: "Europe/Istanbul",
  },
  async () => {
    ensureAdmin();
    const nowMs = Date.now();
    try {
      const result = await generateFloodManifest({
        actor: "scheduled",
        generatedAt: nowMs,
        publishedAt: nowMs,
      });
      console.log("flood_manifest_scheduled_done", result);
    } catch (error: any) {
      console.error("flood_manifest_scheduled_failed", {
        detail: error?.message || String(error),
      });
      throw error;
    }
  },
);
