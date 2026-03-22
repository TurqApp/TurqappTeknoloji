"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toNonNegativeInt = exports.parseLegacyCreatedDateToTimestamp = exports.parseForceFollowUids = exports.normalizeAvatarUrl = exports.normalizeUsernameLower = exports.normalizePhone = exports.LEGACY_DEFAULT_AVATAR_URL = void 0;
const admin = require("firebase-admin");
exports.LEGACY_DEFAULT_AVATAR_URL = "https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2";
const normalizePhone = (raw) => {
    if (!raw)
        return "";
    const digits = String(raw).replace(/[^0-9]/g, "");
    if (digits.length >= 10) {
        return digits.substring(digits.length - 10);
    }
    return digits;
};
exports.normalizePhone = normalizePhone;
const normalizeUsernameLower = (raw) => {
    const s = String(raw ?? "")
        .trim()
        .toLowerCase()
        .replace(/\s+/g, "");
    return s.replace(/[^a-z0-9._]/g, "");
};
exports.normalizeUsernameLower = normalizeUsernameLower;
const normalizeAvatarUrl = (raw) => {
    const value = String(raw ?? "").trim();
    if (!value)
        return "";
    if (value === exports.LEGACY_DEFAULT_AVATAR_URL)
        return "";
    const lower = value.toLowerCase();
    if (lower.includes("/o/profileimage.png") ||
        lower.endsWith("/profileimage.png") ||
        lower.endsWith("profileimage.png")) {
        return "";
    }
    return value;
};
exports.normalizeAvatarUrl = normalizeAvatarUrl;
const parseForceFollowUids = (data) => {
    if (!data)
        return [];
    const enabled = data.enabled;
    if (enabled === false)
        return [];
    const out = new Set();
    const addOne = (v) => {
        if (typeof v !== "string")
            return;
        const trimmed = v.trim();
        if (trimmed)
            out.add(trimmed);
    };
    const addMany = (arr) => {
        if (!Array.isArray(arr))
            return;
        for (const v of arr)
            addOne(v);
    };
    addOne(data.requiredUserIds);
    addMany(data.requiredUserIds);
    addOne(data.equiredUserIds);
    addMany(data.equiredUserIds);
    addOne(data.requiredUserId);
    addOne(data.uid);
    addOne(data.userId);
    return Array.from(out);
};
exports.parseForceFollowUids = parseForceFollowUids;
const parseLegacyCreatedDateToTimestamp = (raw) => {
    if (typeof raw === "number" && Number.isFinite(raw) && raw > 0) {
        return admin.firestore.Timestamp.fromMillis(Math.floor(raw));
    }
    if (typeof raw === "string") {
        const n = Number(raw);
        if (Number.isFinite(n) && n > 0) {
            return admin.firestore.Timestamp.fromMillis(Math.floor(n));
        }
    }
    return null;
};
exports.parseLegacyCreatedDateToTimestamp = parseLegacyCreatedDateToTimestamp;
const toNonNegativeInt = (raw) => {
    const n = Number(raw);
    if (!Number.isFinite(n))
        return 0;
    return Math.max(0, Math.trunc(n));
};
exports.toNonNegativeInt = toNonNegativeInt;
//# sourceMappingURL=userSchemaUtils.js.map