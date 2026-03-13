import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { RateLimits } from "./rateLimiter";

const db = admin.firestore();

const BADGE_MAP = new Map<string, string>([
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
      .map((value: unknown) => String(value ?? "").trim())
      .filter((value: string) => value.length > 0);
    if (allowed.includes(uid)) {
      RateLimits.admin(uid);
      return;
    }
  }

  throw new functions.https.HttpsError("permission-denied", "admin_required");
}

function normalizeNickname(raw: unknown): string {
  return String(raw ?? "")
    .trim()
    .replace(/^@+/, "")
    .replace(/\s+/g, "")
    .toLowerCase();
}

function normalizeBadge(raw: unknown): string | null {
  const key = String(raw ?? "").trim().toLowerCase();
  return BADGE_MAP.get(key) ?? null;
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

export const setUserBadgeByNickname = functions
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

    const rozet = normalizeBadge(data?.rozet);
    if (rozet === null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid_badge",
      );
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
