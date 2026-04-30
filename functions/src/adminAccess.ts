import { getApps, initializeApp } from "firebase-admin/app";
import { Firestore, getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { RateLimits } from "./rateLimiter";

type CallableAuthLike =
  | {
      uid?: string | null;
      token?: unknown;
    }
  | null
  | undefined;

export function ensureAdminApp() {
  if (getApps().length === 0) {
    initializeApp();
  }
}

export function adminDb(): Firestore {
  ensureAdminApp();
  return getFirestore();
}

export function adminConfigRef(db: Firestore = adminDb()) {
  return db.collection("adminConfig").doc("admin");
}

export function verifiedAdminCollection(db: Firestore = adminDb()) {
  return adminConfigRef(db).collection("TurqAppVerified");
}

export function bannedAdminCollection(db: Firestore = adminDb()) {
  return adminConfigRef(db).collection("bannedUser");
}

export function requireCallableAuthUid(auth: CallableAuthLike): string {
  const uid = String(auth?.uid ?? "").trim();
  if (!uid) {
    throw new HttpsError("unauthenticated", "auth_required");
  }
  return uid;
}

export async function isUidInAdminAllowList(
  uid: string,
  db: Firestore = adminDb(),
): Promise<boolean> {
  const normalizedUid = String(uid ?? "").trim();
  if (!normalizedUid) return false;
  const allowSnap = await adminConfigRef(db).get();
  const allowedRaw = allowSnap.data()?.allowedUserIds;
  if (!Array.isArray(allowedRaw)) return false;
  return allowedRaw
    .map((value: unknown) => String(value ?? "").trim())
    .filter((value: string) => value.length > 0)
    .includes(normalizedUid);
}

export async function requireCallableAdminUid(
  auth: CallableAuthLike,
  db: Firestore = adminDb(),
): Promise<string> {
  const uid = requireCallableAuthUid(auth);
  const token = (auth?.token ?? null) as { admin?: unknown } | null;
  if (token?.admin === true) {
    RateLimits.admin(uid);
    return uid;
  }

  if (await isUidInAdminAllowList(uid, db)) {
    RateLimits.admin(uid);
    return uid;
  }
  throw new HttpsError("permission-denied", "admin_required");
}
