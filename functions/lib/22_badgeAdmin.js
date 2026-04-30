"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processBadgeRenewals = exports.setUserBadgeByUserId = exports.setUserBadgeByNickname = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const adminAccess_1 = require("./adminAccess");
const notificationInbox_1 = require("./notificationInbox");
const userSchemaUtils_1 = require("./userSchemaUtils");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
const RENEWAL_CUTOFF_MS = Date.UTC(2026, 3, 1, 0, 0, 0, 0);
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const ONE_MONTH_MS = 30 * ONE_DAY_MS;
const ONE_YEAR_MS = 365 * ONE_DAY_MS;
function verifiedCollection() {
    return (0, adminAccess_1.verifiedAdminCollection)(db);
}
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
function badgeNeedsAnnualRenewal(rozet, nowMs) {
    if (!rozet)
        return false;
    if (nowMs < RENEWAL_CUTOFF_MS)
        return false;
    return rozet !== "Turkuaz" && rozet !== "Gri";
}
async function createRenewalNotification(uid, rozet, expiresAt) {
    await (0, notificationInbox_1.addInboxItem)(db, uid, {
        type: "System",
        fromUserID: "",
        postID: "",
        timeStamp: Date.now(),
        read: false,
        title: "Rozet yenileme zamanı",
        body: `${rozet} rozetiniz 1 ay içinde sona erecek. Yeniden başvuru ekranı açıldı.`,
        badgeExpiresAt: expiresAt,
    });
}
function ensureAuth(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "auth_required");
    }
}
async function ensureAdmin(context) {
    ensureAuth(context);
    await (0, adminAccess_1.requireCallableAdminUid)(context.auth, db);
}
function normalizeNickname(raw) {
    return String(raw ?? "")
        .trim()
        .replace(/^@+/, "")
        .replace(/\s+/g, "")
        .toLowerCase();
}
function normalizeBadge(raw) {
    const key = String(raw ?? "")
        .trim()
        .toLowerCase()
        .replace(/onay\s*rozeti/g, "")
        .replace(/rozeti/g, "")
        .replace(/rozeti/g, "")
        .replace(/rozet/g, "")
        .replace(/\s+/g, " ")
        .trim();
    if (key === "rozetsiz")
        return "";
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
async function ensureNicknameAvailableForUser(userId, nicknameRaw) {
    const normalized = (0, userSchemaUtils_1.normalizeUsernameLower)(nicknameRaw);
    if (!normalized)
        return "";
    const usersRef = db.collection("users");
    const usernameLowerSnap = await usersRef
        .where("usernameLower", "==", normalized)
        .limit(2)
        .get();
    for (const doc of usernameLowerSnap.docs) {
        if (doc.id !== userId) {
            throw new functions.https.HttpsError("already-exists", "nickname_already_taken");
        }
    }
    const nicknameSnap = await usersRef
        .where("nickname", "==", normalized)
        .limit(2)
        .get();
    for (const doc of nicknameSnap.docs) {
        if (doc.id !== userId) {
            throw new functions.https.HttpsError("already-exists", "nickname_already_taken");
        }
    }
    return normalized;
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
async function applyBadgeToUserDoc(userDoc, rozet, requestedNicknameRaw) {
    const nowMs = Date.now();
    const requiresRenewal = badgeNeedsAnnualRenewal(rozet, nowMs);
    const badgeExpiresAt = requiresRenewal ? nowMs + ONE_YEAR_MS : 0;
    const renewalOpensAt = requiresRenewal ? badgeExpiresAt - ONE_MONTH_MS : 0;
    const currentNickname = normalizeNickname(userDoc.get("usernameLower") || userDoc.get("username") || userDoc.get("nickname"));
    const requestedNickname = normalizeNickname(requestedNicknameRaw);
    const userPatch = {
        rozet,
        "profile.rozet": rozet,
        updatedDate: nowMs,
    };
    if (requiresRenewal) {
        userPatch.rozetGrantedAt = nowMs;
        userPatch.rozetExpiresAt = badgeExpiresAt;
        userPatch.rozetRenewalOpensAt = renewalOpensAt;
        userPatch.rozetRenewalWarnedAt = admin.firestore.FieldValue.delete();
        userPatch.rozetExpiredAt = admin.firestore.FieldValue.delete();
    }
    else {
        userPatch.rozetGrantedAt = admin.firestore.FieldValue.delete();
        userPatch.rozetExpiresAt = admin.firestore.FieldValue.delete();
        userPatch.rozetRenewalOpensAt = admin.firestore.FieldValue.delete();
        userPatch.rozetRenewalWarnedAt = admin.firestore.FieldValue.delete();
        userPatch.rozetExpiredAt = admin.firestore.FieldValue.delete();
    }
    await userDoc.ref.update(userPatch);
    await verifiedCollection().doc(userDoc.id).set({
        userID: userDoc.id,
        selected: rozet,
        status: "approved",
        reviewedAt: nowMs,
        approvedNickname: currentNickname,
        requestedNickname,
        badgeGrantedAt: nowMs,
        badgeExpiresAt,
        renewalOpensAt,
    }, { merge: true });
    return {
        ok: true,
        userId: userDoc.id,
        nickname: currentNickname,
        rozet,
        approvedNickname: currentNickname,
        requestedNickname,
        badgeExpiresAt,
        renewalOpensAt,
        updatedAt: nowMs,
    };
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
    return applyBadgeToUserDoc(userDoc, rozet);
});
exports.setUserBadgeByUserId = functions
    .region("europe-west3")
    .https
    .onCall(async (data, context) => {
    await ensureAdmin(context);
    const userId = String(data?.userId ?? "").trim();
    if (!userId) {
        throw new functions.https.HttpsError("invalid-argument", "user_id_required");
    }
    const rozet = normalizeBadge(data?.rozet);
    if (rozet === null) {
        throw new functions.https.HttpsError("invalid-argument", "invalid_badge");
    }
    const userDoc = await findUserById(userId);
    if (!userDoc) {
        throw new functions.https.HttpsError("not-found", "user_not_found");
    }
    return applyBadgeToUserDoc(userDoc, rozet, data?.requestedNickname);
});
exports.processBadgeRenewals = functions
    .region("europe-west3")
    .pubsub
    .schedule("every 24 hours")
    .timeZone("Europe/Istanbul")
    .onRun(async () => {
    let lastDoc = null;
    while (true) {
        let query = db
            .collection("users")
            .where("rozetExpiresAt", ">", 0)
            .orderBy("rozetExpiresAt")
            .limit(300);
        if (lastDoc != null) {
            query = query.startAfter(lastDoc);
        }
        const snap = await query.get();
        if (snap.empty)
            break;
        for (const doc of snap.docs) {
            const data = doc.data() || {};
            const rozet = String(data.rozet || "").trim();
            const expiresAt = Number(data.rozetExpiresAt || 0);
            const renewalOpensAt = Number(data.rozetRenewalOpensAt || 0);
            const warnedAt = Number(data.rozetRenewalWarnedAt || 0);
            const nowMs = Date.now();
            if (!badgeNeedsAnnualRenewal(rozet, expiresAt - ONE_YEAR_MS)) {
                continue;
            }
            if (expiresAt > 0 && nowMs >= expiresAt) {
                await doc.ref.set({
                    rozet: "",
                    "profile.rozet": "",
                    updatedDate: nowMs,
                    rozetExpiredAt: nowMs,
                }, { merge: true });
                await verifiedCollection().doc(doc.id).set({
                    userID: doc.id,
                    status: "expired",
                    expiredAt: nowMs,
                }, { merge: true });
                continue;
            }
            if (renewalOpensAt > 0 && nowMs >= renewalOpensAt && warnedAt <= 0) {
                await createRenewalNotification(doc.id, rozet, expiresAt);
                await doc.ref.set({
                    rozetRenewalWarnedAt: nowMs,
                    updatedDate: nowMs,
                }, { merge: true });
                await verifiedCollection().doc(doc.id).set({
                    userID: doc.id,
                    status: "renewal_open",
                    renewalOpenedAt: nowMs,
                    badgeExpiresAt: expiresAt,
                    renewalOpensAt,
                }, { merge: true });
            }
        }
        lastDoc = snap.docs[snap.docs.length - 1] ?? null;
        if (snap.docs.length < 300)
            break;
    }
    return null;
});
//# sourceMappingURL=22_badgeAdmin.js.map