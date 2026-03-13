import { getApps, initializeApp } from "firebase-admin/app";
import {
  FieldPath,
  FieldValue,
  getFirestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import { generateTagDetails, getTagSettings, writeTagIndex } from "./04_tagSettings";

function getEnv(name: string): string {
  return String(process.env[name] || "").trim();
}

const REGION = getEnv("TYPESENSE_REGION") || "us-central1";

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

function normalizeTagRaw(tag: unknown): string {
  return String(tag || "").trim().toLocaleLowerCase("tr-TR");
}

function normalizeForCompare(s: string): string {
  return (s || "")
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .trim();
}

function dedupeTags(tags: string[]): string[] {
  return Array.from(new Set(tags.map(normalizeTagRaw).filter(Boolean)));
}

function isAllowedTag(tag: string, cfg: Awaited<ReturnType<typeof getTagSettings>>): boolean {
  const t = normalizeTagRaw(tag);
  if (!t) return false;
  if (t.length < cfg.tagMinLength || t.length > cfg.tagMaxLength) return false;
  if (/^\d+$/.test(t)) return false;
  const n = normalizeForCompare(t);
  const banned = new Set((cfg.bannedWords || []).map((x: string) => normalizeForCompare(x)));
  const stop = new Set((cfg.stopwords || []).map((x: string) => normalizeForCompare(x)));
  if (banned.has(n)) return false;
  if (stop.has(n)) return false;
  return true;
}

async function desiredTagsFromPostData(
  data: Record<string, any>,
  cfg: Awaited<ReturnType<typeof getTagSettings>>
): Promise<string[]> {
  const analysis = (data.analysis as Record<string, any> | undefined) || {};
  let hashtags = Array.isArray(analysis.hashtags) ? analysis.hashtags : [];
  let captionTags = Array.isArray(analysis.captionTags) ? analysis.captionTags : [];

  // analysis yoksa caption'dan üret (uygulama şemasında sık görülen durum)
  if (!hashtags.length && !captionTags.length) {
    const caption = String(data.metin || data.caption || "");
    if (caption.trim().length > 0) {
      const derived = await generateTagDetails({ caption });
      hashtags = derived.hashtags || [];
      captionTags = derived.captionTags || [];
    }
  }

  const rootTags = Array.isArray(data.tags) ? data.tags : [];
  return dedupeTags([...hashtags, ...captionTags, ...rootTags]).filter((t) =>
    isAllowedTag(t, cfg)
  );
}

async function hashtagTagsFromPostData(
  data: Record<string, any>,
  cfg: Awaited<ReturnType<typeof getTagSettings>>
): Promise<string[]> {
  const analysis = (data.analysis as Record<string, any> | undefined) || {};
  let hashtags = Array.isArray(analysis.hashtags) ? analysis.hashtags : [];
  if (!hashtags.length) {
    const caption = String(data.metin || data.caption || "");
    if (caption.trim().length > 0) {
      const derived = await generateTagDetails({ caption });
      hashtags = derived.hashtags || [];
    }
  }
  return dedupeTags(hashtags).filter((t) => isAllowedTag(t, cfg));
}

async function existingTagsForPost(postId: string): Promise<string[]> {
  const db = getFirestore();
  const fromPostSide = await db
    .collection("Posts")
    .doc(postId)
    .collection("tags")
    .get();
  const fromPostHashtagSide = await db
    .collection("Posts")
    .doc(postId)
    .collection("hashtags")
    .get();

  const out = new Set<string>();
  for (const doc of fromPostSide.docs) {
    out.add(String(doc.id || "").trim().toLocaleLowerCase("tr-TR"));
  }
  for (const doc of fromPostHashtagSide.docs) {
    out.add(String(doc.id || "").trim().toLocaleLowerCase("tr-TR"));
  }
  return Array.from(out);
}

async function removeTagLinks(postId: string, tags: string[]): Promise<void> {
  if (!tags.length) return;
  const db = getFirestore();
  const chunkSize = 200;
  for (let i = 0; i < tags.length; i += chunkSize) {
    const chunk = tags.slice(i, i + chunkSize);
    await db.runTransaction(async (tx) => {
      const refs = chunk.map((tag) => db.doc(`tags/${tag}/posts/${postId}`));
      const snaps = await tx.getAll(...refs);

      for (let idx = 0; idx < chunk.length; idx++) {
        const tag = chunk[idx];
        const linkSnap = snaps[idx];
        tx.delete(db.doc(`Posts/${postId}/tags/${tag}`));
        tx.delete(db.doc(`Posts/${postId}/hashtags/${tag}`));
        if (!linkSnap.exists) continue;
        const wasHashtag = linkSnap.get("hasHashtag") === true;
        tx.delete(linkSnap.ref);
        tx.set(
          db.doc(`tags/${tag}`),
          {
            count: FieldValue.increment(-1),
            hashtagCount: FieldValue.increment(wasHashtag ? -1 : 0),
            plainCount: FieldValue.increment(wasHashtag ? 0 : -1),
          },
          { merge: true }
        );
      }
    });
  }
}

type ReconcileInput = {
  limit?: number;
  cursor?: string;
  dryRun?: boolean;
};

type ReconcileOutput = {
  scanned: number;
  updated: number;
  addedLinks: number;
  removedLinks: number;
  nextCursor: string | null;
  done: boolean;
};

type PruneInput = {
  limit?: number;
  cursor?: string;
  dryRun?: boolean;
};

type PruneOutput = {
  scanned: number;
  deletedTagDocs: number;
  normalizedCounts: number;
  cleanedAddedAtFields: number;
  nextCursor: string | null;
  done: boolean;
};

function buildMeta(data: Record<string, any>) {
  const hlsMaster = String(data.hlsMasterUrl || data.hlsUrl || "");
  const videoUrl = String(data.video || data.rawVideoUrl || "");
  const hlsReady =
    data.hlsReady === true ||
    (String(data.hlsStatus || "").toLowerCase() === "ready" &&
      (hlsMaster.length > 0 || videoUrl.includes(".m3u8")));
  return {
    authorId: String(data.authorId || data.userID || ""),
    type: String(data.type || "video"),
    visibility: String(data.visibility || "public"),
    status: String(data.status || "published"),
    isArchived: data.isArchived === true || data.arsiv === true,
    isDeleted: data.isDeleted === true || data.deletedPost === true,
    isHidden: data.isHidden === true || data.gizlendi === true,
    isUploading: data.isUploading === true,
    hlsReady,
    createdAt: data.createdAt || data.timeStamp || Date.now(),
  };
}

function shouldKeepPostInTagIndex(data: Record<string, any> | undefined): boolean {
  if (!data) return false;
  const status = String(data.status || "published");
  const visibility = String(
    data.visibility ||
      ((Number(data.paylasGizliligi) === 0 || data.paylasGizliligi === undefined)
        ? "public"
        : "private")
  );
  const type = String(data.type || "").toLocaleLowerCase("tr-TR");
  const hasImageUrl =
    String(data.imageURL || data.thumbnail || "").trim().length > 0;
  const hasImageArray =
    (Array.isArray(data.images) &&
      data.images.some((x: unknown) => String(x || "").trim().length > 0)) ||
    (Array.isArray(data.img) &&
      data.img.some((x: unknown) => String(x || "").trim().length > 0));
  const isImagePost = type === "image" || type === "photo" || hasImageUrl || hasImageArray;
  const hlsMaster = String(data.hlsMasterUrl || data.hlsUrl || "");
  const videoUrl = String(data.video || data.rawVideoUrl || "");
  const isVideoReady =
    data.hlsReady === true ||
    (String(data.hlsStatus || "").toLowerCase() === "ready" &&
      (hlsMaster.length > 0 || videoUrl.includes(".m3u8")));
  return (
    data.isArchived !== true &&
    data.arsiv !== true &&
    data.isDeleted !== true &&
    data.deletedPost !== true &&
    data.isHidden !== true &&
    data.gizlendi !== true &&
    data.isUploading !== true &&
    status === "published" &&
    visibility === "public" &&
    (isVideoReady || isImagePost)
  );
}

export const f16_syncPostTagsOnWrite = onDocumentWritten(
  {
    document: "Posts/{postId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (event) => {
    ensureAdmin();

    const postId = String(event.params.postId || "");
    if (!postId) return;

    const afterData = event.data?.after?.data() as Record<string, any> | undefined;
    const tagCfg = await getTagSettings();
    const existing = await existingTagsForPost(postId);

    let desired: string[] = [];
    if (shouldKeepPostInTagIndex(afterData)) {
      desired = await desiredTagsFromPostData(afterData as Record<string, any>, tagCfg);
    }

    const desiredSet = new Set(desired);
    const toRemove = existing.filter((t) => !desiredSet.has(t));
    const toAdd = desired.filter((t) => !existing.includes(t));

    if (toRemove.length) {
      await removeTagLinks(postId, toRemove);
    }

    if (toAdd.length && afterData) {
      const meta = buildMeta(afterData);
      await writeTagIndex(postId, toAdd, {
        ...meta,
        trendThreshold: tagCfg.trendThreshold,
        trendWindowHours: tagCfg.trendWindowHours,
        hashtagTags: await hashtagTagsFromPostData(afterData, tagCfg),
      });
    }
  }
);

function validateAuth(request: CallableRequest) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "auth_required");
  }
  if (request.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "admin_required");
  }
}

async function fetchPosts(limit: number, cursor?: string) {
  const db = getFirestore();
  let q = db.collection("Posts").orderBy(FieldPath.documentId()).limit(limit);

  if (cursor) {
    q = q.startAfter(cursor);
  }
  return q.get();
}

export const f15_reconcilePostTags = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
  },
  async (request: CallableRequest<ReconcileInput>): Promise<ReconcileOutput> => {
    ensureAdmin();
    validateAuth(request);

    const limit = Math.max(1, Math.min(300, Number(request.data?.limit || 100)));
    const cursor = request.data?.cursor || undefined;
    const dryRun = request.data?.dryRun === true;
    const tagCfg = await getTagSettings();

    const snap = await fetchPosts(limit, cursor);
    const posts = snap.docs as QueryDocumentSnapshot[];

    let scanned = 0;
    let updated = 0;
    let addedLinks = 0;
    let removedLinks = 0;

    for (const doc of posts) {
      scanned += 1;
      const data = doc.data() as Record<string, any>;
      const postId = doc.id;

      const desired = await desiredTagsFromPostData(data, tagCfg);
      const existing = await existingTagsForPost(postId);

      const desiredSet = new Set(desired);
      const existingSet = new Set(existing);

      const toAdd = desired.filter((t) => !existingSet.has(t));
      const toRemove = existing.filter((t) => !desiredSet.has(t));

      if (!toAdd.length && !toRemove.length) continue;

      updated += 1;
      addedLinks += toAdd.length;
      removedLinks += toRemove.length;

      if (dryRun) continue;

      if (toAdd.length) {
        const meta = buildMeta(data);
        await writeTagIndex(postId, toAdd, {
          ...meta,
          trendThreshold: tagCfg.trendThreshold,
          trendWindowHours: tagCfg.trendWindowHours,
          hashtagTags: await hashtagTagsFromPostData(data, tagCfg),
        });
      }
      if (toRemove.length) {
        await removeTagLinks(postId, toRemove);
      }
    }

    const last = posts[posts.length - 1];
    const nextCursor = last ? last.id : null;
    const done = posts.length < limit;

    return {
      scanned,
      updated,
      addedLinks,
      removedLinks,
      nextCursor,
      done,
    };
  }
);

export const f15_pruneTagsCollection = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
  },
  async (request: CallableRequest<PruneInput>): Promise<PruneOutput> => {
    ensureAdmin();
    validateAuth(request);

    const db = getFirestore();
    const limit = Math.max(1, Math.min(300, Number(request.data?.limit || 100)));
    const cursor = request.data?.cursor || undefined;
    const dryRun = request.data?.dryRun === true;

    let q = db.collection("tags").orderBy(FieldPath.documentId()).limit(limit);
    if (cursor) {
      q = q.startAfter(cursor);
    }

    const snap = await q.get();
    const docs = snap.docs;

    let scanned = 0;
    let deletedTagDocs = 0;
    let normalizedCounts = 0;
    let cleanedAddedAtFields = 0;

    for (const tagDoc of docs) {
      scanned += 1;
      const postsSnap = await tagDoc.ref.collection("Posts").limit(1000).get();
      const actualCount = postsSnap.size;
      const storedCount = Number(tagDoc.data()?.count || 0);

      const docsWithAddedAt = postsSnap.docs.filter((d) => d.get("addedAt") != null);
      if (docsWithAddedAt.length > 0) {
        cleanedAddedAtFields += docsWithAddedAt.length;
        if (!dryRun) {
          let batch = db.batch();
          let writes = 0;
          for (const d of docsWithAddedAt) {
            batch.set(d.ref, { addedAt: FieldValue.delete() }, { merge: true });
            writes += 1;
            if (writes >= 400) {
              await batch.commit();
              batch = db.batch();
              writes = 0;
            }
          }
          if (writes > 0) {
            await batch.commit();
          }
        }
      }

      if (actualCount === 0) {
        deletedTagDocs += 1;
        if (!dryRun) {
          await tagDoc.ref.delete();
        }
        continue;
      }

      if (storedCount !== actualCount) {
        normalizedCounts += 1;
        if (!dryRun) {
          await tagDoc.ref.set(
            {
              count: actualCount,
            },
            { merge: true }
          );
        }
      }
    }

    const last = docs[docs.length - 1];
    const nextCursor = last ? last.id : null;
    const done = docs.length < limit;

    return {
      scanned,
      deletedTagDocs,
      normalizedCounts,
      cleanedAddedAtFields,
      nextCursor,
      done,
    };
  }
);

// New numbered names (16_*) while keeping backward-compatible aliases (15_*).
export const f16_reconcilePostTags = f15_reconcilePostTags;
export const f16_pruneTagsCollection = f15_pruneTagsCollection;
