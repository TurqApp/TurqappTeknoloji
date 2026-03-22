"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildInboxPayload = buildInboxPayload;
exports.addInboxItem = addInboxItem;
exports.setInboxItem = setInboxItem;
function notificationsRef(db, uid) {
    return db.collection("users").doc(uid.trim()).collection("notifications");
}
function buildInboxPayload(uid, payload) {
    const now = Date.now();
    return {
        userID: uid.trim(),
        timeStamp: payload.timeStamp ?? now,
        read: payload.read ?? false,
        isRead: payload.isRead ?? payload.read ?? false,
        ...payload,
    };
}
async function addInboxItem(db, uid, payload) {
    if (!uid.trim())
        return;
    await notificationsRef(db, uid).add(buildInboxPayload(uid, payload));
}
async function setInboxItem(db, uid, docId, payload) {
    if (!uid.trim() || !docId.trim())
        return;
    await notificationsRef(db, uid)
        .doc(docId.trim())
        .set(buildInboxPayload(uid, payload), { merge: true });
}
//# sourceMappingURL=notificationInbox.js.map