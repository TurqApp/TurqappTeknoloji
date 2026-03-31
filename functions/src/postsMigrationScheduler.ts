import axios from "axios";
import { randomUUID } from "crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as path from "path";
import { pipeline } from "stream/promises";

const REGION = "europe-west1";
const QUEUE_COLLECTION = "postsMigrationQueue";
const USERS_COLLECTION = "users";
const POSTS_COLLECTION = "Posts";
const CDN_DOMAIN = "cdn.turqapp.com";
const PREP_HORIZON_MS = 6 * 60 * 60 * 1000;
const MAX_GROUPS_PER_RUN = 3;
const LEASE_MS = 55 * 1000;
const IMAGE_EXT_CANDIDATES = ["webp", "jpg", "jpeg", "png"];
const THUMB_EXT_CANDIDATES = ["webp", "jpg", "jpeg", "png"];

type QueueGroup = {
  active: boolean;
  baseId: string;
  docCount: number;
  docSeededAt: number;
  kind: string;
  mediaAttempts: number;
  mediaPreparedAt: number;
  publishAt: number;
  publishAttempts: number;
  rootId: string;
  state: string;
  leaseUntil: number;
};

type QueueDoc = {
  docId: string;
  index: number;
  userID: string;
  ad: boolean;
  aspectRatio: number;
  debugMode: boolean;
  editTime: number;
  isAd: boolean;
  konum: string;
  locationCity: string;
  metin: string;
  originalPostID: string;
  originalUserID: string;
  paylasGizliligi: number;
  scheduledAt: number;
  sourceImgMap: Array<{ url: string; aspectRatio: number }>;
  sourceImageUrls: string[];
  sourceThumbnailUrl: string;
  sourceVideoUrl: string;
  tags: string[];
  yorum: boolean;
};

type UserProfile = {
  avatarUrl: string;
  nickname: string;
  displayName: string;
  rozet: string;
  username: string;
  fullName: string;
};

type MediaResolution =
  | {
      ok: true;
      aspectRatio: number;
      hlsMasterUrl: string;
      hlsStatus: string;
      img: string[];
      imgMap: Array<{ url: string; aspectRatio: number }>;
      mediaKind: string;
      thumbnail: string;
      video: string;
    }
  | {
      ok: false;
      reason: string;
    };

function ensureAdmin() {
  if (getApps().length === 0) {
    initializeApp();
  }
}

function db() {
  ensureAdmin();
  return getFirestore();
}

function bucket() {
  ensureAdmin();
  return getStorage().bucket();
}

function asString(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  return String(value).trim();
}

function asBool(value: unknown, fallback = false): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (normalized === "true" || normalized === "1") return true;
    if (normalized === "false" || normalized === "0") return false;
  }
  return fallback;
}

function asNum(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.trim());
    if (Number.isFinite(parsed)) return parsed;
  }
  if (value && typeof (value as { toMillis?: () => number }).toMillis === "function") {
    return (value as { toMillis: () => number }).toMillis();
  }
  return fallback;
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asString(item))
    .filter((item) => item.length > 0);
}

function asMapList(value: unknown): Array<{ url: string; aspectRatio: number }> {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      if (!item || typeof item !== "object" || Array.isArray(item)) return null;
      return {
        url: asString((item as { url?: unknown }).url),
        aspectRatio: asNum((item as { aspectRatio?: unknown }).aspectRatio, 1),
      };
    })
    .filter((item): item is { url: string; aspectRatio: number } => Boolean(item));
}

function buildCdnUrl(storagePath: string): string {
  return `https://${CDN_DOMAIN}/${storagePath}`;
}

function buildTokenizedCdnUrl(storagePath: string, token: string): string {
  return `https://${CDN_DOMAIN}/v0/b/${bucket().name}/o/${encodeURIComponent(
    storagePath,
  )}?alt=media&token=${encodeURIComponent(token)}`;
}

function extractDownloadToken(metadata: unknown): string {
  if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
    return "";
  }
  const raw = asString(
    (metadata as { firebaseStorageDownloadTokens?: unknown })
      .firebaseStorageDownloadTokens,
  );
  if (!raw) return "";
  return raw
    .split(",")
    .map((item) => item.trim())
    .find(Boolean) || "";
}

async function buildProtectedAssetUrl(storagePath: string): Promise<string> {
  const file = bucket().file(storagePath);
  const [metadata] = await file.getMetadata();
  let token = extractDownloadToken(metadata.metadata);
  if (!token) {
    token = randomUUID();
    await file.setMetadata({
      metadata: {
        ...(metadata.metadata || {}),
        firebaseStorageDownloadTokens: token,
      },
    });
  }
  return buildTokenizedCdnUrl(storagePath, token);
}

function buildHlsUrl(docId: string): string {
  return buildCdnUrl(`Posts/${docId}/hls/master.m3u8`);
}

function buildTargetMainFlood(docId: string, index: number): string {
  return index === 0 ? "" : `${docId}_0`;
}

function buildYorumMap(sourceDoc: QueueDoc) {
  return {
    visibility: asBool(sourceDoc.yorum, true) ? 0 : 3,
  };
}

function buildReshareMap(sourceDoc: QueueDoc) {
  return {
    visibility: asNum(sourceDoc.paylasGizliligi, 0),
  };
}

function extractStorageObjectPath(rawUrl: string): string {
  const text = asString(rawUrl);
  if (!text) return "";

  if (text.startsWith("gs://")) {
    const parts = text.replace("gs://", "").split("/");
    parts.shift();
    return parts.join("/");
  }

  try {
    const parsed = new URL(text);
    const objectIndex = parsed.pathname.indexOf("/o/");
    if (objectIndex >= 0) {
      return decodeURIComponent(parsed.pathname.slice(objectIndex + 3));
    }
  } catch (_) {}

  return "";
}

function extFromUrl(rawUrl: string, fallback: string): string {
  const objectPath = extractStorageObjectPath(rawUrl);
  const ext = path.extname(objectPath).toLowerCase();
  return ext || fallback;
}

function contentTypeForExt(ext: string): string {
  switch (ext) {
    case ".webp":
      return "image/webp";
    case ".png":
      return "image/png";
    case ".jpeg":
    case ".jpg":
      return "image/jpeg";
    case ".mp4":
      return "video/mp4";
    default:
      return "application/octet-stream";
  }
}

async function pickExistingStoragePath(
  candidates: string[],
): Promise<string> {
  for (const candidate of candidates) {
    const [exists] = await bucket().file(candidate).exists();
    if (exists) return candidate;
  }
  return "";
}

async function copyUrlToTarget(params: {
  sourceUrl: string;
  targetPath: string;
  customMetadata?: Record<string, string>;
}) {
  const [targetExists] = await bucket().file(params.targetPath).exists();
  if (targetExists) {
    return { ok: true, existed: true } as const;
  }

  const ext = path.extname(params.targetPath).toLowerCase();
  const response = await axios.get(params.sourceUrl, {
    responseType: "stream",
    timeout: 600000,
    maxBodyLength: Infinity,
    maxContentLength: Infinity,
    validateStatus: (status) => status >= 200 && status < 300,
  });

  const writeStream = bucket().file(params.targetPath).createWriteStream({
    resumable: false,
    metadata: {
      contentType: contentTypeForExt(ext),
      cacheControl:
        ext === ".mp4"
          ? "public, max-age=31536000, immutable"
          : "public, max-age=86400",
      metadata: params.customMetadata || {},
    },
  });

  await pipeline(response.data, writeStream);
  return { ok: true, existed: false } as const;
}

async function claimLease(
  rootId: string,
  runId: string,
  now: number,
): Promise<boolean> {
  const ref = db().collection(QUEUE_COLLECTION).doc(rootId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const data = snap.data() as Partial<QueueGroup> | undefined;
    if (!data || data.active !== true) return false;
    if (asNum(data.leaseUntil, 0) > now) return false;
    tx.set(
      ref,
      {
        leaseOwner: runId,
        leaseUntil: now + LEASE_MS,
        lastProcessAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    return true;
  });
}

async function updateGroup(rootId: string, patch: Record<string, unknown>) {
  await db()
    .collection(QUEUE_COLLECTION)
    .doc(rootId)
    .set(patch, { merge: true });
}

async function loadGroupDocs(rootId: string): Promise<QueueDoc[]> {
  const snap = await db()
    .collection(QUEUE_COLLECTION)
    .doc(rootId)
    .collection("docs")
    .orderBy("index")
    .get();

  return snap.docs.map((doc) => {
    const data = doc.data();
    return {
      docId: doc.id,
      index: asNum(data.index, 0),
      userID: asString(data.userID),
      ad: asBool(data.ad, false),
      aspectRatio: asNum(data.aspectRatio, 1),
      debugMode: asBool(data.debugMode, false),
      editTime: asNum(data.editTime, 0),
      isAd: asBool(data.isAd, false),
      konum: asString(data.konum),
      locationCity: asString(data.locationCity),
      metin: asString(data.metin),
      originalPostID: asString(data.originalPostID),
      originalUserID: asString(data.originalUserID),
      paylasGizliligi: asNum(data.paylasGizliligi, 0),
      scheduledAt: asNum(data.scheduledAt, 0),
      sourceImgMap: asMapList(data.sourceImgMap),
      sourceImageUrls: asStringList(data.sourceImageUrls),
      sourceThumbnailUrl: asString(data.sourceThumbnailUrl),
      sourceVideoUrl: asString(data.sourceVideoUrl),
      tags: Array.isArray(data.tags) ? data.tags.map((item) => asString(item)).filter(Boolean) : [],
      yorum: asBool(data.yorum, true),
    };
  });
}

async function ensureGroupMedia(
  docs: QueueDoc[],
): Promise<{ ok: true } | { ok: false; reason: string }> {
  for (const doc of docs) {
    for (let index = 0; index < doc.sourceImageUrls.length; index += 1) {
      const sourceUrl = asString(doc.sourceImageUrls[index]);
      if (!sourceUrl) {
        return { ok: false, reason: `missing_source_image_url:${doc.docId}:${index}` };
      }
      const targetPath = `Posts/${doc.docId}/image_${index}${extFromUrl(sourceUrl, ".jpg")}`;
      try {
        await copyUrlToTarget({
          sourceUrl,
          targetPath,
        });
      } catch (error) {
        return {
          ok: false,
          reason: `copy_image_failed:${doc.docId}:${index}:${(error as Error).message}`,
        };
      }
    }

    const videoUrl = asString(doc.sourceVideoUrl);
    if (!videoUrl) continue;

    try {
      await copyUrlToTarget({
        sourceUrl: videoUrl,
        targetPath: `Posts/${doc.docId}/video.mp4`,
        customMetadata: {
          migrationMode: "true",
        },
      });
    } catch (error) {
      return {
        ok: false,
        reason: `copy_video_failed:${doc.docId}:${(error as Error).message}`,
      };
    }
  }

  return { ok: true };
}

async function resolveTargetMedia(sourceDoc: QueueDoc): Promise<MediaResolution> {
  const hasVideo = asString(sourceDoc.sourceVideoUrl).length > 0;
  const hasText = asString(sourceDoc.metin).length > 0;
  const sourceImages = sourceDoc.sourceImageUrls;

  if (!hasVideo && sourceImages.length === 0 && !hasText) {
    return {
      ok: false,
      reason: `empty_content:${sourceDoc.docId}`,
    };
  }

  const result = {
    ok: true as const,
    aspectRatio: asNum(sourceDoc.aspectRatio, 1),
    hlsMasterUrl: "",
    hlsStatus: "none",
    img: [] as string[],
    imgMap: [] as Array<{ url: string; aspectRatio: number }>,
    mediaKind: hasVideo ? "video" : sourceImages.length > 0 ? "image" : "text",
    thumbnail: "",
    video: "",
  };

  if (sourceImages.length > 0) {
    for (let index = 0; index < sourceImages.length; index += 1) {
      const storagePath = await pickExistingStoragePath(
        IMAGE_EXT_CANDIDATES.map((ext) => `Posts/${sourceDoc.docId}/image_${index}.${ext}`),
      );
      if (!storagePath) {
        return {
          ok: false,
          reason: `missing_image_${index}:${sourceDoc.docId}`,
        };
      }
      const url = await buildProtectedAssetUrl(storagePath);
      result.img.push(url);
      result.imgMap.push({
        url,
        aspectRatio: asNum(sourceDoc.sourceImgMap[index]?.aspectRatio, result.aspectRatio),
      });
    }
    if (!hasVideo && result.imgMap.length > 0) {
      result.aspectRatio = asNum(result.imgMap[0].aspectRatio, result.aspectRatio);
    }
  }

  if (hasVideo) {
    const [hlsExists] = await bucket().file(`Posts/${sourceDoc.docId}/hls/master.m3u8`).exists();
    if (!hlsExists) {
      return {
        ok: false,
        reason: `missing_hls_master:${sourceDoc.docId}`,
      };
    }

    const thumbPath = await pickExistingStoragePath(
      THUMB_EXT_CANDIDATES.map((ext) => `Posts/${sourceDoc.docId}/thumbnail.${ext}`),
    );
    if (!thumbPath) {
      return {
        ok: false,
        reason: `missing_video_thumbnail:${sourceDoc.docId}`,
      };
    }

    result.video = buildHlsUrl(sourceDoc.docId);
    result.hlsMasterUrl = result.video;
    result.hlsStatus = "ready";
    result.thumbnail = await buildProtectedAssetUrl(thumbPath);
  } else if (asString(sourceDoc.sourceThumbnailUrl).length > 0) {
    const thumbPath = await pickExistingStoragePath(
      THUMB_EXT_CANDIDATES.map((ext) => `Posts/${sourceDoc.docId}/thumbnail.${ext}`),
    );
    if (thumbPath) {
      result.thumbnail = await buildProtectedAssetUrl(thumbPath);
    }
  }

  return result;
}

async function loadUserProfile(
  uid: string,
  cache: Map<string, UserProfile | null>,
): Promise<UserProfile | null> {
  if (cache.has(uid)) return cache.get(uid) || null;

  const snap = await db().collection(USERS_COLLECTION).doc(uid).get();
  if (!snap.exists) {
    cache.set(uid, null);
    return null;
  }

  const data = snap.data() || {};
  const profile = {
    avatarUrl: asString(data.avatarUrl),
    nickname: asString(data.nickname),
    displayName:
      asString(data.displayName) ||
      asString(data.fullName) ||
      asString(data.nickname),
    rozet: asString(data.rozet),
    username: asString(data.username),
    fullName: asString(data.fullName) || asString(data.displayName),
  };

  cache.set(uid, profile);
  return profile;
}

async function ensurePlaceholderPosts(group: QueueGroup, docs: QueueDoc[], now: number) {
  const userCache = new Map<string, UserProfile | null>();
  const refs = docs.map((doc) => db().collection(POSTS_COLLECTION).doc(doc.docId));
  const snaps = refs.length > 0 ? await db().getAll(...refs) : [];
  const existingDocIds = new Set(
    snaps.filter((snap) => snap.exists).map((snap) => snap.id),
  );
  const batch = db().batch();
  let seededCount = 0;

  for (const doc of docs) {
    if (existingDocIds.has(doc.docId)) continue;
    if (!doc.userID) return false;
    const profile = await loadUserProfile(doc.userID, userCache);
    if (!profile) return false;

    batch.set(
      db().collection(POSTS_COLLECTION).doc(doc.docId),
      {
        ad: doc.ad,
        arsiv: false,
        aspectRatio: doc.aspectRatio,
        authorAvatarUrl: profile.avatarUrl,
        authorDisplayName: profile.displayName,
        authorNickname: profile.nickname,
        avatarUrl: profile.avatarUrl,
        debugMode: doc.debugMode,
        deletedPost: false,
        deletedPostTime: 0,
        displayName: profile.displayName,
        editTime: 0,
        flood: doc.index !== 0,
        floodCount: group.docCount,
        fullName: profile.fullName,
        gizlendi: false,
        hlsMasterUrl: "",
        hlsStatus: asString(doc.sourceVideoUrl).length > 0 ? "processing" : "none",
        hlsUpdatedAt: 0,
        img: [],
        imgMap: [],
        isAd: doc.isAd,
        isUploading: true,
        izBirakYayinTarihi: group.publishAt,
        konum: doc.konum,
        locationCity: doc.locationCity,
        mainFlood: buildTargetMainFlood(doc.docId, doc.index),
        metin: doc.metin,
        nickname: profile.nickname,
        originalPostID: doc.originalPostID,
        originalUserID: doc.originalUserID,
        paylasGizliligi: doc.paylasGizliligi,
        reshareMap: buildReshareMap(doc),
        rozet: profile.rozet,
        scheduledAt: doc.scheduledAt,
        sikayetEdildi: false,
        stabilized: false,
        stats: {
          commentCount: 0,
          likeCount: 0,
          reportedCount: 0,
          retryCount: 0,
          savedCount: 0,
          statsCount: 0,
        },
        tags: doc.tags,
        thumbnail: "",
        timeStamp: group.publishAt,
        updatedAt: now,
        userID: doc.userID,
        username: profile.username,
        video: "",
        yorum: doc.yorum,
        yorumMap: buildYorumMap(doc),
      },
      { merge: true },
    );
    seededCount += 1;
  }

  if (seededCount === 0) return true;

  batch.set(
    db().collection(QUEUE_COLLECTION).doc(group.rootId),
    {
      docSeededAt: asNum(group.docSeededAt, 0) > 0 ? group.docSeededAt : now,
      updatedAt: now,
    },
    { merge: true },
  );

  await batch.commit();
  return true;
}

async function makeDuePlaceholdersVisible(group: QueueGroup, docs: QueueDoc[], now: number) {
  const batch = db().batch();
  for (const doc of docs) {
    batch.set(
      db().collection(POSTS_COLLECTION).doc(doc.docId),
      {
        isUploading: false,
        updatedAt: now,
      },
      { merge: true },
    );
  }

  batch.set(
    db().collection(QUEUE_COLLECTION).doc(group.rootId),
    {
      lastError: "",
      lastErrorAt: 0,
      leaseOwner: "",
      leaseUntil: 0,
      state: "visible_waiting_media",
      updatedAt: now,
      visibleAt: now,
    },
    { merge: true },
  );

  await batch.commit();
}

async function rehideLeakedPlaceholders(docs: QueueDoc[], now: number) {
  if (docs.length === 0) return;

  const refs = docs.map((doc) => db().collection(POSTS_COLLECTION).doc(doc.docId));
  const snaps = await db().getAll(...refs);
  const batch = db().batch();
  let touched = 0;

  for (const snap of snaps) {
    if (!snap.exists) continue;
    const data = snap.data() || {};
    const hasMedia =
      asString(data.video).length > 0 ||
      asString(data.hlsMasterUrl).length > 0 ||
      asString(data.thumbnail).length > 0 ||
      (Array.isArray(data.img) && data.img.length > 0);
    if (data.isUploading === false && !hasMedia) {
      batch.set(
        snap.ref,
        {
          isUploading: true,
          updatedAt: now,
        },
        { merge: true },
      );
      touched += 1;
    }
  }

  if (touched > 0) {
    await batch.commit();
  }
}

async function buildPayloads(group: QueueGroup, docs: QueueDoc[]) {
  const userCache = new Map<string, UserProfile | null>();
  const payloads = [];
  const skipped: Array<{ docId: string; reason: string }> = [];

  for (const doc of docs) {
    if (!doc.userID) {
      if (doc.index === 0) {
        return {
          ok: false as const,
          reason: `missing_user_id:${doc.docId}`,
        };
      }
      skipped.push({
        docId: doc.docId,
        reason: `missing_user_id:${doc.docId}`,
      });
      continue;
    }

    const profile = await loadUserProfile(doc.userID, userCache);
    if (!profile) {
      if (doc.index === 0) {
        return {
          ok: false as const,
          reason: `missing_target_user:${doc.userID}`,
        };
      }
      skipped.push({
        docId: doc.docId,
        reason: `missing_target_user:${doc.userID}`,
      });
      continue;
    }

    const media = await resolveTargetMedia(doc);
    if (!media.ok) {
      if (doc.index === 0) {
        return {
          ok: false as const,
          reason: media.reason,
        };
      }
      skipped.push({
        docId: doc.docId,
        reason: media.reason,
      });
      continue;
    }

    payloads.push({
      docId: doc.docId,
      payload: {
        ad: doc.ad,
        arsiv: false,
        aspectRatio: media.aspectRatio,
        authorAvatarUrl: profile.avatarUrl,
        authorDisplayName: profile.displayName,
        authorNickname: profile.nickname,
        avatarUrl: profile.avatarUrl,
        debugMode: doc.debugMode,
        deletedPost: false,
        deletedPostTime: 0,
        displayName: profile.displayName,
        editTime: 0,
        flood: doc.index !== 0,
        floodCount: group.docCount,
        fullName: profile.fullName,
        gizlendi: false,
        hlsMasterUrl: media.hlsMasterUrl,
        hlsStatus: media.hlsStatus,
        hlsUpdatedAt: media.hlsStatus === "ready" ? group.publishAt : 0,
        img: media.img,
        imgMap: media.imgMap,
        isAd: doc.isAd,
        isUploading: false,
        izBirakYayinTarihi: group.publishAt,
        konum: doc.konum,
        locationCity: doc.locationCity,
        mainFlood: buildTargetMainFlood(doc.docId, doc.index),
        metin: doc.metin,
        nickname: profile.nickname,
        originalPostID: doc.originalPostID,
        originalUserID: doc.originalUserID,
        paylasGizliligi: doc.paylasGizliligi,
        reshareMap: buildReshareMap(doc),
        rozet: profile.rozet,
        scheduledAt: doc.scheduledAt,
        sikayetEdildi: false,
        stabilized: false,
        stats: {
          commentCount: 0,
          likeCount: 0,
          reportedCount: 0,
          retryCount: 0,
          savedCount: 0,
          statsCount: 0,
        },
        tags: doc.tags,
        thumbnail: media.thumbnail,
        timeStamp: group.publishAt,
        updatedAt: group.publishAt,
        userID: doc.userID,
        username: profile.username,
        video: media.video,
        yorum: doc.yorum,
        yorumMap: buildYorumMap(doc),
      },
    });
  }

  return {
    ok: true as const,
    payloads,
    skipped,
  };
}

async function publishGroup(group: QueueGroup, docs: QueueDoc[], now: number) {
  const payloads = await buildPayloads(group, docs);
  if (!payloads.ok) {
    await updateGroup(group.rootId, {
      lastError: payloads.reason,
      lastErrorAt: now,
      leaseOwner: "",
      leaseUntil: 0,
      publishAttempts: FieldValue.increment(1),
      state: "awaiting_media",
      updatedAt: now,
    });
    return false;
  }

  const batch = db().batch();
  for (const item of payloads.payloads) {
    batch.set(
      db().collection(POSTS_COLLECTION).doc(item.docId),
      item.payload,
      { merge: true },
    );
  }
  const hasSkipped = payloads.skipped.length > 0;
  batch.set(
    db().collection(QUEUE_COLLECTION).doc(group.rootId),
    {
      active: false,
      lastError: hasSkipped ? payloads.skipped[0].reason : "",
      lastErrorAt: hasSkipped ? now : 0,
      leaseOwner: "",
      leaseUntil: 0,
      publishedAt: now,
      state: hasSkipped ? "published_partial" : "published",
      updatedAt: now,
    },
    { merge: true },
  );
  await batch.commit();
  return true;
}

async function processGroup(rootId: string, runId: string, now: number) {
  const ref = db().collection(QUEUE_COLLECTION).doc(rootId);
  const snap = await ref.get();
  if (!snap.exists) return "missing";

  const group = snap.data() as QueueGroup;
  if (!group.active) {
    await updateGroup(rootId, {
      leaseOwner: "",
      leaseUntil: 0,
      updatedAt: now,
    });
    return "inactive";
  }

  const docs = await loadGroupDocs(rootId);
  if (docs.length === 0) {
    await updateGroup(rootId, {
      active: false,
      lastError: "missing_group_docs",
      lastErrorAt: now,
      leaseOwner: "",
      leaseUntil: 0,
      state: "failed",
      updatedAt: now,
    });
    return "failed";
  }

  const seeded = await ensurePlaceholderPosts(group, docs, now);
  if (!seeded) {
    await updateGroup(rootId, {
      lastError: "placeholder_seed_failed",
      lastErrorAt: now,
      leaseOwner: "",
      leaseUntil: 0,
      state: "failed",
      updatedAt: now,
    });
    return "failed";
  }

  await rehideLeakedPlaceholders(docs, now);

  const prep = await ensureGroupMedia(docs);
  if (!prep.ok) {
    await updateGroup(rootId, {
      lastError: prep.reason,
      lastErrorAt: now,
      leaseOwner: "",
      leaseUntil: 0,
      mediaAttempts: FieldValue.increment(1),
      state: "media_failed",
      updatedAt: now,
    });
    return "media_failed";
  }

  await updateGroup(rootId, {
    lastError: "",
    leaseOwner: "",
    leaseUntil: 0,
    mediaPreparedAt: group.mediaPreparedAt > 0 ? group.mediaPreparedAt : now,
    state: "media_prepared",
    updatedAt: now,
  });

  if (asNum(group.publishAt, 0) > now) {
    return "prepared";
  }

  const republishClaim = await claimLease(rootId, `${runId}_publish`, now);
  if (!republishClaim) {
    return "lease_lost";
  }

  const publishSnap = await ref.get();
  if (!publishSnap.exists) return "missing_after_prepare";
  const publishGroupData = publishSnap.data() as QueueGroup;
  return (await publishGroup(publishGroupData, docs, now)) ? "published" : "awaiting_media";
}

export const processPostsMigrationQueue = onSchedule(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    schedule: "every 1 minutes",
  },
  async () => {
    const now = Date.now();
    const runId = `posts_migration_${now}`;
    const activeSnap = await db()
      .collection(QUEUE_COLLECTION)
      .where("active", "==", true)
      .get();

    if (activeSnap.empty) {
      console.log("processPostsMigrationQueue no_active_groups");
      return;
    }

    const groups = activeSnap.docs
      .map((doc) => {
        const data = doc.data() as QueueGroup;
        return {
          ...data,
          rootId: asString(data.rootId) || doc.id,
        };
      })
      .sort((a, b) => asNum(a.publishAt, 0) - asNum(b.publishAt, 0));

    const selected = groups
      .filter((group) => asNum(group.publishAt, 0) <= now + PREP_HORIZON_MS)
      .slice(0, MAX_GROUPS_PER_RUN);

    if (selected.length === 0) {
      console.log("processPostsMigrationQueue no_groups_in_window");
      return;
    }

    const results: string[] = [];
    for (const group of selected) {
      const claimed = await claimLease(group.rootId, runId, now);
      if (!claimed) {
        results.push(`${group.rootId}:lease_busy`);
        continue;
      }

      try {
        const result = await processGroup(group.rootId, runId, now);
        results.push(`${group.rootId}:${result}`);
      } catch (error) {
        await updateGroup(group.rootId, {
          lastError: (error as Error).message,
          lastErrorAt: now,
          leaseOwner: "",
          leaseUntil: 0,
          state: "failed",
          updatedAt: now,
        });
        results.push(`${group.rootId}:failed`);
      }
    }

    console.log("processPostsMigrationQueue", {
      totalActiveGroups: activeSnap.size,
      selectedGroups: selected.length,
      results,
      runId,
    });
  },
);
