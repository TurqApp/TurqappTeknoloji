import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { RateLimits } from "./rateLimiter";

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
  const uid = context.auth!.uid;
  const claims = context.auth?.token as { admin?: unknown } | undefined;
  if (claims?.admin === true) {
    RateLimits.admin(uid);
    return;
  }

  const allowSnap = await db.doc("adminConfig/admin").get();
  const allowedRaw = allowSnap.data()?.allowedUserIds;
  if (Array.isArray(allowedRaw)) {
    const allowed = allowedRaw
      .map((v: unknown) => String(v ?? "").trim())
      .filter((v: string) => v.length > 0);
    if (allowed.includes(uid)) {
      RateLimits.admin(uid);
      return;
    }
  }

  throw new functions.https.HttpsError("permission-denied", "admin_required");
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
