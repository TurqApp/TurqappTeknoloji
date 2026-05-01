"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f28_generateShortManifestScheduled = exports.f28_generateShortManifestCallable = void 0;
exports.resolveShortManifestDateForNow = resolveShortManifestDateForNow;
exports.istanbulDayRangeForDate = istanbulDayRangeForDate;
exports.buildShortManifestItems = buildShortManifestItems;
exports.buildIndexAndSlots = buildIndexAndSlots;
exports.generateShortManifest = generateShortManifest;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-admin/storage");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");
const rateLimiter_1 = require("./rateLimiter");
const REGION = getEnv("SHORT_MANIFEST_REGION") || getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "Posts";
const SHORT_MANIFEST_COLLECTION = "shortManifest";
const SCHEMA_VERSION = 1;
const SLOT_SIZE = 240;
const DEFAULT_MAX_SLOTS = 1;
const MAX_SLOTS = 12;
const MAX_SCAN_PAGES = 24;
const TYPESENSE_PAGE_SIZE = 250;
const TURQAPP_SHORT_DOMAIN = getEnv("SHORT_LINK_DOMAIN") || "turqapp.com";
const ISTANBUL_UTC_OFFSET = "+03:00";
const DAY_MS = 24 * 60 * 60 * 1000;
const SHORT_SOURCE_DAY_OFFSET = 4;
function ensureAdmin() {
    if ((0, app_1.getApps)().length === 0)
        (0, app_1.initializeApp)();
}
function requireAdminAuth(request) {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    const token = request.auth?.token;
    if (token?.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "admin_required");
    }
    rateLimiter_1.RateLimits.admin(uid);
    return uid;
}
function getEnv(name) {
    const fromProcess = String(process.env[name] || "").trim();
    if (fromProcess)
        return fromProcess;
    try {
        return String(functions.config?.()?.shortmanifest?.[name.toLowerCase()] || "").trim();
    }
    catch {
        return "";
    }
}
function asString(value) {
    return typeof value === "string" ? value.trim() : "";
}
function asBool(value) {
    return value === true;
}
function asNumber(value, fallback = 0) {
    if (typeof value === "number" && Number.isFinite(value))
        return value;
    if (typeof value === "string") {
        const parsed = Number(value);
        if (Number.isFinite(parsed))
            return parsed;
    }
    return fallback;
}
function asInt(value, fallback = 0) {
    return Math.max(0, Math.floor(asNumber(value, fallback)));
}
function asStringArray(value) {
    if (!Array.isArray(value))
        return [];
    return value
        .map((entry) => {
        if (typeof entry === "string")
            return entry.trim();
        if (entry && typeof entry === "object") {
            return asString(entry.url);
        }
        return "";
    })
        .filter(Boolean);
}
function clampInt(value, min, max, fallback) {
    const raw = Math.floor(asNumber(value, fallback));
    if (!Number.isFinite(raw))
        return fallback;
    return Math.max(min, Math.min(max, raw));
}
function envInt(name, min, max, fallback) {
    return clampInt(getEnv(name), min, max, fallback);
}
function formatDateIstanbul(nowMs) {
    const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Europe/Istanbul",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
    }).formatToParts(new Date(nowMs));
    const get = (type) => parts.find((part) => part.type === type)?.value || "";
    return `${get("year")}-${get("month")}-${get("day")}`;
}
function resolveShortManifestDateForNow(nowMs) {
    return formatDateIstanbul(nowMs - SHORT_SOURCE_DAY_OFFSET * DAY_MS);
}
function istanbulDayRangeForDate(date) {
    const normalized = date.trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(normalized)) {
        throw new Error(`invalid_manifest_date:${date}`);
    }
    const startMs = Date.parse(`${normalized}T00:00:00.000${ISTANBUL_UTC_OFFSET}`);
    const endMs = Date.parse(`${normalized}T23:59:59.999${ISTANBUL_UTC_OFFSET}`);
    if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) {
        throw new Error(`invalid_manifest_day_range:${date}`);
    }
    return { startMs, endMs };
}
function stableHash(input) {
    let hash = 2166136261;
    for (let i = 0; i < input.length; i += 1) {
        hash ^= input.charCodeAt(i);
        hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
}
function buildShortUrl(shortId, docId) {
    const id = shortId || docId;
    return id ? `https://${TURQAPP_SHORT_DOMAIN}/p/${id}` : "";
}
function resolveCanonicalId(candidate) {
    const mainFlood = asString(candidate.mainFlood);
    if (mainFlood)
        return mainFlood;
    const docId = asString(candidate.id);
    const floodCount = asInt(candidate.floodCount, 1);
    if (docId && floodCount > 1 && !asBool(candidate.flood))
        return docId;
    if (docId && /_\\d+$/.test(docId))
        return docId.replace(/_\\d+$/, "");
    return docId;
}
function qualityScore(candidate) {
    return (asInt(candidate.likeCount) * 3 +
        asInt(candidate.savedCount) * 4 +
        asInt(candidate.commentCount) * 2 +
        asInt(candidate.statsCount) +
        asInt(candidate.retryCount));
}
function normalizeManifestItem(candidate) {
    const docId = asString(candidate.id);
    const canonicalId = resolveCanonicalId(candidate);
    const userID = asString(candidate.userID);
    const authorNickname = asString(candidate.authorNickname);
    const authorDisplayName = asString(candidate.authorDisplayName) || authorNickname;
    const authorAvatarUrl = asString(candidate.authorAvatarUrl);
    const rozet = asString(candidate.rozet);
    const thumbnail = asString(candidate.thumbnail);
    const img = asStringArray(candidate.img);
    const hlsMasterUrl = asString(candidate.hlsMasterUrl);
    const hlsStatus = asString(candidate.hlsStatus).toLowerCase();
    const floodCount = asInt(candidate.floodCount, 1);
    const mainFlood = asString(candidate.mainFlood);
    const isFloodRoot = !asBool(candidate.flood) && !mainFlood && floodCount > 1;
    const shortId = asString(candidate.shortId);
    const shortUrl = asString(candidate.shortUrl) || buildShortUrl(shortId, docId);
    const posterCandidates = Array.from(new Set([thumbnail, ...img].filter(Boolean)));
    const timeStamp = Math.floor(asNumber(candidate.timeStamp));
    const createdAtTs = Math.floor(asNumber(candidate.createdAtTs, timeStamp));
    const aspectRatio = asNumber(candidate.aspectRatio);
    if (!docId || !canonicalId || !userID)
        return null;
    if (!authorNickname || !authorDisplayName || !authorAvatarUrl || !rozet)
        return null;
    if (asBool(candidate.flood) || mainFlood || isFloodRoot)
        return null;
    if (!thumbnail || posterCandidates.length === 0)
        return null;
    if (!hlsMasterUrl || hlsStatus !== "ready")
        return null;
    if (!Number.isFinite(aspectRatio) || aspectRatio <= 0)
        return null;
    if (!Number.isFinite(timeStamp) || timeStamp <= 0)
        return null;
    if (!shortUrl)
        return null;
    return {
        docId,
        canonicalId,
        userID,
        authorNickname,
        authorDisplayName,
        authorAvatarUrl,
        rozet,
        metin: asString(candidate.metin),
        thumbnail,
        posterCandidates,
        video: asString(candidate.video),
        hlsMasterUrl,
        hlsStatus: "ready",
        hasPlayableVideo: true,
        aspectRatio,
        timeStamp,
        createdAtTs,
        shortId,
        shortUrl,
        contentType: asString(candidate.contentType),
        source: "manifest",
        stats: {
            likeCount: asInt(candidate.likeCount),
            commentCount: asInt(candidate.commentCount),
            savedCount: asInt(candidate.savedCount),
            retryCount: asInt(candidate.retryCount),
            statsCount: asInt(candidate.statsCount),
        },
        flags: {
            deletedPost: false,
            gizlendi: false,
            arsiv: false,
            flood: false,
            floodCount: asInt(candidate.floodCount, 1),
            mainFlood: "",
            isFloodRoot,
            paylasGizliligi: 0,
        },
    };
}
function buildShortManifestItems(candidates, options) {
    const seed = String(options?.seed || "short_manifest");
    const maxItems = Math.max(0, Math.floor(asNumber(options?.maxItems, 0)));
    const seenDocIds = new Set();
    const normalized = [];
    for (const candidate of candidates) {
        const item = normalizeManifestItem(candidate);
        if (!item || seenDocIds.has(item.docId))
            continue;
        seenDocIds.add(item.docId);
        normalized.push({
            item,
            score: qualityScore(candidate),
            hash: stableHash(`${seed}:${item.docId}`),
        });
    }
    normalized.sort((left, right) => {
        if (right.score !== left.score)
            return right.score - left.score;
        return left.hash - right.hash;
    });
    const ordered = [];
    const pool = [...normalized];
    while (pool.length > 0 && (maxItems === 0 || ordered.length < maxItems)) {
        const previousUserId = ordered.length > 0 ? ordered[ordered.length - 1].userID : "";
        let pickedIndex = 0;
        if (previousUserId) {
            const diverseIndex = pool.findIndex((entry) => entry.item.userID !== previousUserId);
            if (diverseIndex >= 0 && diverseIndex < 24) {
                pickedIndex = diverseIndex;
            }
        }
        const [picked] = pool.splice(pickedIndex, 1);
        ordered.push(picked.item);
    }
    return ordered;
}
function buildIndexAndSlots(params) {
    const fullSlotCount = Math.floor(params.items.length / SLOT_SIZE);
    const slots = [];
    for (let slotIndex = 0; slotIndex < fullSlotCount; slotIndex += 1) {
        const slotId = `slot_${String(slotIndex + 1).padStart(3, "0")}`;
        const items = params.items.slice(slotIndex * SLOT_SIZE, (slotIndex + 1) * SLOT_SIZE);
        slots.push({
            schemaVersion: SCHEMA_VERSION,
            date: params.date,
            manifestId: params.manifestId,
            slotId,
            slotIndex,
            itemCount: items.length,
            items,
        });
    }
    const index = {
        schemaVersion: SCHEMA_VERSION,
        date: params.date,
        manifestId: params.manifestId,
        itemsPerSlot: SLOT_SIZE,
        slotCount: slots.length,
        itemCount: slots.length * SLOT_SIZE,
        generatedAt: params.generatedAt,
        slots: slots.map((slot) => ({
            slotId: slot.slotId,
            slotIndex: slot.slotIndex,
            itemCount: slot.itemCount,
            path: `${SHORT_MANIFEST_COLLECTION}/${params.date}/slots/${slot.slotId}.json`,
        })),
    };
    return { index, slots };
}
async function generateShortManifest(params) {
    const manifestId = `short_${params.date}_v${params.generatedAt}`;
    const targetItemCount = params.maxSlots * SLOT_SIZE;
    const fetched = await fetchCandidatesFromFirestore({
        limit: targetItemCount * 3,
        startMs: params.startMs,
        endMs: params.endMs,
    });
    const items = buildShortManifestItems(fetched.candidates, {
        seed: manifestId,
        maxItems: targetItemCount,
    });
    const { index, slots } = buildIndexAndSlots({
        date: params.date,
        manifestId,
        generatedAt: params.generatedAt,
        items,
    });
    if (params.publish && slots.length > 0) {
        await publishManifest({
            index,
            slots,
            publishedAt: Date.now(),
        });
    }
    console.log("short_manifest_generate", {
        actor: params.actor,
        date: params.date,
        publish: params.publish,
        candidates: fetched.candidates.length,
        validItems: items.length,
        slotCount: slots.length,
        itemCount: index.itemCount,
        scannedPages: fetched.scannedPages,
        found: fetched.found,
    });
    return {
        ok: true,
        published: params.publish && slots.length > 0,
        date: params.date,
        manifestId,
        slotCount: slots.length,
        itemCount: index.itemCount,
        candidates: fetched.candidates.length,
        validItems: items.length,
        scannedPages: fetched.scannedPages,
        found: fetched.found,
        indexPath: `${SHORT_MANIFEST_COLLECTION}/${params.date}/index.json`,
    };
}
async function fetchCandidatesFromFirestore(params) {
    const db = (0, firestore_1.getFirestore)();
    const candidates = [];
    let found = 0;
    let scannedPages = 0;
    let lastDoc = null;
    for (let page = 1; page <= MAX_SCAN_PAGES && candidates.length < params.limit; page += 1) {
        let query = db
            .collection(POSTS_COLLECTION)
            .where("timeStamp", ">=", params.startMs)
            .where("timeStamp", "<=", params.endMs)
            .orderBy("timeStamp", "desc")
            .limit(TYPESENSE_PAGE_SIZE);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snapshot = await query.get();
        scannedPages = page;
        if (snapshot.empty)
            break;
        found += snapshot.size;
        for (const doc of snapshot.docs) {
            candidates.push({
                id: doc.id,
                ...doc.data(),
            });
        }
        lastDoc = snapshot.docs[snapshot.docs.length - 1] || null;
        if (snapshot.docs.length < TYPESENSE_PAGE_SIZE)
            break;
    }
    return { candidates, scannedPages, found };
}
async function publishManifest(params) {
    const bucket = (0, storage_1.getStorage)().bucket();
    const cacheControl = "public, max-age=300";
    await bucket
        .file(`${SHORT_MANIFEST_COLLECTION}/${params.index.date}/index.json`)
        .save(JSON.stringify(params.index), {
        resumable: false,
        contentType: "application/json; charset=utf-8",
        metadata: { cacheControl },
    });
    for (const slot of params.slots) {
        await bucket
            .file(`${SHORT_MANIFEST_COLLECTION}/${params.index.date}/slots/${slot.slotId}.json`)
            .save(JSON.stringify(slot), {
            resumable: false,
            contentType: "application/json; charset=utf-8",
            metadata: { cacheControl },
        });
    }
    const firestorePayload = {
        schemaVersion: params.index.schemaVersion,
        date: params.index.date,
        manifestId: params.index.manifestId,
        status: "active",
        indexPath: `${SHORT_MANIFEST_COLLECTION}/${params.index.date}/index.json`,
        slotCount: params.index.slotCount,
        itemCount: params.index.itemCount,
        itemsPerSlot: params.index.itemsPerSlot,
        generatedAt: params.index.generatedAt,
        publishedAt: params.publishedAt,
    };
    const db = (0, firestore_1.getFirestore)();
    const batch = db.batch();
    batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc(params.index.date), firestorePayload, { merge: true });
    batch.set(db.collection(SHORT_MANIFEST_COLLECTION).doc("active"), firestorePayload, { merge: true });
    await batch.commit();
}
exports.f28_generateShortManifestCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
}, async (request) => {
    ensureAdmin();
    const uid = requireAdminAuth(request);
    const nowMs = Date.now();
    const requestedDate = asString(request.data?.date);
    const date = requestedDate || resolveShortManifestDateForNow(nowMs);
    const maxSlots = clampInt(request.data?.maxSlots, 1, MAX_SLOTS, DEFAULT_MAX_SLOTS);
    const defaultRange = istanbulDayRangeForDate(date);
    const startMs = Math.floor(asNumber(request.data?.startMs, defaultRange.startMs));
    const endMs = Math.floor(asNumber(request.data?.endMs, defaultRange.endMs));
    const publish = request.data?.publish === true;
    try {
        return await generateShortManifest({
            actor: uid,
            date,
            maxSlots,
            startMs,
            endMs,
            publish,
            generatedAt: nowMs,
        });
    }
    catch (err) {
        const detail = err?.message || "unknown_error";
        console.error("short_manifest_generate_failed", { detail });
        throw new https_1.HttpsError("internal", "short_manifest_generate_failed", detail);
    }
});
exports.f28_generateShortManifestScheduled = (0, scheduler_1.onSchedule)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    schedule: getEnv("SHORT_MANIFEST_SCHEDULE") || "10 0 * * *",
    timeZone: "Europe/Istanbul",
}, async () => {
    ensureAdmin();
    const nowMs = Date.now();
    const date = resolveShortManifestDateForNow(nowMs);
    const defaultRange = istanbulDayRangeForDate(date);
    try {
        const result = await generateShortManifest({
            actor: "scheduled",
            date,
            maxSlots: envInt("SHORT_MANIFEST_MAX_SLOTS", 1, MAX_SLOTS, DEFAULT_MAX_SLOTS),
            startMs: defaultRange.startMs,
            endMs: defaultRange.endMs,
            publish: true,
            generatedAt: nowMs,
        });
        console.log("short_manifest_scheduled_done", result);
    }
    catch (err) {
        const detail = err?.message || "unknown_error";
        console.error("short_manifest_scheduled_failed", { detail });
        throw err;
    }
});
//# sourceMappingURL=28_shortManifest.js.map