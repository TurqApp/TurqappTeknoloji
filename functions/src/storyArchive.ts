import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

function buildArchivePayload(
  storyId: string,
  data: FirebaseFirestore.DocumentData,
  now: number,
  reason: string,
) {
  const userId: string = data.userId;
  return {
    storyId,
    deletedAt: now,
    reason,
    userId,
    createdAtOriginal: data.createdDate ?? data.createdAt ?? now,
    backgroundColor: data.backgroundColor ?? 0,
    musicUrl: data.musicUrl ?? "",
    elements: data.elements ?? [],
  };
}

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
          .doc(doc.id);
        batch.set(archiveRef, buildArchivePayload(doc.id, data, now, "expired_cf"), {
          merge: true,
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
        .doc(context.params.storyId);
      await archiveRef.create(
        buildArchivePayload(
          context.params.storyId,
          data,
          now,
          "onDelete_trigger",
        ),
      );
    } catch (e) {
      const code = (e as { code?: number | string } | undefined)?.code;
      if (code === 6 || code === "already-exists") {
        console.log("archiveOnStoryDelete skip:already_archived", {
          storyId: context.params.storyId,
        });
        return;
      }
      console.error("archiveOnStoryDelete error", e);
    }
  });
