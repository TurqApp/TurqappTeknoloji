import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";

const BATCH_SIZE = 500;
const MAX_POSTS_PER_EXECUTION = 2000;
const REGION = "europe-west3";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface UserProfileFields {
  username: string;
  displayName: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

interface SyncResult {
  postsFound: number;
  postsUpdated: number;
  batchesExecuted: number;
  errors: string[];
  duration: number;
}

export const syncUserProfileToPosts = onDocumentUpdated(
  {
    document: "users/{userId}",
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (event) => {
    const userId = event.params.userId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const startTime = Date.now();

    console.log(`[User Profile Sync] Started for user: ${userId}`);

    try {
      if (!before || !after) {
        console.log(`[User Profile Sync] Missing before/after snapshot for user: ${userId}`);
        return null;
      }

      const beforeProfile = extractProfileFields(before);
      const afterProfile = extractProfileFields(after);
      const needsSync = shouldSyncUserProfile(beforeProfile, afterProfile);
      if (!needsSync) {
        console.log(`[User Profile Sync] No displayable fields changed. Skipping sync for user: ${userId}`);
        return null;
      }

      const postsSnapshot = await admin
        .firestore()
        .collection("posts")
        .where("authorId", "==", userId)
        .limit(MAX_POSTS_PER_EXECUTION)
        .get();

      if (postsSnapshot.empty) {
        console.log(`[User Profile Sync] No posts found for user: ${userId}`);
        return null;
      }

      const updateData: Partial<UserProfileFields> = {};
      if (beforeProfile.username !== afterProfile.username) updateData.username = afterProfile.username;
      if (beforeProfile.displayName !== afterProfile.displayName) updateData.displayName = afterProfile.displayName;
      if (beforeProfile.avatarUrl !== afterProfile.avatarUrl) updateData.avatarUrl = afterProfile.avatarUrl;
      if (beforeProfile.isVerified !== afterProfile.isVerified) updateData.isVerified = afterProfile.isVerified;

      const result = await updatePostsInBatches(postsSnapshot.docs, updateData, userId);
      result.duration = Date.now() - startTime;
      await logSyncMetrics(userId, result);
      return result;
    } catch (error) {
      console.error(`[User Profile Sync] Failed for user: ${userId}`, error);
      throw new HttpsError("internal", `Failed to sync user profile: ${error}`, {
        userId,
        error: String(error),
      });
    }
  }
);

function extractProfileFields(data: admin.firestore.DocumentData): UserProfileFields {
  const firstName = data.firstName as string | undefined;
  const lastName = data.lastName as string | undefined;
  const combined = [firstName, lastName].filter(Boolean).join(" ");
  const displayName =
    (data.displayName as string | undefined) ??
    (data.fullName as string | undefined) ??
    combined ??
    "";
  const username = (data.username as string | undefined) ?? "";
  const avatarUrl =
    (data.avatarUrl as string | undefined) ?? null;
  const isVerified = (data.isVerified as boolean | undefined) ?? false;

  return { username, displayName, avatarUrl, isVerified };
}

function shouldSyncUserProfile(before: UserProfileFields, after: UserProfileFields): boolean {
  return (
    before.username !== after.username ||
    before.displayName !== after.displayName ||
    before.avatarUrl !== after.avatarUrl ||
    before.isVerified !== after.isVerified
  );
}

async function updatePostsInBatches(
  posts: admin.firestore.QueryDocumentSnapshot[],
  updateData: Partial<UserProfileFields>,
  userId: string
): Promise<SyncResult> {
  const result: SyncResult = {
    postsFound: posts.length,
    postsUpdated: 0,
    batchesExecuted: 0,
    errors: [],
    duration: 0,
  };

  const chunks = chunkArray(posts, BATCH_SIZE);
  const batchPromises = chunks.map(async (chunk, index) => {
    try {
      const batch = admin.firestore().batch();

      chunk.forEach((postDoc) => {
        const update: { [key: string]: unknown } = {
          updatedAt: Date.now(),
        };

        if (updateData.username !== undefined) update["author.username"] = updateData.username;
        if (updateData.displayName !== undefined) update["author.displayName"] = updateData.displayName;
        if (updateData.avatarUrl !== undefined) update["author.avatarUrl"] = updateData.avatarUrl;
        if (updateData.isVerified !== undefined) update["author.isVerified"] = updateData.isVerified;

        batch.update(postDoc.ref, update);
      });

      await batch.commit();
      return { success: true, count: chunk.length, batchIndex: index };
    } catch (error) {
      console.error(
        `[User Profile Sync] Batch ${index + 1}/${chunks.length} failed for user: ${userId}`,
        error
      );
      return {
        success: false,
        count: 0,
        batchIndex: index,
        error: String(error),
      };
    }
  });

  const batchResults = await Promise.all(batchPromises);
  batchResults.forEach((batchResult) => {
    if (batchResult.success) {
      result.postsUpdated += batchResult.count;
      result.batchesExecuted++;
    } else {
      result.errors.push(`Batch ${batchResult.batchIndex}: ${batchResult.error}`);
    }
  });

  return result;
}

function chunkArray<T>(array: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

async function logSyncMetrics(userId: string, result: SyncResult): Promise<void> {
  try {
    await admin.firestore().collection("sync_metrics").add({
      userId,
      type: "user_profile_sync",
      timestamp: Date.now(),
      postsFound: result.postsFound,
      postsUpdated: result.postsUpdated,
      batchesExecuted: result.batchesExecuted,
      errorCount: result.errors.length,
      errors: result.errors,
      durationMs: result.duration,
      success: result.errors.length === 0,
    });
  } catch (error) {
    console.error("[User Profile Sync] Failed to log metrics", error);
  }
}

export const manualSyncUserProfile = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
  },
  async (request: CallableRequest) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated to trigger manual sync");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin privileges required");
    }

    const userId = request.data?.userId as string | undefined;
    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required");
    }

    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        throw new HttpsError("not-found", `User not found: ${userId}`);
      }

      const userData = userDoc.data()!;
      const postsSnapshot = await admin
        .firestore()
        .collection("posts")
        .where("authorId", "==", userId)
        .limit(MAX_POSTS_PER_EXECUTION)
        .get();

      if (postsSnapshot.empty) {
        return {
          success: true,
          message: `No posts found for user: ${userId}`,
          postsUpdated: 0,
        };
      }

      const profile = extractProfileFields(userData);
      const updateData: Partial<UserProfileFields> = {
        username: profile.username,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        isVerified: profile.isVerified,
      };

      const result = await updatePostsInBatches(postsSnapshot.docs, updateData, userId);
      await logSyncMetrics(userId, result);

      return {
        success: true,
        message: `Successfully synced ${result.postsUpdated} posts`,
        result,
      };
    } catch (error) {
      console.error(`[Manual Sync] Failed for user: ${userId}`, error);
      throw new HttpsError("internal", `Manual sync failed: ${error}`, {
        userId,
        error: String(error),
      });
    }
  }
);
