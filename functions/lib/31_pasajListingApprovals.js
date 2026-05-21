"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reviewPasajListing = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const adminAccess_1 = require("./adminAccess");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
function normalizeListingType(raw) {
    const value = String(raw ?? "").trim().toLowerCase();
    if (value === "market" || value === "job" || value === "tutoring") {
        return value;
    }
    throw new functions.https.HttpsError("invalid-argument", "invalid_listing_type");
}
function normalizeListingAction(raw) {
    const value = String(raw ?? "approve").trim().toLowerCase();
    if (value === "approve" || value === "reject")
        return value;
    throw new functions.https.HttpsError("invalid-argument", "invalid_action");
}
function docRefForListing(type, docId) {
    switch (type) {
        case "market":
            return db.collection("marketStore").doc(docId);
        case "job":
            return db.collection("isBul").doc(docId);
        case "tutoring":
            return db.collection("educators").doc(docId);
    }
}
function patchForListing(type, action, adminUid) {
    const now = Date.now();
    if (type === "market") {
        return action === "approve"
            ? {
                status: "active",
                publishedAt: now,
                updatedAt: now,
                approvedAt: now,
                approvedBy: adminUid,
            }
            : {
                status: "archived",
                updatedAt: now,
                rejectedAt: now,
                rejectedBy: adminUid,
            };
    }
    return action === "approve"
        ? {
            onayVerildi: true,
            approvalStatus: "approved",
            approvedAt: now,
            approvedBy: adminUid,
        }
        : {
            onayVerildi: false,
            approvalStatus: "rejected",
            ended: true,
            rejectedAt: now,
            rejectedBy: adminUid,
        };
}
exports.reviewPasajListing = functions
    .region("europe-west3")
    .https.onCall(async (data, context) => {
    const adminUid = await (0, adminAccess_1.requireCallableAdminUid)(context.auth, db);
    const type = normalizeListingType(data?.listingType);
    const action = normalizeListingAction(data?.action);
    const docId = String(data?.docId ?? "").trim();
    if (!docId) {
        throw new functions.https.HttpsError("invalid-argument", "missing_doc_id");
    }
    const ref = docRefForListing(type, docId);
    const snap = await ref.get();
    if (!snap.exists) {
        throw new functions.https.HttpsError("not-found", "listing_not_found");
    }
    await ref.set(patchForListing(type, action, adminUid), { merge: true });
    return { ok: true, listingType: type, docId, action };
});
//# sourceMappingURL=31_pasajListingApprovals.js.map