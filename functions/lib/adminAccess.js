"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureAdminApp = ensureAdminApp;
exports.adminDb = adminDb;
exports.adminConfigRef = adminConfigRef;
exports.verifiedAdminCollection = verifiedAdminCollection;
exports.bannedAdminCollection = bannedAdminCollection;
exports.requireCallableAuthUid = requireCallableAuthUid;
exports.isUidInAdminAllowList = isUidInAdminAllowList;
exports.requireCallableAdminUid = requireCallableAdminUid;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const rateLimiter_1 = require("./rateLimiter");
function ensureAdminApp() {
    if ((0, app_1.getApps)().length === 0) {
        (0, app_1.initializeApp)();
    }
}
function adminDb() {
    ensureAdminApp();
    return (0, firestore_1.getFirestore)();
}
function adminConfigRef(db = adminDb()) {
    return db.collection("adminConfig").doc("admin");
}
function verifiedAdminCollection(db = adminDb()) {
    return adminConfigRef(db).collection("TurqAppVerified");
}
function bannedAdminCollection(db = adminDb()) {
    return adminConfigRef(db).collection("bannedUser");
}
function requireCallableAuthUid(auth) {
    const uid = String(auth?.uid ?? "").trim();
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    return uid;
}
async function isUidInAdminAllowList(uid, db = adminDb()) {
    const normalizedUid = String(uid ?? "").trim();
    if (!normalizedUid)
        return false;
    const allowSnap = await adminConfigRef(db).get();
    const allowedRaw = allowSnap.data()?.allowedUserIds;
    if (!Array.isArray(allowedRaw))
        return false;
    return allowedRaw
        .map((value) => String(value ?? "").trim())
        .filter((value) => value.length > 0)
        .includes(normalizedUid);
}
async function requireCallableAdminUid(auth, db = adminDb()) {
    const uid = requireCallableAuthUid(auth);
    const token = (auth?.token ?? null);
    if (token?.admin === true) {
        rateLimiter_1.RateLimits.admin(uid);
        return uid;
    }
    if (await isUidInAdminAllowList(uid, db)) {
        rateLimiter_1.RateLimits.admin(uid);
        return uid;
    }
    throw new https_1.HttpsError("permission-denied", "admin_required");
}
//# sourceMappingURL=adminAccess.js.map