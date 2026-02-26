"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f15_reindexUsersToTypesenseScheduled = exports.f15_reindexUsersToTypesenseCallable = exports.f15_syncUsersToTypesense = exports.f15_getTrendingTagsCallable = exports.f15_getPostIdsByTagCallable = exports.f15_searchTagsCallable = exports.f15_searchUsersCallable = exports.f14_syncUsersToTypesense = exports.f15_syncTagsToTypesense = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
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
            const required = [
                { name: "count", type: "int32", optional: true },
                { name: "lastSeenTs", type: "int64", optional: true },
                { name: "hasHashtag", type: "bool", optional: true },
                { name: "hashtagCount", type: "int32", optional: true },
                { name: "plainCount", type: "int32", optional: true },
            ];
            const missing = required.filter((rf) => !fields.some((f) => f?.name === rf.name));
            if (missing.length) {
                await axios_1.default.patch(`${baseUrl}/collections/${TAGS_COLLECTION}`, {
                    fields: missing,
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
                { name: "tag", type: "string" },
                { name: "authorId", type: "string", optional: true },
                { name: "count", type: "int32", optional: true },
                { name: "lastSeenTs", type: "int64", optional: true },
                { name: "hasHashtag", type: "bool", optional: true },
                { name: "hashtagCount", type: "int32", optional: true },
                { name: "plainCount", type: "int32", optional: true },
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
        hashtags: asStringArray(analysis.hashtags),
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
async function upsertDoc(doc) {
    await ensurePostsCollection();
    const baseUrl = getTypesenseBaseUrl();
    await axios_1.default.post(`${baseUrl}/collections/${POSTS_COLLECTION}/documents?action=upsert`, doc, {
        headers: headers(),
        timeout: 8000,
    });
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
function buildUserSearchDoc(userId, data) {
    const createdDateRaw = Number(data.createdDate || 0);
    const createdDateTs = Number.isFinite(createdDateRaw) && createdDateRaw > 0
        ? Math.floor(createdDateRaw / 1000)
        : 0;
    return {
        id: userId,
        nickname: asString(data.nickname) || asString(data.username),
        firstName: asString(data.firstName),
        lastName: asString(data.lastName),
        pfImage: asString(data.pfImage) || asString(data.avatarUrl) || asString(data.profileImageUrl),
        rozet: asString(data.rozet),
        gizliHesap: asBool(data.gizliHesap),
        deletedAccount: asBool(data.deletedAccount) || asBool(data.isDeleted),
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
function normalizeTag(raw) {
    const t = String(raw || "").trim().toLocaleLowerCase("tr-TR");
    if (!t)
        return "";
    return t.startsWith("#") ? t.slice(1) : t;
}
function buildTagAggregateDoc(tagId, data) {
    const tag = normalizeTag(asString(data.name) || tagId);
    const count = Math.max(0, Number(data.count || 0) || 0);
    const lastSeenTs = asEpochMillis(data.lastSeenAt) || Date.now();
    const hashtagCount = Math.max(0, Number(data.hashtagCount || 0) || 0);
    const plainCount = Math.max(0, Number(data.plainCount || 0) || Math.max(0, count - hashtagCount));
    return {
        id: `agg__${tag}`,
        tag,
        count,
        lastSeenTs,
        hasHashtag: hashtagCount > 0 || data.hasHashtag === true,
        hashtagCount,
        plainCount,
        createdAtTs: lastSeenTs,
    };
}
async function upsertTagAggregateDoc(doc) {
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    await axios_1.default.post(`${baseUrl}/collections/${TAGS_COLLECTION}/documents?action=upsert`, doc, {
        headers: headers(),
        timeout: 8000,
    });
}
async function deleteTagAggregateDoc(tagId, rawName) {
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    const normalized = normalizeTag(rawName || tagId);
    if (!normalized)
        return;
    try {
        await axios_1.default.delete(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/${encodeURIComponent(`agg__${normalized}`)}`, {
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
async function upsertUserDoc(doc) {
    await ensureUsersCollection();
    const baseUrl = getTypesenseBaseUrl();
    try {
        await axios_1.default.post(`${baseUrl}/collections/${USERS_COLLECTION}/documents?action=upsert`, doc, {
            headers: headers(),
            timeout: 8000,
        });
    }
    catch (err) {
        console.error("typesense_upsert_user_failed", err?.response?.status, err?.response?.data || err?.message);
        throw err;
    }
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
        hits: hits
            .filter((h) => h?.document?.deletedAccount !== true && h?.document?.gizliHesap !== true)
            .map((h) => ({
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
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    const normalizedQuery = String(q || "").trim().toLocaleLowerCase("tr-TR").replace(/^#/, "");
    const perPage = Math.max(20, Math.min(250, limit));
    const resp = await axios_1.default.get(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 10000,
        params: {
            q: normalizedQuery,
            query_by: "tag",
            per_page: perPage,
            page,
            prefix: "true",
            sort_by: "count:desc,lastSeenTs:desc",
            filter_by: "count:>=1",
            typo_tokens_threshold: 1,
        },
    });
    const body = resp.data || {};
    const hits = Array.isArray(body.hits) ? body.hits : [];
    const tags = hits
        .map((h) => {
        const tag = String(h?.document?.tag || "").trim().toLocaleLowerCase("tr-TR");
        const count = Math.max(0, Number(h?.document?.count || 0) || 0);
        const lastSeenTs = Math.max(0, Number(h?.document?.lastSeenTs || 0) || 0);
        const hashtagCount = Math.max(0, Number(h?.document?.hashtagCount || 0) || 0);
        const hasHashtag = h?.document?.hasHashtag === true || hashtagCount > 0;
        return { tag, count, lastSeenTs, hasHashtag };
    })
        .filter((item) => !!item.tag)
        .filter((item) => !normalizedQuery || item.tag.startsWith(normalizedQuery))
        .sort((a, b) => {
        if (a.hasHashtag !== b.hasHashtag)
            return a.hasHashtag ? -1 : 1;
        if (b.count !== a.count)
            return b.count - a.count;
        return b.lastSeenTs - a.lastSeenTs;
    })
        .slice(0, limit)
        .map(({ tag, count, hasHashtag, lastSeenTs }) => ({ tag, count, hasHashtag, lastSeenTs }));
    return {
        q,
        page,
        limit,
        found: Number(body.found || tags.length),
        out_of: Number(body.out_of || tags.length),
        search_time_ms: Number(body.search_time_ms || 0),
        hits: tags,
    };
}
async function getTrendingTagsFromTypesense(limit, windowHours, trendThreshold, tagMinLength, tagMaxLength) {
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    const nowTs = Date.now();
    const safeWindowHours = Math.max(1, Math.min(24 * 14, windowHours));
    const cutoffTs = nowTs - safeWindowHours * 3600 * 1000;
    const perPage = Math.max(100, Math.min(500, limit * 12));
    const safeThreshold = Math.max(1, trendThreshold);
    const safeMinLength = Math.max(1, tagMinLength);
    const safeMaxLength = Math.max(safeMinLength, tagMaxLength);
    const resp = await axios_1.default.get(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 10000,
        params: {
            q: "*",
            query_by: "tag",
            per_page: perPage,
            page: 1,
            sort_by: "count:desc,lastSeenTs:desc",
            filter_by: `count:>=${safeThreshold} && lastSeenTs:>=${cutoffTs}`,
        },
    });
    const body = resp.data || {};
    const hits = Array.isArray(body.hits) ? body.hits : [];
    const tags = hits
        .map((h) => ({
        tag: String(h?.document?.tag || "").trim().toLocaleLowerCase("tr-TR"),
        count: Math.max(0, Number(h?.document?.count || 0) || 0),
        hasHashtag: h?.document?.hasHashtag === true ||
            Math.max(0, Number(h?.document?.hashtagCount || 0) || 0) > 0,
        lastSeenTs: Math.max(0, Number(h?.document?.lastSeenTs || 0) || 0),
        hashtagCount: Math.max(0, Number(h?.document?.hashtagCount || 0) || 0),
        plainCount: Math.max(0, Number(h?.document?.plainCount || 0) || 0),
    }))
        .filter((item) => !!item.tag)
        .filter((item) => item.count >= safeThreshold &&
        item.tag.length >= safeMinLength &&
        item.tag.length <= safeMaxLength &&
        item.lastSeenTs >= cutoffTs)
        .sort((a, b) => {
        if (a.hasHashtag !== b.hasHashtag)
            return a.hasHashtag ? -1 : 1;
        if (b.count !== a.count)
            return b.count - a.count;
        return b.lastSeenTs - a.lastSeenTs;
    })
        .slice(0, limit);
    return {
        limit,
        window_hours: safeWindowHours,
        trend_threshold: safeThreshold,
        tag_min_length: safeMinLength,
        tag_max_length: safeMaxLength,
        found: tags.length,
        out_of: Number(body.found || hits.length),
        search_time_ms: Number(body.search_time_ms || 0),
        hits: tags,
    };
}
const f14_syncPostsToTypesense = (0, firestore_1.onDocumentWritten)({
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
    const afterData = event.data?.after?.data();
    if (!afterData) {
        await deleteDoc(postId);
        return;
    }
    const doc = buildSearchDoc(postId, afterData);
    if (!shouldIndex(doc)) {
        await deleteDoc(postId);
        return;
    }
    await upsertDoc(doc);
});
exports.f15_syncTagsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "tags/{tagId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady()) {
        console.log("Typesense env missing, skipping tag sync.");
        return;
    }
    const tagId = String(event.params.tagId || "").trim();
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    if (!afterData) {
        await deleteTagAggregateDoc(tagId, asString(beforeData?.name));
        return;
    }
    const doc = buildTagAggregateDoc(tagId, afterData);
    if (!doc.tag)
        return;
    await upsertTagAggregateDoc(doc);
});
exports.f14_syncUsersToTypesense = (0, firestore_1.onDocumentWritten)({
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
const f14_searchPosts = (0, https_1.onRequest)({
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
const f14_searchPostsCallable = (0, https_1.onCall)({
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
exports.f15_searchUsersCallable = (0, https_1.onCall)({
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
exports.f15_searchTagsCallable = (0, https_1.onCall)({
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
exports.f15_getPostIdsByTagCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const rawTag = String(request.data?.tag || request.data?.q || "").trim().toLocaleLowerCase("tr-TR");
    const tag = rawTag.startsWith("#") ? rawTag.slice(1) : rawTag;
    if (tag.length < 1) {
        throw new https_1.HttpsError("invalid-argument", "query_too_short");
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    await ensureTagsCollection();
    const baseUrl = getTypesenseBaseUrl();
    try {
        const resp = await axios_1.default.get(`${baseUrl}/collections/${TAGS_COLLECTION}/documents/search`, {
            headers: headers(),
            timeout: 10000,
            params: {
                q: "*",
                query_by: "tag",
                per_page: limit,
                page,
                sort_by: "timeStamp:desc",
                filter_by: `tag:=${tag}`,
            },
        });
        const body = resp.data || {};
        const hits = Array.isArray(body.hits) ? body.hits : [];
        const postHits = hits.map((h) => ({
            postId: String(h?.document?.postId || ""),
            timeStamp: Number(h?.document?.timeStamp || 0),
        })).filter((x) => !!x.postId);
        // Fallback: if tags_search has only aggregate docs for this tag, resolve post ids from posts_search.
        if (postHits.length === 0) {
            const postsResp = await axios_1.default.get(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`, {
                headers: headers(),
                timeout: 10000,
                params: {
                    q: tag,
                    query_by: "hashtags",
                    per_page: limit,
                    page,
                    sort_by: "timeStamp:desc",
                    filter_by: "paylasGizliligi:=0 && arsiv:=false && deletedPost:=false && gizlendi:=false && isUploading:=false",
                    prefix: "true",
                    typo_tokens_threshold: 1,
                },
            });
            const postsBody = postsResp.data || {};
            const postsHits = Array.isArray(postsBody.hits) ? postsBody.hits : [];
            for (const h of postsHits) {
                const postId = String(h?.document?.id || "").trim();
                if (!postId)
                    continue;
                postHits.push({
                    postId,
                    timeStamp: Number(h?.document?.timeStamp || 0),
                });
            }
        }
        // Shuffle to randomize listing order for the selected tag.
        for (let i = postHits.length - 1; i > 0; i -= 1) {
            const j = Math.floor(Math.random() * (i + 1));
            const tmp = postHits[i];
            postHits[i] = postHits[j];
            postHits[j] = tmp;
        }
        return {
            tag,
            page,
            limit,
            found: Number(body.found || 0),
            out_of: Number(body.out_of || 0),
            search_time_ms: Number(body.search_time_ms || 0),
            hits: postHits,
        };
    }
    catch (err) {
        const detail = err?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
exports.f15_getTrendingTagsCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 30)));
    const db = (0, firestore_2.getFirestore)();
    const settingsSnap = await db.collection("adminConfig").doc("tagSettings").get();
    const settings = settingsSnap.data() || {};
    const windowHoursDefault = Number(settings.trendWindowHours || 24);
    const trendThresholdDefault = Number(settings.trendThreshold || 1);
    const tagMinLengthDefault = Number(settings.tagMinLength || 1);
    const tagMaxLengthDefault = Number(settings.tagMaxLength || 64);
    const windowHours = Math.max(1, Math.min(24 * 14, Number(request.data?.windowHours || windowHoursDefault)));
    const trendThreshold = Math.max(1, Number(request.data?.trendThreshold || trendThresholdDefault));
    const tagMinLength = Math.max(1, Number(request.data?.tagMinLength || tagMinLengthDefault));
    const tagMaxLength = Math.max(tagMinLength, Number(request.data?.tagMaxLength || tagMaxLengthDefault));
    try {
        return await getTrendingTagsFromTypesense(limit, windowHours, trendThreshold, tagMinLength, tagMaxLength);
    }
    catch (err) {
        const detail = err?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
// New numbered names (15_*).
exports.f15_syncUsersToTypesense = exports.f14_syncUsersToTypesense;
exports.f15_reindexUsersToTypesenseCallable = (0, https_1.onCall)({
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
    let q = db.collection("users").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
    if (cursor)
        q = q.startAfter(cursor);
    const snap = await q.get();
    let scanned = 0;
    let upserted = 0;
    let skipped = 0;
    for (const docSnap of snap.docs) {
        scanned += 1;
        const doc = buildUserSearchDoc(docSnap.id, docSnap.data());
        if (!shouldIndexUser(doc)) {
            skipped += 1;
            continue;
        }
        if (!dryRun) {
            await upsertUserDoc(doc);
        }
        upserted += 1;
    }
    const last = snap.docs[snap.docs.length - 1];
    const nextCursor = last ? last.id : null;
    const done = snap.docs.length < limit;
    return { scanned, upserted, skipped, nextCursor, done };
});
exports.f15_reindexUsersToTypesenseScheduled = (0, scheduler_1.onSchedule)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    schedule: "every 5 minutes",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async () => {
    ensureAdmin();
    if (!typesenseReady()) {
        console.log("Typesense env missing, skipping scheduled reindex.");
        return;
    }
    const db = (0, firestore_2.getFirestore)();
    const stateRef = db.collection("adminConfig").doc("typesenseUsersReindex");
    const stateSnap = await stateRef.get();
    const state = (stateSnap.data() || {});
    const cursor = String(state.cursor || "").trim();
    const batchSize = 300;
    let q = db.collection("users").orderBy(firestore_2.FieldPath.documentId()).limit(batchSize);
    if (cursor)
        q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) {
        await stateRef.set({
            cursor: "",
            doneAt: Date.now(),
            done: true,
        }, { merge: true });
        console.log("typesense_users_reindex_scheduled_done");
        return;
    }
    let scanned = 0;
    let upserted = 0;
    let skipped = 0;
    for (const docSnap of snap.docs) {
        scanned += 1;
        const doc = buildUserSearchDoc(docSnap.id, docSnap.data());
        if (!shouldIndexUser(doc)) {
            skipped += 1;
            continue;
        }
        await upsertUserDoc(doc);
        upserted += 1;
    }
    const last = snap.docs[snap.docs.length - 1];
    const done = snap.docs.length < batchSize;
    await stateRef.set({
        cursor: done ? "" : (last?.id || ""),
        lastRunAt: Date.now(),
        done,
        scanned,
        upserted,
        skipped,
    }, { merge: true });
    console.log("typesense_users_reindex_scheduled_progress", {
        scanned,
        upserted,
        skipped,
        done,
        nextCursor: done ? "" : (last?.id || ""),
    });
});
//# sourceMappingURL=15_typesenseUsersTags.js.map