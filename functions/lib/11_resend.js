"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPasswordResetSmsCode = exports.verifySignupSmsCode = exports.sendSignupSmsCode = exports.sendPasswordResetSmsCode = exports.updateUserPhoneNumberAfterEmailVerification = exports.markCurrentEmailVerified = exports.updateUserEmail = exports.verifyEmailCode = exports.sendEmailVerificationCode = void 0;
const admin = require("firebase-admin");
const axios_1 = require("axios");
const resend_1 = require("resend");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const rateLimiter_1 = require("./rateLimiter");
const REGION = "europe-west3";
const RESEND_API_KEY = (0, params_1.defineSecret)("RESEND_API_KEY");
const EMAIL_ACCOUNTS_COLLECTION = "emailAccounts";
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
const EMAIL_MIN_INTERVAL_MS = 60 * 1000;
const EMAIL_DAILY_LIMIT = 8;
const VERIFY_TTL_MS = 60 * 60 * 1000;
const VERIFY_USE_WINDOW_MS = 60 * 60 * 1000;
const NETGSM_ENDPOINT = "https://api.netgsm.com.tr/sms/send/otp";
const SIGNUP_SMS_RESEND_MS = 5 * 60 * 1000;
const SIGNUP_SMS_TTL_MS = 5 * 60 * 1000;
const PASSWORD_RESET_SMS_RESEND_MS = 5 * 60 * 1000;
const PASSWORD_RESET_SMS_TTL_MS = 60 * 1000;
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const VALID_PURPOSES = [
    "signup",
    "password_reset",
    "phone_change",
    "email_change",
    "email_confirm",
    "account_delete",
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
function requiredEnv(name) {
    const value = String(process.env[name] || "").trim();
    if (!value) {
        throw new https_1.HttpsError("failed-precondition", `${name.toLowerCase()}_missing`);
    }
    return value;
}
function accountRef(emailLower) {
    return db.collection(EMAIL_ACCOUNTS_COLLECTION).doc(emailLower);
}
function verificationRef(emailLower, purpose) {
    return accountRef(emailLower).collection("verifications").doc(purpose);
}
function passwordResetSmsRef(emailLower) {
    return accountRef(emailLower).collection("smsVerifications").doc("password_reset");
}
function signupSmsRef(phone) {
    return db.collection("phoneVerifications").doc(phone);
}
function isNetgsmSuccessResponse(rawBody) {
    const body = String(rawBody || "").trim();
    if (body.startsWith("00"))
        return true;
    const match = body.match(/<code>\s*([0-9]+)\s*<\/code>/i);
    if (!match)
        return false;
    const code = Number(match[1]);
    return Number.isFinite(code) && code === 0;
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
    if (purpose === "account_delete") {
        return {
            subject: "TurqApp - Hesap Silme Onay Kodu",
            intro: "Hesabınızı silme talebini onaylamak için onay kodunuz:",
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
    if (purpose === "account_delete") {
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
    const nowMs = Date.now();
    const nowDate = new Date(nowMs);
    const dayKey = nowDate.toISOString().slice(0, 10);
    const codeRef = verificationRef(emailLower, purpose);
    const existing = await codeRef.get();
    if (existing.exists) {
        const data = existing.data() || {};
        const lastSentAt = Number(data.lastSentAt || 0);
        if (lastSentAt > 0 && nowDate.getTime() - lastSentAt < EMAIL_MIN_INTERVAL_MS) {
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
        createdAt: Date.now(),
        lastSentAt: nowMs,
        dailyKey: dayKey,
        dailyCount,
        expiresAt: Date.now() + VERIFY_TTL_MS,
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
        updatedAt: Date.now(),
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
    (0, rateLimiter_1.enforceRateLimitForKey)(emailLower, `email_code_send_${purpose}`, 5, 600);
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
    (0, rateLimiter_1.enforceRateLimitForKey)(emailLower, `email_code_verify_${purpose}`, 12, 600);
    const codeRef = verificationRef(emailLower, purpose);
    const verificationDoc = await codeRef.get();
    if (!verificationDoc.exists) {
        throw new https_1.HttpsError("not-found", "Doğrulama kodu bulunamadı. Lütfen yeni kod isteyin.");
    }
    const verificationData = verificationDoc.data() || {};
    if (verificationData.verified === true) {
        throw new https_1.HttpsError("failed-precondition", "Bu doğrulama kodu zaten kullanılmış");
    }
    const now = Date.now();
    const expiresAt = Number(verificationData.expiresAt || 0);
    if (!expiresAt || expiresAt < now) {
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
        verifiedAt: Date.now(),
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
    rateLimiter_1.RateLimits.general(caller.uid);
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
    const verifiedAt = Number(verificationData.verifiedAt || 0);
    const withinWindow = verifiedAt > 0 && (Date.now() - verifiedAt) <= VERIFY_USE_WINDOW_MS;
    if (!verified || !withinWindow) {
        throw new https_1.HttpsError("failed-precondition", "Geçerli e-posta doğrulaması gerekli");
    }
    await admin.auth().updateUser(caller.uid, {
        email: newEmail,
        emailVerified: true,
    });
    await db.collection("users").doc(caller.uid).update({
        email: newEmail,
        updatedAt: Date.now(),
    });
    await codeRef.set({
        verified: false,
        consumedAt: Date.now(),
    }, { merge: true });
    return { success: true, message: "E-posta adresi güncellendi" };
});
exports.markCurrentEmailVerified = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    const caller = await resolveCaller(request);
    rateLimiter_1.RateLimits.general(caller.uid);
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
    const verifiedAt = Number(verificationData.verifiedAt || 0);
    const withinWindow = verifiedAt > 0 && (Date.now() - verifiedAt) <= VERIFY_USE_WINDOW_MS;
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
            code,
            hasPendingEmail: emailToConfirm.length > 0,
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
        updatedAt: Date.now(),
    }, { merge: true });
    await codeRef.set({
        verified: false,
        consumedAt: Date.now(),
    }, { merge: true });
    return { success: true, message: "E-posta onayı tamamlandı" };
});
exports.updateUserPhoneNumberAfterEmailVerification = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    const caller = await resolveCaller(request);
    rateLimiter_1.RateLimits.general(caller.uid);
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
    const verifiedAt = Number(verificationData.verifiedAt || 0);
    const verifiedPhone = String(verificationData.newPhone || "");
    const withinWindow = verifiedAt > 0 && (Date.now() - verifiedAt) <= VERIFY_USE_WINDOW_MS;
    if (!verified || !withinWindow || verifiedPhone !== newPhone) {
        throw new https_1.HttpsError("failed-precondition", "Geçerli telefon değişikliği doğrulaması bulunamadı");
    }
    await db.collection("users").doc(caller.uid).update({
        phoneNumber: newPhone,
        updatedAt: Date.now(),
    });
    await codeRef.set({
        verified: false,
        consumedAt: Date.now(),
        consumedPhone: newPhone,
    }, { merge: true });
    return { success: true, message: "Telefon numarası güncellendi" };
});
exports.sendPasswordResetSmsCode = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    try {
        const emailRaw = request.data?.email;
        if (!emailRaw || typeof emailRaw !== "string") {
            throw new https_1.HttpsError("invalid-argument", "Email zorunludur");
        }
        const emailLower = emailRaw.toLowerCase().trim();
        if (!validEmail(emailLower)) {
            throw new https_1.HttpsError("invalid-argument", "Geçersiz e-posta formatı");
        }
        (0, rateLimiter_1.enforceRateLimitForKey)(emailLower, "password_reset_sms_send", 5, 600);
        const userQuery = await db
            .collection("users")
            .where("email", "==", emailLower)
            .limit(1)
            .get();
        if (userQuery.empty) {
            throw new https_1.HttpsError("not-found", "Bu e-posta adresi kayıtlı değil");
        }
        const userSnap = userQuery.docs[0];
        const uid = userSnap.id;
        const phone = normalizePhone(String((userSnap.data() || {}).phoneNumber || ""));
        if (phone.length !== 10 || !phone.startsWith("5")) {
            throw new https_1.HttpsError("failed-precondition", "Bu hesap için kayıtlı telefon numarası bulunamadı");
        }
        const smsRef = passwordResetSmsRef(emailLower);
        const existing = await smsRef.get();
        const now = Date.now();
        if (existing.exists) {
            const data = existing.data() || {};
            const lastSentAt = Number(data.lastSentAt || 0);
            const leftMs = PASSWORD_RESET_SMS_RESEND_MS - (now - lastSentAt);
            if (lastSentAt > 0 && leftMs > 0) {
                const leftSec = Math.ceil(leftMs / 1000);
                throw new https_1.HttpsError("failed-precondition", `Yeni SMS için ${leftSec} saniye bekleyin.`);
            }
        }
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const netgsmUserCode = requiredEnv("NETGSM_USERCODE");
        const netgsmPassword = requiredEnv("NETGSM_PASSWORD");
        const netgsmMsgHeader = String(process.env.NETGSM_MSG_HEADER || "TurqApp").trim() || "TurqApp";
        const xml = `<?xml version="1.0"?><mainbody><header><usercode>${netgsmUserCode}</usercode><password>${netgsmPassword}</password><msgheader>${netgsmMsgHeader}</msgheader></header><body><msg><![CDATA[${verificationCode} TurqApp hesabı doğrulama kodunuzdur.]]></msg><no>${phone}</no></body></mainbody>`;
        const response = await axios_1.default.post(NETGSM_ENDPOINT, xml, {
            headers: {
                "Content-Type": "application/xml",
            },
            timeout: 15000,
        });
        const netgsmBody = String(response.data || "").trim();
        if (!isNetgsmSuccessResponse(netgsmBody)) {
            console.error("sendPasswordResetSmsCode netgsm-error", {
                hasUser: uid.length > 0,
                responsePresent: netgsmBody.length > 0,
            });
            throw new https_1.HttpsError("unavailable", "SMS servisine ulaşılamadı. Lütfen tekrar deneyin.");
        }
        await smsRef.set({
            email: emailLower,
            uid,
            verificationCode,
            createdAt: now,
            lastSentAt: now,
            expiresAt: now + PASSWORD_RESET_SMS_TTL_MS,
            attempts: 0,
            verified: false,
            consumed: false,
        }, { merge: true });
        return {
            success: true,
            message: "Doğrulama kodu kayıtlı telefon numaranıza gönderildi",
            resendInSec: 300,
            expiresInSec: 60,
        };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        const message = error?.message || "unknown";
        console.error("sendPasswordResetSmsCode fatal-error", {
            message,
        });
        throw new https_1.HttpsError("failed-precondition", "Kod gönderilemedi. Lütfen tekrar deneyin.");
    }
});
exports.sendSignupSmsCode = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    try {
        const phoneRaw = String(request.data?.phone || "").trim();
        const phone = normalizePhone(phoneRaw);
        if (phone.length !== 10 || !phone.startsWith("5")) {
            throw new https_1.HttpsError("invalid-argument", "Telefon numarası 5 ile başlayan 10 hane olmalı");
        }
        (0, rateLimiter_1.enforceRateLimitForKey)(phone, "signup_sms_send", 4, 900);
        const existingUser = await db
            .collection("users")
            .where("phoneNumber", "==", phone)
            .limit(1)
            .get();
        if (!existingUser.empty) {
            throw new https_1.HttpsError("already-exists", "Bu telefon numarası zaten kullanımda");
        }
        const smsRef = signupSmsRef(phone);
        const existing = await smsRef.get();
        const now = Date.now();
        if (existing.exists) {
            const data = existing.data() || {};
            const lastSentAt = Number(data.lastSentAt || 0);
            const leftMs = SIGNUP_SMS_RESEND_MS - (now - lastSentAt);
            if (lastSentAt > 0 && leftMs > 0) {
                const leftSec = Math.ceil(leftMs / 1000);
                throw new https_1.HttpsError("failed-precondition", `Yeni SMS için ${leftSec} saniye bekleyin.`);
            }
        }
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const netgsmUserCode = requiredEnv("NETGSM_USERCODE");
        const netgsmPassword = requiredEnv("NETGSM_PASSWORD");
        const netgsmMsgHeader = String(process.env.NETGSM_MSG_HEADER || "TurqApp").trim() || "TurqApp";
        const xml = `<?xml version="1.0"?><mainbody><header><usercode>${netgsmUserCode}</usercode><password>${netgsmPassword}</password><msgheader>${netgsmMsgHeader}</msgheader></header><body><msg><![CDATA[${verificationCode} TurqApp hesabı doğrulama kodunuzdur.]]></msg><no>${phone}</no></body></mainbody>`;
        const response = await axios_1.default.post(NETGSM_ENDPOINT, xml, {
            headers: {
                "Content-Type": "application/xml",
            },
            timeout: 15000,
        });
        const netgsmBody = String(response.data || "").trim();
        if (!isNetgsmSuccessResponse(netgsmBody)) {
            console.error("sendSignupSmsCode netgsm-error", {
                phonePresent: phone.length > 0,
                responsePresent: netgsmBody.length > 0,
            });
            throw new https_1.HttpsError("unavailable", "SMS servisine ulaşılamadı. Lütfen tekrar deneyin.");
        }
        await smsRef.set({
            phone,
            verificationCode,
            createdAt: now,
            lastSentAt: now,
            expiresAt: now + SIGNUP_SMS_TTL_MS,
            attempts: 0,
            verified: false,
            verifiedAt: admin.firestore.FieldValue.delete(),
        }, { merge: true });
        return {
            success: true,
            message: "Doğrulama kodu telefon numaranıza gönderildi",
            resendInSec: 300,
            expiresInSec: 300,
        };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        const message = error?.message || "unknown";
        console.error("sendSignupSmsCode fatal-error", {
            message,
        });
        throw new https_1.HttpsError("failed-precondition", "Kod gönderilemedi. Lütfen tekrar deneyin.");
    }
});
exports.verifySignupSmsCode = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
}, async (request) => {
    const phoneRaw = String(request.data?.phone || "").trim();
    const verificationCode = String(request.data?.verificationCode || "").trim();
    const phone = normalizePhone(phoneRaw);
    if (phone.length !== 10 || !phone.startsWith("5") || !verificationCode) {
        throw new https_1.HttpsError("invalid-argument", "Telefon numarası ve doğrulama kodu gereklidir");
    }
    if (!/^\d{6}$/.test(verificationCode)) {
        throw new https_1.HttpsError("invalid-argument", "Doğrulama kodu 6 hane olmalı");
    }
    (0, rateLimiter_1.enforceRateLimitForKey)(phone, "signup_sms_verify", 12, 900);
    const smsRef = signupSmsRef(phone);
    const snap = await smsRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "Doğrulama kodu bulunamadı. Lütfen yeni kod isteyin.");
    }
    const data = snap.data() || {};
    const expiresAt = Number(data.expiresAt || 0);
    const now = Date.now();
    if (!expiresAt || now > expiresAt) {
        throw new https_1.HttpsError("deadline-exceeded", "Doğrulama kodunun süresi doldu");
    }
    const attempts = Number(data.attempts || 0);
    if (attempts >= 5) {
        throw new https_1.HttpsError("resource-exhausted", "Çok fazla hatalı deneme. Yeni kod isteyin.");
    }
    if (String(data.verificationCode || "") !== verificationCode) {
        await smsRef.set({ attempts: admin.firestore.FieldValue.increment(1) }, { merge: true });
        throw new https_1.HttpsError("invalid-argument", "Geçersiz doğrulama kodu");
    }
    await smsRef.set({
        verified: true,
        verifiedAt: now,
        attempts,
    }, { merge: true });
    return {
        success: true,
        message: "Telefon doğrulaması başarılı",
    };
});
exports.verifyPasswordResetSmsCode = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
}, async (request) => {
    const emailRaw = request.data?.email;
    const verificationCode = String(request.data?.verificationCode || "").trim();
    if (!emailRaw || typeof emailRaw !== "string" || !verificationCode) {
        throw new https_1.HttpsError("invalid-argument", "Email ve doğrulama kodu gereklidir");
    }
    const emailLower = emailRaw.toLowerCase().trim();
    if (!validEmail(emailLower)) {
        throw new https_1.HttpsError("invalid-argument", "Geçersiz e-posta formatı");
    }
    if (!/^\d{6}$/.test(verificationCode)) {
        throw new https_1.HttpsError("invalid-argument", "Doğrulama kodu 6 hane olmalı");
    }
    (0, rateLimiter_1.enforceRateLimitForKey)(emailLower, "password_reset_sms_verify", 12, 900);
    const smsRef = passwordResetSmsRef(emailLower);
    const snap = await smsRef.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "Doğrulama kodu bulunamadı. Lütfen yeni kod isteyin.");
    }
    const data = snap.data() || {};
    if (data.consumed === true) {
        throw new https_1.HttpsError("failed-precondition", "Kod zaten kullanıldı. Yeni kod isteyin.");
    }
    const expiresAt = Number(data.expiresAt || 0);
    const now = Date.now();
    if (!expiresAt || now > expiresAt) {
        throw new https_1.HttpsError("deadline-exceeded", "Doğrulama kodunun süresi doldu");
    }
    const attempts = Number(data.attempts || 0);
    if (attempts >= 5) {
        throw new https_1.HttpsError("resource-exhausted", "Çok fazla hatalı deneme. Yeni kod isteyin.");
    }
    if (String(data.verificationCode || "") != verificationCode) {
        await smsRef.set({ attempts: admin.firestore.FieldValue.increment(1) }, { merge: true });
        throw new https_1.HttpsError("invalid-argument", "Geçersiz doğrulama kodu");
    }
    await smsRef.set({
        verified: true,
        verifiedAt: now,
        consumed: true,
        consumedAt: now,
    }, { merge: true });
    return { success: true, message: "SMS doğrulaması başarılı" };
});
//# sourceMappingURL=11_resend.js.map