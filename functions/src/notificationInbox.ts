import * as admin from "firebase-admin";

type InboxPayload = Record<string, unknown>;

function asTrimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function firstNonEmptyString(...values: unknown[]): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
    if (Array.isArray(value)) {
      for (const entry of value) {
        if (typeof entry === "string" && entry.trim().length > 0) {
          return entry.trim();
        }
      }
    }
  }
  return "";
}

function resolveInboxImageUrl(payload: InboxPayload): string {
  return firstNonEmptyString(
    payload.imageUrl,
    payload.thumbnail,
    payload.imageURL,
    payload.avatarUrl,
    payload.applicantPfImage,
    payload.tutorImage,
    payload.companyLogo,
    payload.logo,
    payload.coverImageUrl,
    payload.img,
    payload.images,
  );
}

function notificationsRef(
  db: FirebaseFirestore.Firestore,
  uid: string,
) {
  return db.collection("users").doc(uid.trim()).collection("notifications");
}

export function buildInboxPayload(uid: string, payload: InboxPayload) {
  const now = Date.now();
  const imageUrl = resolveInboxImageUrl(payload);
  const thumbnail = firstNonEmptyString(payload.thumbnail, imageUrl);
  return {
    userID: uid.trim(),
    timeStamp: payload.timeStamp ?? now,
    read: payload.read ?? false,
    isRead: payload.isRead ?? payload.read ?? false,
    ...payload,
    ...(imageUrl ? { imageUrl } : {}),
    ...(thumbnail ? { thumbnail } : {}),
  };
}

export async function addInboxItem(
  db: FirebaseFirestore.Firestore,
  uid: string,
  payload: InboxPayload,
) {
  if (!uid.trim()) return;
  await notificationsRef(db, uid).add(buildInboxPayload(uid, payload));
}

export async function setInboxItem(
  db: FirebaseFirestore.Firestore,
  uid: string,
  docId: string,
  payload: InboxPayload,
) {
  if (!uid.trim() || !docId.trim()) return;
  await notificationsRef(db, uid)
    .doc(docId.trim())
    .set(buildInboxPayload(uid, payload), { merge: true });
}
