"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateUserPhoneNumberAfterEmailVerification = exports.markCurrentEmailVerified = exports.updateUserEmail = exports.verifyEmailCode = exports.sendEmailVerificationCode = void 0;
const admin = require("firebase-admin");
const resend_1 = require("resend");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const REGION = "europe-west3";
const RESEND_API_KEY = (0, params_1.defineSecret)("RESEND_API_KEY");
const EMAIL_ACCOUNTS_COLLECTION = "EmailAccounts";
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
const EMAIL_MIN_INTERVAL_MS = 60 * 1000;
const EMAIL_DAILY_LIMIT = 8;
const VERIFY_TTL_MS = 60 * 60 * 1000;
const VERIFY_USE_WINDOW_MS = 60 * 60 * 1000;
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const VALID_PURPOSES = [
    "signup",
    "password_reset",
    "phone_change",
    "email_change",
    "email_confirm",
];
function validEmail(email) {
    return EMAIL_REGEX.test(email);
}
function parsePurpose(raw) {
    const value = String(raw || "signup").trim();
    return VALID_PURPOSES.includes(value) ? value : "signup";
}
function normalizePhone(raw) {
    return String(raw || "").replace(/[^0-9]/g, "");
}
function accountRef(emailLower) {
    return db.collection(EMAIL_ACCOUNTS_COLLECTION).doc(emailLower);
}
function verificationRef(emailLower, purpose) {
    return accountRef(emailLower).collection("verifications").doc(purpose);
}
async function resolveCaller(request) {
    const authUid = String(request.auth?.uid || "").trim();
    const authEmail = String(request.auth?.token?.email || "").toLowerCase().trim();
    if (authUid) {
        return { uid: authUid, email: authEmail };
    }
    const idToken = String(request.data?.idToken || "").trim();
    if (!idToken) {
        throw new https_1.HttpsError("unauthenticated", "Kullanıcı doğrulanmamış");
    }
    try {
        const decoded = await admin.auth().verifyIdToken(idToken);
        return {
            uid: String(decoded.uid || "").trim(),
            email: String(decoded.email || "").toLowerCase().trim(),
        };
    }
    catch {
        throw new https_1.HttpsError("unauthenticated", "Geçersiz oturum tokenı");
    }
}
function buildMailCopy(purpose) {
    if (purpose === "password_reset") {
        return {
            subject: "TurqApp - Şifre Sıfırlama Kodunuz",
            intro: "Şifrenizi sıfırlamak için doğrulama kodunuz:",
        };
    }
    if (purpose === "phone_change") {
        return {
            subject: "TurqApp - Telefon Değişikliği Onay Kodu",
            intro: "Telefon numaranızı değiştirmek için onay kodunuz:",
        };
    }
    if (purpose === "email_change") {
        return {
            subject: "TurqApp - E-posta Değişikliği Onay Kodu",
            intro: "E-posta adresinizi değiştirmek için onay kodunuz:",
        };
    }
    if (purpose === "email_confirm") {
        return {
            subject: "TurqApp - E-posta Onay Kodu",
            intro: "E-posta adresinizi onaylamak için onay kodunuz:",
        };
    }
    return {
        subject: "TurqApp - Email Doğrulama Kodunuz",
        intro: "Email doğrulama kodunuz:",
    };
}
function buildMailHtml(purpose, code) {
    const copy = buildMailCopy(purpose);
    return `
<!DOCTYPE html>
<html lang="tr">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>TurqApp - Email Doğrulama</title></head>
<body style="margin:0;padding:20px;background:#f6f9fc;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
  <div style="max-width:600px;margin:0 auto;background:#fff;border-radius:8px;overflow:hidden;">
    <div style="background:#1f2937;color:#fff;padding:24px;text-align:center;">
      <h1 style="margin:0;font-size:24px;">TurqApp</h1>
    </div>
    <div style="padding:24px;">
      <p>Merhaba,</p>
      <p>${copy.intro}</p>
      <div style="font-size:32px;font-weight:700;letter-spacing:6px;margin:16px 0;">${code}</div>
      <p>Bu kod 1 saat geçerlidir.</p>
    </div>
  </div>
</body>
</html>`;
}
async function ensurePurposeEmailRules(request, purpose, emailLower) {
    const ensureEmailBelongsToCaller = async () => {
        const caller = await resolveCaller(request);
        const authEmail = String(caller.email || "").toLowerCase().trim();
        if (authEmail && authEmail === emailLower) {
            return;
        }
        const userSnap = await db.collection("users").doc(caller.uid).get();
        const profileEmail = String((userSnap.data() || {}).email || "").toLowerCase().trim();
        if (!profileEmail || profileEmail !== emailLower) {
            throw new https_1.HttpsError("permission-denied", "Bu işlem için hesabınızdaki kayıtlı e-posta adresini kullanmalısınız");
        }
    };
    if (purpose === "phone_change") {
        await ensureEmailBelongsToCaller();
        return;
    }
    if (purpose === "email_confirm") {
        await ensureEmailBelongsToCaller();
        return;
    }
    if (purpose === "email_change") {
        await resolveCaller(request);
        try {
            const existing = await admin.auth().getUserByEmail(emailLower);
            if (existing) {
                throw new https_1.HttpsError("already-exists", "Bu e-posta adresi zaten kullanımda");
            }
        }
        catch (error) {
            const code = error?.code || "";
            if (code === "auth/user-not-found") {
                return;
            }
            if (error instanceof https_1.HttpsError) {
                throw error;
            }
            throw new https_1.HttpsError("internal", "E-posta kontrolü sırasında hata oluştu");
        }
        return;
    }
    try {
        const userRecord = await admin.auth().getUserByEmail(emailLower);
        if (purpose === "signup" && userRecord) {
            throw new https_1.HttpsError("already-exists", "Bu e-posta adresi zaten kullanımda");
        }
    }
    catch (error) {
        const code = error?.code || "";
        if (code === "auth/user-not-found") {
            if (purpose === "password_reset") {
                throw new https_1.HttpsError("not-found", "Bu e-posta adresi kayıtlı değil");
            }
            return;
        }
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError("internal", "E-posta kontrolü sırasında hata oluştu");
    }
}
async function sendCodeInternal(request, emailLower, purpose) {
    await ensurePurposeEmailRules(request, purpose, emailLower);
    const now = admin.firestore.Timestamp.now();
    const nowDate = now.toDate();
    const dayKey = nowDate.toISOString().slice(0, 10);
    const codeRef = verificationRef(emailLower, purpose);
    const existing = await codeRef.get();
    if (existing.exists) {
        const data = existing.data() || {};
        const lastSentAt = data.lastSentAt;
        if (lastSentAt && nowDate.getTime() - lastSentAt.toDate().getTime() < EMAIL_MIN_INTERVAL_MS) {
            throw new https_1.HttpsError("failed-precondition", "Lütfen yeni kod istemeden önce 1 dakika bekleyin");
        }
        const dailyKey = String(data.dailyKey || "");
        const dailyCount = Number(data.dailyCount || 0);
        if (dailyKey === dayKey && dailyCount >= EMAIL_DAILY_LIMIT) {
            throw new https_1.HttpsError("resource-exhausted", "Günlük e-posta kod limiti aşıldı");
        }
    }
    const apiKey = RESEND_API_KEY.value() || process.env.RESEND_API_KEY || "";
    if (!apiKey) {
        throw new https_1.HttpsError("failed-precondition", "Resend API key tanımlı değil");
    }
    const fromEmail = process.env.RESEND_FROM || "TurqApp <noreply@turqapp.com>";
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    const copy = buildMailCopy(purpose);
    const resend = new resend_1.Resend(apiKey);
    await resend.emails.send({
        from: fromEmail,
        to: emailLower,
        subject: copy.subject,
        html: buildMailHtml(purpose, verificationCode),
    });
    let dailyCount = 1;
    const prev = existing.exists ? existing.data() || {} : {};
    if (String(prev.dailyKey || "") === dayKey) {
        dailyCount = Number(prev.dailyCount || 0) + 1;
    }
    const payload = {
        email: emailLower,
        purpose,
        verificationCode,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSentAt: now,
        dailyKey: dayKey,
        dailyCount,
        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + VERIFY_TTL_MS)),
        verified: false,
        verifiedAt: admin.firestore.FieldValue.delete(),
        attempts: 0,
        consumedAt: admin.firestore.FieldValue.delete(),
    };
    if (purpose === "phone_change") {
        const newPhone = normalizePhone(String(request.data?.newPhone || ""));
        if (newPhone.length !== 10 || !newPhone.startsWith("5")) {
            throw new https_1.HttpsError("invalid-argument", "Telefon numarası 5 ile başlayan 10 hane olmalı");
        }
        payload.newPhone = newPhone;
    }
    await codeRef.set(payload, { merge: true });
    await accountRef(emailLower).set({
        email: emailLower,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastPurpose: purpose,
    }, { merge: true });
}
exports.sendEmailVerificationCode = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [RESEND_API_KEY],
}, async (request) => {
    const emailRaw = request.data?.email;
    if (!emailRaw || typeof emailRaw !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Email zorunludur");
    }
    const emailLower = emailRaw.toLowerCase().trim();
    const purpose = parsePurpose(request.data?.purpose);
    if (!validEmail(emailLower)) {
        throw new https_1.HttpsError("invalid-argument", "Geçersiz e-posta formatı");
    }
    await sendCodeInternal(request, emailLower, purpose);
    return { success: true, message: "Doğrulama kodu e-posta adresinize gönderildi" };
});
exports.verifyEmailCode = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
}, async (request) => {
    const emailRaw = request.data?.email;
    const verificationCode = String(request.data?.verificationCode || "").trim();
    const purpose = parsePurpose(request.data?.purpose);
    if (!emailRaw || typeof emailRaw !== "string" || !verificationCode) {
        throw new https_1.HttpsError("invalid-argument", "Email ve doğrulama kodu gereklidir");
    }
    const emailLower = emailRaw.toLowerCase().trim();
    const codeRef = verificationRef(emailLower, purpose);
    const verificationDoc = await codeRef.get();
    if (!verificationDoc.exists) {
        throw new https_1.HttpsError("not-found", "Doğrulama kodu bulunamadı. Lütfen yeni kod isteyin.");
    }
    const verificationData = verificationDoc.data() || {};
    if (verificationData.verified === true) {
        throw new https_1.HttpsError("failed-precondition", "Bu doğrulama kodu zaten kullanılmış");
    }
    const now = admin.firestore.Timestamp.now();
    const expiresAt = verificationData.expiresAt;
    if (!expiresAt || expiresAt.toMillis() < now.toMillis()) {
        throw new https_1.HttpsError("deadline-exceeded", "Doğrulama kodunun süresi doldu");
    }
    const attempts = Number(verificationData.attempts || 0);
    if (attempts >= 5) {
        throw new https_1.HttpsError("resource-exhausted", "Çok fazla hatalı deneme. Yeni kod isteyin.");
    }
    if (String(verificationData.verificationCode || "") !== verificationCode) {
        await codeRef.update({
            attempts: admin.firestore.FieldValue.increment(1),
        });
        throw new https_1.HttpsError("invalid-argument", "Geçersiz doğrulama kodu");
    }
    await codeRef.update({
        verified: true,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        attempts,
    });
    return { success: true, message: "E-posta doğrulaması başarılı" };
});
exports.updateUserEmail = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    const caller = await resolveCaller(request);
    const newEmail = String(request.data?.newEmail || "").toLowerCase().trim();
    if (!newEmail || !validEmail(newEmail)) {
        throw new https_1.HttpsError("invalid-argument", "Geçerli bir e-posta adresi gerekli");
    }
    const codeRef = verificationRef(newEmail, "email_change");
    const verificationSnap = await codeRef.get();
    if (!verificationSnap.exists) {
        throw new https_1.HttpsError("failed-precondition", "E-posta doğrulaması gerekli");
    }
    const verificationData = verificationSnap.data() || {};
    const verified = verificationData.verified === true;
    const verifiedAt = verificationData.verifiedAt;
    const withinWindow = !!verifiedAt && (Date.now() - verifiedAt.toDate().getTime()) <= VERIFY_USE_WINDOW_MS;
    if (!verified || !withinWindow) {
        throw new https_1.HttpsError("failed-precondition", "Geçerli e-posta doğrulaması gerekli");
    }
    await admin.auth().updateUser(caller.uid, {
        email: newEmail,
        emailVerified: true,
    });
    await db.collection("users").doc(caller.uid).update({
        email: newEmail,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await codeRef.set({
        verified: false,
        consumedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { success: true, message: "E-posta adresi güncellendi" };
});
exports.markCurrentEmailVerified = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    const caller = await resolveCaller(request);
    const userSnap = await db.collection("users").doc(caller.uid).get();
    const profileEmail = String((userSnap.data() || {}).email || "").toLowerCase().trim();
    const emailToConfirm = profileEmail || String(caller.email || "").toLowerCase().trim();
    if (!emailToConfirm) {
        throw new https_1.HttpsError("failed-precondition", "Hesabınızda e-posta bulunamadı");
    }
    const codeRef = verificationRef(emailToConfirm, "email_confirm");
    const verificationSnap = await codeRef.get();
    if (!verificationSnap.exists) {
        throw new https_1.HttpsError("failed-precondition", "E-posta onayı gerekli");
    }
    const verificationData = verificationSnap.data() || {};
    const verified = verificationData.verified === true;
    const verifiedAt = verificationData.verifiedAt;
    const withinWindow = !!verifiedAt && (Date.now() - verifiedAt.toDate().getTime()) <= VERIFY_USE_WINDOW_MS;
    if (!verified || !withinWindow) {
        throw new https_1.HttpsError("failed-precondition", "Geçerli e-posta onayı bulunamadı");
    }
    try {
        await admin.auth().updateUser(caller.uid, {
            email: emailToConfirm,
            emailVerified: true,
        });
    }
    catch (error) {
        const code = error?.code || "";
        const message = error?.message || "";
        console.error("markCurrentEmailVerified:updateUser warning", {
            uid: caller.uid,
            emailToConfirm,
            code,
            message,
        });
        // Runtime service account yetkisi yoksa akışı bozma:
        // uygulama tarafı Firestore emailVerified alanını esas alacak.
        if (code === "auth/insufficient-permission" ||
            message.toLowerCase().includes("insufficient permission")) {
            console.warn("markCurrentEmailVerified: auth update skipped due to insufficient permission");
        }
        else if (code === "auth/email-already-exists") {
            throw new https_1.HttpsError("already-exists", "Bu e-posta başka bir hesapta kullanılıyor");
        }
        else if (code === "auth/invalid-email") {
            throw new https_1.HttpsError("invalid-argument", "E-posta formatı geçersiz");
        }
        else if (code === "auth/user-not-found") {
            throw new https_1.HttpsError("not-found", "Kullanıcı bulunamadı");
        }
        else {
            throw new https_1.HttpsError("internal", message.length > 0 ? `Auth güncelleme hatası: ${message}` : "Auth e-posta onayı güncellenemedi");
        }
    }
    await db.collection("users").doc(caller.uid).set({
        email: emailToConfirm,
        emailVerified: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await codeRef.set({
        verified: false,
        consumedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { success: true, message: "E-posta onayı tamamlandı" };
});
exports.updateUserPhoneNumberAfterEmailVerification = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    const caller = await resolveCaller(request);
    const newPhoneRaw = String(request.data?.newPhone || "").trim();
    const newPhone = normalizePhone(newPhoneRaw);
    if (newPhone.length !== 10 || !newPhone.startsWith("5")) {
        throw new https_1.HttpsError("invalid-argument", "Telefon numarası 5 ile başlayan 10 hane olmalı");
    }
    const codeRef = verificationRef(caller.email, "phone_change");
    const verificationSnap = await codeRef.get();
    if (!verificationSnap.exists) {
        throw new https_1.HttpsError("failed-precondition", "Telefon değişikliği için e-posta doğrulaması gerekli");
    }
    const verificationData = verificationSnap.data() || {};
    const verified = verificationData.verified === true;
    const verifiedAt = verificationData.verifiedAt;
    const verifiedPhone = String(verificationData.newPhone || "");
    const withinWindow = !!verifiedAt && (Date.now() - verifiedAt.toDate().getTime()) <= VERIFY_USE_WINDOW_MS;
    if (!verified || !withinWindow || verifiedPhone !== newPhone) {
        throw new https_1.HttpsError("failed-precondition", "Geçerli telefon değişikliği doğrulaması bulunamadı");
    }
    await db.collection("users").doc(caller.uid).update({
        phoneNumber: newPhone,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await codeRef.set({
        verified: false,
        consumedAt: admin.firestore.FieldValue.serverTimestamp(),
        consumedPhone: newPhone,
    }, { merge: true });
    return { success: true, message: "Telefon numarası güncellendi" };
});
//# sourceMappingURL=11_resend.js.map