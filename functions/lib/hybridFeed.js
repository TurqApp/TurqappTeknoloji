"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupExpiredFeedItems = exports.onNewFollower = exports.onPostDelete = exports.onPostBecomeVisible = exports.onPostCreate = exports.backfillHybridFeedForUser = void 0;
exports.resolveFollowerCollection = resolveFollowerCollection;
exports.upsertPostIntoHybridFeed = upsertPostIntoHybridFeed;
exports.rebuildHybridFeedForUser = rebuildHybridFeedForUser;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const notificationInbox_1 = require("./notificationInbox");
const hybridFeedContract_1 = require("./hybridFeedContract");
const db = () => admin.firestore();
/// Takipçi eşiği: üzerindeyse celebrity (fan-in), altındaysa fan-out
const FAN_OUT_THRESHOLD = 10000;
/// Tek bir fan-out batch'inde işlenecek max takipçi sayısı
const FAN_OUT_BATCH_SIZE = 450; // Firestore batch limiti 500, güvenli margin
/// Feed item'ın geçerlilik süresi: 7 gün
const FEED_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const FOLLOWED_POST_NOTIFICATION_FIELD = "followedPostNotificationSentAt";
const FOLLOWED_POST_SUBCOLLECTION = "postNotificationSubscribers";
const NOTIFICATION_BATCH_SIZE = 400;
function asTrimmedString(value) {
    return typeof value === "string" ? value.trim() : "";
}
function firstNonEmptyString(...values) {
    for (const value of values) {
        if (typeof value === "string" && value.trim().length > 0) {
            return value.trim();
        }
        if (Array.isArray(value)) {
            for (const entry of value) {
                if (typeof entry === "string" && entry.trim().length > 0) {
                    return entry.trim();
                }
            }
        }
    }
    return "";
}
function resolveAuthorTitle(data) {
    return firstNonEmptyString(data?.authorDisplayName, data?.authorNickname, data?.nickname, data?.username, data?.fullName, "TurqApp");
}
function resolveAuthorAvatarUrl(data) {
    return firstNonEmptyString(data?.authorAvatarUrl, data?.avatarUrl, data?.profileImage);
}
function resolvePostPreviewImage(data) {
    return firstNonEmptyString(data?.thumbnail, data?.imageUrl, data?.imageURL, data?.coverImageUrl, data?.images, data?.img);
}
async function claimFollowedPostNotification(postRef) {
    return db().runTransaction(async (tx) => {
        const snap = await tx.get(postRef);
        if (!snap.exists)
            return false;
        const data = snap.data() || {};
        if (Number(data[FOLLOWED_POST_NOTIFICATION_FIELD] || 0) > 0) {
            return false;
        }
        tx.set(postRef, {
            [FOLLOWED_POST_NOTIFICATION_FIELD]: Date.now(),
        }, { merge: true });
        return true;
    });
}
async function notifyFollowedPostSubscribers(args) {
    const { postId, postRef, data } = args;
    const authorId = asTrimmedString(data.userID);
    if (!postId || !authorId || !isVisiblePostRecord(data))
        return;
    const claimed = await claimFollowedPostNotification(postRef);
    if (!claimed)
        return;
    const timeStamp = Number(data.timeStamp) || Date.now();
    const title = resolveAuthorTitle(data);
    const body = "yeni bir gönderi paylaştı";
    const avatarUrl = resolveAuthorAvatarUrl(data);
    const imageUrl = resolvePostPreviewImage(data);
    let lastDoc = null;
    while (true) {
        let query = db()
            .collection("users")
            .doc(authorId)
            .collection(FOLLOWED_POST_SUBCOLLECTION)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(NOTIFICATION_BATCH_SIZE);
        if (lastDoc)
            query = query.startAfter(lastDoc);
        const subscribersSnap = await query.get();
        if (subscribersSnap.empty)
            break;
        const batch = db().batch();
        for (const subscriberDoc of subscribersSnap.docs) {
            const subscriberUid = subscriberDoc.id.trim();
            if (!subscriberUid || subscriberUid == authorId)
                continue;
            const payload = (0, notificationInbox_1.buildInboxPayload)(subscriberUid, {
                fromUserID: authorId,
                postID: postId,
                type: "posts",
                followedPostSubscriber: true,
                title,
                body,
                desc: body,
                timeStamp,
                ...(avatarUrl ? { avatarUrl } : {}),
                ...(imageUrl ? { imageUrl, thumbnail: imageUrl } : {}),
            });
            batch.set(db()
                .collection("users")
                .doc(subscriberUid)
                .collection("notifications")
                .doc(`followed_post_${postId}`), payload, { merge: true });
        }
        await batch.commit();
        lastDoc = subscribersSnap.docs[subscribersSnap.docs.length - 1];
        if (subscribersSnap.docs.length < NOTIFICATION_BATCH_SIZE)
            break;
    }
}
function isCountedRootPost(data, nowMs = Date.now()) {
    if (!data)
        return false;
    const timeStamp = Number(data.timeStamp || 0);
    const scheduledAt = Number(data.scheduledAt || 0);
    return (data.flood !== true &&
        data.arsiv !== true &&
        data.deletedPost !== true &&
        data.gizlendi !== true &&
        data.isUploading !== true &&
        scheduledAt <= 0 &&
        timeStamp > 0 &&
        timeStamp <= nowMs);
}
async function adjustAuthorPostCount(authorId, delta) {
    if (!authorId || delta == 0)
        return;
    await db().collection("users").doc(authorId).set({
        counterOfPosts: admin.firestore.FieldValue.increment(delta),
    }, { merge: true });
}
async function resolveFollowerCollection(authorId) {
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
async function upsertPostIntoHybridFeed(args) {
    const { postId, authorId, timeStamp, isVideo } = args;
    if (!postId || !authorId)
        return;
    const authorDoc = await db().collection("users").doc(authorId).get();
    const followerCount = Number(authorDoc.data()?.counterOfFollowers) ||
        0;
    if (followerCount > FAN_OUT_THRESHOLD) {
        await db().collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.celebrityCollection).doc(authorId).set({ uid: authorId, followerCount, updatedAt: Date.now() }, { merge: true });
        await db()
            .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryCollection)
            .doc(authorId)
            .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
            .doc(postId)
            .set({
            [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.postId]: postId,
            [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.authorId]: authorId,
            [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.timeStamp]: timeStamp,
            [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isVideo]: isVideo,
            [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.expiresAt]: timeStamp + FEED_TTL_MS,
            [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isCelebrity]: true,
        }, { merge: true });
        return;
    }
    let lastDoc = null;
    const followerCollection = await resolveFollowerCollection(authorId);
    while (true) {
        let q = db()
            .collection("users")
            .doc(authorId)
            .collection(followerCollection)
            .limit(FAN_OUT_BATCH_SIZE);
        if (lastDoc)
            q = q.startAfter(lastDoc);
        const followersSnap = await q.get();
        if (followersSnap.empty)
            break;
        const wb = db().batch();
        for (const followerDoc of followersSnap.docs) {
            const followerUid = followerDoc.id;
            const feedRef = db()
                .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryCollection)
                .doc(followerUid)
                .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
                .doc(postId);
            wb.set(feedRef, {
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.postId]: postId,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.authorId]: authorId,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.timeStamp]: timeStamp,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isVideo]: isVideo,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.expiresAt]: timeStamp + FEED_TTL_MS,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isCelebrity]: false,
            }, { merge: true });
        }
        await wb.commit();
        lastDoc = followersSnap.docs[followersSnap.docs.length - 1];
        if (followersSnap.docs.length < FAN_OUT_BATCH_SIZE)
            break;
    }
    await db()
        .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryCollection)
        .doc(authorId)
        .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
        .doc(postId)
        .set({
        [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.postId]: postId,
        [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.authorId]: authorId,
        [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.timeStamp]: timeStamp,
        [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isVideo]: isVideo,
        [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.expiresAt]: timeStamp + FEED_TTL_MS,
        [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isCelebrity]: false,
    }, { merge: true });
}
async function collectRelationIds(uid, relation) {
    const normalizedUid = uid.trim();
    if (!normalizedUid)
        return [];
    const ids = [];
    let lastDoc = null;
    while (true) {
        let q = db()
            .collection("users")
            .doc(normalizedUid)
            .collection(relation)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(450);
        if (lastDoc)
            q = q.startAfter(lastDoc);
        const snap = await q.get();
        if (snap.empty)
            break;
        ids.push(...snap.docs.map((doc) => doc.id).filter((id) => id.trim().length > 0));
        lastDoc = snap.docs[snap.docs.length - 1];
        if (snap.docs.length < 450)
            break;
    }
    return Array.from(new Set(ids));
}
function isVisiblePostRecord(data) {
    if (!data)
        return false;
    return (data.arsiv !== true &&
        data.deletedPost !== true &&
        data.gizlendi !== true &&
        data.isUploading !== true);
}
async function rebuildHybridFeedForUser(args) {
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
    const authorIds = Array.from(new Set([normalizedUid, ...followings]));
    const celebIds = new Set((await Promise.all(authorIds
        .filter((id) => id.trim().length > 0)
        .reduce((chunks, id, index) => {
        const chunkIndex = Math.floor(index / 10);
        if (!chunks[chunkIndex])
            chunks[chunkIndex] = [];
        chunks[chunkIndex].push(id);
        return chunks;
    }, [])
        .map(async (chunk) => {
        const snap = await db()
            .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.celebrityCollection)
            .where(admin.firestore.FieldPath.documentId(), "in", chunk)
            .get();
        return snap.docs.map((doc) => doc.id);
    }))).flat());
    const postEntries = (await Promise.all(authorIds.map(async (authorId) => {
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
    }))).flat();
    const deduped = new Map();
    for (const entry of postEntries) {
        deduped.set(entry.postId, entry);
    }
    const entries = Array.from(deduped.values()).sort((a, b) => b.timeStamp - a.timeStamp);
    let writeCount = 0;
    for (let i = 0; i < entries.length; i += 400) {
        const chunk = entries.slice(i, i + 400);
        const wb = db().batch();
        for (const entry of chunk) {
            wb.set(db()
                .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryCollection)
                .doc(normalizedUid)
                .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
                .doc(entry.postId), {
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.postId]: entry.postId,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.authorId]: entry.authorId,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.timeStamp]: entry.timeStamp,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isVideo]: entry.isVideo,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.expiresAt]: entry.timeStamp + FEED_TTL_MS,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isCelebrity]: entry.isCelebrity,
            }, { merge: true });
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
exports.backfillHybridFeedForUser = functions
    .region("europe-west1")
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }
    const requestedUid = typeof data?.uid === "string" ? data.uid.trim() : "";
    const targetUid = requestedUid || context.auth.uid;
    const isAdmin = context.auth.token?.admin === true;
    if (!isAdmin && targetUid !== context.auth.uid) {
        throw new functions.https.HttpsError("permission-denied", "Only admins can backfill other users");
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
exports.onPostCreate = functions
    .region("europe-west1")
    .firestore.document("Posts/{postId}")
    .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const data = snap.data();
    if (!data)
        return;
    const authorId = data.userID || "";
    const timeStamp = data.timeStamp || Date.now();
    const isVideo = !!(data.videoHLSMasterUrl || data.hlsMasterUrl || data.video);
    if (!authorId || !isVisiblePostRecord(data) || timeStamp > Date.now())
        return;
    try {
        await upsertPostIntoHybridFeed({
            postId,
            authorId,
            timeStamp,
            isVideo,
        });
        console.log("[HybridFeed] Fan-out complete");
    }
    catch (e) {
        console.error("[HybridFeed] onPostCreate error:", e);
    }
    try {
        await notifyFollowedPostSubscribers({
            postId,
            postRef: snap.ref,
            data,
        });
    }
    catch (e) {
        console.error("[HybridFeed] onPostCreate notify followers error:", e);
    }
    try {
        if (isCountedRootPost(data)) {
            await adjustAuthorPostCount(authorId, 1);
        }
    }
    catch (e) {
        console.error("[HybridFeed] onPostCreate counter error:", e);
    }
});
exports.onPostBecomeVisible = functions
    .region("europe-west1")
    .firestore.document("Posts/{postId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!after)
        return;
    const postId = context.params.postId;
    const authorId = (after.userID || "").toString();
    const timeStamp = Number(after.timeStamp) || Date.now();
    const isVideo = !!(after.videoHLSMasterUrl || after.hlsMasterUrl || after.video);
    const beforeVisible = before != null &&
        before.arsiv !== true &&
        before.deletedPost !== true &&
        before.gizlendi !== true &&
        before.isUploading !== true;
    const afterVisible = after.arsiv !== true &&
        after.deletedPost !== true &&
        after.gizlendi !== true &&
        after.isUploading !== true;
    const beforeCounted = isCountedRootPost(before);
    const afterCounted = isCountedRootPost(after);
    if (!authorId)
        return;
    if (!beforeVisible && afterVisible) {
        try {
            await upsertPostIntoHybridFeed({
                postId,
                authorId,
                timeStamp,
                isVideo,
            });
            console.log("[HybridFeed] Visibility upsert complete");
        }
        catch (e) {
            console.error("[HybridFeed] onPostBecomeVisible error:", e);
        }
        try {
            await notifyFollowedPostSubscribers({
                postId,
                postRef: change.after.ref,
                data: after,
            });
        }
        catch (e) {
            console.error("[HybridFeed] onPostBecomeVisible notify followers error:", e);
        }
    }
    try {
        if (!beforeCounted && afterCounted) {
            await adjustAuthorPostCount(authorId, 1);
        }
        else if (beforeCounted && !afterCounted) {
            await adjustAuthorPostCount(authorId, -1);
        }
    }
    catch (e) {
        console.error("[HybridFeed] onPostVisibility counter error:", e);
    }
});
// ─────────────────────────────────────────────────────────
// 🗑️ TRIGGER: Post silindiğinde feed item'larını temizle
// ─────────────────────────────────────────────────────────
exports.onPostDelete = functions
    .region("europe-west1")
    .firestore.document("Posts/{postId}")
    .onDelete(async (snap, context) => {
    const postId = context.params.postId;
    const authorId = snap.data()?.userID || "";
    const wasCounted = isCountedRootPost(snap.data());
    if (!authorId)
        return;
    try {
        // Author'ın kendi feed'inden sil
        await db()
            .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryCollection)
            .doc(authorId)
            .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
            .doc(postId)
            .delete();
        // Takipçilerin feed'inden temizle (collectionGroup sorgusu)
        let lastDocRef = null;
        while (true) {
            let q = db()
                .collectionGroup(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
                .where(hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.postId, "==", postId)
                .limit(400);
            if (lastDocRef)
                q = q.startAfter(lastDocRef);
            const snap = await q.get();
            if (snap.empty)
                break;
            const wb = db().batch();
            for (const d of snap.docs)
                wb.delete(d.ref);
            await wb.commit();
            lastDocRef = snap.docs[snap.docs.length - 1];
            if (snap.docs.length < 400)
                break;
        }
        console.log("[HybridFeed] Feed items cleaned up");
    }
    catch (e) {
        console.error("[HybridFeed] onPostDelete error:", e);
    }
    try {
        if (wasCounted) {
            await adjustAuthorPostCount(authorId, -1);
        }
    }
    catch (e) {
        console.error("[HybridFeed] onPostDelete counter error:", e);
    }
});
// ─────────────────────────────────────────────────────────
// 👤 TRIGGER: Yeni takipçi geldiğinde author'ın son N postunu feed'e ekle
// ─────────────────────────────────────────────────────────
exports.onNewFollower = functions
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
        if (postsSnap.empty)
            return;
        const wb = db().batch();
        const now = Date.now();
        for (const postDoc of postsSnap.docs) {
            const d = postDoc.data();
            const feedRef = db()
                .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryCollection)
                .doc(followerId)
                .collection(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
                .doc(postDoc.id);
            wb.set(feedRef, {
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.postId]: postDoc.id,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.authorId]: authorId,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.timeStamp]: d.timeStamp || now,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isVideo]: !!(d.videoHLSMasterUrl || d.video),
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.expiresAt]: (d.timeStamp || now) + FEED_TTL_MS,
                [hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.isCelebrity]: false,
            });
        }
        await wb.commit();
        console.log(`[HybridFeed] Backfilled ${postsSnap.size} posts for new follower`);
    }
    catch (e) {
        console.error(`[HybridFeed] onNewFollower error:`, e);
    }
});
// ─────────────────────────────────────────────────────────
// 🧹 SCHEDULED: Süresi dolmuş feed item'larını temizle (günlük)
// ─────────────────────────────────────────────────────────
exports.cleanupExpiredFeedItems = functions
    .region("europe-west1")
    .pubsub.schedule("every 24 hours")
    .onRun(async () => {
    const now = Date.now();
    let cleaned = 0;
    let lastDocRef = null;
    while (true) {
        let q = db()
            .collectionGroup(hybridFeedContract_1.HYBRID_FEED_CONTRACT.primaryItemsSubcollection)
            .where(hybridFeedContract_1.HYBRID_FEED_CONTRACT.referenceFields.expiresAt, "<", now)
            .limit(400);
        if (lastDocRef)
            q = q.startAfter(lastDocRef);
        const snap = await q.get();
        if (snap.empty)
            break;
        const wb = db().batch();
        for (const d of snap.docs)
            wb.delete(d.ref);
        await wb.commit();
        cleaned += snap.docs.length;
        lastDocRef = snap.docs[snap.docs.length - 1];
        if (snap.docs.length < 400)
            break;
    }
    console.log(`[HybridFeed] Cleaned ${cleaned} expired feed items`);
    return null;
});
//# sourceMappingURL=hybridFeed.js.map