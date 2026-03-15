"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.archiveOnStoryDelete = exports.cleanupExpiredStories = void 0;
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const db = admin.firestore();
exports.cleanupExpiredStories = functions.pubsub
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
            const userId = data.userId;
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
        }
        catch (e) {
            console.error("cleanupExpiredStories error", e);
        }
    }
    await batch.commit();
    return null;
});
exports.archiveOnStoryDelete = functions.firestore
    .document("stories/{storyId}")
    .onDelete(async (snap, context) => {
    const data = snap.data();
    if (!data)
        return;
    try {
        const now = Date.now();
        const userId = data.userId;
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
    }
    catch (e) {
        console.error("archiveOnStoryDelete error", e);
    }
});
//# sourceMappingURL=storyArchive.js.map