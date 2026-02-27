"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f15_getLatestPostIdsCallable = exports.f14_reindexPostsToTypesenseCallable = exports.f14_searchPostsCallable = exports.f14_searchPosts = exports.f14_syncPostsToTypesense = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const axios_1 = require("axios");
const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const POSTS_COLLECTION = "posts_search";
const USERS_COLLECTION = "users_search";
const TAGS_COLLECTION = "tags_search";
const MAX_LIMIT = 50;
function ensureAdmin() {
    if ((0, app_1.getApps)().length === 0)
        (0, app_1.initializeApp)();
}
function getEnv(name) {
    return String(process.env[name] || "").trim();
}
function getTypesenseBaseUrl() {
    const raw = getEnv("TYPESENSE_HOST");
    if (!raw)
        return "";
    const hasProtocol = raw.startsWith("http://") || raw.startsWith("https://");
    return (hasProtocol ? raw : `https://${raw}`).replace(/\/+$/g, "");
}
function getTypesenseApiKey() {
    return getEnv("TYPESENSE_API_KEY");
}
function typesenseReady() {
    return !!getTypesenseBaseUrl() && !!getTypesenseApiKey();
}
function headers() {
    return {
        "X-TYPESENSE-API-KEY": getTypesenseApiKey(),
        "Content-Type": "application/json",
    };
}
function asString(x) {
    return typeof x === "string" ? x : "";
}
function asBool(x) {
    return x === true;
}
function asStringArray(x) {
    if (!Array.isArray(x))
        return [];
    return x.map((v) => String(v || "").trim()).filter(Boolean);
}
function asEpochSeconds(x) {
    if (!x)
        return 0;
    if (typeof x === "number" && Number.isFinite(x)) {
        return x > 1e12 ? Math.floor(x / 1000) : Math.floor(x);
    }
    if (typeof x === "object" && x !== null) {
        const maybe = x;
        if (typeof maybe.seconds === "number")
            return Math.floor(maybe.seconds);
        if (typeof maybe._seconds === "number")
            return Math.floor(maybe._seconds);
        if (typeof maybe.toMillis === "function") {
            const ms = maybe.toMillis();
            if (Number.isFinite(ms))
                return Math.floor(ms / 1000);
        }
    }
    return 0;
}
function asEpochMillis(x) {
    const sec = asEpochSeconds(x);
    if (sec > 0)
        return sec * 1000;
    if (typeof x === "number" && Number.isFinite(x))
        return Math.floor(x);
    if (typeof x === "string") {
        const n = Number(x);
        if (Number.isFinite(n))
            return Math.floor(n);
    }
    return 0;
}
let collectionEnsurePromise = null;
let usersCollectionEnsurePromise = null;
let tagsCollectionEnsurePromise = null;
async function ensurePostsCollection() {
    if (collectionEnsurePromise)
        return collectionEnsurePromise;
    collectionEnsurePromise = (async () => {
        const baseUrl = getTypesenseBaseUrl();
        if (!baseUrl)
            return;
        try {
            const existing = await axios_1.default.get(`${baseUrl}/collections/${POSTS_COLLECTION}`, {
                headers: headers(),
                timeout: 8000,
            });
            const fields = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
            const required = [
                { name: "paylasGizliligi", type: "int32", optional: true },
                { name: "arsiv", type: "bool", optional: true },
                { name: "deletedPost", type: "bool", optional: true },
                { name: "gizlendi", type: "bool", optional: true },
                { name: "isUploading", type: "bool", optional: true },
                { name: "hlsStatus", type: "string", optional: true },
                { name: "imageURL", type: "string", optional: true },
                { name: "timeStamp", type: "int64", optional: true },
            ];
            const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
            if (missing.length) {
                await axios_1.default.patch(`${baseUrl}/collections/${POSTS_COLLECTION}`, { fields: missing }, { headers: headers(), timeout: 8000 });
            }
            return;
        }
        catch (err) {
            const status = err?.response?.status;
            if (status !== 404)
                throw err;
        }
        await axios_1.default.post(`${baseUrl}/collections`, {
            name: POSTS_COLLECTION,
            fields: [
                { name: "id", type: "string" },
                { name: "authorId", type: "string", optional: true },
                { name: "caption", type: "string", optional: true },
                { name: "hashtags", type: "string[]", optional: true },
                { name: "mentions", type: "string[]", optional: true },
                { name: "hlsUrl", type: "string", optional: true },
                { name: "hlsThumbnailUrl", type: "string", optional: true },
                { name: "rawVideoUrl", type: "string", optional: true },
                { name: "imageURL", type: "string", optional: true },
                { name: "previewUrl", type: "string", optional: true },
                { name: "paylasGizliligi", type: "int32", optional: true },
                { name: "arsiv", type: "bool", optional: true },
                { name: "deletedPost", type: "bool", optional: true },
                { name: "gizlendi", type: "bool", optional: true },
                { name: "isUploading", type: "bool", optional: true },
                { name: "hlsStatus", type: "string", optional: true },
                { name: "timeStamp", type: "int64", optional: true },
            ],
            default_sorting_field: "timeStamp",
        }, {
            headers: headers(),
            timeout: 8000,
        });
    })().catch((err) => {
        collectionEnsurePromise = null;
        throw err;
    });
    return collectionEnsurePromise;
}
async function ensureUsersCollection() {
    if (usersCollectionEnsurePromise)
        return usersCollectionEnsurePromise;
    usersCollectionEnsurePromise = (async () => {
        const baseUrl = getTypesenseBaseUrl();
        if (!baseUrl)
            return;
        try {
            const existing = await axios_1.default.get(`${baseUrl}/collections/${USERS_COLLECTION}`, {
                headers: headers(),
                timeout: 8000,
            });
            const fields = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
            const required = [
                { name: "nickname", type: "string", optional: true },
                { name: "firstName", type: "string", optional: true },
                { name: "lastName", type: "string", optional: true },
                { name: "pfImage", type: "string", optional: true },
                { name: "rozet", type: "string", optional: true },
                { name: "gizliHesap", type: "bool", optional: true },
                { name: "deletedAccount", type: "bool", optional: true },
                { name: "hesapOnayi", type: "bool", optional: true },
            ];
            const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
            if (missing.length) {
                await axios_1.default.patch(`${baseUrl}/collections/${USERS_COLLECTION}`, { fields: missing }, { headers: headers(), timeout: 8000 });
            }
            return;
        }
        catch (err) {
            const status = err?.response?.status;
            if (status !== 404)
                throw err;
        }
        await axios_1.default.post(`${baseUrl}/collections`, {
            name: USERS_COLLECTION,
            fields: [
                { name: "id", type: "string" },
                { name: "nickname", type: "string", optional: true },
                { name: "firstName", type: "string", optional: true },
                { name: "lastName", type: "string", optional: true },
                { name: "pfImage", type: "string", optional: true },
                { name: "rozet", type: "string", optional: true },
                { name: "gizliHesap", type: "bool", optional: true },
                { name: "deletedAccount", type: "bool", optional: true },
                { name: "hesapOnayi", type: "bool", optional: true },
                { name: "updatedAtTs", type: "int32" },
            ],
            default_sorting_field: "updatedAtTs",
        }, {
            headers: headers(),
            timeout: 8000,
        });
    })().catch((err) => {
        usersCollectionEnsurePromise = null;
        throw err;
    });
    return usersCollectionEnsurePromise;
}
async function ensureTagsCollection() {
    if (tagsCollectionEnsurePromise)
        return tagsCollectionEnsurePromise;
    tagsCollectionEnsurePromise = (async () => {
        const baseUrl = getTypesenseBaseUrl();
        if (!baseUrl)
            return;
        try {
            const existing = await axios_1.default.get(`${baseUrl}/collections/${TAGS_COLLECTION}`, {
                headers: headers(),
                timeout: 8000,
            });
            const fields = Array.isArray(existing.data?.fields) ? existing.data.fields : [];
            const missingFields = [];
            if (!fields.some((f) => f?.name === "docType")) {
                missingFields.push({ name: "docType", type: "string", optional: true });
            }
            if (!fields.some((f) => f?.name === "hasHashtag")) {
                missingFields.push({ name: "hasHashtag", type: "bool", optional: true });
            }
            if (missingFields.length) {
                await axios_1.default.patch(`${baseUrl}/collections/${TAGS_COLLECTION}`, {
                    fields: missingFields,
                }, {
                    headers: headers(),
                    timeout: 8000,
                });
            }
            return;
        }
        catch (err) {
            const status = err?.response?.status;
            if (status !== 404)
                throw err;
        }
        await axios_1.default.post(`${baseUrl}/collections`, {
            name: TAGS_COLLECTION,
            fields: [
                { name: "id", type: "string" },
                { name: "docType", type: "string", optional: true },
                { name: "tag", type: "string" },
                { name: "postId", type: "string", optional: true },
                { name: "authorId", type: "string", optional: true },
                { name: "hasHashtag", type: "bool", optional: true },
                { name: "createdAtTs", type: "int64" },
            ],
            default_sorting_field: "createdAtTs",
        }, {
            headers: headers(),
            timeout: 8000,
        });
    })().catch((err) => {
        tagsCollectionEnsurePromise = null;
        throw err;
    });
    return tagsCollectionEnsurePromise;
}
function buildSearchDoc(postId, data) {
    const analysis = data.analysis || {};
    const paylas = Number(data.paylasGizliligi);
    const paylasGizliligi = Number.isFinite(paylas) ? paylas : 0;
    const deletedPost = asBool(data.deletedPost) || asBool(data.isDeleted);
    const arsiv = asBool(data.arsiv) || asBool(data.isArchived);
    const gizlendi = asBool(data.gizlendi) || asBool(data.isHidden);
    const isUploading = asBool(data.isUploading);
    const caption = asString(data.metin) || asString(data.caption);
    const imgList = Array.isArray(data.img) ? data.img : [];
    const firstImg = imgList.length ? String(imgList[0] || "") : "";
    const hlsMasterUrl = asString(data.hlsMasterUrl) || asString(data.hlsUrl);
    const thumbnailUrl = asString(data.thumbnail) || asString(data.hlsThumbnailUrl);
    const rawVideoUrl = asString(data.rawVideoUrl) || asString(data.video);
    const hlsStatusRaw = asString(data.hlsStatus).toLowerCase();
    const hlsStatus = hlsStatusRaw || (asBool(data.hlsReady) ? "ready" : "none");
    const timeStamp = Number(data.timeStamp || 0) ||
        asEpochMillis(data.createdAt) ||
        Date.now();
    const createdAtTs = timeStamp;
    return {
        id: postId,
        authorId: asString(data.authorId) || asString(data.userID),
        caption,
        hashtags: extractPostTags(data).map((x) => x.tag),
        mentions: asStringArray(analysis.mentions),
        hlsUrl: hlsMasterUrl,
        hlsThumbnailUrl: thumbnailUrl,
        rawVideoUrl,
        imageURL: asString(data.imageURL) || firstImg,
        previewUrl: thumbnailUrl ||
            asString(data.imageURL) ||
            firstImg ||
            asString((Array.isArray(data.images) ? data.images[0] : "")) ||
            "",
        paylasGizliligi,
        arsiv,
        deletedPost,
        gizlendi,
        isUploading,
        hlsStatus,
        timeStamp,
        createdAtTs,
    };
}
function shouldIndex(doc) {
    return true;
}
function normalizeTag(tag) {
    const t = String(tag || "").trim().toLocaleLowerCase("tr-TR");
    if (!t)
        return "";
    return t.startsWith("#") ? t.slice(1) : t;
}
function hasExplicitHash(raw) {
    return String(raw || "").trim().startsWith("#");
}
function extractHashtagsFromCaption(text) {
    const out = new Set();
    const re = /#([\p{L}\p{N}_]{2,40})/gu;
    let m;
    while ((m = re.exec(text || ""))) {
        const t = normalizeTag(m[1]);
        if (t)
            out.add(t);
    }
    return Array.from(out);
}
function extractPostTags(data) {
    const analysis = data.analysis || {};
    const caption = asString(data.metin) || asString(data.caption);
    const fromAnalysis = [
        ...asStringArray(analysis.hashtags),
        ...asStringArray(analysis.captionTags),
        ...extractHashtagsFromCaption(caption),
    ];
    const fromRoot = asStringArray(data.hashtags);
    const merged = [];
    const seen = new Map();
    for (const raw of fromAnalysis) {
        const normalized = normalizeTag(raw);
        if (!normalized)
            continue;
        const hasHashtag = hasExplicitHash(raw);
        seen.set(normalized, (seen.get(normalized) || false) || hasHashtag);
    }
    for (const raw of fromRoot) {
        const normalized = normalizeTag(raw);
        if (!normalized)
            continue;
        // Root hashtags parametresi explicit hashtag kaynagi kabul edilir.
        seen.set(normalized, true);
    }
    for (const [tag, hasHashtag] of seen.entries()) {
        merged.push({ tag, hasHashtag });
    }
    return merged;
}
async function upsertDoc(doc) {
    await ensurePostsCollection();
    const baseUrl = getTypesenseBaseUrl();
    try {
        await axios_1.default.post(`${baseUrl}/collections/${POSTS_COLLECTION}/documents?action=upsert`, doc, {
            headers: headers(),
            timeout: 8000,
        });
    }
    catch (err) {
        console.error("typesense_upsert_post_failed", err?.response?.status, err?.response?.data || err?.message);
        throw err;
    }
}
async function deleteDoc(postId) {
    await ensurePostsCollection();
    const baseUrl = getTypesenseBaseUrl();
    try {
        await axios_1.default.delete(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/${encodeURIComponent(postId)}`, {
            headers: headers(),
            timeout: 8000,
        });
    }
    catch (err) {
        const status = err?.response?.status;
        if (status !== 404)
            throw err;
    }
}
async function upsertTagDocs(postId, authorId, createdAtTs, tags) {
    if (!tags.length)
        return;
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    for (const entry of tags) {
        const tag = normalizeTag(entry.tag);
        if (!tag)
            continue;
        const hasHashtag = entry.hasHashtag === true;
        await axios_1.default.post(`${baseUrl}/collections/${TAGS_COLLECTION}/documents?action=upsert`, {
            id: `${tag}__${postId}`,
            docType: "post",
            tag,
            postId,
            authorId,
            hasHashtag,
            createdAtTs,
        }, { headers: headers(), timeout: 8000 });
    }
}
async function deleteTagDocs(postId, tags) {
    if (!tags.length)
        return;
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    for (const tagRaw of tags) {
        const tag = normalizeTag(tagRaw);
        if (!tag)
            continue;
        try {
            await axios_1.default.delete(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/${encodeURIComponent(`${tag}__${postId}`)}`, { headers: headers(), timeout: 8000 });
        }
        catch (err) {
            const status = err?.response?.status;
            if (status !== 404)
                throw err;
        }
    }
}
function buildUserSearchDoc(userId, data) {
    const createdDateRaw = Number(data.createdDate || 0);
    const createdDateTs = Number.isFinite(createdDateRaw) && createdDateRaw > 0
        ? Math.floor(createdDateRaw / 1000)
        : 0;
    const accountStatus = asString(data.accountStatus).toLowerCase();
    const isPendingOrDeleted = accountStatus === "pending_deletion" || accountStatus === "deleted";
    return {
        id: userId,
        nickname: asString(data.nickname) || asString(data.username),
        firstName: asString(data.firstName),
        lastName: asString(data.lastName),
        pfImage: asString(data.pfImage) || asString(data.avatarUrl) || asString(data.profileImageUrl),
        rozet: asString(data.rozet),
        gizliHesap: asBool(data.gizliHesap),
        deletedAccount: asBool(data.deletedAccount) || asBool(data.isDeleted) || isPendingOrDeleted,
        hesapOnayi: asBool(data.hesapOnayi) || asBool(data.isVerified),
        updatedAtTs: asEpochSeconds(data.updatedAt) ||
            asEpochSeconds(data.createdAt) ||
            createdDateTs ||
            Math.floor(Date.now() / 1000),
    };
}
function shouldIndexUser(doc) {
    return true;
}
async function upsertUserDoc(doc) {
    await ensureUsersCollection();
    const baseUrl = getTypesenseBaseUrl();
    await axios_1.default.post(`${baseUrl}/collections/${USERS_COLLECTION}/documents?action=upsert`, doc, {
        headers: headers(),
        timeout: 8000,
    });
}
async function deleteUserDoc(userId) {
    await ensureUsersCollection();
    const baseUrl = getTypesenseBaseUrl();
    try {
        await axios_1.default.delete(`${baseUrl}/collections/${USERS_COLLECTION}/documents/${encodeURIComponent(userId)}`, {
            headers: headers(),
            timeout: 8000,
        });
    }
    catch (err) {
        const status = err?.response?.status;
        if (status !== 404)
            throw err;
    }
}
async function searchPostsFromTypesense(q, limit, page) {
    await ensurePostsCollection();
    const baseUrl = getTypesenseBaseUrl();
    const resp = await axios_1.default.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 10000,
        params: {
            q,
            query_by: "caption,hashtags,mentions",
            per_page: limit,
            page,
            sort_by: "timeStamp:desc",
            filter_by: "paylasGizliligi:=0 && arsiv:=false && deletedPost:=false && gizlendi:=false && isUploading:=false",
            prefix: "true,true,true",
            typo_tokens_threshold: 1,
        },
    });
    const body = resp.data || {};
    const hits = Array.isArray(body.hits) ? body.hits : [];
    return {
        q,
        page,
        limit,
        found: Number(body.found || 0),
        out_of: Number(body.out_of || 0),
        search_time_ms: Number(body.search_time_ms || 0),
        hits: hits.map((h) => ({
            id: h?.document?.id,
            authorId: h?.document?.authorId,
            caption: h?.document?.caption,
            hashtags: h?.document?.hashtags || [],
            mentions: h?.document?.mentions || [],
            hlsUrl: h?.document?.hlsUrl || "",
            hlsThumbnailUrl: h?.document?.hlsThumbnailUrl || "",
            rawVideoUrl: h?.document?.rawVideoUrl || "",
            imageURL: h?.document?.imageURL || "",
            previewUrl: h?.document?.previewUrl || "",
            timeStamp: h?.document?.timeStamp || 0,
            text_match: h?.text_match || 0,
        })),
    };
}
async function getLatestPostIdsFromTypesense(limit, page) {
    await ensurePostsCollection();
    const baseUrl = getTypesenseBaseUrl();
    const resp = await axios_1.default.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 10000,
        params: {
            q: "*",
            query_by: "caption",
            per_page: limit,
            page,
            sort_by: "timeStamp:desc",
            filter_by: "paylasGizliligi:=0 && arsiv:=false && deletedPost:=false && gizlendi:=false && isUploading:=false",
        },
    });
    const body = resp.data || {};
    const hits = Array.isArray(body.hits) ? body.hits : [];
    return {
        page,
        limit,
        found: Number(body.found || 0),
        out_of: Number(body.out_of || 0),
        search_time_ms: Number(body.search_time_ms || 0),
        hits: hits
            .map((h) => ({
            postId: String(h?.document?.id || ""),
            timeStamp: Number(h?.document?.timeStamp || 0),
        }))
            .filter((x) => !!x.postId),
    };
}
async function searchUsersFromTypesense(q, limit, page) {
    await ensureUsersCollection();
    const baseUrl = getTypesenseBaseUrl();
    const resp = await axios_1.default.get(`${baseUrl}/collections/${USERS_COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 10000,
        params: {
            q,
            query_by: "nickname,firstName,lastName",
            per_page: limit,
            page,
            sort_by: "updatedAtTs:desc",
            filter_by: "deletedAccount:=false && gizliHesap:=false",
            prefix: "true,true,true",
            typo_tokens_threshold: 1,
        },
    });
    const body = resp.data || {};
    const hits = Array.isArray(body.hits) ? body.hits : [];
    return {
        q,
        page,
        limit,
        found: Number(body.found || 0),
        out_of: Number(body.out_of || 0),
        search_time_ms: Number(body.search_time_ms || 0),
        hits: hits.map((h) => ({
            id: h?.document?.id,
            nickname: h?.document?.nickname || "",
            firstName: h?.document?.firstName || "",
            lastName: h?.document?.lastName || "",
            pfImage: h?.document?.pfImage || "",
            rozet: h?.document?.rozet || "",
            gizliHesap: h?.document?.gizliHesap === true,
            deletedAccount: h?.document?.deletedAccount === true,
            hesapOnayi: h?.document?.hesapOnayi === true,
            text_match: h?.text_match || 0,
        })),
    };
}
async function searchTagsFromTypesense(q, limit, page) {
    // Build tags from hashtag arrays inside posts_search.
    const base = await searchPostsFromTypesense(q, Math.max(limit * 5, 100), page);
    const normalizedQuery = q.toLocaleLowerCase("tr-TR");
    const counts = new Map();
    for (const hit of base.hits) {
        const hashtags = Array.isArray(hit.hashtags) ? hit.hashtags : [];
        for (const tagRaw of hashtags) {
            const tag = String(tagRaw || "").trim().toLocaleLowerCase("tr-TR");
            if (!tag)
                continue;
            if (!tag.startsWith(normalizedQuery))
                continue;
            counts.set(tag, (counts.get(tag) || 0) + 1);
        }
    }
    const tags = Array.from(counts.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit)
        .map(([tag, count]) => ({ tag, count }));
    return {
        q,
        page,
        limit,
        found: tags.length,
        out_of: tags.length,
        search_time_ms: base.search_time_ms,
        hits: tags,
    };
}
exports.f14_syncPostsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "Posts/{postId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady()) {
        console.log("Typesense env missing, skipping sync.");
        return;
    }
    const postId = event.params.postId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const beforeDoc = beforeData ? buildSearchDoc(postId, beforeData) : null;
    const afterDoc = afterData ? buildSearchDoc(postId, afterData) : null;
    const beforeIndexed = !!beforeDoc && shouldIndex(beforeDoc);
    const afterIndexed = !!afterDoc && shouldIndex(afterDoc);
    const beforeTagEntries = beforeIndexed && beforeData ? extractPostTags(beforeData) : [];
    const afterTagEntries = afterIndexed && afterData ? extractPostTags(afterData) : [];
    const beforeTags = beforeTagEntries.map((x) => x.tag);
    const afterTags = afterTagEntries.map((x) => x.tag);
    if (!afterData || !afterIndexed || !afterDoc) {
        await deleteDoc(postId);
        if (beforeTags.length)
            await deleteTagDocs(postId, beforeTags);
        return;
    }
    await upsertDoc(afterDoc);
    const beforeSet = new Set(beforeTags);
    const afterSet = new Set(afterTags);
    const toDelete = beforeTags.filter((t) => !afterSet.has(t));
    const beforeHashtagMap = new Map(beforeTagEntries.map((x) => [x.tag, x.hasHashtag]));
    const toUpsertEntries = afterTagEntries.filter((entry) => {
        if (!beforeSet.has(entry.tag))
            return true;
        return beforeHashtagMap.get(entry.tag) !== entry.hasHashtag;
    });
    if (toDelete.length)
        await deleteTagDocs(postId, toDelete);
    if (toUpsertEntries.length) {
        await upsertTagDocs(postId, afterDoc.authorId || "", Number(afterDoc.timeStamp || Date.now()), toUpsertEntries);
    }
});
const f14_syncUsersToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "users/{userId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady()) {
        console.log("Typesense env missing, skipping user sync.");
        return;
    }
    const userId = event.params.userId;
    const afterData = event.data?.after?.data();
    if (!afterData) {
        await deleteUserDoc(userId);
        return;
    }
    const doc = buildUserSearchDoc(userId, afterData);
    if (!shouldIndexUser(doc)) {
        await deleteUserDoc(userId);
        return;
    }
    await upsertUserDoc(doc);
});
exports.f14_searchPosts = (0, https_1.onRequest)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
    }
    if (req.method !== "GET") {
        res.status(405).json({ error: "method_not_allowed" });
        return;
    }
    if (!typesenseReady()) {
        res.status(503).json({ error: "typesense_not_configured" });
        return;
    }
    const q = String(req.query.q || "").trim();
    if (q.length < 2) {
        res.status(400).json({ error: "query_too_short", minLength: 2 });
        return;
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(req.query.limit || 20)));
    const page = Math.max(1, Number(req.query.page || 1));
    try {
        res.json(await searchPostsFromTypesense(q, limit, page));
    }
    catch (err) {
        const status = err?.response?.status || 500;
        const detail = err?.response?.data || err?.message || "unknown_error";
        res.status(status).json({ error: "typesense_search_failed", detail });
    }
});
exports.f14_searchPostsCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const q = String(request.data?.q || "").trim();
    if (q.length < 2) {
        throw new https_1.HttpsError("invalid-argument", "query_too_short");
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    try {
        return await searchPostsFromTypesense(q, limit, page);
    }
    catch (err) {
        const detail = err?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
const f14_searchUsersCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const q = String(request.data?.q || "").trim();
    if (q.length < 2) {
        throw new https_1.HttpsError("invalid-argument", "query_too_short");
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    try {
        return await searchUsersFromTypesense(q, limit, page);
    }
    catch (err) {
        const detail = err?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
const f14_searchTagsCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const q = String(request.data?.q || "").trim().toLocaleLowerCase("tr-TR");
    if (q.length < 1) {
        throw new https_1.HttpsError("invalid-argument", "query_too_short");
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    try {
        return await searchTagsFromTypesense(q, limit, page);
    }
    catch (err) {
        const detail = err?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
exports.f14_reindexPostsToTypesenseCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    ensureAdmin();
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
    const cursor = String(request.data?.cursor || "").trim();
    const dryRun = request.data?.dryRun === true;
    const db = (0, firestore_2.getFirestore)();
    let q = db.collection("Posts").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
    if (cursor)
        q = q.startAfter(cursor);
    const snap = await q.get();
    let scanned = 0;
    let upserted = 0;
    let deleted = 0;
    let skipped = 0;
    for (const docSnap of snap.docs) {
        scanned += 1;
        const postId = docSnap.id;
        const data = docSnap.data();
        const doc = buildSearchDoc(postId, data);
        const tags = extractPostTags(data);
        if (!shouldIndex(doc)) {
            if (!dryRun) {
                await deleteDoc(postId);
                if (tags.length)
                    await deleteTagDocs(postId, tags.map((x) => x.tag));
            }
            deleted += 1;
            continue;
        }
        if (!doc.caption && (!doc.hashtags || doc.hashtags.length === 0)) {
            skipped += 1;
            continue;
        }
        if (!dryRun) {
            await upsertDoc(doc);
            if (tags.length) {
                await upsertTagDocs(postId, doc.authorId || "", Number(doc.timeStamp || Date.now()), tags);
            }
        }
        upserted += 1;
    }
    const last = snap.docs[snap.docs.length - 1];
    const nextCursor = last ? last.id : null;
    const done = snap.docs.length < limit;
    return { scanned, upserted, deleted, skipped, nextCursor, done };
});
exports.f15_getLatestPostIdsCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    try {
        return await getLatestPostIdsFromTypesense(limit, page);
    }
    catch (err) {
        const detail = err?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
//# sourceMappingURL=14_typesensePosts.js.map