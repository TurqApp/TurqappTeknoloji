"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.migrateusersToUsers = exports.purgeStudentSubcollections = exports.purgePostSubcollections = exports.backfillPostsOriginalFields = exports.backfillUserAvatarUrls = exports.backfillUsernames = exports.backfillPhoneAccounts = exports.resetMonthlyAntPoint = exports.publishScheduledIzBirakPosts = exports.processScheduledAccountDeletions = exports.onUserNotificationCreate = exports.onUserDocUpdate = exports.onUserDocDelete = exports.decrementOwnerLikesOnLikeDelete = exports.incrementOwnerLikesOnLikeCreate = exports.decrementFollowCountersOnFollowingDelete = exports.incrementFollowCountersOnFollowingCreate = exports.enforceMandatoryFollowOnUserCreate = exports.syncUserSchemaAndFlags = exports.syncAuthorFieldsOnProfileUpdate = exports.denormAuthorOnPostWrite = exports.backfillHybridFeedForUser = exports.cleanupExpiredFeedItems = exports.onNewFollower = exports.onPostDelete = exports.onPostBecomeVisible = exports.onPostCreate = exports.initCounterShards = exports.aggregateCounterShards = exports.toggleLikeBatch = exports.recordViewBatch = exports.processPostsMigrationQueue = exports.onVideoUpload = exports.generateThumbnails = exports.cleanupExpiredStories = exports.archiveOnStoryDelete = void 0;
// Cloud Functions templates for story TTL and deletion archival
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const rateLimiter_1 = require("./rateLimiter");
const hybridFeed_1 = require("./hybridFeed");
const notificationInbox_1 = require("./notificationInbox");
const notificationPushPolicy_1 = require("./notificationPushPolicy");
var storyArchive_1 = require("./storyArchive");
Object.defineProperty(exports, "archiveOnStoryDelete", { enumerable: true, get: function () { return storyArchive_1.archiveOnStoryDelete; } });
Object.defineProperty(exports, "cleanupExpiredStories", { enumerable: true, get: function () { return storyArchive_1.cleanupExpiredStories; } });
const userSchemaUtils_1 = require("./userSchemaUtils");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
const DEFAULT_SIGNUP_FOLLOW_UID = "fzP4AVdMugTi5oe11UTj6ljnfCj2";
const PUSH_TOKEN_FIELDS = ["fcmToken", "pushToken", "token", "fcm_token"];
function _firstNonEmptyString(...values) {
    for (const value of values) {
        if (typeof value === "string" && value.trim().length > 0) {
            return value.trim();
        }
        if (Array.isArray(value)) {
            for (const entry of value) {
                if (typeof entry === "string" && entry.trim().length > 0) {
                    return entry.trim();
                }
            }
        }
    }
    return "";
}
function _pickPostPreviewImage(data) {
    if (!data)
        return "";
    return _firstNonEmptyString(data.imageUrl, data.thumbnail, data.imageURL, data.coverImageUrl, data.logo, data.avatarUrl, data.img, data.images);
}
function _resolveUserPushToken(data) {
    if (!data)
        return "";
    return _firstNonEmptyString(data.fcmToken, data.pushToken, data.token, data.fcm_token);
}
async function _resolveNotificationImageUrl(data) {
    const direct = _firstNonEmptyString(data.imageUrl, data.thumbnail, data.imageURL, data.avatarUrl, data.applicantPfImage, data.tutorImage, data.companyLogo, data.logo, data.coverImageUrl, data.img, data.images);
    if (direct)
        return direct;
    const rawType = String(data.type || "").trim().toLowerCase();
    const postId = String(data.postID || data.chatID || "").trim();
    if (postId) {
        if (rawType === "posts" ||
            rawType === "post" ||
            rawType === "like" ||
            rawType === "comment" ||
            rawType === "reshared_posts" ||
            rawType === "shared_as_posts") {
            const postSnap = await db.collection("Posts").doc(postId).get();
            if (postSnap.exists) {
                const preview = _pickPostPreviewImage(postSnap.data());
                if (preview)
                    return preview;
            }
        }
        else if (rawType === "job_application") {
            const jobSnap = await db.collection("isBul").doc(postId).get();
            if (jobSnap.exists) {
                const preview = _pickPostPreviewImage(jobSnap.data());
                if (preview)
                    return preview;
            }
        }
        else if (rawType === "tutoring_application" ||
            rawType === "tutoring_status") {
            const tutoringSnap = await db.collection("educators").doc(postId).get();
            if (tutoringSnap.exists) {
                const preview = _pickPostPreviewImage(tutoringSnap.data());
                if (preview)
                    return preview;
            }
        }
    }
    const fromUserID = String(data.fromUserID || "").trim();
    if (fromUserID) {
        const userSnap = await db.collection("users").doc(fromUserID).get();
        if (userSnap.exists) {
            const avatarUrl = (0, userSchemaUtils_1.normalizeAvatarUrl)(userSnap.data()?.avatarUrl);
            if (avatarUrl)
                return avatarUrl;
        }
    }
    return "";
}
async function _resolveNotificationPushPayload(raw) {
    const data = { ...raw };
    const rawType = String(data.type || "").trim().toLowerCase();
    const postId = String(data.postID || "").trim();
    if (rawType !== "like" || !postId) {
        return data;
    }
    if ((0, userSchemaUtils_1.toNonNegativeInt)(data.likeCount) > 0) {
        return data;
    }
    try {
        const postSnap = await db.collection("Posts").doc(postId).get();
        if (!postSnap.exists)
            return data;
        const postData = postSnap.data();
        const stats = postData?.stats &&
            typeof postData.stats === "object" &&
            !Array.isArray(postData.stats)
            ? postData.stats
            : undefined;
        const likeCount = (0, userSchemaUtils_1.toNonNegativeInt)(stats?.likeCount);
        if (likeCount > 0) {
            data.likeCount = likeCount;
        }
    }
    catch (e) {
        console.error("_resolveNotificationPushPayload error", {
            type: rawType,
            postId,
            message: String(e),
        });
    }
    return data;
}
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📸 IMAGE THUMBNAILS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// B9: generateThumbnails aktif — sharp build için package.json'da
// "sharp": "^0.33.0" ve "engines": {"node": "20"} gerekli.
// deploy öncesi: cd functions && npm install sharp --platform=linux --arch=x64
var thumbnails_1 = require("./thumbnails");
Object.defineProperty(exports, "generateThumbnails", { enumerable: true, get: function () { return thumbnails_1.generateThumbnails; } });
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎬 HLS VIDEO TRANSCODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var hlsTranscode_1 = require("./hlsTranscode");
Object.defineProperty(exports, "onVideoUpload", { enumerable: true, get: function () { return hlsTranscode_1.onVideoUpload; } });
var postsMigrationScheduler_1 = require("./postsMigrationScheduler");
Object.defineProperty(exports, "processPostsMigrationQueue", { enumerable: true, get: function () { return postsMigrationScheduler_1.processPostsMigrationQueue; } });
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📊 AGGREGATION COUNTER SHARDING (A9)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var counterShards_1 = require("./counterShards");
Object.defineProperty(exports, "recordViewBatch", { enumerable: true, get: function () { return counterShards_1.recordViewBatch; } });
Object.defineProperty(exports, "toggleLikeBatch", { enumerable: true, get: function () { return counterShards_1.toggleLikeBatch; } });
Object.defineProperty(exports, "aggregateCounterShards", { enumerable: true, get: function () { return counterShards_1.aggregateCounterShards; } });
Object.defineProperty(exports, "initCounterShards", { enumerable: true, get: function () { return counterShards_1.initCounterShards; } });
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📰 HYBRID FEED FAN-OUT / FAN-IN (B4)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var hybridFeed_2 = require("./hybridFeed");
Object.defineProperty(exports, "onPostCreate", { enumerable: true, get: function () { return hybridFeed_2.onPostCreate; } });
Object.defineProperty(exports, "onPostBecomeVisible", { enumerable: true, get: function () { return hybridFeed_2.onPostBecomeVisible; } });
Object.defineProperty(exports, "onPostDelete", { enumerable: true, get: function () { return hybridFeed_2.onPostDelete; } });
Object.defineProperty(exports, "onNewFollower", { enumerable: true, get: function () { return hybridFeed_2.onNewFollower; } });
Object.defineProperty(exports, "cleanupExpiredFeedItems", { enumerable: true, get: function () { return hybridFeed_2.cleanupExpiredFeedItems; } });
Object.defineProperty(exports, "backfillHybridFeedForUser", { enumerable: true, get: function () { return hybridFeed_2.backfillHybridFeedForUser; } });
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 👤 AUTHOR FIELD DENORMALIZATION (B10)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var authorDenorm_1 = require("./authorDenorm");
Object.defineProperty(exports, "denormAuthorOnPostWrite", { enumerable: true, get: function () { return authorDenorm_1.denormAuthorOnPostWrite; } });
Object.defineProperty(exports, "syncAuthorFieldsOnProfileUpdate", { enumerable: true, get: function () { return authorDenorm_1.syncAuthorFieldsOnProfileUpdate; } });
__exportStar(require("./04_tagSettings"), exports);
__exportStar(require("./09_userProfile"), exports);
__exportStar(require("./11_resend"), exports);
__exportStar(require("./14_typesensePosts"), exports);
__exportStar(require("./15_typesenseUsersTags"), exports);
__exportStar(require("./16_tagMaintenance"), exports);
__exportStar(require("./17_shortLinksIndex"), exports);
__exportStar(require("./18_tutoringNotifications"), exports);
__exportStar(require("./19_adsCenter"), exports);
__exportStar(require("./20_moderationConfig"), exports);
__exportStar(require("./21_typesenseEducation"), exports);
__exportStar(require("./22_badgeAdmin"), exports);
__exportStar(require("./23_sharedPostCascade"), exports);
__exportStar(require("./24_reports"), exports);
__exportStar(require("./25_typesenseMarket"), exports);
__exportStar(require("./26_userBanAdmin"), exports);
__exportStar(require("./27_nicknameChange"), exports);
// USER SCHEMA NORMALIZER (canonical-only)
exports.syncUserSchemaAndFlags = functions.firestore
    .document("users/{uid}")
    .onWrite(async (change, context) => {
    const uid = context.params.uid;
    const afterExists = change.after.exists;
    const afterData = (afterExists ? change.after.data() : undefined);
    // Delete case: nothing to normalize.
    if (!afterExists) {
        return;
    }
    const patch = {};
    const canonicalUsername = (0, userSchemaUtils_1.normalizeUsernameLower)(afterData?.usernameLower ||
        afterData?.username ||
        afterData?.nickname ||
        afterData?.displayName ||
        afterData?.firstName);
    if (afterData?.isPrivate === undefined)
        patch.isPrivate = false;
    if (afterData?.isApproved === undefined)
        patch.isApproved = false;
    if (afterData?.isDeleted === undefined)
        patch.isDeleted = false;
    if (afterData?.isBanned === undefined)
        patch.isBanned = false;
    if (afterData?.moderationStrikeCount === undefined)
        patch.moderationStrikeCount = 0;
    if (afterData?.moderationLevel === undefined)
        patch.moderationLevel = 0;
    if (afterData?.moderationRestrictedUntil === undefined)
        patch.moderationRestrictedUntil = 0;
    if (afterData?.moderationPermanentBan === undefined)
        patch.moderationPermanentBan = false;
    if (afterData?.moderationBanReason === undefined)
        patch.moderationBanReason = "";
    if (afterData?.moderationUpdatedAt === undefined)
        patch.moderationUpdatedAt = 0;
    if (afterData?.singleDeviceSessionEnabled === undefined)
        patch.singleDeviceSessionEnabled = false;
    if (afterData?.activeSessionDeviceKey === undefined)
        patch.activeSessionDeviceKey = "";
    if (afterData?.activeSessionUpdatedAt === undefined)
        patch.activeSessionUpdatedAt = 0;
    if (afterData?.isBot === undefined)
        patch.isBot = false;
    const canonicalAvatarUrl = (0, userSchemaUtils_1.normalizeAvatarUrl)(afterData?.avatarUrl);
    if (String(afterData?.avatarUrl ?? "").trim() !== canonicalAvatarUrl) {
        patch.avatarUrl = canonicalAvatarUrl;
    }
    if (!afterData?.version)
        patch.version = 3;
    if (!afterData?.locale)
        patch.locale = "tr_TR";
    if (!afterData?.timezone)
        patch.timezone = "Europe/Istanbul";
    if (afterData?.isOnboarded === undefined)
        patch.isOnboarded = false;
    if (afterData?.deletedAt === undefined)
        patch.deletedAt = null;
    if (canonicalUsername) {
        if (String(afterData?.usernameLower || "") !== canonicalUsername) {
            patch.usernameLower = canonicalUsername;
        }
        if (String(afterData?.username || "") !== canonicalUsername) {
            patch.username = canonicalUsername;
        }
        if (String(afterData?.nickname || "") !== canonicalUsername) {
            patch.nickname = canonicalUsername;
        }
    }
    const firstName = String(afterData?.firstName || "").trim();
    const lastName = String(afterData?.lastName || "").trim();
    const fullName = [firstName, lastName].filter((v) => v.length > 0).join(" ").trim();
    const displayName = fullName || canonicalUsername;
    if (displayName && String(afterData?.displayName || "") !== displayName) {
        patch.displayName = displayName;
    }
    const createdDateTs = (0, userSchemaUtils_1.parseLegacyCreatedDateToTimestamp)(afterData?.createdDate);
    if (!afterData?.createdDate) {
        patch.createdDate = createdDateTs?.toMillis() ?? Date.now();
    }
    else if (typeof afterData?.createdDate !== "number") {
        patch.createdDate = Number(afterData.createdDate) || Date.now();
    }
    if (afterData?.createdAt !== undefined) {
        patch.createdAt = admin.firestore.FieldValue.delete();
    }
    if (afterData?.updatedAt !== undefined) {
        const updatedTs = (0, userSchemaUtils_1.parseLegacyCreatedDateToTimestamp)(afterData?.updatedAt);
        patch.updatedDate = updatedTs?.toMillis() ?? Date.now();
        patch.updatedAt = admin.firestore.FieldValue.delete();
    }
    else if (typeof afterData?.updatedDate !== "number") {
        patch.updatedDate = Number(afterData?.updatedDate) || Date.now();
    }
    if (afterData?.lastActiveAt !== undefined) {
        patch.lastActiveAt = admin.firestore.FieldValue.delete();
    }
    if (afterData?.lastActiveDate !== undefined) {
        patch.lastActiveDate = admin.firestore.FieldValue.delete();
    }
    if (afterData?.sifre !== undefined) {
        patch.sifre = admin.firestore.FieldValue.delete();
    }
    if (afterData?.userID !== undefined) {
        patch.userID = admin.firestore.FieldValue.delete();
    }
    const followersCount = (0, userSchemaUtils_1.toNonNegativeInt)(afterData?.counterOfFollowers);
    const followingsCount = (0, userSchemaUtils_1.toNonNegativeInt)(afterData?.counterOfFollowings);
    const postsCount = (0, userSchemaUtils_1.toNonNegativeInt)(afterData?.counterOfPosts);
    if (followersCount !== Number(afterData?.counterOfFollowers)) {
        patch.counterOfFollowers = followersCount;
    }
    if (followingsCount !== Number(afterData?.counterOfFollowings)) {
        patch.counterOfFollowings = followingsCount;
    }
    if (postsCount !== Number(afterData?.counterOfPosts)) {
        patch.counterOfPosts = postsCount;
    }
    const adRoot = (afterData?.ad && typeof afterData.ad === "object") ? afterData.ad : undefined;
    const adInfo = {
        isAdvertiser: Boolean(afterData?.isAdvertiser ?? adRoot?.isAdvertiser ?? false),
        accountStatus: String(adRoot?.accountStatus ?? "inactive"),
        campaignCount: Number(adRoot?.campaignCount ?? 0),
        spendTotal: Number(adRoot?.spendTotal ?? 0),
        lastCampaignAt: adRoot?.lastCampaignAt ?? null,
        lastImpressionAt: adRoot?.lastImpressionAt ?? null,
        lastClickAt: adRoot?.lastClickAt ?? null,
        updatedDate: Date.now(),
    };
    if (afterData?.isAdvertiser === undefined) {
        patch.isAdvertiser = adInfo.isAdvertiser;
    }
    // Enforce single source of truth: keep advertising data only in users/{uid}/ad/info.
    // Delete root ad on every run to prevent legacy writers from reintroducing duplication.
    patch.ad = admin.firestore.FieldValue.delete();
    const userRef = db.collection("users").doc(uid);
    await db.runTransaction(async (tx) => {
        if (Object.keys(patch).length > 0) {
            tx.set(userRef, patch, { merge: true });
        }
        // Keep signup lightweight: only touch canonical subdocs when they already exist,
        // or when ad data must be materialized for advertiser accounts.
        if (afterData?.ad !== undefined || afterData?.isAdvertiser === true) {
            tx.set(userRef.collection("ad").doc("info"), adInfo, { merge: true });
        }
    });
});
// ONE-TIME DEFAULT FOLLOW ON NEW USER CREATE
exports.enforceMandatoryFollowOnUserCreate = functions.firestore
    .document("users/{uid}")
    .onCreate(async (_snap, context) => {
    const uid = String(context.params.uid || "").trim();
    const targetUid = DEFAULT_SIGNUP_FOLLOW_UID.trim();
    if (!uid || !targetUid || uid == targetUid)
        return;
    try {
        const now = Date.now();
        const myFollowingRef = db.doc(`users/${uid}/followings/${targetUid}`);
        const targetFollowerRef = db.doc(`users/${targetUid}/followers/${uid}`);
        await db.runTransaction(async (tx) => {
            const existing = await tx.get(myFollowingRef);
            if (existing.exists)
                return;
            tx.set(myFollowingRef, { timeStamp: now }, { merge: true });
            tx.set(targetFollowerRef, { timeStamp: now }, { merge: true });
        });
    }
    catch (e) {
        console.error("enforceMandatoryFollowOnUserCreate error", e);
    }
});
exports.incrementFollowCountersOnFollowingCreate = functions.firestore
    .document("users/{uid}/followings/{targetUid}")
    .onCreate(async (_snap, context) => {
    const uid = String(context.params.uid || "").trim();
    const targetUid = String(context.params.targetUid || "").trim();
    if (!uid || !targetUid || uid == targetUid)
        return;
    try {
        const now = Date.now();
        await db.runTransaction(async (tx) => {
            tx.set(db.doc(`users/${uid}`), {
                counterOfFollowings: admin.firestore.FieldValue.increment(1),
                updatedDate: now,
            }, { merge: true });
            tx.set(db.doc(`users/${targetUid}`), {
                counterOfFollowers: admin.firestore.FieldValue.increment(1),
                updatedDate: now,
            }, { merge: true });
        });
    }
    catch (e) {
        console.error("incrementFollowCountersOnFollowingCreate error", e);
    }
});
exports.decrementFollowCountersOnFollowingDelete = functions.firestore
    .document("users/{uid}/followings/{targetUid}")
    .onDelete(async (_snap, context) => {
    const uid = String(context.params.uid || "").trim();
    const targetUid = String(context.params.targetUid || "").trim();
    if (!uid || !targetUid || uid == targetUid)
        return;
    try {
        const now = Date.now();
        const meRef = db.doc(`users/${uid}`);
        const targetRef = db.doc(`users/${targetUid}`);
        await db.runTransaction(async (tx) => {
            const meSnap = await tx.get(meRef);
            const targetSnap = await tx.get(targetRef);
            const myCount = Number(meSnap.data()?.counterOfFollowings || 0);
            const targetCount = Number(targetSnap.data()?.counterOfFollowers || 0);
            if (myCount > 0) {
                tx.set(meRef, {
                    counterOfFollowings: admin.firestore.FieldValue.increment(-1),
                    updatedDate: now,
                }, { merge: true });
            }
            if (targetCount > 0) {
                tx.set(targetRef, {
                    counterOfFollowers: admin.firestore.FieldValue.increment(-1),
                    updatedDate: now,
                }, { merge: true });
            }
        });
    }
    catch (e) {
        console.error("decrementFollowCountersOnFollowingDelete error", e);
    }
});
// LIKE COUNTER MIRROR: keep profile counterOfLikes in sync with post likes.
exports.incrementOwnerLikesOnLikeCreate = functions.firestore
    .document("Posts/{postId}/likes/{likeId}")
    .onCreate(async (_snap, context) => {
    const postId = String(context.params.postId || "").trim();
    if (!postId)
        return;
    try {
        const postRef = db.doc(`Posts/${postId}`);
        const postSnap = await postRef.get();
        const ownerId = String(postSnap.data()?.userID || "").trim();
        if (!ownerId)
            return;
        await db.doc(`users/${ownerId}`).set({
            counterOfLikes: admin.firestore.FieldValue.increment(1),
            updatedDate: Date.now(),
        }, { merge: true });
    }
    catch (e) {
        console.error("incrementOwnerLikesOnLikeCreate error", e);
    }
});
exports.decrementOwnerLikesOnLikeDelete = functions.firestore
    .document("Posts/{postId}/likes/{likeId}")
    .onDelete(async (_snap, context) => {
    const postId = String(context.params.postId || "").trim();
    if (!postId)
        return;
    try {
        const postRef = db.doc(`Posts/${postId}`);
        const postSnap = await postRef.get();
        const ownerId = String(postSnap.data()?.userID || "").trim();
        if (!ownerId)
            return;
        const ownerRef = db.doc(`users/${ownerId}`);
        await db.runTransaction(async (tx) => {
            const ownerSnap = await tx.get(ownerRef);
            const current = Number(ownerSnap.data()?.counterOfLikes || 0);
            if (current <= 0)
                return;
            tx.set(ownerRef, {
                counterOfLikes: admin.firestore.FieldValue.increment(-1),
                updatedDate: Date.now(),
            }, { merge: true });
        });
    }
    catch (e) {
        console.error("decrementOwnerLikesOnLikeDelete error", e);
    }
});
// SAFETY NET: Keep phoneAccounts in sync when a user doc is deleted
exports.onUserDocDelete = functions.firestore
    .document("users/{uid}")
    .onDelete(async (snap, context) => {
    const before = snap.data();
    const uid = context.params.uid;
    const phone = (0, userSchemaUtils_1.normalizePhone)(before?.phoneNumber);
    if (!phone)
        return;
    try {
        const ref = db.collection("phoneAccounts").doc(phone);
        await db.runTransaction(async (tx) => {
            const doc = await tx.get(ref);
            if (!doc.exists)
                return;
            const data = doc.data() || {};
            const accounts = Array.isArray(data.accounts) ? data.accounts : [];
            const count = typeof data.count === "number" ? data.count : 0;
            const shouldDec = accounts.includes(uid) && count > 0;
            const update = {
                accounts: admin.firestore.FieldValue.arrayRemove(uid),
                lastUpdatedAt: Date.now(),
            };
            if (shouldDec)
                update.count = admin.firestore.FieldValue.increment(-1);
            tx.update(ref, update);
        });
    }
    catch (e) {
        console.error("onUserDocDelete error", e);
    }
});
// SAFETY NET: Adjust counts if phone number changes on user doc
exports.onUserDocUpdate = functions.firestore
    .document("users/{uid}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const uid = context.params.uid;
    const oldPhone = (0, userSchemaUtils_1.normalizePhone)(before?.phoneNumber);
    const newPhone = (0, userSchemaUtils_1.normalizePhone)(after?.phoneNumber);
    if (!oldPhone && !newPhone)
        return;
    try {
        await db.runTransaction(async (tx) => {
            const now = Date.now();
            if (oldPhone && oldPhone !== newPhone) {
                const oldRef = db.collection("phoneAccounts").doc(oldPhone);
                const oldDoc = await tx.get(oldRef);
                if (oldDoc.exists) {
                    const odata = oldDoc.data() || {};
                    const accounts = Array.isArray(odata.accounts) ? odata.accounts : [];
                    const count = typeof odata.count === "number" ? odata.count : 0;
                    const shouldDec = accounts.includes(uid) && count > 0;
                    const update = {
                        accounts: admin.firestore.FieldValue.arrayRemove(uid),
                        lastUpdatedAt: now,
                    };
                    if (shouldDec)
                        update.count = admin.firestore.FieldValue.increment(-1);
                    tx.update(oldRef, update);
                }
            }
            if (newPhone && oldPhone !== newPhone) {
                const newRef = db.collection("phoneAccounts").doc(newPhone);
                const newDoc = await tx.get(newRef);
                if (newDoc.exists) {
                    const ndata = newDoc.data() || {};
                    const accounts = Array.isArray(ndata.accounts) ? ndata.accounts : [];
                    const shouldInc = !accounts.includes(uid);
                    const update = {
                        accounts: admin.firestore.FieldValue.arrayUnion(uid),
                        lastUpdatedAt: now,
                        lastCreatedAt: now,
                    };
                    if (shouldInc)
                        update.count = admin.firestore.FieldValue.increment(1);
                    tx.update(newRef, update);
                }
                else {
                    tx.set(newRef, {
                        phone: newPhone,
                        count: 1,
                        limit: 5,
                        accounts: [uid],
                        createdAt: now,
                        lastCreatedAt: now,
                    });
                }
            }
        });
    }
    catch (e) {
        console.error("onUserDocUpdate error", e);
    }
});
// PUSH DISPATCHER: users/{uid}/notifications onCreate -> FCM
exports.onUserNotificationCreate = functions.firestore
    .document("users/{uid}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
    let resolvedUserData;
    try {
        const uid = context.params.uid;
        const rawData = (snap.data() || {});
        const initialType = String(rawData.type || "Posts");
        const initialFromUserID = String(rawData.fromUserID || "");
        const initialTargetDocID = String(rawData.postID || rawData.chatID || rawData.userID || "");
        const isAdminPush = rawData.adminPush === true;
        // Self-notification push göndermeyelim.
        if (initialFromUserID && initialFromUserID === uid)
            return;
        const [cfg, userPrefs] = await Promise.all([
            _loadNotificationPushConfig(),
            _loadUserNotificationPreferences(uid),
        ]);
        // Global veya tür bazlı kapalıysa push gönderme.
        if (!cfg.enabled || !(0, notificationPushPolicy_1.isNotificationTypeEnabled)(initialType, cfg.types))
            return;
        if (!(0, notificationPushPolicy_1.isUserNotificationTypeEnabled)(initialType, userPrefs)) {
            console.log("onUserNotificationCreate skip:user_pref_disabled", {
                uid,
                type: initialType,
            });
            return;
        }
        const userDoc = await db.collection("users").doc(uid).get();
        resolvedUserData = (userDoc.data() || {});
        const token = _resolveUserPushToken(resolvedUserData);
        if (!token) {
            console.log("onUserNotificationCreate skip:no_token", {
                type: initialType,
                targetPresent: initialTargetDocID.length > 0,
            });
            return;
        }
        const data = await _resolveNotificationPushPayload(rawData);
        const type = String(data.type || initialType);
        const fromUserID = String(data.fromUserID || initialFromUserID);
        const targetDocID = String(data.postID || data.chatID || data.userID || initialTargetDocID);
        if (!isAdminPush && !(0, notificationPushPolicy_1.shouldDispatchNotificationPush)(type, data)) {
            console.log("onUserNotificationCreate skip:milestone_gate", {
                uid,
                type,
                targetPresent: targetDocID.length > 0,
            });
            return;
        }
        if (!isAdminPush) {
            const canSendPush = await _claimInteractionPushWindow({
                uid,
                type,
                postId: targetDocID,
                fromUserID,
            });
            if (!canSendPush) {
                console.log("onUserNotificationCreate skip:rate_limited", {
                    uid,
                    type,
                    targetPresent: targetDocID.length > 0,
                });
                return;
            }
        }
        const title = String(data.title || "TurqApp");
        const body = String(data.body || (0, notificationPushPolicy_1.notificationBodyFromType)(type));
        const imageUrl = await _resolveNotificationImageUrl(data);
        await admin.messaging().send({
            token,
            notification: {
                title,
                body,
                ...(imageUrl ? { imageUrl } : {}),
            },
            data: {
                docID: targetDocID,
                type,
                title,
                body,
                ...(fromUserID ? { fromUserID } : {}),
                ...(imageUrl ? { imageUrl } : {}),
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    icon: "ic_notification_small",
                    color: "#4F718E",
                    ...(imageUrl ? { imageUrl } : {}),
                },
            },
            apns: {
                headers: { "apns-priority": "10" },
                ...(imageUrl ? { fcmOptions: { imageUrl } } : {}),
                payload: {
                    aps: {
                        alert: { title, body },
                        "mutable-content": imageUrl ? 1 : 0,
                        sound: "default",
                    },
                },
            },
        });
        console.log("onUserNotificationCreate sent", {
            type,
            tokenPresent: true,
            targetPresent: targetDocID.length > 0,
        });
    }
    catch (e) {
        const code = String(e?.errorInfo?.code || e?.code || "");
        if (code === "messaging/registration-token-not-registered") {
            try {
                const uid = context.params.uid;
                const userData = resolvedUserData ??
                    (await db.collection("users").doc(uid).get()).data() ??
                    {};
                const invalidToken = _resolveUserPushToken(userData);
                const cleanup = {};
                for (const key of PUSH_TOKEN_FIELDS) {
                    const raw = _firstNonEmptyString(userData[key]);
                    if (!raw || raw === invalidToken) {
                        cleanup[key] = admin.firestore.FieldValue.delete();
                    }
                }
                await db.collection("users").doc(uid).set(cleanup, { merge: true });
                console.log("onUserNotificationCreate cleared_invalid_token", {
                    uid,
                });
            }
            catch (cleanupError) {
                console.error("onUserNotificationCreate clear_invalid_token_error", cleanupError);
            }
        }
        console.error("onUserNotificationCreate error", e);
    }
});
// ACCOUNT DELETION CRON: process users whose deletion grace period is over
exports.processScheduledAccountDeletions = functions.pubsub
    .schedule("every 60 minutes")
    .timeZone("UTC")
    .onRun(async () => {
    const now = Date.now();
    let processedCount = 0;
    let errorCount = 0;
    console.log("processScheduledAccountDeletions:start");
    try {
        const usersSnap = await db
            .collection("users")
            .where("accountStatus", "==", "pending_deletion")
            .get();
        for (const userDoc of usersSnap.docs) {
            try {
                const userId = userDoc.id;
                const userData = userDoc.data();
                const actionsSnap = await db
                    .collection("users")
                    .doc(userId)
                    .collection("account_actions")
                    .where("type", "==", "deletion")
                    .where("status", "==", "pending")
                    .orderBy("createdDate", "desc")
                    .limit(1)
                    .get();
                if (actionsSnap.empty) {
                    continue;
                }
                const actionDoc = actionsSnap.docs[0];
                const action = actionDoc.data();
                const scheduledAt = Number(action.scheduledAt || 0);
                if (!scheduledAt || scheduledAt > now) {
                    continue;
                }
                const timestamp = Date.now();
                const baseName = String(userData.username || userData.nickname || "user").replace(/\s+/g, "_");
                const deletedName = `deleted_${baseName}_${timestamp}`;
                await db.collection("users").doc(userId).set({
                    accountStatus: "deleted",
                    username: deletedName,
                    nickname: deletedName,
                    usernameLower: deletedName.toLowerCase(),
                    isDeleted: true,
                    isPrivate: true,
                    updatedDate: timestamp,
                    deletedAt: timestamp,
                    deletionCompletedAt: timestamp,
                }, { merge: true });
                await actionDoc.ref.set({
                    status: "completed",
                    completedAt: Date.now(),
                    originalUsername: String(userData.username || ""),
                    originalNickname: String(userData.nickname || ""),
                }, { merge: true });
                processedCount++;
            }
            catch (e) {
                console.error("processScheduledAccountDeletions:user_error", e);
                errorCount++;
            }
        }
        console.log("processScheduledAccountDeletions:done", {
            processedCount,
            errorCount,
            totalPending: usersSnap.size,
        });
        return null;
    }
    catch (e) {
        console.error("processScheduledAccountDeletions:fatal", e);
        throw e;
    }
});
exports.publishScheduledIzBirakPosts = functions.pubsub
    .schedule("every 5 minutes")
    .timeZone("UTC")
    .onRun(async () => {
    const now = Date.now();
    console.log("publishScheduledIzBirakPosts:start");
    const dueSnap = await db
        .collection("Posts")
        .where("scheduledAt", ">", 0)
        .where("scheduledAt", "<=", now)
        .limit(100)
        .get();
    if (dueSnap.empty) {
        console.log("publishScheduledIzBirakPosts:none_due");
        return null;
    }
    for (const postDoc of dueSnap.docs) {
        const data = postDoc.data();
        const ownerId = String(data.userID || "");
        const publishAt = Number(data.scheduledAt || 0);
        const alreadyNotified = Number(data.izBirakNotificationSentAt || 0);
        if (!ownerId || !publishAt || alreadyNotified > 0) {
            continue;
        }
        try {
            const subscribersSnap = await postDoc.ref
                .collection("izBirakSubscribers")
                .get();
            const imageUrl = String(data.thumbnail ||
                (Array.isArray(data.img) && data.img.length > 0
                    ? data.img[0]
                    : "") ||
                "");
            const caption = String(data.metin || "").trim();
            const body = caption.length > 0
                ? caption.slice(0, 120)
                : "İz bıraktığın içerik yayına girdi.";
            let batch = db.batch();
            let opCount = 0;
            for (const subscriberDoc of subscribersSnap.docs) {
                const subscriberId = subscriberDoc.id;
                if (!subscriberId || subscriberId === ownerId) {
                    continue;
                }
                batch.set(db
                    .collection("users")
                    .doc(subscriberId)
                    .collection("notifications")
                    .doc(`izbirak_${postDoc.id}`), (0, notificationInbox_1.buildInboxPayload)(subscriberId, {
                    type: "Posts",
                    fromUserID: ownerId,
                    postID: postDoc.id,
                    timeStamp: now,
                    read: false,
                    title: "İz Bırak yayında",
                    body,
                    imageUrl,
                }));
                opCount++;
                if (opCount >= 400) {
                    await batch.commit();
                    batch = db.batch();
                    opCount = 0;
                }
            }
            batch.set(postDoc.ref, {
                scheduledAt: 0,
                timeStamp: now,
                updatedAt: now,
                izBirakPublishedAt: now,
                izBirakNotificationSentAt: now,
            }, { merge: true });
            await batch.commit();
            await (0, hybridFeed_1.upsertPostIntoHybridFeed)({
                postId: postDoc.id,
                authorId: ownerId,
                timeStamp: now,
                isVideo: !!(data.videoHLSMasterUrl || data.hlsMasterUrl || data.video),
            });
            console.log("publishScheduledIzBirakPosts:published", {
                subscriberCount: subscribersSnap.size,
            });
        }
        catch (e) {
            console.error("publishScheduledIzBirakPosts:error", {
                error: e,
            });
        }
    }
    return null;
});
// MONTHLY RESET: Set antPoint to 100 for all users on the 1st day of each month
exports.resetMonthlyAntPoint = functions.pubsub
    .schedule("0 0 1 * *")
    .timeZone("UTC")
    .onRun(async () => {
    const batchSize = 450;
    const now = new Date();
    const monthKey = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;
    const resetCollection = async (queryFactory, extraFields = {}) => {
        let lastDoc = null;
        let total = 0;
        while (true) {
            const query = queryFactory(lastDoc);
            const snap = await query.get();
            if (snap.empty)
                break;
            const batch = db.batch();
            for (const doc of snap.docs) {
                batch.set(doc.ref, { antPoint: 100, ...extraFields }, { merge: true });
            }
            await batch.commit();
            total += snap.size;
            lastDoc = snap.docs[snap.docs.length - 1];
        }
        return total;
    };
    const usersTotal = await resetCollection((lastDoc) => {
        let query = db
            .collection("users")
            .orderBy("__name__")
            .limit(batchSize);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        return query;
    });
    const leaderboardTotal = await resetCollection((lastDoc) => {
        let query = db
            .collection("questionBankSkor")
            .doc(monthKey)
            .collection("items")
            .orderBy("__name__")
            .limit(batchSize);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        return query;
    }, {
        updatedAt: Date.now(),
    });
    console.log("resetMonthlyAntPoint done", {
        monthKey,
        usersTotal,
        leaderboardTotal,
    });
    return null;
});
function _pushThrottleRef(uid) {
    return db
        .collection("users")
        .doc(uid.trim())
        .collection("_runtime")
        .doc("pushThrottle");
}
async function _claimInteractionPushWindow(args) {
    const uid = args.uid.trim();
    const type = (0, notificationPushPolicy_1.interactionThrottleType)(args.type);
    const quietWindowMs = (0, notificationPushPolicy_1.interactionQuietWindowMs)(type);
    if (!uid || !quietWindowMs)
        return true;
    const ref = _pushThrottleRef(uid);
    const now = Date.now();
    return db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const data = (snap.data() || {});
        const lastSentAt = Number(data[`${type}LastSentAt`] ?? 0);
        if (lastSentAt > 0 && now - lastSentAt < quietWindowMs) {
            tx.set(ref, {
                [`${type}SuppressedCount`]: admin.firestore.FieldValue.increment(1),
                [`${type}LastSuppressedAt`]: now,
                updatedAt: now,
            }, { merge: true });
            return false;
        }
        tx.set(ref, {
            [`${type}LastSentAt`]: now,
            [`${type}LastPostID`]: String(args.postId || ""),
            [`${type}LastFromUserID`]: String(args.fromUserID || ""),
            updatedAt: now,
        }, { merge: true });
        return true;
    });
}
async function _loadNotificationPushConfig() {
    try {
        const [pushSnap, serviceSnap] = await Promise.all([
            db.doc("adminConfig/push").get(),
            db.doc("adminConfig/service").get(),
        ]);
        const pushData = (pushSnap.data() || {});
        // Primary schema (requested):
        // adminConfig/push => { enabled, follow, comment, message, like, reshared_posts, shared_as_posts, posts }
        const primaryEnabledRaw = pushData.enabled ?? true;
        const primaryTypesRaw = pushData;
        // Backward-compatible fallback schema:
        // adminConfig/service => { notifications: { enabled, types: {...} } } or legacy keys.
        const serviceData = (serviceSnap.data() || {});
        const notifications = (serviceData.notifications || {});
        const fallbackTypesRaw = (notifications.types || serviceData.notificationTypes || {});
        const fallbackEnabledRaw = notifications.enabled ?? serviceData.notificationsEnabled ?? true;
        const normalizeBool = (value, fallback) => {
            if (typeof value === "boolean")
                return value;
            return fallback;
        };
        return {
            enabled: normalizeBool(primaryEnabledRaw, normalizeBool(fallbackEnabledRaw, true)),
            types: {
                follow: normalizeBool(primaryTypesRaw.follow, normalizeBool(fallbackTypesRaw.follow, notificationPushPolicy_1.defaultPushTypes.follow)),
                comment: normalizeBool(primaryTypesRaw.comment, normalizeBool(fallbackTypesRaw.comment, notificationPushPolicy_1.defaultPushTypes.comment)),
                message: normalizeBool(primaryTypesRaw.message, normalizeBool(fallbackTypesRaw.message, notificationPushPolicy_1.defaultPushTypes.message)),
                like: normalizeBool(primaryTypesRaw.like, normalizeBool(fallbackTypesRaw.like, notificationPushPolicy_1.defaultPushTypes.like)),
                reshared_posts: normalizeBool(primaryTypesRaw.reshared_posts, normalizeBool(fallbackTypesRaw.reshared_posts, notificationPushPolicy_1.defaultPushTypes.reshared_posts)),
                shared_as_posts: normalizeBool(primaryTypesRaw.shared_as_posts, normalizeBool(fallbackTypesRaw.shared_as_posts, notificationPushPolicy_1.defaultPushTypes.shared_as_posts)),
                posts: normalizeBool(primaryTypesRaw.posts, normalizeBool(fallbackTypesRaw.posts, notificationPushPolicy_1.defaultPushTypes.posts)),
            },
        };
    }
    catch (e) {
        console.error("_loadNotificationPushConfig error", e);
        return { enabled: true, types: notificationPushPolicy_1.defaultPushTypes };
    }
}
async function _loadUserNotificationPreferences(uid) {
    try {
        const settingsSnap = await db
            .collection("users")
            .doc(uid.trim())
            .collection("settings")
            .doc("notifications")
            .get();
        return (settingsSnap.data() || {});
    }
    catch (e) {
        console.error("_loadUserNotificationPreferences error", e);
        return {};
    }
}
// ADMIN UTILITY: Backfill phoneAccounts from existing users
exports.backfillPhoneAccounts = functions.https.onCall(async (data, context) => {
    // Require authenticated call; ideally require admin custom claim
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const isAdmin = context.auth.token?.admin === true;
    if (isAdmin) {
        rateLimiter_1.RateLimits.admin(context.auth.uid);
    }
    const providedSecret = typeof data?.secret === 'string' ? data.secret : '';
    const configuredSecret = (process.env.PHONE_BACKFILL_SECRET || '').toString();
    if (!isAdmin && (!configuredSecret || providedSecret !== configuredSecret)) {
        throw new functions.https.HttpsError('permission-denied', 'Admin or valid secret required');
    }
    const batchSize = Math.min(Number(data?.batchSize) || 500, 500);
    const startAfterId = typeof data?.startAfter === 'string' ? data.startAfter : undefined;
    let q = db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
    if (startAfterId) {
        const startSnap = await db.collection('users').doc(startAfterId).get();
        if (startSnap.exists) {
            q = db.collection('users')
                .orderBy(admin.firestore.FieldPath.documentId())
                .startAfter(startSnap.id)
                .limit(batchSize);
        }
    }
    const snap = await q.get();
    if (snap.empty) {
        return { done: true, processed: 0 };
    }
    const phoneMap = new Map();
    for (const doc of snap.docs) {
        const data = doc.data();
        const uid = doc.id;
        const phone = (0, userSchemaUtils_1.normalizePhone)(data?.phoneNumber);
        if (!phone)
            continue;
        if (!phoneMap.has(phone))
            phoneMap.set(phone, new Set());
        phoneMap.get(phone).add(uid);
    }
    const batch = db.batch();
    const now = Date.now();
    for (const [phone, uids] of phoneMap.entries()) {
        const ref = db.collection('phoneAccounts').doc(phone);
        const arr = Array.from(uids);
        batch.set(ref, {
            phone,
            count: admin.firestore.FieldValue.increment(arr.length),
            limit: 5,
            accounts: admin.firestore.FieldValue.arrayUnion(...arr),
            lastUpdatedAt: now,
            lastCreatedAt: now,
            createdAt: now,
        }, { merge: true });
    }
    await batch.commit();
    const lastDoc = snap.docs[snap.docs.length - 1];
    return { done: false, processed: snap.size, lastId: lastDoc.id };
});
// ADMIN UTILITY: disabled (users_usernames removed)
exports.backfillUsernames = functions.https.onCall(async (data, context) => {
    throw new functions.https.HttpsError("failed-precondition", "users_usernames is deprecated and disabled");
});
// ADMIN UTILITY: Backfill users.avatarUrl legacy placeholder values to empty string
// Authentication'da kayıtlı kullanıcıları baz alır; users/{uid} varsa normalize eder.
exports.backfillUserAvatarUrls = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }
    const isAdmin = context.auth.token?.admin === true;
    if (isAdmin) {
        rateLimiter_1.RateLimits.admin(context.auth.uid);
    }
    const providedSecret = typeof data?.secret === "string" ? data.secret : "";
    const configuredSecret = (process.env.USER_AVATAR_BACKFILL_SECRET || "").toString();
    if (!isAdmin && (!configuredSecret || providedSecret !== configuredSecret)) {
        throw new functions.https.HttpsError("permission-denied", "Admin or valid secret required");
    }
    const batchSize = Math.min(Math.max(Number(data?.batchSize) || 400, 1), 400);
    const pageToken = typeof data?.pageToken === "string" ? data.pageToken.trim() : undefined;
    const listResult = await admin.auth().listUsers(batchSize, pageToken || undefined);
    if (listResult.users.length === 0) {
        return { done: true, processed: 0, updated: 0, skipped: 0, missingDocs: 0 };
    }
    const now = Date.now();
    const batch = db.batch();
    let updated = 0;
    let skipped = 0;
    let missingDocs = 0;
    for (const authUser of listResult.users) {
        const docRef = db.collection("users").doc(authUser.uid);
        const doc = await docRef.get();
        if (!doc.exists) {
            missingDocs += 1;
            continue;
        }
        const userData = doc.data();
        const before = String(userData?.avatarUrl ?? "").trim();
        const after = (0, userSchemaUtils_1.normalizeAvatarUrl)(before);
        if (before === after) {
            skipped += 1;
            continue;
        }
        batch.update(docRef, {
            avatarUrl: after,
            updatedDate: now,
        });
        updated += 1;
    }
    if (updated > 0) {
        await batch.commit();
    }
    return {
        done: !listResult.pageToken,
        processed: listResult.users.length,
        updated,
        skipped,
        missingDocs,
        nextPageToken: listResult.pageToken ?? null,
    };
});
// ADMIN UTILITY: Backfill Posts with missing originalUserID/originalUserNickname (String '')
exports.backfillPostsOriginalFields = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const isAdmin = context.auth.token?.admin === true;
    if (isAdmin) {
        rateLimiter_1.RateLimits.admin(context.auth.uid);
    }
    const providedSecret = typeof data?.secret === 'string' ? data.secret : '';
    const configuredSecret = (process.env.POSTS_BACKFILL_SECRET || '').toString();
    if (!isAdmin && (!configuredSecret || providedSecret !== configuredSecret)) {
        throw new functions.https.HttpsError('permission-denied', 'Admin or valid secret required');
    }
    const batchSize = Math.min(Math.max(Number(data?.batchSize) || 500, 1), 500);
    const cursorTs = typeof data?.cursor?.timeStamp === 'number' ? data.cursor.timeStamp : undefined;
    const cursorId = typeof data?.cursor?.docId === 'string' ? data.cursor.docId : undefined;
    const onlyMissing = (data?.onlyMissing ?? true) !== false; // default true
    let q = db.collection('Posts')
        .orderBy('timeStamp', 'desc')
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(batchSize);
    if (cursorTs !== undefined && cursorId) {
        q = db.collection('Posts')
            .orderBy('timeStamp', 'desc')
            .orderBy(admin.firestore.FieldPath.documentId())
            .startAfter(cursorTs, cursorId)
            .limit(batchSize);
    }
    const snap = await q.get();
    if (snap.empty) {
        return { done: true, processed: 0, updated: 0, skipped: 0, failed: 0 };
    }
    let updated = 0;
    let skipped = 0;
    let failed = 0;
    const batch = db.batch();
    let writes = 0;
    for (const doc of snap.docs) {
        try {
            const data = doc.data();
            const hasId = typeof data.originalUserID === 'string';
            const hasNick = typeof data.originalUserNickname === 'string';
            const patch = {};
            if (!hasId)
                patch.originalUserID = '';
            if (!hasNick)
                patch.originalUserNickname = '';
            if (Object.keys(patch).length === 0 && onlyMissing) {
                skipped += 1;
            }
            else if (Object.keys(patch).length > 0) {
                batch.update(doc.ref, patch);
                writes += 1;
                updated += 1;
            }
            else {
                skipped += 1;
            }
        }
        catch (e) {
            console.error('backfillPostsOriginalFields: error', e);
            failed += 1;
        }
    }
    if (writes > 0) {
        await batch.commit();
    }
    const last = snap.docs[snap.docs.length - 1];
    const lastData = last.data();
    return {
        done: false,
        processed: snap.size,
        updated,
        skipped,
        failed,
        nextCursor: {
            timeStamp: typeof lastData.timeStamp === 'number' ? lastData.timeStamp : null,
            docId: last.id,
        },
    };
});
const STUDENT_PROTECTED_COLLECTIONS = new Set([
    'followings',
    'followers',
    'SosyalMedyaLinkleri',
]);
const countDocuments = async (collection) => {
    try {
        const snapshot = await collection.count().get();
        const total = snapshot.data().count;
        return typeof total === "number" ? total : 0;
    }
    catch (err) {
        console.error("countDocuments error", err);
        // Fallback: iterate in batches of 500 (may be slower but guarantees correctness)
        let total = 0;
        let query = collection
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(500);
        // eslint-disable-next-line no-constant-condition
        while (true) {
            const batch = await query.get();
            if (batch.empty)
                break;
            total += batch.size;
            const last = batch.docs[batch.docs.length - 1];
            query = collection.orderBy(admin.firestore.FieldPath.documentId()).startAfter(last.id).limit(500);
        }
        return total;
    }
};
exports.purgePostSubcollections = functions
    .region('europe-west1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    // SECURITY: Sadece admin silme işlemi yapabilir
    const isAdmin = context.auth.token?.admin === true;
    if (!isAdmin) {
        throw new functions.https.HttpsError("permission-denied", "Admin privileges required");
    }
    rateLimiter_1.RateLimits.admin(context.auth.uid);
    const docPathRaw = typeof data?.docPath === "string" ? data.docPath : "";
    const docPath = docPathRaw.trim();
    if (!docPath || !/^posts\/[A-Za-z0-9_-]+$/.test(docPath)) {
        throw new functions.https.HttpsError("invalid-argument", "docPath must be a posts/{docId} path");
    }
    const docRef = db.doc(docPath);
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
        return {
            ok: true,
            found: false,
            deletedSubcollections: [],
            totalDeletedDocuments: 0,
        };
    }
    try {
        const subcollections = await docRef.listCollections();
        if (subcollections.length === 0) {
            return {
                ok: true,
                found: true,
                deletedSubcollections: [],
                totalDeletedDocuments: 0,
            };
        }
        const details = [];
        let totalDeleted = 0;
        for (const subcollection of subcollections) {
            const deletedDocuments = await countDocuments(subcollection);
            await admin.firestore().recursiveDelete(subcollection);
            details.push({
                name: subcollection.id,
                deletedDocuments,
            });
            totalDeleted += deletedDocuments;
        }
        return {
            ok: true,
            found: true,
            deletedSubcollections: details,
            totalDeletedDocuments: totalDeleted,
        };
    }
    catch (error) {
        console.error("purgePostSubcollections error", error);
        throw new functions.https.HttpsError("internal", error?.message ?? "Failed to purge subcollections");
    }
});
exports.purgeStudentSubcollections = functions
    .region('europe-west1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    // SECURITY: Sadece admin silme işlemi yapabilir
    const isAdmin = context.auth.token?.admin === true;
    if (!isAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin privileges required');
    }
    rateLimiter_1.RateLimits.admin(context.auth.uid);
    const docPathRaw = typeof data?.docPath === 'string' ? data.docPath : '';
    const docPath = docPathRaw.trim();
    if (!docPath || !/^users\/[A-Za-z0-9_-]+$/.test(docPath)) {
        throw new functions.https.HttpsError('invalid-argument', 'docPath must be a users/{docId} path');
    }
    const docRef = db.doc(docPath);
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
        return {
            ok: true,
            found: false,
            docPath,
            deletedSubcollections: [],
            failedSubcollections: [],
            skippedCollections: [],
            totalDeletedDocuments: 0,
            totalCollections: 0,
        };
    }
    try {
        const subcollections = await docRef.listCollections();
        if (subcollections.length === 0) {
            return {
                ok: true,
                found: true,
                docPath,
                deletedSubcollections: [],
                failedSubcollections: [],
                skippedCollections: [],
                totalDeletedDocuments: 0,
                totalCollections: 0,
            };
        }
        const details = [];
        const failures = [];
        const skipped = [];
        let totalDeleted = 0;
        for (const subcollection of subcollections) {
            const name = subcollection.id;
            if (STUDENT_PROTECTED_COLLECTIONS.has(name)) {
                skipped.push(name);
                continue;
            }
            try {
                const deletedDocuments = await countDocuments(subcollection);
                if (deletedDocuments > 0) {
                    await admin.firestore().recursiveDelete(subcollection);
                }
                details.push({
                    name,
                    deletedDocuments,
                });
                totalDeleted += deletedDocuments;
            }
            catch (err) {
                console.error('purgeStudentSubcollections error', err);
                failures.push({
                    name,
                    message: typeof err?.message === 'string' ? err.message : String(err),
                });
            }
        }
        return {
            ok: true,
            found: true,
            docPath,
            deletedSubcollections: details,
            failedSubcollections: failures,
            skippedCollections: skipped,
            totalDeletedDocuments: totalDeleted,
            totalCollections: subcollections.length,
            processedAt: Date.now(),
        };
    }
    catch (err) {
        console.error('purgeStudentSubcollections fatal error', err);
        throw new functions.https.HttpsError('internal', typeof err?.message === 'string' ? err.message : 'Unexpected error');
    }
});
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔄 MIGRATION: Copy users → users collection
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
exports.migrateusersToUsers = functions
    .region('europe-west1')
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const isAdmin = context.auth.token?.admin === true;
    if (!isAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin privileges required');
    }
    rateLimiter_1.RateLimits.admin(context.auth.uid);
    const batchSize = Math.min(Number(data?.batchSize) || 100, 500);
    const startAfterId = typeof data?.startAfter === 'string' ? data.startAfter : undefined;
    const copySubcollections = data?.copySubcollections === true;
    let q = db.collection('users')
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(batchSize);
    if (startAfterId) {
        q = q.startAfter(startAfterId);
    }
    const snap = await q.get();
    if (snap.empty) {
        return { done: true, processed: 0, message: 'Migration complete!' };
    }
    const writeBatch = db.batch();
    let processed = 0;
    for (const doc of snap.docs) {
        const targetRef = db.collection('users').doc(doc.id);
        writeBatch.set(targetRef, doc.data(), { merge: true });
        processed++;
        if (copySubcollections) {
            const subcols = await doc.ref.listCollections();
            for (const subcol of subcols) {
                const subDocs = await subcol.get();
                for (const subDoc of subDocs.docs) {
                    const subTargetRef = db.collection('users')
                        .doc(doc.id)
                        .collection(subcol.id)
                        .doc(subDoc.id);
                    writeBatch.set(subTargetRef, subDoc.data(), { merge: true });
                }
            }
        }
    }
    await writeBatch.commit();
    const lastId = snap.docs[snap.docs.length - 1].id;
    return {
        done: false,
        processed,
        lastId,
        message: `Migrated ${processed} users. Call again with startAfter: "${lastId}"`,
    };
});
//# sourceMappingURL=index.js.map