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
exports.migrateusersToUsers = exports.purgeStudentSubcollections = exports.purgePostSubcollections = exports.backfillPostsOriginalFields = exports.backfillUsernames = exports.backfillPhoneAccounts = exports.resetMonthlyAntPoint = exports.processScheduledAccountDeletions = exports.onUserNotificationCreate = exports.onUserDocUpdate = exports.onUserDocDelete = exports.enforceMandatoryFollowOnUserCreate = exports.syncUserSchemaAndFlags = exports.archiveOnStoryDelete = exports.cleanupExpiredStories = exports.syncAuthorFieldsOnProfileUpdate = exports.denormAuthorOnPostWrite = exports.cleanupExpiredFeedItems = exports.onNewFollower = exports.onPostDelete = exports.onPostCreate = exports.initCounterShards = exports.aggregateCounterShards = exports.recordViewBatch = exports.onVideoUpload = exports.generateThumbnails = void 0;
// Cloud Functions templates for story TTL and deletion archival
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const rateLimiter_1 = require("./rateLimiter");
admin.initializeApp();
const DEFAULT_PROFILE_IMAGE_URL = "https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2";
const db = admin.firestore();
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
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📊 AGGREGATION COUNTER SHARDING (A9)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var counterShards_1 = require("./counterShards");
Object.defineProperty(exports, "recordViewBatch", { enumerable: true, get: function () { return counterShards_1.recordViewBatch; } });
Object.defineProperty(exports, "aggregateCounterShards", { enumerable: true, get: function () { return counterShards_1.aggregateCounterShards; } });
Object.defineProperty(exports, "initCounterShards", { enumerable: true, get: function () { return counterShards_1.initCounterShards; } });
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📰 HYBRID FEED FAN-OUT / FAN-IN (B4)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var hybridFeed_1 = require("./hybridFeed");
Object.defineProperty(exports, "onPostCreate", { enumerable: true, get: function () { return hybridFeed_1.onPostCreate; } });
Object.defineProperty(exports, "onPostDelete", { enumerable: true, get: function () { return hybridFeed_1.onPostDelete; } });
Object.defineProperty(exports, "onNewFollower", { enumerable: true, get: function () { return hybridFeed_1.onNewFollower; } });
Object.defineProperty(exports, "cleanupExpiredFeedItems", { enumerable: true, get: function () { return hybridFeed_1.cleanupExpiredFeedItems; } });
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
// SCHEDULED CLEANUP: Move expired (older than 24h) stories to DeletedStories and delete from Stories
exports.cleanupExpiredStories = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async () => {
    const now = Date.now();
    const cutoff = now - 24 * 60 * 60 * 1000; // 24h in ms
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
                userId: userId,
                createdAtOriginal: data.createdAt ?? now,
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
// FIRESTORE TRIGGER: When a story is deleted without client-side archival, archive it.
// Note: v2 onDocumentDeleted provides the old data; here we simulate with onDelete + data in value before delete.
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
            userId: userId,
            createdAtOriginal: data.createdAt ?? now,
            backgroundColor: data.backgroundColor ?? 0,
            musicUrl: data.musicUrl ?? "",
            elements: data.elements ?? [],
        });
    }
    catch (e) {
        console.error("archiveOnStoryDelete error", e);
    }
});
// Helper: normalize phone to last 10 digits (TR mobile format in app)
const normalizePhone = (raw) => {
    if (!raw)
        return "";
    const digits = String(raw).replace(/[^0-9]/g, "");
    if (digits.length >= 10) {
        return digits.substring(digits.length - 10);
    }
    return digits;
};
const normalizeUsernameLower = (raw) => {
    const s = String(raw ?? "")
        .trim()
        .toLowerCase()
        .replace(/\s+/g, "");
    return s.replace(/[^a-z0-9._]/g, "");
};
const parseForceFollowUids = (data) => {
    if (!data)
        return [];
    const enabled = data.enabled;
    if (enabled === false)
        return [];
    const out = new Set();
    const addOne = (v) => {
        if (typeof v !== "string")
            return;
        const trimmed = v.trim();
        if (trimmed)
            out.add(trimmed);
    };
    const addMany = (arr) => {
        if (!Array.isArray(arr))
            return;
        for (const v of arr)
            addOne(v);
    };
    addOne(data.requiredUserIds);
    addMany(data.requiredUserIds);
    addOne(data.equiredUserIds);
    addMany(data.equiredUserIds);
    addOne(data.requiredUserId);
    addOne(data.uid);
    addOne(data.userId);
    return Array.from(out);
};
const parseLegacyCreatedDateToTimestamp = (raw) => {
    if (typeof raw === "number" && Number.isFinite(raw) && raw > 0) {
        return admin.firestore.Timestamp.fromMillis(Math.floor(raw));
    }
    if (typeof raw === "string") {
        const n = Number(raw);
        if (Number.isFinite(n) && n > 0) {
            return admin.firestore.Timestamp.fromMillis(Math.floor(n));
        }
    }
    return null;
};
const toNonNegativeInt = (raw) => {
    const n = Number(raw);
    if (!Number.isFinite(n))
        return 0;
    return Math.max(0, Math.trunc(n));
};
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
    const canonicalUsername = normalizeUsernameLower(afterData?.usernameLower ||
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
    if (afterData?.isBot === undefined)
        patch.isBot = false;
    if (!afterData?.avatarUrl) {
        patch.avatarUrl = DEFAULT_PROFILE_IMAGE_URL;
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
    const createdDateTs = parseLegacyCreatedDateToTimestamp(afterData?.createdDate);
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
        const updatedTs = parseLegacyCreatedDateToTimestamp(afterData?.updatedAt);
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
    const followersCount = toNonNegativeInt(afterData?.counterOfFollowers);
    const followingsCount = toNonNegativeInt(afterData?.counterOfFollowings);
    const postsCount = toNonNegativeInt(afterData?.counterOfPosts);
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
// FORCE FOLLOW ON NEW USER CREATE (server-side guarantee)
exports.enforceMandatoryFollowOnUserCreate = functions.firestore
    .document("users/{uid}")
    .onCreate(async (_snap, context) => {
    const uid = context.params.uid;
    if (!uid)
        return;
    try {
        const configSnap = await db.collection("adminConfig").doc("forceFollow").get();
        const required = parseForceFollowUids(configSnap.data()).filter((target) => target !== uid);
        if (required.length === 0)
            return;
        const now = Date.now();
        for (const targetUid of required) {
            const myFollowingRef = db.doc(`users/${uid}/followings/${targetUid}`);
            const targetFollowerRef = db.doc(`users/${targetUid}/followers/${uid}`);
            const meRootRef = db.doc(`users/${uid}`);
            const targetRootRef = db.doc(`users/${targetUid}`);
            await db.runTransaction(async (tx) => {
                const existing = await tx.get(myFollowingRef);
                if (existing.exists)
                    return;
                tx.set(myFollowingRef, { timeStamp: now }, { merge: true });
                tx.set(targetFollowerRef, { timeStamp: now }, { merge: true });
                tx.set(meRootRef, {
                    counterOfFollowings: admin.firestore.FieldValue.increment(1),
                    updatedDate: now,
                }, { merge: true });
                tx.set(targetRootRef, {
                    counterOfFollowers: admin.firestore.FieldValue.increment(1),
                    updatedDate: now,
                }, { merge: true });
            });
        }
    }
    catch (e) {
        console.error("enforceMandatoryFollowOnUserCreate error", e);
    }
});
// SAFETY NET: Keep phoneAccounts in sync when a user doc is deleted
exports.onUserDocDelete = functions.firestore
    .document("users/{uid}")
    .onDelete(async (snap, context) => {
    const before = snap.data();
    const uid = context.params.uid;
    const phone = normalizePhone(before?.phoneNumber);
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
    const oldPhone = normalizePhone(before?.phoneNumber);
    const newPhone = normalizePhone(after?.phoneNumber);
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
    try {
        const uid = context.params.uid;
        const data = (snap.data() || {});
        const type = String(data.type || "Posts");
        const fromUserID = String(data.fromUserID || "");
        const targetDocID = String(data.postID || data.chatID || data.userID || "");
        const cfg = await _loadNotificationPushConfig();
        // Self-notification push göndermeyelim.
        if (fromUserID && fromUserID === uid)
            return;
        // Global veya tür bazlı kapalıysa push gönderme.
        if (!cfg.enabled || !_isNotificationTypeEnabled(type, cfg.types))
            return;
        const userDoc = await db.collection("users").doc(uid).get();
        const userData = (userDoc.data() || {});
        const token = String(userData.fcmToken || "");
        if (!token) {
            console.log("onUserNotificationCreate skip:no_token", { uid, type });
            return;
        }
        const title = String(data.title || "TurqApp");
        const body = String(data.body || _notificationBodyFromType(type));
        const imageUrl = String(data.imageUrl || "");
        await admin.messaging().send({
            token,
            notification: { title, body },
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
                payload: {
                    aps: {
                        alert: { title, body },
                        "mutable-content": imageUrl ? 1 : 0,
                        sound: "default",
                    },
                },
            },
        });
        console.log("onUserNotificationCreate sent", { uid, type, tokenPresent: true });
    }
    catch (e) {
        console.error("onUserNotificationCreate error", e);
    }
});
// ACCOUNT DELETION CRON: process users whose deletion grace period is over
exports.processScheduledAccountDeletions = functions.pubsub
    .schedule("0 0 * * *")
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
                    updatedAt: Date.now(),
                    deletedAt: Date.now(),
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
const _defaultPushTypes = {
    follow: true,
    comment: true,
    message: true,
    like: true,
    reshared_posts: true,
    shared_as_posts: true,
    posts: true,
};
async function _loadNotificationPushConfig() {
    try {
        const pushSnap = await db.doc("adminConfig/push").get();
        const pushData = (pushSnap.data() || {});
        // Primary schema (requested):
        // adminConfig/push => { enabled, follow, comment, message, like, reshared_posts, shared_as_posts, posts }
        const primaryEnabledRaw = pushData.enabled ?? true;
        const primaryTypesRaw = pushData;
        // Backward-compatible fallback schema:
        // adminConfig/service => { notifications: { enabled, types: {...} } } or legacy keys.
        const serviceSnap = await db.doc("adminConfig/service").get();
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
                follow: normalizeBool(primaryTypesRaw.follow, normalizeBool(fallbackTypesRaw.follow, _defaultPushTypes.follow)),
                comment: normalizeBool(primaryTypesRaw.comment, normalizeBool(fallbackTypesRaw.comment, _defaultPushTypes.comment)),
                message: normalizeBool(primaryTypesRaw.message, normalizeBool(fallbackTypesRaw.message, _defaultPushTypes.message)),
                like: normalizeBool(primaryTypesRaw.like, normalizeBool(fallbackTypesRaw.like, _defaultPushTypes.like)),
                reshared_posts: normalizeBool(primaryTypesRaw.reshared_posts, normalizeBool(fallbackTypesRaw.reshared_posts, _defaultPushTypes.reshared_posts)),
                shared_as_posts: normalizeBool(primaryTypesRaw.shared_as_posts, normalizeBool(fallbackTypesRaw.shared_as_posts, _defaultPushTypes.shared_as_posts)),
                posts: normalizeBool(primaryTypesRaw.posts, normalizeBool(fallbackTypesRaw.posts, _defaultPushTypes.posts)),
            },
        };
    }
    catch (e) {
        console.error("_loadNotificationPushConfig error", e);
        return { enabled: true, types: _defaultPushTypes };
    }
}
function _isNotificationTypeEnabled(type, types) {
    const t = String(type || "").toLowerCase();
    switch (t) {
        case "user":
        case "follow":
            return types.follow;
        case "comment":
            return types.comment;
        case "chat":
        case "message":
            return types.message;
        case "like":
            return types.like;
        case "reshared_posts":
            return types.reshared_posts;
        case "shared_as_posts":
            return types.shared_as_posts;
        case "posts":
            return types.posts;
        default:
            // Tanınmayan tipleri güvenli tarafta bırak: push açık
            return true;
    }
}
function _notificationBodyFromType(type) {
    switch (type) {
        case "User":
        case "follow":
            return "seni takip etmeye başladı";
        case "Chat":
        case "message":
            return "sana mesaj gönderdi";
        case "Comment":
        case "comment":
            return "gönderine yorum yaptı";
        case "Posts":
        case "like":
        case "reshared_posts":
        case "shared_as_posts":
        default:
            return "gönderinle etkileşime geçti";
    }
}
// ADMIN UTILITY: Backfill phoneAccounts from existing users
exports.backfillPhoneAccounts = functions.https.onCall(async (data, context) => {
    // Require authenticated call; ideally require admin custom claim
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const isAdmin = context.auth.token?.admin === true;
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
        const phone = normalizePhone(data?.phoneNumber);
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
// ADMIN UTILITY: Backfill Posts with missing originalUserID/originalUserNickname (String '')
exports.backfillPostsOriginalFields = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }
    const isAdmin = context.auth.token?.admin === true;
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
            console.error('backfillPostsOriginalFields: error on', doc.id, e);
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
        console.error("countDocuments error", collection.path, err);
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
        console.error("purgePostSubcollections error", docPath, error);
        throw new functions.https.HttpsError("internal", error?.message ?? "Failed to purge subcollections", {
            docPath,
        });
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
                console.error('purgeStudentSubcollections error', docPath, name, err);
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
        console.error('purgeStudentSubcollections fatal error', docPath, err);
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