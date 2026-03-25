/**
 * TurqApp — Hybrid Feed Fan-out / Fan-in
 *
 * Problem: Mevcut feed tüm Posts'u çekip client'ta filtreler →
 *          100K kullanıcıda ölçeklenmez, Firestore okuma maliyeti yüksek
 *
 * Strateji:
 *   - Küçük hesaplar (<= FAN_OUT_THRESHOLD takipçi):
 *       POST oluşturulduğunda tüm takipçilerin feed'ine yazılır (fan-out at write)
 *   - Büyük hesaplar (> FAN_OUT_THRESHOLD takipçi, "celebrities"):
 *       Feed okunurken merge edilir (fan-in at read)
 *
 * Koleksiyon yapısı:
 *   userFeeds/{uid}/items/{postId}  → { postId, authorId, timeStamp, isCelebrity }
 *   celebAccounts/{uid}             → { uid, followerCount } (fan-in listesi)
 *
 * Client tarafı değişikliği:
 *   agenda_controller.dart'ta fetchAgendaBigData() metodunda
 *   userFeeds/{uid}/items sorgusuna geç + celebAccounts'tan fan-in merge et.
 *   (Bu şema CF tarafını hazır eder; client migration ayrı sprint.)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = () => admin.firestore();

/// Takipçi eşiği: üzerindeyse celebrity (fan-in), altındaysa fan-out
const FAN_OUT_THRESHOLD = 10_000;

/// Tek bir fan-out batch'inde işlenecek max takipçi sayısı
const FAN_OUT_BATCH_SIZE = 450; // Firestore batch limiti 500, güvenli margin

/// Feed item'ın geçerlilik süresi: 7 gün
const FEED_TTL_MS = 7 * 24 * 60 * 60 * 1000;

function isCountedRootPost(
  data: admin.firestore.DocumentData | undefined,
  nowMs: number = Date.now(),
): boolean {
  if (!data) return false;
  const timeStamp = Number(data.timeStamp || 0);
  const scheduledAt = Number(data.scheduledAt || 0);
  return (
    data.flood !== true &&
    data.arsiv !== true &&
    data.deletedPost !== true &&
    data.gizlendi !== true &&
    data.isUploading !== true &&
    scheduledAt <= 0 &&
    timeStamp > 0 &&
    timeStamp <= nowMs
  );
}

async function adjustAuthorPostCount(
  authorId: string,
  delta: number,
): Promise<void> {
  if (!authorId || delta == 0) return;
  await db().collection("users").doc(authorId).set(
    {
      counterOfPosts: admin.firestore.FieldValue.increment(delta),
    },
    { merge: true },
  );
}

export async function resolveFollowerCollection(authorId: string): Promise<string> {
  const followersSnap = await db()
    .collection("users")
    .doc(authorId)
    .collection("followers")
    .limit(1)
    .get();
  if (!followersSnap.empty) {
    return "followers";
  }
  return "TakipciLer";
}

export async function upsertPostIntoHybridFeed(args: {
  postId: string;
  authorId: string;
  timeStamp: number;
  isVideo: boolean;
}): Promise<void> {
  const { postId, authorId, timeStamp, isVideo } = args;
  if (!postId || !authorId) return;

  const authorDoc = await db().collection("users").doc(authorId).get();
  const followerCount: number =
    Number(authorDoc.data()?.followerCount) ||
    Number(authorDoc.data()?.takipciSayisi) ||
    Number(authorDoc.data()?.counterOfFollowers) ||
    0;

  if (followerCount > FAN_OUT_THRESHOLD) {
    await db().collection("celebAccounts").doc(authorId).set(
      { uid: authorId, followerCount, updatedAt: Date.now() },
      { merge: true }
    );
    await db()
      .collection("userFeeds")
      .doc(authorId)
      .collection("items")
      .doc(postId)
      .set(
        {
          postId,
          authorId,
          timeStamp,
          isVideo,
          expiresAt: timeStamp + FEED_TTL_MS,
          isCelebrity: true,
        },
        { merge: true }
      );
    return;
  }

  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  const followerCollection = await resolveFollowerCollection(authorId);

  while (true) {
    let q: admin.firestore.Query = db()
      .collection("users")
      .doc(authorId)
      .collection(followerCollection)
      .limit(FAN_OUT_BATCH_SIZE);

    if (lastDoc) q = q.startAfter(lastDoc);

    const followersSnap = await q.get();
    if (followersSnap.empty) break;

    const wb = db().batch();
    for (const followerDoc of followersSnap.docs) {
      const followerUid = followerDoc.id;
      const feedRef = db()
        .collection("userFeeds")
        .doc(followerUid)
        .collection("items")
        .doc(postId);

      wb.set(
        feedRef,
        {
          postId,
          authorId,
          timeStamp,
          isVideo,
          expiresAt: timeStamp + FEED_TTL_MS,
          isCelebrity: false,
        },
        { merge: true }
      );
    }

    await wb.commit();
    lastDoc = followersSnap.docs[followersSnap.docs.length - 1];
    if (followersSnap.docs.length < FAN_OUT_BATCH_SIZE) break;
  }

  await db()
    .collection("userFeeds")
    .doc(authorId)
    .collection("items")
    .doc(postId)
    .set(
      {
        postId,
        authorId,
        timeStamp,
        isVideo,
        expiresAt: timeStamp + FEED_TTL_MS,
        isCelebrity: false,
      },
      { merge: true }
    );
}

async function collectRelationIds(
  uid: string,
  relation: string
): Promise<string[]> {
  const normalizedUid = uid.trim();
  if (!normalizedUid) return [];

  const ids: string[] = [];
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

  while (true) {
    let q: admin.firestore.Query = db()
      .collection("users")
      .doc(normalizedUid)
      .collection(relation)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(450);
    if (lastDoc) q = q.startAfter(lastDoc);

    const snap = await q.get();
    if (snap.empty) break;

    ids.push(...snap.docs.map((doc) => doc.id).filter((id) => id.trim().length > 0));
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < 450) break;
  }

  return Array.from(new Set(ids));
}

function isVisiblePostRecord(data: FirebaseFirestore.DocumentData | undefined): boolean {
  if (!data) return false;
  return (
    data.arsiv !== true &&
    data.deletedPost !== true &&
    data.gizlendi !== true &&
    data.isUploading !== true
  );
}

export async function rebuildHybridFeedForUser(args: {
  uid: string;
  perAuthorLimit?: number;
}): Promise<{
  uid: string;
  followingCount: number;
  authorCount: number;
  postCount: number;
  writeCount: number;
}> {
  const normalizedUid = args.uid.trim();
  if (!normalizedUid) {
    return {
      uid: "",
      followingCount: 0,
      authorCount: 0,
      postCount: 0,
      writeCount: 0,
    };
  }

  const perAuthorLimit = Math.min(Math.max(Number(args.perAuthorLimit) || 3, 1), 20);
  const cutoffMs = Date.now() - FEED_TTL_MS;
  const followings = await collectRelationIds(normalizedUid, "followings");
  const authorIds = Array.from(new Set<string>([normalizedUid, ...followings]));
  const celebIds = new Set(
    (
      await Promise.all(
        authorIds
          .filter((id) => id.trim().length > 0)
          .reduce<string[][]>((chunks, id, index) => {
            const chunkIndex = Math.floor(index / 10);
            if (!chunks[chunkIndex]) chunks[chunkIndex] = [];
            chunks[chunkIndex].push(id);
            return chunks;
          }, [])
          .map(async (chunk) => {
            const snap = await db()
              .collection("celebAccounts")
              .where(admin.firestore.FieldPath.documentId(), "in", chunk)
              .get();
            return snap.docs.map((doc) => doc.id);
          })
      )
    ).flat()
  );

  const postEntries = (
    await Promise.all(
      authorIds.map(async (authorId) => {
        const postsSnap = await db()
          .collection("Posts")
          .where("userID", "==", authorId)
          .where("arsiv", "==", false)
          .where("deletedPost", "==", false)
          .orderBy("timeStamp", "desc")
          .limit(perAuthorLimit)
          .get();

        return postsSnap.docs
          .filter((doc) => {
            const data = doc.data();
            const timeStamp = Number(data?.timeStamp) || 0;
            return isVisiblePostRecord(data) && timeStamp >= cutoffMs;
          })
          .map((doc) => {
            const data = doc.data();
            const timeStamp = Number(data?.timeStamp) || Date.now();
            return {
              postId: doc.id,
              authorId,
              timeStamp,
              isVideo: !!(data?.videoHLSMasterUrl || data?.hlsMasterUrl || data?.video),
              isCelebrity: celebIds.has(authorId),
            };
          });
      })
    )
  ).flat();

  const deduped = new Map<string, {
    postId: string;
    authorId: string;
    timeStamp: number;
    isVideo: boolean;
    isCelebrity: boolean;
  }>();
  for (const entry of postEntries) {
    deduped.set(entry.postId, entry);
  }

  const entries = Array.from(deduped.values()).sort((a, b) => b.timeStamp - a.timeStamp);
  let writeCount = 0;
  for (let i = 0; i < entries.length; i += 400) {
    const chunk = entries.slice(i, i + 400);
    const wb = db().batch();
    for (const entry of chunk) {
      wb.set(
        db()
          .collection("userFeeds")
          .doc(normalizedUid)
          .collection("items")
          .doc(entry.postId),
        {
          postId: entry.postId,
          authorId: entry.authorId,
          timeStamp: entry.timeStamp,
          isVideo: entry.isVideo,
          expiresAt: entry.timeStamp + FEED_TTL_MS,
          isCelebrity: entry.isCelebrity,
        },
        { merge: true }
      );
      writeCount += 1;
    }
    await wb.commit();
  }

  return {
    uid: normalizedUid,
    followingCount: followings.length,
    authorCount: authorIds.length,
    postCount: entries.length,
    writeCount,
  };
}

export const backfillHybridFeedForUser = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }

    const requestedUid = typeof data?.uid === "string" ? data.uid.trim() : "";
    const targetUid = requestedUid || context.auth.uid;
    const isAdmin = (context.auth.token as { admin?: unknown } | undefined)?.admin === true;
    if (!isAdmin && targetUid !== context.auth.uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can backfill other users"
      );
    }

    const result = await rebuildHybridFeedForUser({
      uid: targetUid,
      perAuthorLimit: Number(data?.perAuthorLimit) || 3,
    });
    console.log("[HybridFeed] Backfill callable complete", result);
    return result;
  });

// ─────────────────────────────────────────────────────────
// 📤 TRIGGER: Post oluşturulduğunda fan-out başlat
// ─────────────────────────────────────────────────────────

export const onPostCreate = functions
  .region("europe-west1")
  .firestore.document("Posts/{postId}")
  .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const data = snap.data();
    if (!data) return;

    const authorId: string = data.userID || "";
    const timeStamp: number = data.timeStamp || Date.now();
    const isVideo: boolean = !!(data.videoHLSMasterUrl || data.hlsMasterUrl || data.video);
    const arsiv: boolean = data.arsiv === true;
    const deletedPost: boolean = data.deletedPost === true;

    if (!authorId || arsiv || deletedPost) return;

    try {
      await upsertPostIntoHybridFeed({
        postId,
        authorId,
        timeStamp,
        isVideo,
      });

      console.log("[HybridFeed] Fan-out complete");
    } catch (e) {
      console.error("[HybridFeed] onPostCreate error:", e);
    }

    try {
      if (isCountedRootPost(data)) {
        await adjustAuthorPostCount(authorId, 1);
      }
    } catch (e) {
      console.error("[HybridFeed] onPostCreate counter error:", e);
    }
  });

export const onPostBecomeVisible = functions
  .region("europe-west1")
  .firestore.document("Posts/{postId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!after) return;

    const postId = context.params.postId;
    const authorId: string = (after.userID || "").toString();
    const timeStamp: number = Number(after.timeStamp) || Date.now();
    const isVideo: boolean = !!(after.videoHLSMasterUrl || after.hlsMasterUrl || after.video);

    const beforeVisible =
      before != null &&
      before.arsiv !== true &&
      before.deletedPost !== true &&
      before.gizlendi !== true &&
      before.isUploading !== true;
    const afterVisible =
      after.arsiv !== true &&
      after.deletedPost !== true &&
      after.gizlendi !== true &&
      after.isUploading !== true;
    const beforeCounted = isCountedRootPost(before);
    const afterCounted = isCountedRootPost(after);

    if (!authorId) return;

    if (!beforeVisible && afterVisible) {
      try {
        await upsertPostIntoHybridFeed({
          postId,
          authorId,
          timeStamp,
          isVideo,
        });
        console.log("[HybridFeed] Visibility upsert complete");
      } catch (e) {
        console.error("[HybridFeed] onPostBecomeVisible error:", e);
      }
    }

    try {
      if (!beforeCounted && afterCounted) {
        await adjustAuthorPostCount(authorId, 1);
      } else if (beforeCounted && !afterCounted) {
        await adjustAuthorPostCount(authorId, -1);
      }
    } catch (e) {
      console.error("[HybridFeed] onPostVisibility counter error:", e);
    }
  });

// ─────────────────────────────────────────────────────────
// 🗑️ TRIGGER: Post silindiğinde feed item'larını temizle
// ─────────────────────────────────────────────────────────

export const onPostDelete = functions
  .region("europe-west1")
  .firestore.document("Posts/{postId}")
  .onDelete(async (snap, context) => {
    const postId = context.params.postId;
    const authorId: string = snap.data()?.userID || "";
    const wasCounted = isCountedRootPost(snap.data());
    if (!authorId) return;

    try {
      // Author'ın kendi feed'inden sil
      await db()
        .collection("userFeeds")
        .doc(authorId)
        .collection("items")
        .doc(postId)
        .delete();

      // Takipçilerin feed'inden temizle (collectionGroup sorgusu)
      let lastDocRef: admin.firestore.QueryDocumentSnapshot | null = null;
      while (true) {
        let q: admin.firestore.Query = db()
          .collectionGroup("items")
          .where("postId", "==", postId)
          .limit(400);
        if (lastDocRef) q = q.startAfter(lastDocRef);

        const snap = await q.get();
        if (snap.empty) break;

        const wb = db().batch();
        for (const d of snap.docs) wb.delete(d.ref);
        await wb.commit();

        lastDocRef = snap.docs[snap.docs.length - 1];
        if (snap.docs.length < 400) break;
      }

      console.log("[HybridFeed] Feed items cleaned up");
    } catch (e) {
      console.error("[HybridFeed] onPostDelete error:", e);
    }

    try {
      if (wasCounted) {
        await adjustAuthorPostCount(authorId, -1);
      }
    } catch (e) {
      console.error("[HybridFeed] onPostDelete counter error:", e);
    }
  });

// ─────────────────────────────────────────────────────────
// 👤 TRIGGER: Yeni takipçi geldiğinde author'ın son N postunu feed'e ekle
// ─────────────────────────────────────────────────────────

export const onNewFollower = functions
  .region("europe-west1")
  .firestore.document("users/{authorId}/{relation}/{followerId}")
  .onCreate(async (snap, context) => {
    const authorId = context.params.authorId;
    const relation = context.params.relation;
    const followerId = context.params.followerId;
    if (relation !== "followers" && relation !== "TakipciLer") {
      return;
    }

    try {
      // Author'ın son 20 postunu yeni takipçinin feed'ine ekle
      const postsSnap = await db()
        .collection("Posts")
        .where("userID", "==", authorId)
        .where("arsiv", "==", false)
        .where("deletedPost", "==", false)
        .orderBy("timeStamp", "desc")
        .limit(20)
        .get();

      if (postsSnap.empty) return;

      const wb = db().batch();
      const now = Date.now();
      for (const postDoc of postsSnap.docs) {
        const d = postDoc.data();
        const feedRef = db()
          .collection("userFeeds")
          .doc(followerId)
          .collection("items")
          .doc(postDoc.id);

        wb.set(feedRef, {
          postId: postDoc.id,
          authorId,
          timeStamp: d.timeStamp || now,
          isVideo: !!(d.videoHLSMasterUrl || d.video),
          expiresAt: (d.timeStamp || now) + FEED_TTL_MS,
          isCelebrity: false,
        });
      }
      await wb.commit();

      console.log(`[HybridFeed] Backfilled ${postsSnap.size} posts for new follower`);
    } catch (e) {
      console.error(`[HybridFeed] onNewFollower error:`, e);
    }
  });

// ─────────────────────────────────────────────────────────
// 🧹 SCHEDULED: Süresi dolmuş feed item'larını temizle (günlük)
// ─────────────────────────────────────────────────────────

export const cleanupExpiredFeedItems = functions
  .region("europe-west1")
  .pubsub.schedule("every 24 hours")
  .onRun(async () => {
    const now = Date.now();
    let cleaned = 0;

    let lastDocRef: admin.firestore.QueryDocumentSnapshot | null = null;
    while (true) {
      let q: admin.firestore.Query = db()
        .collectionGroup("items")
        .where("expiresAt", "<", now)
        .limit(400);
      if (lastDocRef) q = q.startAfter(lastDocRef);

      const snap = await q.get();
      if (snap.empty) break;

      const wb = db().batch();
      for (const d of snap.docs) wb.delete(d.ref);
      await wb.commit();

      cleaned += snap.docs.length;
      lastDocRef = snap.docs[snap.docs.length - 1];
      if (snap.docs.length < 400) break;
    }

    console.log(`[HybridFeed] Cleaned ${cleaned} expired feed items`);
    return null;
  });
