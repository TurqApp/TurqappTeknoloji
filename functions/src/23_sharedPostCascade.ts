import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

const REGION = "europe-west3";
const CASCADE_BATCH_SIZE = 400;

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const uniqueById = (
  docs: admin.firestore.DocumentSnapshot[]
): admin.firestore.DocumentSnapshot[] => {
  const byId = new Map<string, admin.firestore.DocumentSnapshot>();
  for (const doc of docs) {
    byId.set(doc.id, doc);
  }
  return Array.from(byId.values());
};

export const cascadeDeleteSharedPosts = onDocumentUpdated(
  {
    document: "Posts/{postId}",
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const postId = event.params.postId;

    if (!before || !after) return null;

    const deletedBefore = before.deletedPost === true;
    const deletedAfter = after.deletedPost === true;

    if (deletedBefore || !deletedAfter) {
      return null;
    }

    const nowMs = Date.now();

    const sharedPostsSnap = await db
      .collection("Posts")
      .where("originalPostID", "==", postId)
      .where("sharedAsPost", "==", true)
      .get();

    const postSharersSnap = await db
      .collection("Posts")
      .doc(postId)
      .collection("postSharers")
      .get();

    const sharedPostRefs = await Promise.all(
      postSharersSnap.docs.map(async (doc) => {
        const sharedPostId = String(doc.get("sharedPostID") ?? "").trim();
        if (!sharedPostId) return null;
        const sharedPostSnap = await db.collection("Posts").doc(sharedPostId).get();
        return sharedPostSnap.exists ? sharedPostSnap : null;
      })
    );

    const sharedPostDocs = uniqueById([
      ...sharedPostsSnap.docs,
      ...sharedPostRefs.filter((snap): snap is admin.firestore.DocumentSnapshot => snap != null && snap.exists),
    ]).filter((doc) => {
      if (doc.get("deletedPost") === true) return false;
      if (doc.get("quotedPost") === true) return false;
      return doc.get("sharedAsPost") === true;
    });

    for (let i = 0; i < sharedPostDocs.length; i += CASCADE_BATCH_SIZE) {
      const batch = db.batch();
      for (const doc of sharedPostDocs.slice(i, i + CASCADE_BATCH_SIZE)) {
        batch.update(doc.ref, {
          deletedPost: true,
          deletedPostTime: nowMs,
        });
      }
      await batch.commit();
    }

    for (let i = 0; i < postSharersSnap.docs.length; i += CASCADE_BATCH_SIZE) {
      const batch = db.batch();
      for (const doc of postSharersSnap.docs.slice(i, i + CASCADE_BATCH_SIZE)) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }

    console.log(
      `[cascadeDeleteSharedPosts] source=${postId} sharedPosts=${sharedPostDocs.length} postSharers=${postSharersSnap.docs.length}`
    );

    return null;
  }
);
