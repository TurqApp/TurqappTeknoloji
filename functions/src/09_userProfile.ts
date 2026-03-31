import * as admin from "firebase-admin";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { RateLimits } from "./rateLimiter";

const BATCH_SIZE = 500;
const MAX_POSTS_PER_EXECUTION = 2000;
const REGION = "europe-west3";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface UserProfileFields {
  nickname: string;
  username: string;
  displayName: string;
  avatarUrl: string | null;
  rozet: string;
}

interface SyncResult {
  postsFound: number;
  postsUpdated: number;
  scholarshipsFound?: number;
  scholarshipsUpdated?: number;
  batchesExecuted: number;
  errors: string[];
  duration: number;
}

function extractProfileFields(data: admin.firestore.DocumentData): UserProfileFields {
  const firstName = data.firstName as string | undefined;
  const lastName = data.lastName as string | undefined;
  const combined = [firstName, lastName].filter(Boolean).join(" ");
  const displayName =
    (data.displayName as string | undefined) ??
    (data.fullName as string | undefined) ??
    combined ??
    "";
  const nickname = (data.nickname as string | undefined) ?? "";
  const username = (data.username as string | undefined) ?? "";
  const avatarUrl = (data.avatarUrl as string | undefined) ?? null;
  const rozet = (data.rozet as string | undefined) ?? "";

  return { nickname, username, displayName, avatarUrl, rozet };
}

function shouldSyncUserProfile(before: UserProfileFields, after: UserProfileFields): boolean {
  return (
    before.nickname !== after.nickname ||
    before.username !== after.username ||
    before.displayName !== after.displayName ||
    before.avatarUrl !== after.avatarUrl ||
    before.rozet !== after.rozet
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

        if (updateData.nickname !== undefined) {
          update.authorNickname = updateData.nickname;
          update.nickname = updateData.nickname;
        }
        if (updateData.username !== undefined) {
          update.username = updateData.username;
        }
        if (updateData.displayName !== undefined) {
          update.authorDisplayName = updateData.displayName;
          update.displayName = updateData.displayName;
          update.fullName = updateData.displayName;
        }
        if (updateData.avatarUrl !== undefined) {
          update.authorAvatarUrl = updateData.avatarUrl;
          update.avatarUrl = updateData.avatarUrl;
        }
        if (updateData.rozet !== undefined) {
          update.rozet = updateData.rozet;
        }

        batch.update(postDoc.ref, update);
      });

      await batch.commit();
      return { success: true, count: chunk.length, batchIndex: index };
    } catch (error) {
      console.error(
        `[User Profile Sync] Batch ${index + 1}/${chunks.length} failed`,
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

async function updateScholarshipsInBatches(
  userId: string,
  updateData: Partial<UserProfileFields>
): Promise<{
  found: number;
  updated: number;
  batchesExecuted: number;
  errors: string[];
}> {
  const snapshot = await admin
    .firestore()
    .collection("catalog")
    .doc("education")
    .collection("scholarships")
    .where("userID", "==", userId)
    .limit(MAX_POSTS_PER_EXECUTION)
    .get();

  if (snapshot.empty) {
    return { found: 0, updated: 0, batchesExecuted: 0, errors: [] };
  }

  let updated = 0;
  let batchesExecuted = 0;
  const errors: string[] = [];
  const chunks = chunkArray(snapshot.docs, BATCH_SIZE);

  const batchResults = await Promise.all(
    chunks.map(async (chunk, index) => {
      try {
        const batch = admin.firestore().batch();
        chunk.forEach((docSnap) => {
          const update: { [key: string]: unknown } = {
            updatedAt: Date.now(),
          };
          if (updateData.nickname !== undefined) {
            update.authorNickname = updateData.nickname;
          }
          if (updateData.displayName !== undefined) {
            update.authorDisplayName = updateData.displayName;
          }
          if (updateData.avatarUrl !== undefined) {
            update.authorAvatarUrl = updateData.avatarUrl;
          }
          if (updateData.rozet !== undefined) {
            update.rozet = updateData.rozet;
          }
          batch.update(docSnap.ref, update);
        });
        await batch.commit();
        return { success: true, count: chunk.length, batchIndex: index };
      } catch (error) {
        return {
          success: false,
          count: 0,
          batchIndex: index,
          error: String(error),
        };
      }
    })
  );

  for (const batchResult of batchResults) {
    if (batchResult.success) {
      updated += batchResult.count;
      batchesExecuted += 1;
    } else {
      errors.push(`Scholarship batch ${batchResult.batchIndex}: ${batchResult.error}`);
    }
  }

  return {
    found: snapshot.size,
    updated,
    batchesExecuted,
    errors,
  };
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
    RateLimits.admin(request.auth.uid);

    const userId = request.data?.userId as string | undefined;
    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required");
    }

    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "User not found");
      }

      const userData = userDoc.data()!;
      const postsSnapshot = await admin
        .firestore()
        .collection("Posts")
        .where("userID", "==", userId)
        .limit(MAX_POSTS_PER_EXECUTION)
        .get();

      if (postsSnapshot.empty) {
        return {
          success: true,
          message: "No posts found for requested user",
          postsUpdated: 0,
        };
      }

      const profile = extractProfileFields(userData);
      const updateData: Partial<UserProfileFields> = {
        nickname: profile.nickname,
        username: profile.username,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        rozet: profile.rozet,
      };

      const result = await updatePostsInBatches(postsSnapshot.docs, updateData, userId);
      const scholarshipResult = await updateScholarshipsInBatches(
        userId,
        updateData
      );
      result.scholarshipsFound = scholarshipResult.found;
      result.scholarshipsUpdated = scholarshipResult.updated;
      result.batchesExecuted += scholarshipResult.batchesExecuted;
      result.errors.push(...scholarshipResult.errors);
      await logSyncMetrics(userId, result);

      return {
        success: true,
        message:
            `Successfully synced ${result.postsUpdated} posts and ` +
            `${result.scholarshipsUpdated ?? 0} scholarships`,
        result,
      };
    } catch (error) {
      console.error("[Manual Sync] Failed", error);
      throw new HttpsError("internal", `Manual sync failed: ${error}`);
    }
  }
);

export const manualBackfillScholarshipAuthors = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
  },
  async (request: CallableRequest) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin privileges required");
    }
    RateLimits.admin(request.auth.uid);

    const limitRaw = Number(request.data?.limit || 300);
    const limit = Math.max(1, Math.min(500, limitRaw));
    const cursor = String(request.data?.cursor || "").trim();

    let query: admin.firestore.Query = admin
      .firestore()
      .collection("catalog")
      .doc("education")
      .collection("scholarships")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(limit);
    if (cursor) {
      query = query.startAfter(cursor);
    }

    const snap = await query.get();
    let updated = 0;
    const errors: string[] = [];
    const chunks = chunkArray(snap.docs, BATCH_SIZE);

    for (const [index, chunk] of chunks.entries()) {
      const batch = admin.firestore().batch();
      for (const docSnap of chunk) {
        try {
          const data = docSnap.data();
          const uid = String(data.userID || "").trim();
          if (!uid) continue;
          const userSnap = await admin.firestore().collection("users").doc(uid).get();
          const user = userSnap.data() || {};
          const nickname = String(user.nickname || "").trim();
          const displayName = String(
            user.displayName ||
            user.fullName ||
            [user.firstName, user.lastName].filter(Boolean).join(" ") ||
            nickname ||
            ""
          ).trim();
          const avatarUrl = String(user.avatarUrl || "").trim();
          const rozet = String(user.rozet || "").trim();
          batch.update(docSnap.ref, {
            authorNickname: nickname,
            authorDisplayName: displayName,
            authorAvatarUrl: avatarUrl,
            rozet,
            updatedAt: Date.now(),
          });
          updated += 1;
        } catch (error) {
          errors.push(`doc ${docSnap.id}: ${String(error)}`);
        }
      }
      try {
        await batch.commit();
      } catch (error) {
        errors.push(`batch ${index}: ${String(error)}`);
      }
    }

    const last = snap.docs.length > 0 ? snap.docs[snap.docs.length - 1].id : null;
    return {
      success: true,
      scanned: snap.size,
      updated,
      nextCursor: last,
      done: snap.size < limit,
      errors,
    };
  }
);
