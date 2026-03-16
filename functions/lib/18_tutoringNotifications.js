"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onTutoringApplicationUpdate = exports.onTutoringApplicationCreate = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
/**
 * Yeni başvuru oluşturulduğunda öğretmene bildirim gönder.
 * Tetikleme: educators/{docId}/Applications/{applicantId} onCreate
 */
exports.onTutoringApplicationCreate = functions.firestore
    .document("educators/{docId}/Applications/{applicantId}")
    .onCreate(async (snap, context) => {
    try {
        const { docId, applicantId } = context.params;
        const data = snap.data() || {};
        const tutoringTitle = String(data.tutoringTitle || "Özel Ders İlanı");
        // Öğretmenin userID'sini bul
        const tutoringDoc = await db.collection("educators").doc(docId).get();
        if (!tutoringDoc.exists)
            return;
        const tutorUID = String(tutoringDoc.data()?.userID || "");
        if (!tutorUID || tutorUID === applicantId)
            return;
        // Başvuranın adını bul
        const applicantDoc = await db.collection("users").doc(applicantId).get();
        const applicantData = applicantDoc.data() || {};
        const applicantName = String(applicantData.displayName ||
            applicantData.username ||
            applicantData.nickname ||
            "Bir kullanıcı");
        // Öğretmene bildirim oluştur
        await db
            .collection("users")
            .doc(tutorUID)
            .collection("notifications")
            .add({
            type: "tutoring_application",
            fromUserID: applicantId,
            title: "Yeni Başvuru",
            body: `${applicantName} "${tutoringTitle}" ilanınıza başvurdu.`,
            postID: docId,
            timeStamp: Date.now(),
            read: false,
        });
        console.log("[TutoringNotif] Application notification sent");
    }
    catch (e) {
        console.error("[TutoringNotif] onCreate error:", e);
    }
});
/**
 * Başvuru durumu güncellendiğinde başvurana bildirim gönder.
 * Tetikleme: educators/{docId}/Applications/{applicantId} onUpdate
 */
exports.onTutoringApplicationUpdate = functions.firestore
    .document("educators/{docId}/Applications/{applicantId}")
    .onUpdate(async (change, context) => {
    try {
        const { docId, applicantId } = context.params;
        const before = change.before.data() || {};
        const after = change.after.data() || {};
        // Sadece status değişikliğinde tetikle
        if (before.status === after.status)
            return;
        const newStatus = String(after.status || "");
        const tutoringTitle = String(after.tutoringTitle || "Özel Ders İlanı");
        const statusMessages = {
            reviewing: "İnceleniyor",
            accepted: "Kabul Edildi",
            rejected: "Reddedildi",
        };
        const statusText = statusMessages[newStatus];
        if (!statusText)
            return;
        // Başvurana bildirim oluştur
        await db
            .collection("users")
            .doc(applicantId)
            .collection("notifications")
            .add({
            type: "tutoring_status",
            fromUserID: "",
            title: "Başvuru Durumu Güncellendi",
            body: `"${tutoringTitle}" başvurunuz: ${statusText}`,
            postID: docId,
            timeStamp: Date.now(),
            read: false,
        });
        console.log("[TutoringNotif] Status update notification sent");
    }
    catch (e) {
        console.error("[TutoringNotif] onUpdate error:", e);
    }
});
//# sourceMappingURL=18_tutoringNotifications.js.map