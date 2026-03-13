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
exports.cleanupExpiredFeedItems = exports.onNewFollower = exports.onPostDelete = exports.onPostCreate = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
/// Takipçi eşiği: üzerindeyse celebrity (fan-in), altındaysa fan-out
const FAN_OUT_THRESHOLD = 10000;
/// Tek bir fan-out batch'inde işlenecek max takipçi sayısı
const FAN_OUT_BATCH_SIZE = 450; // Firestore batch limiti 500, güvenli margin
/// Feed item'ın geçerlilik süresi: 7 gün
const FEED_TTL_MS = 7 * 24 * 60 * 60 * 1000;
async function resolveFollowerCollection(authorId) {
    const followersSnap = await db
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
    const arsiv = data.arsiv === true;
    const deletedPost = data.deletedPost === true;
    if (!authorId || arsiv || deletedPost)
        return;
    try {
        // 1. Takipçi sayısını kontrol et
        const authorDoc = await db.collection("users").doc(authorId).get();
        const followerCount = Number(authorDoc.data()?.followerCount) ||
            Number(authorDoc.data()?.takipciSayisi) ||
            Number(authorDoc.data()?.counterOfFollowers) ||
            0;
        if (followerCount > FAN_OUT_THRESHOLD) {
            // Celebrity: fan-in listesine ekle, fan-out yapma
            await db.collection("celebAccounts").doc(authorId).set({ uid: authorId, followerCount, updatedAt: Date.now() }, { merge: true });
            console.log(`[HybridFeed] Celebrity fan-in: ${authorId} (${followerCount} followers)`);
            return;
        }
        // 2. Küçük hesap: fan-out — tüm takipçilere yaz
        let lastDoc = null;
        let totalFannedOut = 0;
        const followerCollection = await resolveFollowerCollection(authorId);
        while (true) {
            let q = db
                .collection("users")
                .doc(authorId)
                .collection(followerCollection)
                .limit(FAN_OUT_BATCH_SIZE);
            if (lastDoc)
                q = q.startAfter(lastDoc);
            const followersSnap = await q.get();
            if (followersSnap.empty)
                break;
            const wb = db.batch();
            for (const followerDoc of followersSnap.docs) {
                const followerUid = followerDoc.id;
                const feedRef = db
                    .collection("userFeeds")
                    .doc(followerUid)
                    .collection("items")
                    .doc(postId);
                wb.set(feedRef, {
                    postId,
                    authorId,
                    timeStamp,
                    isVideo,
                    expiresAt: timeStamp + FEED_TTL_MS,
                    isCelebrity: false,
                });
            }
            await wb.commit();
            totalFannedOut += followersSnap.docs.length;
            lastDoc = followersSnap.docs[followersSnap.docs.length - 1];
            if (followersSnap.docs.length < FAN_OUT_BATCH_SIZE)
                break;
        }
        // Ayrıca author'ın kendi feed'ine de ekle
        await db
            .collection("userFeeds")
            .doc(authorId)
            .collection("items")
            .doc(postId)
            .set({
            postId,
            authorId,
            timeStamp,
            isVideo,
            expiresAt: timeStamp + FEED_TTL_MS,
            isCelebrity: false,
        });
        console.log(`[HybridFeed] Fan-out complete: ${postId} → ${totalFannedOut} followers`);
    }
    catch (e) {
        console.error(`[HybridFeed] onPostCreate error for ${postId}:`, e);
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
    if (!authorId)
        return;
    try {
        // Author'ın kendi feed'inden sil
        await db
            .collection("userFeeds")
            .doc(authorId)
            .collection("items")
            .doc(postId)
            .delete();
        // Takipçilerin feed'inden temizle (collectionGroup sorgusu)
        let lastDocRef = null;
        while (true) {
            let q = db
                .collectionGroup("items")
                .where("postId", "==", postId)
                .limit(400);
            if (lastDocRef)
                q = q.startAfter(lastDocRef);
            const snap = await q.get();
            if (snap.empty)
                break;
            const wb = db.batch();
            for (const d of snap.docs)
                wb.delete(d.ref);
            await wb.commit();
            lastDocRef = snap.docs[snap.docs.length - 1];
            if (snap.docs.length < 400)
                break;
        }
        console.log(`[HybridFeed] Post ${postId} feed items cleaned up`);
    }
    catch (e) {
        console.error(`[HybridFeed] onPostDelete error for ${postId}:`, e);
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
        const postsSnap = await db
            .collection("Posts")
            .where("userID", "==", authorId)
            .where("arsiv", "==", false)
            .where("deletedPost", "==", false)
            .orderBy("timeStamp", "desc")
            .limit(20)
            .get();
        if (postsSnap.empty)
            return;
        const wb = db.batch();
        const now = Date.now();
        for (const postDoc of postsSnap.docs) {
            const d = postDoc.data();
            const feedRef = db
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
        console.log(`[HybridFeed] Backfilled ${postsSnap.size} posts for new follower ${followerId}`);
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
        let q = db
            .collectionGroup("items")
            .where("expiresAt", "<", now)
            .limit(400);
        if (lastDocRef)
            q = q.startAfter(lastDocRef);
        const snap = await q.get();
        if (snap.empty)
            break;
        const wb = db.batch();
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