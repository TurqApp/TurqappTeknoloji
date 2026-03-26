"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultPushTypes = void 0;
exports.interactionThrottleType = interactionThrottleType;
exports.interactionQuietWindowMs = interactionQuietWindowMs;
exports.isNotificationTypeEnabled = isNotificationTypeEnabled;
exports.notificationBodyFromType = notificationBodyFromType;
exports.mergeNotificationPreferences = mergeNotificationPreferences;
exports.isUserNotificationTypeEnabled = isUserNotificationTypeEnabled;
exports.defaultPushTypes = {
    follow: true,
    comment: true,
    message: true,
    like: true,
    reshared_posts: true,
    shared_as_posts: true,
    posts: true,
};
const interactionPushQuietWindowsMs = {
    like: 30 * 60 * 1000,
    comment: 2 * 60 * 1000,
    reshared_posts: 30 * 60 * 1000,
    shared_as_posts: 30 * 60 * 1000,
    posts: 30 * 60 * 1000,
};
const notificationPreferenceDefaults = {
    pauseAll: false,
    sleepMode: false,
    messagesOnly: false,
    messages: {
        directMessages: true,
    },
    posts: {
        posts: true,
        comments: true,
        likes: true,
        postActivity: true,
    },
    followers: {
        follows: true,
    },
    opportunities: {
        jobApplications: true,
        tutoringApplications: true,
        applicationStatus: true,
    },
};
function normalizeNotificationType(type) {
    const normalized = String(type || "").trim().toLowerCase();
    switch (normalized) {
        case "user":
            return "follow";
        case "chat":
            return "message";
        case "posts":
            return "posts";
        default:
            return normalized;
    }
}
function readBool(source, path) {
    let current = source;
    for (const segment of path.split(".")) {
        if (!current || typeof current !== "object")
            return false;
        current = current[segment];
    }
    return current === true;
}
function deepMerge(base, override) {
    const result = {};
    const keys = new Set([
        ...Object.keys(base || {}),
        ...Object.keys(override || {}),
    ]);
    for (const key of keys) {
        const baseValue = base?.[key];
        const overrideValue = override?.[key];
        if (baseValue &&
            typeof baseValue === "object" &&
            !Array.isArray(baseValue) &&
            overrideValue &&
            typeof overrideValue === "object" &&
            !Array.isArray(overrideValue)) {
            result[key] = deepMerge(baseValue, overrideValue);
        }
        else if (overrideValue !== undefined) {
            result[key] = overrideValue;
        }
        else {
            result[key] = baseValue;
        }
    }
    return result;
}
function interactionThrottleType(type) {
    return normalizeNotificationType(type);
}
function interactionQuietWindowMs(type) {
    return interactionPushQuietWindowsMs[interactionThrottleType(type)];
}
function isNotificationTypeEnabled(type, types) {
    switch (normalizeNotificationType(type)) {
        case "follow":
            return types.follow;
        case "comment":
            return types.comment;
        case "message":
            return types.message;
        case "like":
            return types.like;
        case "reshared_posts":
            return types.reshared_posts;
        case "shared_as_posts":
            return types.shared_as_posts;
        case "posts":
            return types.posts;
        default:
            return true;
    }
}
function notificationBodyFromType(type) {
    switch (normalizeNotificationType(type)) {
        case "follow":
            return "seni takip etmeye başladı";
        case "message":
            return "sana mesaj gönderdi";
        case "comment":
            return "gönderine yorum yaptı";
        case "like":
            return "gönderini beğendi";
        case "reshared_posts":
            return "gönderini yeniden paylaştı";
        case "shared_as_posts":
            return "gönderini paylaştı";
        case "posts":
        default:
            return "gönderinle etkileşime geçti";
    }
}
function mergeNotificationPreferences(raw) {
    return deepMerge(notificationPreferenceDefaults, raw || {});
}
function isUserNotificationTypeEnabled(type, rawPrefs) {
    const prefs = mergeNotificationPreferences(rawPrefs);
    const normalizedType = normalizeNotificationType(type);
    if (readBool(prefs, "pauseAll")) {
        return false;
    }
    if (readBool(prefs, "messagesOnly")) {
        return normalizedType === "message";
    }
    switch (normalizedType) {
        case "message":
            return readBool(prefs, "messages.directMessages");
        case "comment":
            return readBool(prefs, "posts.comments");
        case "like":
        case "comment_like":
            return (readBool(prefs, "posts.likes") ||
                readBool(prefs, "posts.postActivity"));
        case "reshared_posts":
        case "shared_as_posts":
        case "posts":
            return (readBool(prefs, "posts.posts") ||
                readBool(prefs, "posts.postActivity"));
        case "follow":
            return readBool(prefs, "followers.follows");
        case "job_application":
        case "market_offer":
            return readBool(prefs, "opportunities.jobApplications");
        case "tutoring_application":
            return readBool(prefs, "opportunities.tutoringApplications");
        case "tutoring_status":
        case "market_offer_status":
            return readBool(prefs, "opportunities.applicationStatus");
        default:
            return true;
    }
}
//# sourceMappingURL=notificationPushPolicy.js.map