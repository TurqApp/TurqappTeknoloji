"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.manualSyncUserProfile = exports.syncUserProfileToPosts = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const rateLimiter_1 = require("./rateLimiter");
const BATCH_SIZE = 500;
const MAX_POSTS_PER_EXECUTION = 2000;
const REGION = "europe-west3";
if (admin.apps.length === 0) {
    admin.initializeApp();
}
exports.syncUserProfileToPosts = (0, firestore_1.onDocumentUpdated)({
    document: "users/{userId}",
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
}, async (event) => {
    const userId = event.params.userId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const startTime = Date.now();
    console.log("[User Profile Sync] Started");
    try {
        if (!before || !after) {
            console.log("[User Profile Sync] Missing before/after snapshot");
            return null;
        }
        const beforeProfile = extractProfileFields(before);
        const afterProfile = extractProfileFields(after);
        const needsSync = shouldSyncUserProfile(beforeProfile, afterProfile);
        if (!needsSync) {
            console.log("[User Profile Sync] No displayable fields changed. Skipping sync");
            return null;
        }
        const postsSnapshot = await admin
            .firestore()
            .collection("Posts")
            .where("userID", "==", userId)
            .limit(MAX_POSTS_PER_EXECUTION)
            .get();
        if (postsSnapshot.empty) {
            console.log("[User Profile Sync] No posts found");
            return null;
        }
        const updateData = {};
        if (beforeProfile.nickname !== afterProfile.nickname)
            updateData.nickname = afterProfile.nickname;
        if (beforeProfile.username !== afterProfile.username)
            updateData.username = afterProfile.username;
        if (beforeProfile.displayName !== afterProfile.displayName)
            updateData.displayName = afterProfile.displayName;
        if (beforeProfile.avatarUrl !== afterProfile.avatarUrl)
            updateData.avatarUrl = afterProfile.avatarUrl;
        if (beforeProfile.rozet !== afterProfile.rozet)
            updateData.rozet = afterProfile.rozet;
        const result = await updatePostsInBatches(postsSnapshot.docs, updateData, userId);
        result.duration = Date.now() - startTime;
        await logSyncMetrics(userId, result);
        return result;
    }
    catch (error) {
        console.error("[User Profile Sync] Failed", error);
        throw new https_1.HttpsError("internal", `Failed to sync user profile: ${error}`);
    }
});
function extractProfileFields(data) {
    const firstName = data.firstName;
    const lastName = data.lastName;
    const combined = [firstName, lastName].filter(Boolean).join(" ");
    const displayName = data.displayName ??
        data.fullName ??
        combined ??
        "";
    const nickname = data.nickname ?? "";
    const username = data.username ?? "";
    const avatarUrl = data.avatarUrl ?? null;
    const rozet = data.rozet ?? "";
    return { nickname, username, displayName, avatarUrl, rozet };
}
function shouldSyncUserProfile(before, after) {
    return (before.nickname !== after.nickname ||
        before.username !== after.username ||
        before.displayName !== after.displayName ||
        before.avatarUrl !== after.avatarUrl ||
        before.rozet !== after.rozet);
}
async function updatePostsInBatches(posts, updateData, userId) {
    const result = {
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
                const update = {
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
        }
        catch (error) {
            console.error(`[User Profile Sync] Batch ${index + 1}/${chunks.length} failed`, error);
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
        }
        else {
            result.errors.push(`Batch ${batchResult.batchIndex}: ${batchResult.error}`);
        }
    });
    return result;
}
function chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
        chunks.push(array.slice(i, i + size));
    }
    return chunks;
}
async function logSyncMetrics(userId, result) {
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
    }
    catch (error) {
        console.error("[User Profile Sync] Failed to log metrics", error);
    }
}
exports.manualSyncUserProfile = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to trigger manual sync");
    }
    if (request.auth.token?.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "Admin privileges required");
    }
    rateLimiter_1.RateLimits.admin(request.auth.uid);
    const userId = request.data?.userId;
    if (!userId) {
        throw new https_1.HttpsError("invalid-argument", "userId is required");
    }
    try {
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) {
            throw new https_1.HttpsError("not-found", "User not found");
        }
        const userData = userDoc.data();
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
        const updateData = {
            nickname: profile.nickname,
            username: profile.username,
            displayName: profile.displayName,
            avatarUrl: profile.avatarUrl,
            rozet: profile.rozet,
        };
        const result = await updatePostsInBatches(postsSnapshot.docs, updateData, userId);
        await logSyncMetrics(userId, result);
        return {
            success: true,
            message: `Successfully synced ${result.postsUpdated} posts`,
            result,
        };
    }
    catch (error) {
        console.error("[Manual Sync] Failed", error);
        throw new https_1.HttpsError("internal", `Manual sync failed: ${error}`);
    }
});
//# sourceMappingURL=09_userProfile.js.map