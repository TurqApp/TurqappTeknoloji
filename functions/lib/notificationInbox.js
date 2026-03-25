"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildInboxPayload = buildInboxPayload;
exports.addInboxItem = addInboxItem;
exports.setInboxItem = setInboxItem;
function asTrimmedString(value) {
    return typeof value === "string" ? value.trim() : "";
}
function firstNonEmptyString(...values) {
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
function resolveInboxImageUrl(payload) {
    return firstNonEmptyString(payload.imageUrl, payload.thumbnail, payload.imageURL, payload.avatarUrl, payload.applicantPfImage, payload.tutorImage, payload.companyLogo, payload.logo, payload.coverImageUrl, payload.img, payload.images);
}
function notificationsRef(db, uid) {
    return db.collection("users").doc(uid.trim()).collection("notifications");
}
function buildInboxPayload(uid, payload) {
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