import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

export const cleanupExpiredStories = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now = Date.now();
    const cutoff = now - 24 * 60 * 60 * 1000;

    const snap = await db
      .collection("stories")
      .where("createdDate", "<=", cutoff)
      .limit(500)
      .get();

    const batch = db.batch();
    for (const doc of snap.docs) {
      try {
        const data = doc.data();
        const userId: string = data.userId;
        const archiveRef = db
          .collection("users")
          .doc(userId)
          .collection("DeletedStories")
          .doc();
        batch.set(archiveRef, {
          storyId: doc.id,
          deletedAt: now,
          reason: "expired_cf",
          userId,
          createdAtOriginal: data.createdDate ?? data.createdAt ?? now,
          backgroundColor: data.backgroundColor ?? 0,
          musicUrl: data.musicUrl ?? "",
          elements: data.elements ?? [],
        });
        batch.delete(doc.ref);
      } catch (e) {
        console.error("cleanupExpiredStories error", e);
      }
    }
    await batch.commit();
    return null;
  });

export const archiveOnStoryDelete = functions.firestore
  .document("stories/{storyId}")
  .onDelete(async (snap, context) => {
    const data = snap.data();
    if (!data) return;
    try {
      const now = Date.now();
      const userId: string = data.userId;
      const archiveRef = db
        .collection("users")
        .doc(userId)
        .collection("DeletedStories")
        .doc();
      await archiveRef.set({
        storyId: context.params.storyId,
        deletedAt: now,
        reason: "onDelete_trigger",
        userId,
        createdAtOriginal: data.createdDate ?? data.createdAt ?? now,
        backgroundColor: data.backgroundColor ?? 0,
        musicUrl: data.musicUrl ?? "",
        elements: data.elements ?? [],
      });
    } catch (e) {
      console.error("archiveOnStoryDelete error", e);
    }
  });
