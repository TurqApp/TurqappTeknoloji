/**
 * TurqApp — Author Field Denormalization (B10)
 *
 * Problem: Her post gösterildiğinde users/{uid} okunuyor → N+1 Firestore read
 *          100 post feed = 100 ekstra okuma → $300/ay gereksiz maliyet
 *
 * Çözüm: Post belgelerine authorNickname + authorDisplayName + authorAvatarUrl + rozet inline yaz.
 *   - Post oluşturulduğunda (onPostWrite) author alanları post'a eklenir
 *   - Kullanıcı profili güncellendiğinde (onUserProfileUpdate) son 500 post senkronize edilir
 *
 * Flutter tarafı: PostsModel.fromMap() zaten authorNickname/authorDisplayName/authorAvatarUrl okuyor.
 *   Feed widget'larında: post.authorNickname.isNotEmpty → direkt kullan, empty → users fetch.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────
// 📝 TRIGGER: Post yazıldığında author alanlarını inline ekle
// ─────────────────────────────────────────────────────────────────

export const denormAuthorOnPostWrite = functions
  .region("europe-west1")
  .firestore.document("Posts/{postId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return;

    const userID: string = data.userID || "";
    if (!userID) return;

    // Author alanları zaten doluysa atlat
    if (data.authorNickname && data.authorDisplayName && data.authorAvatarUrl && data.rozet) return;

    try {
      const userDoc = await db.collection("users").doc(userID).get();
      const userData = userDoc.data();
      if (!userData) return;

      const authorNickname = String(userData.nickname || "").trim();
      const authorDisplayName = String(
        userData.displayName ||
          userData.fullName ||
          [userData.firstName, userData.lastName].filter(Boolean).join(" ") ||
          authorNickname ||
          ""
      ).trim();
      const authorAvatarUrl = String(userData.avatarUrl || "").trim();
      const rozet = String(userData.rozet || "").trim();

      if (!authorNickname && !authorDisplayName && !authorAvatarUrl && !rozet) return;

      await snap.ref.update({
        authorNickname,
        authorDisplayName,
        authorAvatarUrl,
        rozet,
      });
      console.log("[AuthorDenorm] Post author alanları güncellendi");
    } catch (e) {
      console.error(`[AuthorDenorm] denormAuthorOnPostWrite error:`, e);
    }
  });

// ─────────────────────────────────────────────────────────────────
// 👤 TRIGGER: Kullanıcı profili güncellendiğinde son postları senkronize et
// ─────────────────────────────────────────────────────────────────

export const syncAuthorFieldsOnProfileUpdate = functions
  .region("europe-west1")
  .firestore.document("users/{uid}")
  .onUpdate(async (change, context) => {
    const uid = context.params.uid;
    const before = change.before.data();
    const after = change.after.data();

    const nicknameChanged = before?.nickname !== after?.nickname;
    const displayNameChanged =
      before?.displayName !== after?.displayName ||
      before?.fullName !== after?.fullName ||
      before?.firstName !== after?.firstName ||
      before?.lastName !== after?.lastName;
    const avatarChanged = before?.avatarUrl !== after?.avatarUrl;
    const rozetChanged = before?.rozet !== after?.rozet;

    if (!nicknameChanged && !displayNameChanged && !avatarChanged && !rozetChanged) return;

    const newNickname = String(after?.nickname || "").trim();
    const newDisplayName = String(
      after?.displayName ||
        after?.fullName ||
        [after?.firstName, after?.lastName].filter(Boolean).join(" ") ||
        newNickname ||
        ""
    ).trim();
    const newAvatarUrl = String(after?.avatarUrl || "");
    const newRozet = String(after?.rozet || "");

    try {
      // Son 200 postu güncelle (maliyet/latency kontrolü için)
      const postsSnap = await db
        .collection("Posts")
        .where("userID", "==", uid)
        .orderBy("timeStamp", "desc")
        .limit(200)
        .get();

      if (postsSnap.empty) return;

      // Batch güncelle (500 limit göz önünde bulundurularak)
      const BATCH_SIZE = 450;
      const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
      for (let i = 0; i < postsSnap.docs.length; i += BATCH_SIZE) {
        chunks.push(postsSnap.docs.slice(i, i + BATCH_SIZE));
      }

      for (const chunk of chunks) {
        const wb = db.batch();
        for (const doc of chunk) {
          const update: Record<string, string> = {};
          if (nicknameChanged) update.authorNickname = newNickname;
          if (displayNameChanged) update.authorDisplayName = newDisplayName;
          if (avatarChanged) update.authorAvatarUrl = newAvatarUrl;
          if (rozetChanged) update.rozet = newRozet;
          wb.update(doc.ref, update);
        }
        await wb.commit();
      }

      console.log(
        `[AuthorDenorm] Profil değişikliği işlendi → ${postsSnap.size} post güncellendi`
      );
    } catch (e) {
      console.error(`[AuthorDenorm] syncAuthorFieldsOnProfileUpdate error:`, e);
    }
  });
