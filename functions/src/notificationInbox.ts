import * as admin from "firebase-admin";

type InboxPayload = Record<string, unknown>;

function notificationsRef(
  db: FirebaseFirestore.Firestore,
  uid: string,
) {
  return db.collection("users").doc(uid.trim()).collection("notifications");
}

export function buildInboxPayload(uid: string, payload: InboxPayload) {
  const now = Date.now();
  return {
    userID: uid.trim(),
    timeStamp: payload.timeStamp ?? now,
    read: payload.read ?? false,
    isRead: payload.isRead ?? payload.read ?? false,
    ...payload,
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
