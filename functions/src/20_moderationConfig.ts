import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { requireCallableAdminUid } from "./adminAccess";

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

function ensureAuth(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "auth_required");
  }
}

async function ensureAdmin(context: functions.https.CallableContext) {
  ensureAuth(context);
  await requireCallableAdminUid(context.auth, db);
}

export const ensureModerationConfig = functions
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
