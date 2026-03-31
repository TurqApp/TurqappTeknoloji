"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processPostsMigrationQueue = void 0;
const axios_1 = require("axios");
const crypto_1 = require("crypto");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-admin/storage");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const path = require("path");
const promises_1 = require("stream/promises");
const REGION = "europe-west1";
const QUEUE_COLLECTION = "postsMigrationQueue";
const USERS_COLLECTION = "users";
const POSTS_COLLECTION = "Posts";
const CDN_DOMAIN = "cdn.turqapp.com";
const PREP_HORIZON_MS = 6 * 60 * 60 * 1000;
const MAX_GROUPS_PER_RUN = 3;
const LEASE_MS = 55 * 1000;
const IMAGE_EXT_CANDIDATES = ["webp", "jpg", "jpeg", "png"];
const THUMB_EXT_CANDIDATES = ["webp", "jpg", "jpeg", "png"];
function ensureAdmin() {
    if ((0, app_1.getApps)().length === 0) {
        (0, app_1.initializeApp)();
    }
}
function db() {
    ensureAdmin();
    return (0, firestore_1.getFirestore)();
}
function bucket() {
    ensureAdmin();
    return (0, storage_1.getStorage)().bucket();
}
function asString(value, fallback = "") {
    if (value === null || value === undefined)
        return fallback;
    return String(value).trim();
}
function asBool(value, fallback = false) {
    if (typeof value === "boolean")
        return value;
    if (typeof value === "number")
        return value !== 0;
    if (typeof value === "string") {
        const normalized = value.trim().toLowerCase();
        if (normalized === "true" || normalized === "1")
            return true;
        if (normalized === "false" || normalized === "0")
            return false;
    }
    return fallback;
}
function asNum(value, fallback = 0) {
    if (typeof value === "number" && Number.isFinite(value))
        return value;
    if (typeof value === "string") {
        const parsed = Number(value.trim());
        if (Number.isFinite(parsed))
            return parsed;
    }
    if (value && typeof value.toMillis === "function") {
        return value.toMillis();
    }
    return fallback;
}
function asStringList(value) {
    if (!Array.isArray(value))
        return [];
    return value
        .map((item) => asString(item))
        .filter((item) => item.length > 0);
}
function asMapList(value) {
    if (!Array.isArray(value))
        return [];
    return value
        .map((item) => {
        if (!item || typeof item !== "object" || Array.isArray(item))
            return null;
        return {
            url: asString(item.url),
            aspectRatio: asNum(item.aspectRatio, 1),
        };
    })
        .filter((item) => Boolean(item));
}
function buildCdnUrl(storagePath) {
    return `https://${CDN_DOMAIN}/${storagePath}`;
}
function buildTokenizedCdnUrl(storagePath, token) {
    return `https://${CDN_DOMAIN}/v0/b/${bucket().name}/o/${encodeURIComponent(storagePath)}?alt=media&token=${encodeURIComponent(token)}`;
}
function extractDownloadToken(metadata) {
    if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
        return "";
    }
    const raw = asString(metadata
        .firebaseStorageDownloadTokens);
    if (!raw)
        return "";
    return raw
        .split(",")
        .map((item) => item.trim())
        .find(Boolean) || "";
}
async function buildProtectedAssetUrl(storagePath) {
    const file = bucket().file(storagePath);
    const [metadata] = await file.getMetadata();
    let token = extractDownloadToken(metadata.metadata);
    if (!token) {
        token = (0, crypto_1.randomUUID)();
        await file.setMetadata({
            metadata: {
                ...(metadata.metadata || {}),
                firebaseStorageDownloadTokens: token,
            },
        });
    }
    return buildTokenizedCdnUrl(storagePath, token);
}
function buildHlsUrl(docId) {
    return buildCdnUrl(`Posts/${docId}/hls/master.m3u8`);
}
function buildTargetMainFlood(docId, index) {
    return index === 0 ? "" : `${docId}_0`;
}
function buildYorumMap(sourceDoc) {
    return {
        visibility: asBool(sourceDoc.yorum, true) ? 0 : 3,
    };
}
function buildReshareMap(sourceDoc) {
    return {
        visibility: asNum(sourceDoc.paylasGizliligi, 0),
    };
}
function extractStorageObjectPath(rawUrl) {
    const text = asString(rawUrl);
    if (!text)
        return "";
    if (text.startsWith("gs://")) {
        const parts = text.replace("gs://", "").split("/");
        parts.shift();
        return parts.join("/");
    }
    try {
        const parsed = new URL(text);
        const objectIndex = parsed.pathname.indexOf("/o/");
        if (objectIndex >= 0) {
            return decodeURIComponent(parsed.pathname.slice(objectIndex + 3));
        }
    }
    catch (_) { }
    return "";
}
function extFromUrl(rawUrl, fallback) {
    const objectPath = extractStorageObjectPath(rawUrl);
    const ext = path.extname(objectPath).toLowerCase();
    return ext || fallback;
}
function contentTypeForExt(ext) {
    switch (ext) {
        case ".webp":
            return "image/webp";
        case ".png":
            return "image/png";
        case ".jpeg":
        case ".jpg":
            return "image/jpeg";
        case ".mp4":
            return "video/mp4";
        default:
            return "application/octet-stream";
    }
}
async function pickExistingStoragePath(candidates) {
    for (const candidate of candidates) {
        const [exists] = await bucket().file(candidate).exists();
        if (exists)
            return candidate;
    }
    return "";
}
async function copyUrlToTarget(params) {
    const [targetExists] = await bucket().file(params.targetPath).exists();
    if (targetExists) {
        return { ok: true, existed: true };
    }
    const ext = path.extname(params.targetPath).toLowerCase();
    const response = await axios_1.default.get(params.sourceUrl, {
        responseType: "stream",
        timeout: 600000,
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        validateStatus: (status) => status >= 200 && status < 300,
    });
    const writeStream = bucket().file(params.targetPath).createWriteStream({
        resumable: false,
        metadata: {
            contentType: contentTypeForExt(ext),
            cacheControl: ext === ".mp4"
                ? "public, max-age=31536000, immutable"
                : "public, max-age=86400",
            metadata: params.customMetadata || {},
        },
    });
    await (0, promises_1.pipeline)(response.data, writeStream);
    return { ok: true, existed: false };
}
async function claimLease(rootId, runId, now) {
    const ref = db().collection(QUEUE_COLLECTION).doc(rootId);
    return db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists)
            return false;
        const data = snap.data();
        if (!data || data.active !== true)
            return false;
        if (asNum(data.leaseUntil, 0) > now)
            return false;
        tx.set(ref, {
            leaseOwner: runId,
            leaseUntil: now + LEASE_MS,
            lastProcessAt: now,
            updatedAt: now,
        }, { merge: true });
        return true;
    });
}
async function updateGroup(rootId, patch) {
    await db()
        .collection(QUEUE_COLLECTION)
        .doc(rootId)
        .set(patch, { merge: true });
}
async function loadGroupDocs(rootId) {
    const snap = await db()
        .collection(QUEUE_COLLECTION)
        .doc(rootId)
        .collection("docs")
        .orderBy("index")
        .get();
    return snap.docs.map((doc) => {
        const data = doc.data();
        return {
            docId: doc.id,
            index: asNum(data.index, 0),
            userID: asString(data.userID),
            ad: asBool(data.ad, false),
            aspectRatio: asNum(data.aspectRatio, 1),
            debugMode: asBool(data.debugMode, false),
            editTime: asNum(data.editTime, 0),
            isAd: asBool(data.isAd, false),
            konum: asString(data.konum),
            locationCity: asString(data.locationCity),
            metin: asString(data.metin),
            originalPostID: asString(data.originalPostID),
            originalUserID: asString(data.originalUserID),
            paylasGizliligi: asNum(data.paylasGizliligi, 0),
            scheduledAt: asNum(data.scheduledAt, 0),
            sourceImgMap: asMapList(data.sourceImgMap),
            sourceImageUrls: asStringList(data.sourceImageUrls),
            sourceThumbnailUrl: asString(data.sourceThumbnailUrl),
            sourceVideoUrl: asString(data.sourceVideoUrl),
            tags: Array.isArray(data.tags) ? data.tags.map((item) => asString(item)).filter(Boolean) : [],
            yorum: asBool(data.yorum, true),
        };
    });
}
async function ensureGroupMedia(docs) {
    for (const doc of docs) {
        for (let index = 0; index < doc.sourceImageUrls.length; index += 1) {
            const sourceUrl = asString(doc.sourceImageUrls[index]);
            if (!sourceUrl) {
                return { ok: false, reason: `missing_source_image_url:${doc.docId}:${index}` };
            }
            const targetPath = `Posts/${doc.docId}/image_${index}${extFromUrl(sourceUrl, ".jpg")}`;
            try {
                await copyUrlToTarget({
                    sourceUrl,
                    targetPath,
                });
            }
            catch (error) {
                return {
                    ok: false,
                    reason: `copy_image_failed:${doc.docId}:${index}:${error.message}`,
                };
            }
        }
        const videoUrl = asString(doc.sourceVideoUrl);
        if (!videoUrl)
            continue;
        try {
            await copyUrlToTarget({
                sourceUrl: videoUrl,
                targetPath: `Posts/${doc.docId}/video.mp4`,
                customMetadata: {
                    migrationMode: "true",
                },
            });
        }
        catch (error) {
            return {
                ok: false,
                reason: `copy_video_failed:${doc.docId}:${error.message}`,
            };
        }
    }
    return { ok: true };
}
async function resolveTargetMedia(sourceDoc) {
    const hasVideo = asString(sourceDoc.sourceVideoUrl).length > 0;
    const hasText = asString(sourceDoc.metin).length > 0;
    const sourceImages = sourceDoc.sourceImageUrls;
    if (!hasVideo && sourceImages.length === 0 && !hasText) {
        return {
            ok: false,
            reason: `empty_content:${sourceDoc.docId}`,
        };
    }
    const result = {
        ok: true,
        aspectRatio: asNum(sourceDoc.aspectRatio, 1),
        hlsMasterUrl: "",
        hlsStatus: "none",
        img: [],
        imgMap: [],
        mediaKind: hasVideo ? "video" : sourceImages.length > 0 ? "image" : "text",
        thumbnail: "",
        video: "",
    };
    if (sourceImages.length > 0) {
        for (let index = 0; index < sourceImages.length; index += 1) {
            const storagePath = await pickExistingStoragePath(IMAGE_EXT_CANDIDATES.map((ext) => `Posts/${sourceDoc.docId}/image_${index}.${ext}`));
            if (!storagePath) {
                return {
                    ok: false,
                    reason: `missing_image_${index}:${sourceDoc.docId}`,
                };
            }
            const url = await buildProtectedAssetUrl(storagePath);
            result.img.push(url);
            result.imgMap.push({
                url,
                aspectRatio: asNum(sourceDoc.sourceImgMap[index]?.aspectRatio, result.aspectRatio),
            });
        }
        if (!hasVideo && result.imgMap.length > 0) {
            result.aspectRatio = asNum(result.imgMap[0].aspectRatio, result.aspectRatio);
        }
    }
    if (hasVideo) {
        const [hlsExists] = await bucket().file(`Posts/${sourceDoc.docId}/hls/master.m3u8`).exists();
        if (!hlsExists) {
            return {
                ok: false,
                reason: `missing_hls_master:${sourceDoc.docId}`,
            };
        }
        const thumbPath = await pickExistingStoragePath(THUMB_EXT_CANDIDATES.map((ext) => `Posts/${sourceDoc.docId}/thumbnail.${ext}`));
        if (!thumbPath) {
            return {
                ok: false,
                reason: `missing_video_thumbnail:${sourceDoc.docId}`,
            };
        }
        result.video = buildHlsUrl(sourceDoc.docId);
        result.hlsMasterUrl = result.video;
        result.hlsStatus = "ready";
        result.thumbnail = await buildProtectedAssetUrl(thumbPath);
    }
    else if (asString(sourceDoc.sourceThumbnailUrl).length > 0) {
        const thumbPath = await pickExistingStoragePath(THUMB_EXT_CANDIDATES.map((ext) => `Posts/${sourceDoc.docId}/thumbnail.${ext}`));
        if (thumbPath) {
            result.thumbnail = await buildProtectedAssetUrl(thumbPath);
        }
    }
    return result;
}
async function loadUserProfile(uid, cache) {
    if (cache.has(uid))
        return cache.get(uid) || null;
    const snap = await db().collection(USERS_COLLECTION).doc(uid).get();
    if (!snap.exists) {
        cache.set(uid, null);
        return null;
    }
    const data = snap.data() || {};
    const profile = {
        avatarUrl: asString(data.avatarUrl),
        nickname: asString(data.nickname),
        displayName: asString(data.displayName) ||
            asString(data.fullName) ||
            asString(data.nickname),
        rozet: asString(data.rozet),
        username: asString(data.username),
        fullName: asString(data.fullName) || asString(data.displayName),
    };
    cache.set(uid, profile);
    return profile;
}
async function ensurePlaceholderPosts(group, docs, now) {
    const userCache = new Map();
    const refs = docs.map((doc) => db().collection(POSTS_COLLECTION).doc(doc.docId));
    const snaps = refs.length > 0 ? await db().getAll(...refs) : [];
    const existingDocIds = new Set(snaps.filter((snap) => snap.exists).map((snap) => snap.id));
    const batch = db().batch();
    let seededCount = 0;
    for (const doc of docs) {
        if (existingDocIds.has(doc.docId))
            continue;
        if (!doc.userID)
            return false;
        const profile = await loadUserProfile(doc.userID, userCache);
        if (!profile)
            return false;
        batch.set(db().collection(POSTS_COLLECTION).doc(doc.docId), {
            ad: doc.ad,
            arsiv: false,
            aspectRatio: doc.aspectRatio,
            authorAvatarUrl: profile.avatarUrl,
            authorDisplayName: profile.displayName,
            authorNickname: profile.nickname,
            avatarUrl: profile.avatarUrl,
            debugMode: doc.debugMode,
            deletedPost: false,
            deletedPostTime: 0,
            displayName: profile.displayName,
            editTime: doc.editTime,
            flood: doc.index !== 0,
            floodCount: group.docCount,
            fullName: profile.fullName,
            gizlendi: false,
            hlsMasterUrl: "",
            hlsStatus: asString(doc.sourceVideoUrl).length > 0 ? "processing" : "none",
            hlsUpdatedAt: 0,
            img: [],
            imgMap: [],
            isAd: doc.isAd,
            isUploading: true,
            izBirakYayinTarihi: group.publishAt,
            konum: doc.konum,
            locationCity: doc.locationCity,
            mainFlood: buildTargetMainFlood(doc.docId, doc.index),
            metin: doc.metin,
            nickname: profile.nickname,
            originalPostID: doc.originalPostID,
            originalUserID: doc.originalUserID,
            paylasGizliligi: doc.paylasGizliligi,
            reshareMap: buildReshareMap(doc),
            rozet: profile.rozet,
            scheduledAt: doc.scheduledAt,
            sikayetEdildi: false,
            stabilized: false,
            stats: {
                commentCount: 0,
                likeCount: 0,
                reportedCount: 0,
                retryCount: 0,
                savedCount: 0,
                statsCount: 0,
            },
            tags: doc.tags,
            thumbnail: "",
            timeStamp: group.publishAt,
            updatedAt: now,
            userID: doc.userID,
            username: profile.username,
            video: "",
            yorum: doc.yorum,
            yorumMap: buildYorumMap(doc),
        }, { merge: true });
        seededCount += 1;
    }
    if (seededCount === 0)
        return true;
    batch.set(db().collection(QUEUE_COLLECTION).doc(group.rootId), {
        docSeededAt: asNum(group.docSeededAt, 0) > 0 ? group.docSeededAt : now,
        updatedAt: now,
    }, { merge: true });
    await batch.commit();
    return true;
}
async function makeDuePlaceholdersVisible(group, docs, now) {
    const batch = db().batch();
    for (const doc of docs) {
        batch.set(db().collection(POSTS_COLLECTION).doc(doc.docId), {
            isUploading: false,
            updatedAt: now,
        }, { merge: true });
    }
    batch.set(db().collection(QUEUE_COLLECTION).doc(group.rootId), {
        lastError: "",
        lastErrorAt: 0,
        leaseOwner: "",
        leaseUntil: 0,
        state: "visible_waiting_media",
        updatedAt: now,
        visibleAt: now,
    }, { merge: true });
    await batch.commit();
}
async function rehideLeakedPlaceholders(docs, now) {
    if (docs.length === 0)
        return;
    const refs = docs.map((doc) => db().collection(POSTS_COLLECTION).doc(doc.docId));
    const snaps = await db().getAll(...refs);
    const batch = db().batch();
    let touched = 0;
    for (const snap of snaps) {
        if (!snap.exists)
            continue;
        const data = snap.data() || {};
        const hasMedia = asString(data.video).length > 0 ||
            asString(data.hlsMasterUrl).length > 0 ||
            asString(data.thumbnail).length > 0 ||
            (Array.isArray(data.img) && data.img.length > 0);
        if (data.isUploading === false && !hasMedia) {
            batch.set(snap.ref, {
                isUploading: true,
                updatedAt: now,
            }, { merge: true });
            touched += 1;
        }
    }
    if (touched > 0) {
        await batch.commit();
    }
}
async function buildPayloads(group, docs) {
    const userCache = new Map();
    const payloads = [];
    const skipped = [];
    for (const doc of docs) {
        if (!doc.userID) {
            if (doc.index === 0) {
                return {
                    ok: false,
                    reason: `missing_user_id:${doc.docId}`,
                };
            }
            skipped.push({
                docId: doc.docId,
                reason: `missing_user_id:${doc.docId}`,
            });
            continue;
        }
        const profile = await loadUserProfile(doc.userID, userCache);
        if (!profile) {
            if (doc.index === 0) {
                return {
                    ok: false,
                    reason: `missing_target_user:${doc.userID}`,
                };
            }
            skipped.push({
                docId: doc.docId,
                reason: `missing_target_user:${doc.userID}`,
            });
            continue;
        }
        const media = await resolveTargetMedia(doc);
        if (!media.ok) {
            if (doc.index === 0) {
                return {
                    ok: false,
                    reason: media.reason,
                };
            }
            skipped.push({
                docId: doc.docId,
                reason: media.reason,
            });
            continue;
        }
        payloads.push({
            docId: doc.docId,
            payload: {
                ad: doc.ad,
                arsiv: false,
                aspectRatio: media.aspectRatio,
                authorAvatarUrl: profile.avatarUrl,
                authorDisplayName: profile.displayName,
                authorNickname: profile.nickname,
                avatarUrl: profile.avatarUrl,
                debugMode: doc.debugMode,
                deletedPost: false,
                deletedPostTime: 0,
                displayName: profile.displayName,
                editTime: doc.editTime,
                flood: doc.index !== 0,
                floodCount: group.docCount,
                fullName: profile.fullName,
                gizlendi: false,
                hlsMasterUrl: media.hlsMasterUrl,
                hlsStatus: media.hlsStatus,
                hlsUpdatedAt: media.hlsStatus === "ready" ? group.publishAt : 0,
                img: media.img,
                imgMap: media.imgMap,
                isAd: doc.isAd,
                isUploading: false,
                izBirakYayinTarihi: group.publishAt,
                konum: doc.konum,
                locationCity: doc.locationCity,
                mainFlood: buildTargetMainFlood(doc.docId, doc.index),
                metin: doc.metin,
                nickname: profile.nickname,
                originalPostID: doc.originalPostID,
                originalUserID: doc.originalUserID,
                paylasGizliligi: doc.paylasGizliligi,
                reshareMap: buildReshareMap(doc),
                rozet: profile.rozet,
                scheduledAt: doc.scheduledAt,
                sikayetEdildi: false,
                stabilized: false,
                stats: {
                    commentCount: 0,
                    likeCount: 0,
                    reportedCount: 0,
                    retryCount: 0,
                    savedCount: 0,
                    statsCount: 0,
                },
                tags: doc.tags,
                thumbnail: media.thumbnail,
                timeStamp: group.publishAt,
                updatedAt: group.publishAt,
                userID: doc.userID,
                username: profile.username,
                video: media.video,
                yorum: doc.yorum,
                yorumMap: buildYorumMap(doc),
            },
        });
    }
    return {
        ok: true,
        payloads,
        skipped,
    };
}
async function publishGroup(group, docs, now) {
    const payloads = await buildPayloads(group, docs);
    if (!payloads.ok) {
        await updateGroup(group.rootId, {
            lastError: payloads.reason,
            lastErrorAt: now,
            leaseOwner: "",
            leaseUntil: 0,
            publishAttempts: firestore_1.FieldValue.increment(1),
            state: "awaiting_media",
            updatedAt: now,
        });
        return false;
    }
    const batch = db().batch();
    for (const item of payloads.payloads) {
        batch.set(db().collection(POSTS_COLLECTION).doc(item.docId), item.payload, { merge: true });
    }
    const hasSkipped = payloads.skipped.length > 0;
    batch.set(db().collection(QUEUE_COLLECTION).doc(group.rootId), {
        active: false,
        lastError: hasSkipped ? payloads.skipped[0].reason : "",
        lastErrorAt: hasSkipped ? now : 0,
        leaseOwner: "",
        leaseUntil: 0,
        publishedAt: now,
        state: hasSkipped ? "published_partial" : "published",
        updatedAt: now,
    }, { merge: true });
    await batch.commit();
    return true;
}
async function processGroup(rootId, runId, now) {
    const ref = db().collection(QUEUE_COLLECTION).doc(rootId);
    const snap = await ref.get();
    if (!snap.exists)
        return "missing";
    const group = snap.data();
    if (!group.active) {
        await updateGroup(rootId, {
            leaseOwner: "",
            leaseUntil: 0,
            updatedAt: now,
        });
        return "inactive";
    }
    const docs = await loadGroupDocs(rootId);
    if (docs.length === 0) {
        await updateGroup(rootId, {
            active: false,
            lastError: "missing_group_docs",
            lastErrorAt: now,
            leaseOwner: "",
            leaseUntil: 0,
            state: "failed",
            updatedAt: now,
        });
        return "failed";
    }
    const seeded = await ensurePlaceholderPosts(group, docs, now);
    if (!seeded) {
        await updateGroup(rootId, {
            lastError: "placeholder_seed_failed",
            lastErrorAt: now,
            leaseOwner: "",
            leaseUntil: 0,
            state: "failed",
            updatedAt: now,
        });
        return "failed";
    }
    await rehideLeakedPlaceholders(docs, now);
    const prep = await ensureGroupMedia(docs);
    if (!prep.ok) {
        await updateGroup(rootId, {
            lastError: prep.reason,
            lastErrorAt: now,
            leaseOwner: "",
            leaseUntil: 0,
            mediaAttempts: firestore_1.FieldValue.increment(1),
            state: "media_failed",
            updatedAt: now,
        });
        return "media_failed";
    }
    await updateGroup(rootId, {
        lastError: "",
        leaseOwner: "",
        leaseUntil: 0,
        mediaPreparedAt: group.mediaPreparedAt > 0 ? group.mediaPreparedAt : now,
        state: "media_prepared",
        updatedAt: now,
    });
    if (asNum(group.publishAt, 0) > now) {
        return "prepared";
    }
    const republishClaim = await claimLease(rootId, `${runId}_publish`, now);
    if (!republishClaim) {
        return "lease_lost";
    }
    const publishSnap = await ref.get();
    if (!publishSnap.exists)
        return "missing_after_prepare";
    const publishGroupData = publishSnap.data();
    return (await publishGroup(publishGroupData, docs, now)) ? "published" : "awaiting_media";
}
exports.processPostsMigrationQueue = (0, scheduler_1.onSchedule)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    schedule: "every 1 minutes",
}, async () => {
    const now = Date.now();
    const runId = `posts_migration_${now}`;
    const activeSnap = await db()
        .collection(QUEUE_COLLECTION)
        .where("active", "==", true)
        .get();
    if (activeSnap.empty) {
        console.log("processPostsMigrationQueue no_active_groups");
        return;
    }
    const groups = activeSnap.docs
        .map((doc) => {
        const data = doc.data();
        return {
            ...data,
            rootId: asString(data.rootId) || doc.id,
        };
    })
        .sort((a, b) => asNum(a.publishAt, 0) - asNum(b.publishAt, 0));
    const selected = groups
        .filter((group) => asNum(group.publishAt, 0) <= now + PREP_HORIZON_MS)
        .slice(0, MAX_GROUPS_PER_RUN);
    if (selected.length === 0) {
        console.log("processPostsMigrationQueue no_groups_in_window");
        return;
    }
    const results = [];
    for (const group of selected) {
        const claimed = await claimLease(group.rootId, runId, now);
        if (!claimed) {
            results.push(`${group.rootId}:lease_busy`);
            continue;
        }
        try {
            const result = await processGroup(group.rootId, runId, now);
            results.push(`${group.rootId}:${result}`);
        }
        catch (error) {
            await updateGroup(group.rootId, {
                lastError: error.message,
                lastErrorAt: now,
                leaseOwner: "",
                leaseUntil: 0,
                state: "failed",
                updatedAt: now,
            });
            results.push(`${group.rootId}:failed`);
        }
    }
    console.log("processPostsMigrationQueue", {
        totalActiveGroups: activeSnap.size,
        selectedGroups: selected.length,
        results,
        runId,
    });
});
//# sourceMappingURL=postsMigrationScheduler.js.map