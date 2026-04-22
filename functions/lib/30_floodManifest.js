"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f30_generateFloodManifestScheduled = exports.f30_getFloodManifestCallable = exports.f30_generateFloodManifestCallable = void 0;
exports.generateFloodManifest = generateFloodManifest;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");
const rateLimiter_1 = require("./rateLimiter");
const REGION = getEnv("FLOOD_MANIFEST_REGION") || "us-central1";
const POSTS_COLLECTION = "Posts";
const FLOOD_MANIFEST_COLLECTION = "floodManifest";
const SCHEMA_VERSION = 1;
const PAGE_SIZE = 180;
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
        return String(functions.config?.()?.floodmanifest?.[name.toLowerCase()] || "").trim();
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
        const parsed = Number(value.trim());
        if (Number.isFinite(parsed))
            return parsed;
    }
    if (value && typeof value === "object" && "toMillis" in value) {
        try {
            return Number(value.toMillis());
        }
        catch {
            return fallback;
        }
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
function asJsonMap(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        return {};
    }
    return { ...value };
}
function resolveFloodRootId(post) {
    const mainFlood = asString(post.mainFlood);
    if (mainFlood)
        return mainFlood;
    const docId = post.id.trim();
    const floodCount = asInt(post.floodCount, 1);
    if (!asBool(post.flood) && docId && floodCount > 1) {
        return docId;
    }
    return "";
}
function baseIdForFloodRoot(rootId) {
    return rootId.replace(/_\d+$/g, "");
}
function isVisibleFloodRoot(post, nowMs) {
    const rootId = resolveFloodRootId(post);
    if (!rootId)
        return false;
    if (asBool(post.flood))
        return false;
    if (asBool(post.deletedPost) || asBool(post.gizlendi) || asBool(post.arsiv)) {
        return false;
    }
    if (asInt(post.floodCount, 1) <= 1)
        return false;
    const timeStamp = asInt(post.timeStamp, 0);
    return timeStamp <= nowMs;
}
function isVisibleFloodChild(post, nowMs) {
    if (asBool(post.deletedPost) || asBool(post.gizlendi) || asBool(post.arsiv)) {
        return false;
    }
    const timeStamp = asInt(post.timeStamp, 0);
    return timeStamp <= nowMs;
}
function buildChildEntry(post, rootId) {
    const statsMap = asJsonMap(post.stats);
    return {
        docId: post.id.trim(),
        userID: asString(post.userID),
        authorNickname: asString(post.authorNickname),
        authorDisplayName: asString(post.authorDisplayName) || asString(post.authorNickname),
        authorAvatarUrl: asString(post.authorAvatarUrl),
        rozet: asString(post.rozet),
        timeStamp: asInt(post.timeStamp, 0),
        izBirakYayinTarihi: asInt(post.izBirakYayinTarihi, asInt(post.timeStamp, 0)),
        createdAtTs: asInt(post.createdAtTs, asInt(post.timeStamp, 0)),
        shortId: asString(post.shortId),
        shortUrl: asString(post.shortUrl),
        thumbnail: asString(post.thumbnail),
        img: asStringArray(post.img),
        video: asString(post.video),
        hlsMasterUrl: asString(post.hlsMasterUrl),
        hlsStatus: asString(post.hlsStatus) || "none",
        hlsUpdatedAt: asInt(post.hlsUpdatedAt, 0),
        aspectRatio: asNumber(post.aspectRatio, 1),
        metin: asString(post.metin),
        paylasGizliligi: asInt(post.paylasGizliligi, 0),
        flood: post.id.trim() !== rootId,
        floodCount: asInt(post.floodCount, 1),
        mainFlood: post.id.trim() === rootId ? "" : rootId,
        konum: asString(post.konum),
        locationCity: asString(post.locationCity),
        yorum: post.yorum !== false,
        yorumMap: asJsonMap(post.yorumMap),
        reshareMap: asJsonMap(post.reshareMap),
        tags: asStringArray(post.tags),
        isUploading: false,
        stabilized: post.stabilized !== false,
        deletedPost: false,
        gizlendi: false,
        arsiv: false,
        stats: {
            commentCount: asInt(statsMap.commentCount ?? post.commentCount, 0),
            likeCount: asInt(statsMap.likeCount ?? post.likeCount, 0),
            retryCount: asInt(statsMap.retryCount ?? post.retryCount, 0),
            savedCount: asInt(statsMap.savedCount ?? post.savedCount, 0),
            statsCount: asInt(statsMap.statsCount ?? post.statsCount, 0),
        },
    };
}
function buildFloodManifestDoc(params) {
    const root = params.root;
    const rootId = resolveFloodRootId(root);
    const visibleChildren = params.children
        .filter((child) => child.id.trim() !== rootId)
        .map((child) => buildChildEntry(child, rootId));
    const statsMap = asJsonMap(root.stats);
    return {
        kind: "flood",
        schemaVersion: SCHEMA_VERSION,
        status: "active",
        eligible: true,
        generatedAt: params.generatedAt,
        publishedAt: params.publishedAt,
        updatedAtMs: asInt(root.timeStamp, params.generatedAt),
        floodRootId: rootId,
        mainPostId: rootId,
        childPostIds: visibleChildren.map((child) => child.docId),
        floodCount: asInt(root.floodCount, Math.max(1, params.children.length)),
        visibleChildCount: visibleChildren.length,
        visibleItemCount: visibleChildren.length + 1,
        children: visibleChildren,
        userID: asString(root.userID),
        authorNickname: asString(root.authorNickname),
        authorDisplayName: asString(root.authorDisplayName) || asString(root.authorNickname),
        authorAvatarUrl: asString(root.authorAvatarUrl),
        rozet: asString(root.rozet),
        metin: asString(root.metin),
        thumbnail: asString(root.thumbnail),
        img: asStringArray(root.img),
        video: asString(root.video),
        hlsMasterUrl: asString(root.hlsMasterUrl),
        hlsStatus: asString(root.hlsStatus) || "none",
        hlsUpdatedAt: asInt(root.hlsUpdatedAt, 0),
        aspectRatio: asNumber(root.aspectRatio, 1),
        timeStamp: asInt(root.timeStamp, 0),
        izBirakYayinTarihi: asInt(root.izBirakYayinTarihi, asInt(root.timeStamp, 0)),
        scheduledAt: asInt(root.scheduledAt, 0),
        createdAtTs: asInt(root.createdAtTs, asInt(root.timeStamp, 0)),
        shortId: asString(root.shortId),
        shortUrl: asString(root.shortUrl),
        paylasGizliligi: asInt(root.paylasGizliligi, 0),
        deletedPost: false,
        gizlendi: false,
        arsiv: false,
        flood: false,
        mainFlood: "",
        konum: asString(root.konum),
        locationCity: asString(root.locationCity),
        yorum: root.yorum !== false,
        yorumMap: asJsonMap(root.yorumMap),
        reshareMap: asJsonMap(root.reshareMap),
        tags: asStringArray(root.tags),
        isUploading: false,
        stabilized: root.stabilized !== false,
        stats: {
            commentCount: asInt(statsMap.commentCount ?? root.commentCount, 0),
            likeCount: asInt(statsMap.likeCount ?? root.likeCount, 0),
            retryCount: asInt(statsMap.retryCount ?? root.retryCount, 0),
            savedCount: asInt(statsMap.savedCount ?? root.savedCount, 0),
            statsCount: asInt(statsMap.statsCount ?? root.statsCount, 0),
        },
    };
}
async function fetchFloodRootCandidates(nowMs) {
    const db = (0, firestore_1.getFirestore)();
    let query = db
        .collection(POSTS_COLLECTION)
        .where("arsiv", "==", false)
        .where("flood", "==", false)
        .where("floodCount", ">", 1)
        .where("timeStamp", "<=", nowMs)
        .orderBy("floodCount")
        .orderBy("timeStamp", "desc")
        .limit(PAGE_SIZE);
    const roots = [];
    let lastDoc = null;
    while (true) {
        const snap = await query.get();
        if (snap.empty)
            break;
        for (const doc of snap.docs) {
            const candidate = {
                ...doc.data(),
                id: doc.id,
            };
            if (!isVisibleFloodRoot(candidate, nowMs))
                continue;
            roots.push(candidate);
        }
        if (snap.docs.length < PAGE_SIZE)
            break;
        lastDoc = snap.docs[snap.docs.length - 1];
        query = db
            .collection(POSTS_COLLECTION)
            .where("arsiv", "==", false)
            .where("flood", "==", false)
            .where("floodCount", ">", 1)
            .where("timeStamp", "<=", nowMs)
            .orderBy("floodCount")
            .orderBy("timeStamp", "desc")
            .startAfter(lastDoc)
            .limit(PAGE_SIZE);
    }
    roots.sort((a, b) => asInt(b.timeStamp, 0) - asInt(a.timeStamp, 0));
    return roots;
}
async function fetchFloodGroup(root, nowMs) {
    const rootId = resolveFloodRootId(root);
    const floodCount = asInt(root.floodCount, 1);
    if (!rootId || floodCount <= 1)
        return [];
    const baseId = baseIdForFloodRoot(rootId);
    const refs = Array.from({ length: floodCount }, (_, index) => (0, firestore_1.getFirestore)().collection(POSTS_COLLECTION).doc(`${baseId}_${index}`));
    const docs = await (0, firestore_1.getFirestore)().getAll(...refs);
    const visible = docs
        .filter((doc) => doc.exists)
        .map((doc) => ({
        ...doc.data(),
        id: doc.id,
    }))
        .filter((post) => isVisibleFloodChild(post, nowMs));
    visible.sort((a, b) => {
        const aIndex = asInt(a.id.split("_").pop(), 0);
        const bIndex = asInt(b.id.split("_").pop(), 0);
        return aIndex - bIndex;
    });
    return visible;
}
async function deleteStaleFloodManifestDocs(activeRootIds) {
    const db = (0, firestore_1.getFirestore)();
    let deleted = 0;
    let cursor = null;
    while (true) {
        let query = db
            .collection(FLOOD_MANIFEST_COLLECTION)
            .orderBy("updatedAtMs", "desc")
            .limit(200);
        if (cursor != null) {
            query = query.startAfter(cursor);
        }
        const snap = await query.get();
        if (snap.empty)
            break;
        const batch = db.batch();
        let batchDeletes = 0;
        for (const doc of snap.docs) {
            const kind = asString(doc.data()?.kind);
            if (kind !== "flood")
                continue;
            if (activeRootIds.has(doc.id))
                continue;
            batch.delete(doc.ref);
            batchDeletes += 1;
        }
        if (batchDeletes > 0) {
            await batch.commit();
            deleted += batchDeletes;
        }
        if (snap.docs.length < 200)
            break;
        cursor = snap.docs[snap.docs.length - 1];
    }
    return deleted;
}
async function publishFloodManifestMeta(params) {
    await (0, firestore_1.getFirestore)()
        .collection(FLOOD_MANIFEST_COLLECTION)
        .doc("active")
        .set({
        kind: "meta",
        schemaVersion: SCHEMA_VERSION,
        status: "active",
        rootCount: params.roots,
        generatedAt: params.generatedAt,
        publishedAt: params.publishedAt,
        updatedAtMs: params.publishedAt,
    }, { merge: true });
}
async function fetchPublishedFloodManifest() {
    ensureAdmin();
    const db = (0, firestore_1.getFirestore)();
    const activeSnap = await db.collection(FLOOD_MANIFEST_COLLECTION).doc("active").get();
    const activeData = activeSnap.data() || {};
    const rootCount = asInt(activeData.rootCount);
    const updatedAtMs = asInt(activeData.updatedAtMs, Date.now());
    const generatedAt = asInt(activeData.generatedAt, updatedAtMs);
    const publishedAt = asInt(activeData.publishedAt, updatedAtMs);
    const items = [];
    let lastDoc;
    while (true) {
        let query = db
            .collection(FLOOD_MANIFEST_COLLECTION)
            .orderBy("updatedAtMs", "desc")
            .limit(200);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snap = await query.get();
        if (snap.empty)
            break;
        for (const doc of snap.docs) {
            if (doc.id === "active")
                continue;
            const data = doc.data();
            if (data.kind !== "flood" || data.eligible !== true)
                continue;
            items.push(data);
        }
        lastDoc = snap.docs[snap.docs.length - 1];
        if (snap.docs.length < 200)
            break;
        if (rootCount > 0 && items.length >= rootCount)
            break;
    }
    return {
        ok: true,
        rootCount: rootCount > 0 ? rootCount : items.length,
        updatedAtMs,
        generatedAt,
        publishedAt,
        items,
    };
}
async function generateFloodManifest(params) {
    ensureAdmin();
    const roots = await fetchFloodRootCandidates(params.generatedAt);
    const db = (0, firestore_1.getFirestore)();
    const activeRootIds = new Set();
    for (const root of roots) {
        const rootId = resolveFloodRootId(root);
        if (!rootId)
            continue;
        const group = await fetchFloodGroup(root, params.generatedAt);
        const visibleRoot = group.find((post) => post.id.trim() == rootId);
        if (visibleRoot == null)
            continue;
        if (group.length <= 1)
            continue;
        const payload = buildFloodManifestDoc({
            root: visibleRoot,
            children: group,
            generatedAt: params.generatedAt,
            publishedAt: params.publishedAt,
        });
        await db.collection(FLOOD_MANIFEST_COLLECTION).doc(rootId).set(payload, {
            merge: true,
        });
        activeRootIds.add(rootId);
    }
    const deletedRoots = await deleteStaleFloodManifestDocs(activeRootIds);
    await publishFloodManifestMeta({
        roots: activeRootIds.size,
        generatedAt: params.generatedAt,
        publishedAt: params.publishedAt,
    });
    return {
        ok: true,
        roots: activeRootIds.size,
        publishedAt: params.publishedAt,
        generatedAt: params.generatedAt,
        deletedRoots,
    };
}
exports.f30_generateFloodManifestCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
}, async (request) => {
    ensureAdmin();
    const uid = requireAdminAuth(request);
    try {
        return await generateFloodManifest({
            actor: uid,
            generatedAt: Date.now(),
            publishedAt: Date.now(),
        });
    }
    catch (error) {
        console.error("flood_manifest_generate_failed", {
            detail: error?.message || String(error),
        });
        throw new https_1.HttpsError("internal", "flood_manifest_generate_failed", error?.message || "unknown_error");
    }
});
exports.f30_getFloodManifestCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
}, async () => {
    try {
        return await fetchPublishedFloodManifest();
    }
    catch (error) {
        console.error("flood_manifest_fetch_failed", {
            detail: error?.message || String(error),
        });
        throw new https_1.HttpsError("internal", "flood_manifest_fetch_failed", error?.message || "unknown_error");
    }
});
exports.f30_generateFloodManifestScheduled = (0, scheduler_1.onSchedule)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    schedule: getEnv("FLOOD_MANIFEST_SCHEDULE") || "20 0 * * *",
    timeZone: "Europe/Istanbul",
}, async () => {
    ensureAdmin();
    const nowMs = Date.now();
    try {
        const result = await generateFloodManifest({
            actor: "scheduled",
            generatedAt: nowMs,
            publishedAt: nowMs,
        });
        console.log("flood_manifest_scheduled_done", result);
    }
    catch (error) {
        console.error("flood_manifest_scheduled_failed", {
            detail: error?.message || String(error),
        });
        throw error;
    }
});
//# sourceMappingURL=30_floodManifest.js.map