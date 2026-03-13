"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f16_pruneTagsCollection = exports.f16_reconcilePostTags = exports.f15_pruneTagsCollection = exports.f15_reconcilePostTags = exports.f16_syncPostTagsOnWrite = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const _04_tagSettings_1 = require("./04_tagSettings");
function getEnv(name) {
    return String(process.env[name] || "").trim();
}
const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
function ensureAdmin() {
    if ((0, app_1.getApps)().length === 0)
        (0, app_1.initializeApp)();
}
function normalizeTagRaw(tag) {
    return String(tag || "").trim().toLocaleLowerCase("tr-TR");
}
function normalizeForCompare(s) {
    return (s || "")
        .toLocaleLowerCase("tr-TR")
        .replace(/ı/g, "i")
        .replace(/ğ/g, "g")
        .replace(/ü/g, "u")
        .replace(/ş/g, "s")
        .replace(/ö/g, "o")
        .replace(/ç/g, "c")
        .trim();
}
function dedupeTags(tags) {
    return Array.from(new Set(tags.map(normalizeTagRaw).filter(Boolean)));
}
function isAllowedTag(tag, cfg) {
    const t = normalizeTagRaw(tag);
    if (!t)
        return false;
    if (t.length < cfg.tagMinLength || t.length > cfg.tagMaxLength)
        return false;
    if (/^\d+$/.test(t))
        return false;
    const n = normalizeForCompare(t);
    const banned = new Set((cfg.bannedWords || []).map((x) => normalizeForCompare(x)));
    const stop = new Set((cfg.stopwords || []).map((x) => normalizeForCompare(x)));
    if (banned.has(n))
        return false;
    if (stop.has(n))
        return false;
    return true;
}
async function desiredTagsFromPostData(data, cfg) {
    const analysis = data.analysis || {};
    let hashtags = Array.isArray(analysis.hashtags) ? analysis.hashtags : [];
    let captionTags = Array.isArray(analysis.captionTags) ? analysis.captionTags : [];
    // analysis yoksa caption'dan üret (uygulama şemasında sık görülen durum)
    if (!hashtags.length && !captionTags.length) {
        const caption = String(data.metin || data.caption || "");
        if (caption.trim().length > 0) {
            const derived = await (0, _04_tagSettings_1.generateTagDetails)({ caption });
            hashtags = derived.hashtags || [];
            captionTags = derived.captionTags || [];
        }
    }
    const rootTags = Array.isArray(data.tags) ? data.tags : [];
    return dedupeTags([...hashtags, ...captionTags, ...rootTags]).filter((t) => isAllowedTag(t, cfg));
}
async function hashtagTagsFromPostData(data, cfg) {
    const analysis = data.analysis || {};
    let hashtags = Array.isArray(analysis.hashtags) ? analysis.hashtags : [];
    if (!hashtags.length) {
        const caption = String(data.metin || data.caption || "");
        if (caption.trim().length > 0) {
            const derived = await (0, _04_tagSettings_1.generateTagDetails)({ caption });
            hashtags = derived.hashtags || [];
        }
    }
    return dedupeTags(hashtags).filter((t) => isAllowedTag(t, cfg));
}
async function existingTagsForPost(postId) {
    const db = (0, firestore_1.getFirestore)();
    const fromPostSide = await db
        .collection("Posts")
        .doc(postId)
        .collection("tags")
        .get();
    const fromPostHashtagSide = await db
        .collection("Posts")
        .doc(postId)
        .collection("hashtags")
        .get();
    const out = new Set();
    for (const doc of fromPostSide.docs) {
        out.add(String(doc.id || "").trim().toLocaleLowerCase("tr-TR"));
    }
    for (const doc of fromPostHashtagSide.docs) {
        out.add(String(doc.id || "").trim().toLocaleLowerCase("tr-TR"));
    }
    return Array.from(out);
}
async function removeTagLinks(postId, tags) {
    if (!tags.length)
        return;
    const db = (0, firestore_1.getFirestore)();
    const chunkSize = 200;
    for (let i = 0; i < tags.length; i += chunkSize) {
        const chunk = tags.slice(i, i + chunkSize);
        await db.runTransaction(async (tx) => {
            const refs = chunk.map((tag) => db.doc(`tags/${tag}/posts/${postId}`));
            const snaps = await tx.getAll(...refs);
            for (let idx = 0; idx < chunk.length; idx++) {
                const tag = chunk[idx];
                const linkSnap = snaps[idx];
                tx.delete(db.doc(`Posts/${postId}/tags/${tag}`));
                tx.delete(db.doc(`Posts/${postId}/hashtags/${tag}`));
                if (!linkSnap.exists)
                    continue;
                const wasHashtag = linkSnap.get("hasHashtag") === true;
                tx.delete(linkSnap.ref);
                tx.set(db.doc(`tags/${tag}`), {
                    count: firestore_1.FieldValue.increment(-1),
                    hashtagCount: firestore_1.FieldValue.increment(wasHashtag ? -1 : 0),
                    plainCount: firestore_1.FieldValue.increment(wasHashtag ? 0 : -1),
                }, { merge: true });
            }
        });
    }
}
function buildMeta(data) {
    const hlsMaster = String(data.hlsMasterUrl || data.hlsUrl || "");
    const videoUrl = String(data.video || data.rawVideoUrl || "");
    const hlsReady = data.hlsReady === true ||
        (String(data.hlsStatus || "").toLowerCase() === "ready" &&
            (hlsMaster.length > 0 || videoUrl.includes(".m3u8")));
    return {
        authorId: String(data.authorId || data.userID || ""),
        type: String(data.type || "video"),
        visibility: String(data.visibility || "public"),
        status: String(data.status || "published"),
        isArchived: data.isArchived === true || data.arsiv === true,
        isDeleted: data.isDeleted === true || data.deletedPost === true,
        isHidden: data.isHidden === true || data.gizlendi === true,
        isUploading: data.isUploading === true,
        hlsReady,
        createdAt: data.createdAt || data.timeStamp || Date.now(),
    };
}
function shouldKeepPostInTagIndex(data) {
    if (!data)
        return false;
    const status = String(data.status || "published");
    const visibility = String(data.visibility ||
        ((Number(data.paylasGizliligi) === 0 || data.paylasGizliligi === undefined)
            ? "public"
            : "private"));
    const type = String(data.type || "").toLocaleLowerCase("tr-TR");
    const hasImageUrl = String(data.imageURL || data.thumbnail || "").trim().length > 0;
    const hasImageArray = (Array.isArray(data.images) &&
        data.images.some((x) => String(x || "").trim().length > 0)) ||
        (Array.isArray(data.img) &&
            data.img.some((x) => String(x || "").trim().length > 0));
    const isImagePost = type === "image" || type === "photo" || hasImageUrl || hasImageArray;
    const hlsMaster = String(data.hlsMasterUrl || data.hlsUrl || "");
    const videoUrl = String(data.video || data.rawVideoUrl || "");
    const isVideoReady = data.hlsReady === true ||
        (String(data.hlsStatus || "").toLowerCase() === "ready" &&
            (hlsMaster.length > 0 || videoUrl.includes(".m3u8")));
    return (data.isArchived !== true &&
        data.arsiv !== true &&
        data.isDeleted !== true &&
        data.deletedPost !== true &&
        data.isHidden !== true &&
        data.gizlendi !== true &&
        data.isUploading !== true &&
        status === "published" &&
        visibility === "public" &&
        (isVideoReady || isImagePost));
}
exports.f16_syncPostTagsOnWrite = (0, firestore_2.onDocumentWritten)({
    document: "Posts/{postId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
}, async (event) => {
    ensureAdmin();
    const postId = String(event.params.postId || "");
    if (!postId)
        return;
    const afterData = event.data?.after?.data();
    const tagCfg = await (0, _04_tagSettings_1.getTagSettings)();
    const existing = await existingTagsForPost(postId);
    let desired = [];
    if (shouldKeepPostInTagIndex(afterData)) {
        desired = await desiredTagsFromPostData(afterData, tagCfg);
    }
    const desiredSet = new Set(desired);
    const toRemove = existing.filter((t) => !desiredSet.has(t));
    const toAdd = desired.filter((t) => !existing.includes(t));
    if (toRemove.length) {
        await removeTagLinks(postId, toRemove);
    }
    if (toAdd.length && afterData) {
        const meta = buildMeta(afterData);
        await (0, _04_tagSettings_1.writeTagIndex)(postId, toAdd, {
            ...meta,
            trendThreshold: tagCfg.trendThreshold,
            trendWindowHours: tagCfg.trendWindowHours,
            hashtagTags: await hashtagTagsFromPostData(afterData, tagCfg),
        });
    }
});
function validateAuth(request) {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    if (request.auth?.token?.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "admin_required");
    }
}
async function fetchPosts(limit, cursor) {
    const db = (0, firestore_1.getFirestore)();
    let q = db.collection("Posts").orderBy(firestore_1.FieldPath.documentId()).limit(limit);
    if (cursor) {
        q = q.startAfter(cursor);
    }
    return q.get();
}
exports.f15_reconcilePostTags = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
}, async (request) => {
    ensureAdmin();
    validateAuth(request);
    const limit = Math.max(1, Math.min(300, Number(request.data?.limit || 100)));
    const cursor = request.data?.cursor || undefined;
    const dryRun = request.data?.dryRun === true;
    const tagCfg = await (0, _04_tagSettings_1.getTagSettings)();
    const snap = await fetchPosts(limit, cursor);
    const posts = snap.docs;
    let scanned = 0;
    let updated = 0;
    let addedLinks = 0;
    let removedLinks = 0;
    for (const doc of posts) {
        scanned += 1;
        const data = doc.data();
        const postId = doc.id;
        const desired = await desiredTagsFromPostData(data, tagCfg);
        const existing = await existingTagsForPost(postId);
        const desiredSet = new Set(desired);
        const existingSet = new Set(existing);
        const toAdd = desired.filter((t) => !existingSet.has(t));
        const toRemove = existing.filter((t) => !desiredSet.has(t));
        if (!toAdd.length && !toRemove.length)
            continue;
        updated += 1;
        addedLinks += toAdd.length;
        removedLinks += toRemove.length;
        if (dryRun)
            continue;
        if (toAdd.length) {
            const meta = buildMeta(data);
            await (0, _04_tagSettings_1.writeTagIndex)(postId, toAdd, {
                ...meta,
                trendThreshold: tagCfg.trendThreshold,
                trendWindowHours: tagCfg.trendWindowHours,
                hashtagTags: await hashtagTagsFromPostData(data, tagCfg),
            });
        }
        if (toRemove.length) {
            await removeTagLinks(postId, toRemove);
        }
    }
    const last = posts[posts.length - 1];
    const nextCursor = last ? last.id : null;
    const done = posts.length < limit;
    return {
        scanned,
        updated,
        addedLinks,
        removedLinks,
        nextCursor,
        done,
    };
});
exports.f15_pruneTagsCollection = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    enforceAppCheck: true,
}, async (request) => {
    ensureAdmin();
    validateAuth(request);
    const db = (0, firestore_1.getFirestore)();
    const limit = Math.max(1, Math.min(300, Number(request.data?.limit || 100)));
    const cursor = request.data?.cursor || undefined;
    const dryRun = request.data?.dryRun === true;
    let q = db.collection("tags").orderBy(firestore_1.FieldPath.documentId()).limit(limit);
    if (cursor) {
        q = q.startAfter(cursor);
    }
    const snap = await q.get();
    const docs = snap.docs;
    let scanned = 0;
    let deletedTagDocs = 0;
    let normalizedCounts = 0;
    let cleanedAddedAtFields = 0;
    for (const tagDoc of docs) {
        scanned += 1;
        const postsSnap = await tagDoc.ref.collection("Posts").limit(1000).get();
        const actualCount = postsSnap.size;
        const storedCount = Number(tagDoc.data()?.count || 0);
        const docsWithAddedAt = postsSnap.docs.filter((d) => d.get("addedAt") != null);
        if (docsWithAddedAt.length > 0) {
            cleanedAddedAtFields += docsWithAddedAt.length;
            if (!dryRun) {
                let batch = db.batch();
                let writes = 0;
                for (const d of docsWithAddedAt) {
                    batch.set(d.ref, { addedAt: firestore_1.FieldValue.delete() }, { merge: true });
                    writes += 1;
                    if (writes >= 400) {
                        await batch.commit();
                        batch = db.batch();
                        writes = 0;
                    }
                }
                if (writes > 0) {
                    await batch.commit();
                }
            }
        }
        if (actualCount === 0) {
            deletedTagDocs += 1;
            if (!dryRun) {
                await tagDoc.ref.delete();
            }
            continue;
        }
        if (storedCount !== actualCount) {
            normalizedCounts += 1;
            if (!dryRun) {
                await tagDoc.ref.set({
                    count: actualCount,
                }, { merge: true });
            }
        }
    }
    const last = docs[docs.length - 1];
    const nextCursor = last ? last.id : null;
    const done = docs.length < limit;
    return {
        scanned,
        deletedTagDocs,
        normalizedCounts,
        cleanedAddedAtFields,
        nextCursor,
        done,
    };
});
// New numbered names (16_*) while keeping backward-compatible aliases (15_*).
exports.f16_reconcilePostTags = exports.f15_reconcilePostTags;
exports.f16_pruneTagsCollection = exports.f15_pruneTagsCollection;
//# sourceMappingURL=16_tagMaintenance.js.map