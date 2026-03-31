"use strict";
/**
 * TurqApp — Author Field Denormalization (B10)
 *
 * Problem: Her post gösterildiğinde users/{uid} okunuyor → N+1 Firestore read
 *          100 post feed = 100 ekstra okuma → $300/ay gereksiz maliyet
 *
 * Çözüm: Post belgelerine authorNickname + authorDisplayName + authorAvatarUrl + rozet inline yaz.
 *   - Post oluşturulduğunda (onPostWrite) author alanları safety-net olarak post'a eklenir
 *   - Ana write path'ler bu alanları zaten inline üretir; profile-update bulk sync burada tutulmaz
 *
 * Flutter tarafı: PostsModel.fromMap() zaten authorNickname/authorDisplayName/authorAvatarUrl okuyor.
 *   Feed widget'larında: post.authorNickname.isNotEmpty → direkt kullan, empty → users fetch.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.denormAuthorOnPostWrite = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
// ─────────────────────────────────────────────────────────────────
// 📝 TRIGGER: Post yazıldığında author alanlarını inline ekle
// ─────────────────────────────────────────────────────────────────
exports.denormAuthorOnPostWrite = functions
    .region("europe-west1")
    .firestore.document("Posts/{postId}")
    .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data)
        return;
    const userID = data.userID || "";
    if (!userID)
        return;
    // Author alanları zaten doluysa atlat
    if (data.authorNickname && data.authorDisplayName && data.authorAvatarUrl && data.rozet)
        return;
    try {
        const userDoc = await db.collection("users").doc(userID).get();
        const userData = userDoc.data();
        if (!userData)
            return;
        const authorNickname = String(userData.nickname || "").trim();
        const authorDisplayName = String(userData.displayName ||
            userData.fullName ||
            [userData.firstName, userData.lastName].filter(Boolean).join(" ") ||
            authorNickname ||
            "").trim();
        const authorAvatarUrl = String(userData.avatarUrl || "").trim();
        const rozet = String(userData.rozet || "").trim();
        if (!authorNickname && !authorDisplayName && !authorAvatarUrl && !rozet)
            return;
        await snap.ref.update({
            authorNickname,
            authorDisplayName,
            authorAvatarUrl,
            rozet,
        });
        console.log("[AuthorDenorm] Post author alanları güncellendi");
    }
    catch (e) {
        console.error(`[AuthorDenorm] denormAuthorOnPostWrite error:`, e);
    }
});
//# sourceMappingURL=authorDenorm.js.map