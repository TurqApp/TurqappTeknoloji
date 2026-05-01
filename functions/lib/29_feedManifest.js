"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f29_refreshFeedManifestActiveCallable = exports.f29_generateFeedManifestScheduled = exports.f29_generateFeedManifestCallable = void 0;
exports.resolveFeedManifestSlotForNow = resolveFeedManifestSlotForNow;
exports.resolveLatestCompletedFeedManifestSlotForNow = resolveLatestCompletedFeedManifestSlotForNow;
exports.rollingFeedManifestDates = rollingFeedManifestDates;
exports.buildRollingFeedManifestTargets = buildRollingFeedManifestTargets;
exports.istanbulSlotRangeForDateHour = istanbulSlotRangeForDateHour;
exports.buildFeedManifestItems = buildFeedManifestItems;
exports.buildFeedManifestSlot = buildFeedManifestSlot;
exports.buildFeedManifestActiveIndex = buildFeedManifestActiveIndex;
exports.generateFeedManifest = generateFeedManifest;
exports.refreshActiveFeedManifestIndex = refreshActiveFeedManifestIndex;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-admin/storage");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");
const rateLimiter_1 = require("./rateLimiter");
const REGION = getEnv("FEED_MANIFEST_REGION") || getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "Posts";
const FEED_MANIFEST_COLLECTION = "feedManifest";
const SCHEMA_VERSION = 1;
const SLOT_SIZE = 240;
const SLOT_HOURS = 3;
const ROLLING_DAYS = 3;
const MAX_SCAN_PAGES = 24;
const TYPESENSE_PAGE_SIZE = 250;
const TURQAPP_SHORT_DOMAIN = getEnv("SHORT_LINK_DOMAIN") || "turqapp.com";
const ISTANBUL_UTC_OFFSET = "+03:00";
const DAY_MS = 24 * 60 * 60 * 1000;
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
        return String(functions.config?.()?.feedmanifest?.[name.toLowerCase()] || "").trim();
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
function clampSlotHour(value) {
    const raw = Math.floor(asNumber(value, 0));
    if (!Number.isFinite(raw))
        return 0;
    const bounded = Math.max(0, Math.min(23, raw));
    return Math.floor(bounded / SLOT_HOURS) * SLOT_HOURS;
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
function hourIstanbul(nowMs) {
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone: "Europe/Istanbul",
        hour: "2-digit",
        hour12: false,
    }).formatToParts(new Date(nowMs));
    return Math.max(0, Math.min(23, Number(parts.find((part) => part.type === "hour")?.value || 0)));
}
function resolveFeedManifestSlotForNow(nowMs) {
    const hour = hourIstanbul(nowMs);
    const endHour = ((Math.floor(hour / SLOT_HOURS) + 1) * SLOT_HOURS) % 24;
    const slotDateMs = endHour === 0 ? nowMs + DAY_MS : nowMs;
    return {
        date: formatDateIstanbul(slotDateMs),
        slotHour: clampSlotHour(endHour),
    };
}
function resolveLatestCompletedFeedManifestSlotForNow(nowMs) {
    return {
        date: formatDateIstanbul(nowMs),
        slotHour: clampSlotHour(hourIstanbul(nowMs)),
    };
}
function rollingFeedManifestDates(nowMs, days = ROLLING_DAYS) {
    const out = [];
    for (let index = 0; index < days; index += 1) {
        out.push(formatDateIstanbul(nowMs - index * DAY_MS));
    }
    return out;
}
function buildRollingFeedManifestTargets(nowMs) {
    const resolved = resolveLatestCompletedFeedManifestSlotForNow(nowMs);
    const targets = [];
    const latestRange = istanbulSlotRangeForDateHour(resolved.date, resolved.slotHour);
    const totalSlots = ROLLING_DAYS * (24 / SLOT_HOURS);
    for (let offset = totalSlots - 1; offset >= 0; offset -= 1) {
        const slotEndMsExclusive = latestRange.endMs + 1 - offset * SLOT_HOURS * 60 * 60 * 1000;
        targets.push({
            date: formatDateIstanbul(slotEndMsExclusive),
            slotHour: clampSlotHour(hourIstanbul(slotEndMsExclusive)),
            isCurrent: offset === 0,
        });
    }
    return targets;
}
function istanbulSlotRangeForDateHour(date, slotHour) {
    const normalized = date.trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(normalized)) {
        throw new Error(`invalid_manifest_date:${date}`);
    }
    const hour = clampSlotHour(slotHour);
    const endExclusiveMs = Date.parse(`${normalized}T${String(hour).padStart(2, "0")}:00:00.000${ISTANBUL_UTC_OFFSET}`);
    const startMs = endExclusiveMs - SLOT_HOURS * 60 * 60 * 1000;
    const endMs = endExclusiveMs - 1;
    if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) {
        throw new Error(`invalid_manifest_slot:${date}:${slotHour}`);
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
function slotIdForHour(slotHour) {
    return `slot_${String(clampSlotHour(slotHour)).padStart(2, "0")}`;
}
function compareActiveSlots(left, right) {
    if (left.date !== right.date)
        return right.date.localeCompare(left.date);
    if (left.slotHour !== right.slotHour)
        return right.slotHour - left.slotHour;
    if (left.generatedAt !== right.generatedAt)
        return right.generatedAt - left.generatedAt;
    return left.slotId.localeCompare(right.slotId);
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
    if (docId && /_\d+$/.test(docId))
        return docId.replace(/_\d+$/, "");
    return docId;
}
function qualityScore(candidate) {
    return (Math.log1p(asInt(candidate.likeCount) * 2) +
        Math.log1p(asInt(candidate.commentCount) * 3) +
        Math.log1p(asInt(candidate.savedCount) * 4) +
        Math.log1p(asInt(candidate.statsCount)) +
        Math.log1p(asInt(candidate.retryCount)));
}
function normalizeManifestItem(candidate) {
    const docId = asString(candidate.id);
    const canonicalId = resolveCanonicalId(candidate);
    const userID = asString(candidate.userID);
    const authorNickname = asString(candidate.authorNickname);
    const authorDisplayName = asString(candidate.authorDisplayName) || authorNickname;
    const authorAvatarUrl = asString(candidate.authorAvatarUrl);
    const rozet = asString(candidate.rozet);
    const metin = asString(candidate.metin);
    const thumbnail = asString(candidate.thumbnail);
    const img = asStringArray(candidate.img);
    const posterCandidates = Array.from(new Set([thumbnail, ...img].filter(Boolean)));
    const video = asString(candidate.video);
    const hlsMasterUrl = asString(candidate.hlsMasterUrl);
    const hlsStatus = asString(candidate.hlsStatus).toLowerCase();
    const hasPlayableVideo = candidate.hasPlayableVideo === true && hlsMasterUrl.length > 0 && hlsStatus === "ready";
    const flood = asBool(candidate.flood);
    const floodCount = asInt(candidate.floodCount, 1);
    const mainFlood = asString(candidate.mainFlood);
    const isFloodRoot = !flood && !mainFlood && floodCount > 1;
    const timeStamp = Math.floor(asNumber(candidate.timeStamp));
    const createdAtTs = Math.floor(asNumber(candidate.createdAtTs, timeStamp));
    const aspectRatio = asNumber(candidate.aspectRatio, hasPlayableVideo ? 0.5625 : 1);
    const shortId = asString(candidate.shortId);
    const shortUrl = asString(candidate.shortUrl) || buildShortUrl(shortId, docId);
    if (!docId || !canonicalId || !userID)
        return null;
    if (!authorNickname || !authorDisplayName || !authorAvatarUrl)
        return null;
    if (!rozet)
        return null;
    if (!Number.isFinite(timeStamp) || timeStamp <= 0)
        return null;
    if (!shortUrl)
        return null;
    if (!metin && posterCandidates.length === 0 && !hasPlayableVideo && !isFloodRoot)
        return null;
    return {
        docId,
        canonicalId,
        userID,
        authorNickname,
        authorDisplayName,
        authorAvatarUrl,
        rozet,
        metin,
        thumbnail,
        posterCandidates,
        video,
        hlsMasterUrl,
        hlsStatus,
        hasPlayableVideo,
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
            floodCount,
            mainFlood: "",
            isFloodRoot,
            paylasGizliligi: 0,
        },
    };
}
function buildFeedManifestItems(candidates, options) {
    const seed = String(options?.seed || "feed_manifest");
    const maxItems = Math.max(0, Math.floor(asNumber(options?.maxItems, SLOT_SIZE)));
    const maxPerUser = Math.max(1, Math.floor(asNumber(options?.maxPerUser, 8)));
    const userCounts = new Map();
    const deduped = new Map();
    for (const candidate of candidates) {
        const item = normalizeManifestItem(candidate);
        if (!item)
            continue;
        const next = {
            item,
            score: qualityScore(candidate),
            hash: stableHash(`${seed}:${item.canonicalId}`),
        };
        const current = deduped.get(item.canonicalId);
        if (!current) {
            deduped.set(item.canonicalId, next);
            continue;
        }
        const shouldReplace = next.score > current.score ||
            (next.score === current.score && next.item.timeStamp > current.item.timeStamp) ||
            (next.score === current.score &&
                next.item.timeStamp === current.item.timeStamp &&
                next.hash < current.hash);
        if (shouldReplace) {
            deduped.set(item.canonicalId, next);
        }
    }
    const normalized = Array.from(deduped.values());
    normalized.sort((left, right) => {
        if (right.score !== left.score)
            return right.score - left.score;
        if (right.item.timeStamp !== left.item.timeStamp)
            return right.item.timeStamp - left.item.timeStamp;
        return left.hash - right.hash;
    });
    const ordered = [];
    const overflow = [];
    for (const entry of normalized) {
        const nextUserCount = (userCounts.get(entry.item.userID) || 0) + 1;
        if (nextUserCount > maxPerUser) {
            overflow.push(entry);
            continue;
        }
        ordered.push(entry.item);
        userCounts.set(entry.item.userID, nextUserCount);
        if (maxItems > 0 && ordered.length >= maxItems)
            return ordered;
    }
    for (const entry of overflow) {
        ordered.push(entry.item);
        if (maxItems > 0 && ordered.length >= maxItems)
            return ordered;
    }
    return ordered;
}
function buildFeedManifestSlot(params) {
    const slotHour = clampSlotHour(params.slotHour);
    const slotId = slotIdForHour(slotHour);
    return {
        schemaVersion: SCHEMA_VERSION,
        date: params.date,
        slotId,
        slotHour,
        manifestId: params.manifestId,
        itemCount: params.items.length,
        generatedAt: params.generatedAt,
        validFromMs: params.validFromMs,
        validToMs: params.validToMs,
        items: params.items,
    };
}
function buildFeedManifestActiveIndex(params) {
    const normalizedSlots = params.slots
        .map((slot) => ({
        date: asString(slot.date),
        slotId: asString(slot.slotId),
        slotHour: clampSlotHour(slot.slotHour),
        itemCount: Math.max(0, Math.floor(asNumber(slot.itemCount))),
        generatedAt: Math.max(0, Math.floor(asNumber(slot.generatedAt))),
        path: asString(slot.path),
        status: asString(slot.status) || "active",
    }))
        .filter((slot) => slot.status === "active" && slot.path)
        .sort(compareActiveSlots);
    return {
        schemaVersion: SCHEMA_VERSION,
        manifestId: `feed_active_v${params.publishedAt}`,
        status: "active",
        generatedAt: params.nowMs,
        publishedAt: params.publishedAt,
        rollingDays: ROLLING_DAYS,
        itemsPerSlot: SLOT_SIZE,
        slotHours: SLOT_HOURS,
        slots: normalizedSlots.map((slot) => ({
            date: slot.date,
            slotId: slot.slotId,
            slotHour: slot.slotHour,
            itemCount: slot.itemCount,
            generatedAt: slot.generatedAt,
            path: slot.path,
        })),
    };
}
async function generateFeedManifest(params) {
    const slotHour = clampSlotHour(params.slotHour);
    const slotId = slotIdForHour(slotHour);
    const manifestId = `feed_${params.date}_${slotId}_v${params.generatedAt}`;
    const fetchEndMs = Math.min(params.endMs, params.generatedAt);
    const fetched = await fetchCandidatesFromFirestore({
        limit: SLOT_SIZE * 4,
        startMs: params.startMs,
        endMs: fetchEndMs,
    });
    const items = buildFeedManifestItems(fetched.candidates, {
        seed: manifestId,
        maxItems: SLOT_SIZE,
        maxPerUser: 8,
    });
    const slot = buildFeedManifestSlot({
        date: params.date,
        slotHour,
        manifestId,
        generatedAt: params.generatedAt,
        validFromMs: params.startMs,
        validToMs: params.endMs,
        items,
    });
    const path = `${FEED_MANIFEST_COLLECTION}/${params.date}/slots/${slot.slotId}.json`;
    if (params.publish) {
        await publishFeedManifestSlot({
            slot,
            path,
            publishedAt: Date.now(),
        });
    }
    console.log("feed_manifest_generate", {
        actor: params.actor,
        date: params.date,
        slotHour,
        publish: params.publish,
        candidates: fetched.candidates.length,
        validItems: items.length,
        scannedPages: fetched.scannedPages,
        found: fetched.found,
    });
    return {
        ok: true,
        published: params.publish,
        date: params.date,
        slotId,
        manifestId,
        itemCount: slot.itemCount,
        candidates: fetched.candidates.length,
        validItems: items.length,
        scannedPages: fetched.scannedPages,
        found: fetched.found,
        path,
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
async function publishFeedManifestSlot(params) {
    const bucket = (0, storage_1.getStorage)().bucket();
    const cacheControl = "public, max-age=300";
    await bucket.file(params.path).save(JSON.stringify(params.slot), {
        resumable: false,
        contentType: "application/json; charset=utf-8",
        metadata: { cacheControl },
    });
    const db = (0, firestore_1.getFirestore)();
    const slotDoc = {
        schemaVersion: params.slot.schemaVersion,
        date: params.slot.date,
        slotId: params.slot.slotId,
        slotHour: params.slot.slotHour,
        manifestId: params.slot.manifestId,
        status: "active",
        path: params.path,
        itemCount: params.slot.itemCount,
        itemsPerSlot: SLOT_SIZE,
        generatedAt: params.slot.generatedAt,
        validFromMs: params.slot.validFromMs,
        validToMs: params.slot.validToMs,
        publishedAt: params.publishedAt,
    };
    await db.collection(FEED_MANIFEST_COLLECTION).doc(`${params.slot.date}_${params.slot.slotId}`).set(slotDoc, { merge: true });
    await refreshActiveFeedManifestIndex(params.publishedAt);
}
async function refreshActiveFeedManifestIndex(publishedAt) {
    const db = (0, firestore_1.getFirestore)();
    const nowMs = Date.now();
    const slots = [];
    for (const target of buildRollingFeedManifestTargets(nowMs)) {
        const slotId = slotIdForHour(target.slotHour);
        const snapshot = await db.collection(FEED_MANIFEST_COLLECTION).doc(`${target.date}_${slotId}`).get();
        const data = snapshot.data();
        if (!data)
            continue;
        slots.push({
            date: target.date,
            slotId,
            slotHour: target.slotHour,
            itemCount: Math.max(0, Math.floor(asNumber(data.itemCount))),
            generatedAt: Math.max(0, Math.floor(asNumber(data.generatedAt))),
            path: asString(data.path),
            status: asString(data.status) || "active",
        });
    }
    const active = buildFeedManifestActiveIndex({
        nowMs,
        publishedAt,
        slots,
    });
    await db.collection(FEED_MANIFEST_COLLECTION).doc("active").set(active, { merge: true });
    console.log("feed_manifest_active_refreshed", {
        manifestId: active.manifestId,
        publishedAt,
        generatedAt: active.generatedAt,
        slotCount: active.slots.length,
        firstSlot: active.slots[0] || null,
        lastSlot: active.slots[active.slots.length - 1] || null,
    });
}
async function generateRollingFeedManifestBackfill(nowMs) {
    const db = (0, firestore_1.getFirestore)();
    const targets = buildRollingFeedManifestTargets(nowMs);
    const results = [];
    for (const target of targets) {
        const slotId = slotIdForHour(target.slotHour);
        const snapshot = await db.collection(FEED_MANIFEST_COLLECTION).doc(`${target.date}_${slotId}`).get();
        const data = snapshot.data();
        const hasPublishedSlot = snapshot.exists &&
            (asString(data?.status) || "active") === "active" &&
            Math.max(0, Math.floor(asNumber(data?.itemCount))) > 0 &&
            asString(data?.path).length > 0;
        if (hasPublishedSlot && !target.isCurrent)
            continue;
        const range = istanbulSlotRangeForDateHour(target.date, target.slotHour);
        results.push(await generateFeedManifest({
            actor: target.isCurrent ? "scheduled" : "scheduled_backfill",
            date: target.date,
            slotHour: target.slotHour,
            startMs: range.startMs,
            endMs: range.endMs,
            publish: true,
            generatedAt: Date.now(),
        }));
    }
    return results;
}
exports.f29_generateFeedManifestCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
}, async (request) => {
    ensureAdmin();
    const uid = requireAdminAuth(request);
    const nowMs = Date.now();
    const resolved = resolveFeedManifestSlotForNow(nowMs);
    const date = asString(request.data?.date) || resolved.date;
    const slotHour = request.data?.slotHour === undefined
        ? resolved.slotHour
        : clampSlotHour(request.data?.slotHour);
    const defaultRange = istanbulSlotRangeForDateHour(date, slotHour);
    const startMs = Math.floor(asNumber(request.data?.startMs, defaultRange.startMs));
    const endMs = Math.floor(asNumber(request.data?.endMs, defaultRange.endMs));
    const publish = request.data?.publish === true;
    try {
        return await generateFeedManifest({
            actor: uid,
            date,
            slotHour,
            startMs,
            endMs,
            publish,
            generatedAt: nowMs,
        });
    }
    catch (err) {
        const detail = err?.message || "unknown_error";
        console.error("feed_manifest_generate_failed", { detail });
        throw new https_1.HttpsError("internal", "feed_manifest_generate_failed", detail);
    }
});
exports.f29_generateFeedManifestScheduled = (0, scheduler_1.onSchedule)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    schedule: getEnv("FEED_MANIFEST_SCHEDULE") || "5 */3 * * *",
    timeZone: "Europe/Istanbul",
}, async () => {
    ensureAdmin();
    const nowMs = Date.now();
    try {
        const results = await generateRollingFeedManifestBackfill(nowMs);
        console.log("feed_manifest_scheduled_done", {
            generatedSlots: results.length,
            slots: results.map((result) => ({
                date: result.date,
                slotId: result.slotId,
                itemCount: result.itemCount,
                published: result.published,
            })),
        });
    }
    catch (err) {
        const detail = err?.message || "unknown_error";
        console.error("feed_manifest_scheduled_failed", { detail });
        throw err;
    }
});
exports.f29_refreshFeedManifestActiveCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
}, async (request) => {
    ensureAdmin();
    const isAdmin = request.auth?.token?.admin === true;
    const providedSecret = asString(request.data?.secret);
    const configuredSecret = getEnv("FEED_MANIFEST_ACTIVE_REFRESH_SECRET");
    if (!isAdmin && (!configuredSecret || providedSecret !== configuredSecret)) {
        throw new https_1.HttpsError("permission-denied", "admin_or_secret_required");
    }
    const uid = request.auth?.uid || "secret_refresh";
    if (isAdmin && request.auth?.uid) {
        rateLimiter_1.RateLimits.admin(request.auth.uid);
    }
    const publishedAt = Math.max(1, Math.floor(asNumber(request.data?.publishedAt, Date.now())));
    try {
        await refreshActiveFeedManifestIndex(publishedAt);
        const snapshot = await (0, firestore_1.getFirestore)()
            .collection(FEED_MANIFEST_COLLECTION)
            .doc("active")
            .get();
        const active = snapshot.data() || {};
        console.log("feed_manifest_active_refresh_done", {
            actor: uid,
            manifestId: asString(active.manifestId),
            slotCount: Array.isArray(active.slots) ? active.slots.length : 0,
        });
        return {
            ok: true,
            manifestId: asString(active.manifestId),
            slotCount: Array.isArray(active.slots) ? active.slots.length : 0,
            firstSlot: Array.isArray(active.slots) ? active.slots[0] || null : null,
            lastSlot: Array.isArray(active.slots)
                ? active.slots[active.slots.length - 1] || null
                : null,
        };
    }
    catch (err) {
        const detail = err?.message || "unknown_error";
        console.error("feed_manifest_active_refresh_failed", { actor: uid, detail });
        throw new https_1.HttpsError("internal", "feed_manifest_active_refresh_failed", detail);
    }
});
//# sourceMappingURL=29_feedManifest.js.map