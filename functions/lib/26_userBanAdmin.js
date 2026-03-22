"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setUserBanByUserId = exports.setUserBanByNickname = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const rateLimiter_1 = require("./rateLimiter");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const ONE_MONTH_MS = 30 * ONE_DAY_MS;
const THREE_MONTH_MS = 90 * ONE_DAY_MS;
function ensureAuth(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "auth_required");
    }
}
async function ensureAdmin(context) {
    ensureAuth(context);
    const uid = context.auth.uid;
    const claims = context.auth?.token;
    if (claims?.admin === true) {
        rateLimiter_1.RateLimits.admin(uid);
        return;
    }
    const allowSnap = await db.doc("adminConfig/admin").get();
    const allowedRaw = allowSnap.data()?.allowedUserIds;
    if (Array.isArray(allowedRaw)) {
        const allowed = allowedRaw
            .map((value) => String(value ?? "").trim())
            .filter((value) => value.length > 0);
        if (allowed.includes(uid)) {
            rateLimiter_1.RateLimits.admin(uid);
            return;
        }
    }
    throw new functions.https.HttpsError("permission-denied", "admin_required");
}
function normalizeNickname(raw) {
    return String(raw ?? "")
        .trim()
        .replace(/^@+/, "")
        .replace(/\s+/g, "")
        .toLowerCase();
}
async function findUserByNickname(nickname) {
    const usersRef = db.collection("users");
    const usernameLowerSnap = await usersRef
        .where("usernameLower", "==", nickname)
        .limit(2)
        .get();
    if (usernameLowerSnap.size > 1) {
        throw new functions.https.HttpsError("failed-precondition", "nickname_not_unique");
    }
    if (usernameLowerSnap.size === 1) {
        return usernameLowerSnap.docs[0];
    }
    const nicknameSnap = await usersRef
        .where("nickname", "==", nickname)
        .limit(2)
        .get();
    if (nicknameSnap.size > 1) {
        throw new functions.https.HttpsError("failed-precondition", "nickname_not_unique");
    }
    if (nicknameSnap.size === 1) {
        return nicknameSnap.docs[0];
    }
    return null;
}
async function findUserById(userId) {
    const trimmed = String(userId || "").trim();
    if (!trimmed)
        return null;
    const doc = await db.collection("users").doc(trimmed).get();
    if (!doc.exists)
        return null;
    return doc;
}
function normalizeBanAction(raw) {
    const action = String(raw ?? "advance").trim().toLowerCase();
    if (action === "advance" || action === "clear") {
        return action;
    }
    throw new functions.https.HttpsError("invalid-argument", "invalid_action");
}
async function writeBanState(userDoc, action, reasonRaw) {
    const nowMs = Date.now();
    const currentStrikes = Number(userDoc.get("moderationStrikeCount") ?? 0) || 0;
    const reason = String(reasonRaw ?? "").trim();
    const currentNickname = normalizeNickname(userDoc.get("usernameLower") ||
        userDoc.get("username") ||
        userDoc.get("nickname"));
    const displayName = String(userDoc.get("displayName") || "").trim();
    const avatarUrl = String(userDoc.get("avatarUrl") || "").trim();
    const rozet = String(userDoc.get("rozet") || "").trim();
    const bannedRef = db
        .collection("adminConfig")
        .doc("admin")
        .collection("bannedUser")
        .doc(userDoc.id);
    if (action === "clear") {
        await userDoc.ref.set({
            isBanned: false,
            moderationLevel: 0,
            moderationRestrictedUntil: 0,
            moderationPermanentBan: false,
            moderationBanReason: "",
            moderationUpdatedAt: nowMs,
            updatedDate: nowMs,
        }, { merge: true });
        await bannedRef.set({
            userId: userDoc.id,
            nickname: currentNickname,
            displayName,
            avatarUrl,
            rozet,
            strikeCount: currentStrikes,
            status: "cleared",
            banLevel: 0,
            restrictedUntil: 0,
            permanent: false,
            reason: "",
            updatedAt: nowMs,
            clearedAt: nowMs,
            canBrowse: true,
            canLike: true,
            canReshare: true,
            canDoAnythingElse: true,
        }, { merge: true });
        return {
            ok: true,
            action,
            userId: userDoc.id,
            nickname: currentNickname,
            strikeCount: currentStrikes,
            banLevel: 0,
            restrictedUntil: 0,
            permanent: false,
            status: "cleared",
            updatedAt: nowMs,
        };
    }
    const nextStrikeCount = currentStrikes >= 3 ? 3 : currentStrikes + 1;
    const banLevel = nextStrikeCount >= 3 ? 3 : nextStrikeCount;
    const permanent = banLevel >= 3;
    const restrictedUntil = banLevel === 1
        ? nowMs + ONE_MONTH_MS
        : banLevel === 2
            ? nowMs + THREE_MONTH_MS
            : 0;
    await userDoc.ref.set({
        isBanned: permanent,
        moderationStrikeCount: nextStrikeCount,
        moderationLevel: banLevel,
        moderationRestrictedUntil: restrictedUntil,
        moderationPermanentBan: permanent,
        moderationBanReason: reason,
        moderationUpdatedAt: nowMs,
        updatedDate: nowMs,
    }, { merge: true });
    await bannedRef.set({
        userId: userDoc.id,
        nickname: currentNickname,
        displayName,
        avatarUrl,
        rozet,
        strikeCount: nextStrikeCount,
        status: permanent ? "permanent" : "active",
        banLevel,
        restrictedUntil,
        permanent,
        reason,
        updatedAt: nowMs,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        canBrowse: true,
        canLike: true,
        canReshare: true,
        canDoAnythingElse: false,
    }, { merge: true });
    return {
        ok: true,
        action,
        userId: userDoc.id,
        nickname: currentNickname,
        strikeCount: nextStrikeCount,
        banLevel,
        restrictedUntil,
        permanent,
        status: permanent ? "permanent" : "active",
        updatedAt: nowMs,
    };
}
exports.setUserBanByNickname = functions
    .region("europe-west3")
    .https
    .onCall(async (data, context) => {
    await ensureAdmin(context);
    const nickname = normalizeNickname(data?.nickname);
    if (!nickname) {
        throw new functions.https.HttpsError("invalid-argument", "nickname_required");
    }
    const action = normalizeBanAction(data?.action);
    const userDoc = await findUserByNickname(nickname);
    if (!userDoc) {
        throw new functions.https.HttpsError("not-found", "user_not_found");
    }
    return writeBanState(userDoc, action, data?.reason);
});
exports.setUserBanByUserId = functions
    .region("europe-west3")
    .https
    .onCall(async (data, context) => {
    await ensureAdmin(context);
    const userId = String(data?.userId ?? "").trim();
    if (!userId) {
        throw new functions.https.HttpsError("invalid-argument", "user_id_required");
    }
    const action = normalizeBanAction(data?.action);
    const userDoc = await findUserById(userId);
    if (!userDoc) {
        throw new functions.https.HttpsError("not-found", "user_not_found");
    }
    return writeBanState(userDoc, action, data?.reason);
});
//# sourceMappingURL=26_userBanAdmin.js.map