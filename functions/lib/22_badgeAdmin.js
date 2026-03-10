"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setUserBadgeByNickname = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
const BADGE_MAP = new Map([
    ["", ""],
    ["gri", "Gri"],
    ["turkuaz", "Turkuaz"],
    ["sari", "Sarı"],
    ["sarı", "Sarı"],
    ["mavi", "Mavi"],
    ["siyah", "Siyah"],
    ["kirmizi", "Kırmızı"],
    ["kırmızı", "Kırmızı"],
]);
function ensureAuth(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "auth_required");
    }
}
async function ensureAdmin(context) {
    ensureAuth(context);
    const uid = context.auth.uid;
    const claims = context.auth?.token;
    if (claims?.admin === true)
        return;
    const allowSnap = await db.doc("adminConfig/admin").get();
    const allowedRaw = allowSnap.data()?.allowedUserIds;
    if (Array.isArray(allowedRaw)) {
        const allowed = allowedRaw
            .map((value) => String(value ?? "").trim())
            .filter((value) => value.length > 0);
        if (allowed.includes(uid))
            return;
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
function normalizeBadge(raw) {
    const key = String(raw ?? "").trim().toLowerCase();
    return BADGE_MAP.get(key) ?? null;
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
exports.setUserBadgeByNickname = functions
    .region("europe-west3")
    .https
    .onCall(async (data, context) => {
    await ensureAdmin(context);
    const nickname = normalizeNickname(data?.nickname);
    if (!nickname) {
        throw new functions.https.HttpsError("invalid-argument", "nickname_required");
    }
    const rozet = normalizeBadge(data?.rozet);
    if (rozet === null) {
        throw new functions.https.HttpsError("invalid-argument", "invalid_badge");
    }
    const userDoc = await findUserByNickname(nickname);
    if (!userDoc) {
        throw new functions.https.HttpsError("not-found", "user_not_found");
    }
    const nowMs = Date.now();
    await userDoc.ref.update({
        rozet,
        "profile.rozet": rozet,
        updatedDate: nowMs,
    });
    return {
        ok: true,
        userId: userDoc.id,
        nickname,
        rozet,
        updatedAt: nowMs,
    };
});
//# sourceMappingURL=22_badgeAdmin.js.map