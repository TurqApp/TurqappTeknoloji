import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { normalizeUsernameLower } from "./userSchemaUtils";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const GRACE_WINDOW_MS = 60 * 60 * 1000;
const CHANGE_COOLDOWN_MS = 15 * 24 * 60 * 60 * 1000;

function parseMillis(raw: unknown): number | null {
  if (typeof raw === "number" && Number.isFinite(raw) && raw > 0) {
    return Math.trunc(raw);
  }
  if (typeof raw === "string") {
    const parsed = Number(raw);
    if (Number.isFinite(parsed) && parsed > 0) {
      return Math.trunc(parsed);
    }
  }
  if (raw instanceof admin.firestore.Timestamp) {
    return raw.toMillis();
  }
  return null;
}

function extractCreatedAt(data: FirebaseFirestore.DocumentData | undefined): number | null {
  if (!data) return null;
  return parseMillis(data.createdDate) ?? parseMillis(data.timeStamp);
}

function extractLastChangeAt(data: FirebaseFirestore.DocumentData | undefined): number | null {
  if (!data) return null;
  return parseMillis(data.nicknameChangedAt) ?? parseMillis(data.nicknameLastChangedAt);
}

function extractGraceCount(data: FirebaseFirestore.DocumentData | undefined): number {
  const raw = data?.nicknameGraceChangeCount;
  if (typeof raw === "number" && Number.isFinite(raw)) {
    return Math.max(0, Math.trunc(raw));
  }
  return 0;
}

function extractGraceWindowStartAt(
  data: FirebaseFirestore.DocumentData | undefined
): number | null {
  if (!data) return null;
  return parseMillis(data.nicknameGraceWindowStartAt);
}

function historyEntry(fromNickname: string, toNickname: string, changedAt: number) {
  return {
    nickname: fromNickname,
    changedAt,
    to: toNickname,
  };
}

export const changeOwnNickname = functions
  .region("europe-west3")
  .https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError("unauthenticated", "auth_required");
    }

    const uid = context.auth.uid;
    const normalized = normalizeUsernameLower(data?.nickname);
    if (!normalized) {
      throw new functions.https.HttpsError("invalid-argument", "nickname_required");
    }
    if (normalized.length < 8) {
      throw new functions.https.HttpsError("invalid-argument", "nickname_too_short");
    }

    const userRef = db.collection("users").doc(uid);
    const nowMs = Date.now();

    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new functions.https.HttpsError("not-found", "user_not_found");
      }

      const userData = userSnap.data() ?? {};
      const currentNickname = normalizeUsernameLower(
        userData.usernameLower || userData.username || userData.nickname
      );

      if (currentNickname === normalized) {
        return {
          ok: true,
          unchanged: true,
          nickname: currentNickname,
        };
      }

      const lastChangeMs = extractLastChangeAt(userData);
      const createdAtMs = extractCreatedAt(userData);
      const graceStartMs = extractGraceWindowStartAt(userData);
      const graceCount = extractGraceCount(userData);

      if (lastChangeMs != null) {
        const elapsed = nowMs - lastChangeMs;
        if (elapsed <= GRACE_WINDOW_MS && graceCount >= 3) {
          throw new functions.https.HttpsError("failed-precondition", "grace_limit");
        }
        if (elapsed > GRACE_WINDOW_MS && elapsed < CHANGE_COOLDOWN_MS) {
          throw new functions.https.HttpsError("failed-precondition", "cooldown");
        }
      } else if (createdAtMs != null) {
        const sinceCreated = nowMs - createdAtMs;
        if (sinceCreated > GRACE_WINDOW_MS && sinceCreated < CHANGE_COOLDOWN_MS) {
          throw new functions.https.HttpsError("failed-precondition", "cooldown");
        }
      }

      const usernameQuery = db
        .collection("users")
        .where("usernameLower", "==", normalized)
        .limit(2);
      const usernameSnap = await tx.get(usernameQuery);
      for (const doc of usernameSnap.docs) {
        if (doc.id !== uid) {
          throw new functions.https.HttpsError("already-exists", "nickname_already_taken");
        }
      }

      const nicknameQuery = db
        .collection("users")
        .where("nickname", "==", normalized)
        .limit(2);
      const nicknameSnap = await tx.get(nicknameQuery);
      for (const doc of nicknameSnap.docs) {
        if (doc.id !== uid) {
          throw new functions.https.HttpsError("already-exists", "nickname_already_taken");
        }
      }

      const usernamesRef = db.collection("usernames");
      const desiredHandleRef = usernamesRef.doc(normalized);
      const desiredHandleSnap = await tx.get(desiredHandleRef);
      const desiredUid = String(desiredHandleSnap.data()?.uid ?? "").trim();
      if (desiredHandleSnap.exists && desiredUid && desiredUid !== uid) {
        throw new functions.https.HttpsError("already-exists", "nickname_already_taken");
      }

      const patch: Record<string, unknown> = {
        nickname: normalized,
        username: normalized,
        usernameLower: normalized,
        nicknameChangedAt: nowMs,
        updatedDate: nowMs,
      };

      if (currentNickname && currentNickname !== normalized) {
        patch.oldNicknames = admin.firestore.FieldValue.arrayUnion(currentNickname);
        patch.nicknameHistory = admin.firestore.FieldValue.arrayUnion(
          historyEntry(currentNickname, normalized, nowMs)
        );
      }

      const inGrace = lastChangeMs != null && (nowMs - lastChangeMs) <= GRACE_WINDOW_MS;
      if (inGrace) {
        const windowStart = graceStartMs ?? lastChangeMs;
        const currentCount = graceCount <= 0 ? 1 : graceCount;
        patch.nicknameGraceWindowStartAt = windowStart;
        patch.nicknameGraceChangeCount = currentCount + 1;
      } else {
        patch.nicknameGraceWindowStartAt = nowMs;
        patch.nicknameGraceChangeCount = 1;
      }

      tx.update(userRef, patch);
      tx.set(
        desiredHandleRef,
        {
          uid,
          usernameLower: normalized,
          updatedAt: nowMs,
        },
        { merge: true }
      );

      if (currentNickname && currentNickname !== normalized) {
        const oldHandleRef = usernamesRef.doc(currentNickname);
        const oldHandleSnap = await tx.get(oldHandleRef);
        const oldUid = String(oldHandleSnap.data()?.uid ?? "").trim();
        if (oldUid == uid) {
          tx.delete(oldHandleRef);
        }
      }

      return {
        ok: true,
        nickname: normalized,
        changedAt: nowMs,
      };
    });

    return result;
  });
