import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  bannedAdminCollection,
  requireCallableAdminUid,
} from "./adminAccess";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const ONE_MONTH_MS = 30 * ONE_DAY_MS;
const THREE_MONTH_MS = 90 * ONE_DAY_MS;

type BanAction = "advance" | "clear";

function ensureAuth(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "auth_required");
  }
}

async function ensureAdmin(context: functions.https.CallableContext) {
  ensureAuth(context);
  await requireCallableAdminUid(context.auth, db);
}

function normalizeNickname(raw: unknown): string {
  return String(raw ?? "")
    .trim()
    .replace(/^@+/, "")
    .replace(/\s+/g, "")
    .toLowerCase();
}

async function findUserByNickname(nickname: string) {
  const usersRef = db.collection("users");

  const usernameLowerSnap = await usersRef
    .where("usernameLower", "==", nickname)
    .limit(2)
    .get();
  if (usernameLowerSnap.size > 1) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "nickname_not_unique",
    );
  }
  if (usernameLowerSnap.size === 1) {
    return usernameLowerSnap.docs[0];
  }

  const nicknameSnap = await usersRef
    .where("nickname", "==", nickname)
    .limit(2)
    .get();
  if (nicknameSnap.size > 1) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "nickname_not_unique",
    );
  }
  if (nicknameSnap.size === 1) {
    return nicknameSnap.docs[0];
  }

  return null;
}

async function findUserById(userId: string) {
  const trimmed = String(userId || "").trim();
  if (!trimmed) return null;
  const doc = await db.collection("users").doc(trimmed).get();
  if (!doc.exists) return null;
  return doc;
}

function normalizeBanAction(raw: unknown): BanAction {
  const action = String(raw ?? "advance").trim().toLowerCase();
  if (action === "advance" || action === "clear") {
    return action;
  }
  throw new functions.https.HttpsError("invalid-argument", "invalid_action");
}

async function writeBanState(
  userDoc: FirebaseFirestore.DocumentSnapshot,
  action: BanAction,
  reasonRaw?: unknown,
) {
  const nowMs = Date.now();
  const currentStrikes =
    Number(userDoc.get("moderationStrikeCount") ?? 0) || 0;
  const reason = String(reasonRaw ?? "").trim();
  const currentNickname = normalizeNickname(
    userDoc.get("usernameLower") ||
      userDoc.get("username") ||
      userDoc.get("nickname"),
  );
  const displayName = String(userDoc.get("displayName") || "").trim();
  const avatarUrl = String(userDoc.get("avatarUrl") || "").trim();
  const rozet = String(userDoc.get("rozet") || "").trim();
  const bannedRef = bannedAdminCollection(db).doc(userDoc.id);

  if (action === "clear") {
    await userDoc.ref.set(
      {
        isBanned: false,
        moderationLevel: 0,
        moderationRestrictedUntil: 0,
        moderationPermanentBan: false,
        moderationBanReason: "",
        moderationUpdatedAt: nowMs,
        updatedDate: nowMs,
      },
      { merge: true },
    );
    await bannedRef.set(
      {
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
      },
      { merge: true },
    );
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
  const restrictedUntil =
    banLevel === 1
      ? nowMs + ONE_MONTH_MS
      : banLevel === 2
        ? nowMs + THREE_MONTH_MS
        : 0;

  await userDoc.ref.set(
    {
      isBanned: permanent,
      moderationStrikeCount: nextStrikeCount,
      moderationLevel: banLevel,
      moderationRestrictedUntil: restrictedUntil,
      moderationPermanentBan: permanent,
      moderationBanReason: reason,
      moderationUpdatedAt: nowMs,
      updatedDate: nowMs,
    },
    { merge: true },
  );

  await bannedRef.set(
    {
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
    },
    { merge: true },
  );

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

export const setUserBanByNickname = functions
  .region("europe-west3")
  .https
  .onCall(async (data, context) => {
    await ensureAdmin(context);

    const nickname = normalizeNickname(data?.nickname);
    if (!nickname) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "nickname_required",
      );
    }

    const action = normalizeBanAction(data?.action);
    const userDoc = await findUserByNickname(nickname);
    if (!userDoc) {
      throw new functions.https.HttpsError("not-found", "user_not_found");
    }

    return writeBanState(userDoc, action, data?.reason);
  });

export const setUserBanByUserId = functions
  .region("europe-west3")
  .https
  .onCall(async (data, context) => {
    await ensureAdmin(context);

    const userId = String(data?.userId ?? "").trim();
    if (!userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "user_id_required",
      );
    }

    const action = normalizeBanAction(data?.action);
    const userDoc = await findUserById(userId);
    if (!userDoc) {
      throw new functions.https.HttpsError("not-found", "user_not_found");
    }

    return writeBanState(userDoc, action, data?.reason);
  });
