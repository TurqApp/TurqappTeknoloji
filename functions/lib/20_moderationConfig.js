"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureModerationConfig = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const adminAccess_1 = require("./adminAccess");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
const DEFAULT_MODERATION_CONFIG = {
    enabled: true,
    blackBadgeFlagThreshold: 5,
    allowSingleFlagPerUser: true,
    enableShadowHide: true,
    notifyOwnerOnAdminRemove: true,
    notifyFlaggersOnAdminRemove: true,
    resetFlagsOnRestore: true,
};
function ensureAuth(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "auth_required");
    }
}
async function ensureAdmin(context) {
    ensureAuth(context);
    await (0, adminAccess_1.requireCallableAdminUid)(context.auth, db);
}
exports.ensureModerationConfig = functions
    .region("europe-west3")
    .https
    .onCall(async (_data, context) => {
    await ensureAdmin(context);
    const ref = db.doc("adminConfig/moderation");
    await ref.set(DEFAULT_MODERATION_CONFIG, { merge: true });
    const snap = await ref.get();
    const data = snap.data() ?? DEFAULT_MODERATION_CONFIG;
    return {
        ok: true,
        config: data,
    };
});
//# sourceMappingURL=20_moderationConfig.js.map