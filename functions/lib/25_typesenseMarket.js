"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.f25_reindexMarketToTypesenseCallable = exports.f25_searchMarketCallable = exports.f25_ensureMarketTypesenseCollectionCallable = exports.f25_syncMarketToTypesense = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const axios_1 = require("axios");
const rateLimiter_1 = require("./rateLimiter");
__exportStar(require("./marketCounters"), exports);
const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const COLLECTION = "market_search_v3";
const MAX_LIMIT = 100;
const MAX_FLATTEN_DEPTH = 4;
const MAX_FLATTEN_VALUES = 200;
const MAX_TEXT_LEN = 12000;
function ensureAdmin() {
    if ((0, app_1.getApps)().length === 0)
        (0, app_1.initializeApp)();
}
function requireAuth(request) {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    return uid;
}
function resolveRateLimitSubject(request) {
    const authUid = request.auth?.uid?.trim();
    if (authUid)
        return `uid:${authUid}`;
    const rawRequest = request.rawRequest;
    const ipHeader = rawRequest?.headers?.["cf-connecting-ip"] ?? rawRequest?.headers?.["x-forwarded-for"];
    const headerValue = Array.isArray(ipHeader) ? String(ipHeader[0] || "").trim() : String(ipHeader || "").trim();
    const ip = headerValue.length > 0 ? headerValue.split(",")[0].trim() : String(rawRequest?.ip || "").trim();
    if (ip)
        return `ip:${ip}`;
    return "guest:unknown";
}
function requireAdminAuth(request) {
    const uid = requireAuth(request);
    const token = request.auth?.token;
    if (token?.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "admin_required");
    }
    rateLimiter_1.RateLimits.admin(uid);
    return uid;
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
function asString(value) {
    return typeof value === "string" ? value.trim() : "";
}
function asStringArray(value) {
    if (!Array.isArray(value))
        return [];
    const out = new Set();
    for (const item of value) {
        const clean = String(item ?? "").trim();
        if (clean)
            out.add(clean);
    }
    return Array.from(out);
}
function firstString(value) {
    return asStringArray(value)[0] || "";
}
function asNumber(value) {
    if (typeof value === "number" && Number.isFinite(value))
        return value;
    if (typeof value === "string") {
        const parsed = Number(value);
        if (Number.isFinite(parsed))
            return parsed;
    }
    return 0;
}
function asEpochMillis(value) {
    if (typeof value === "number" && Number.isFinite(value)) {
        return value > 1e12 ? Math.floor(value) : Math.floor(value * 1000);
    }
    if (typeof value === "string") {
        const parsed = Number(value);
        if (Number.isFinite(parsed)) {
            return parsed > 1e12 ? Math.floor(parsed) : Math.floor(parsed * 1000);
        }
    }
    if (typeof value === "object" && value !== null) {
        const maybe = value;
        if (typeof maybe.toMillis === "function") {
            const millis = maybe.toMillis();
            if (Number.isFinite(millis))
                return Math.floor(millis);
        }
        if (typeof maybe.seconds === "number")
            return Math.floor(maybe.seconds * 1000);
        if (typeof maybe._seconds === "number")
            return Math.floor(maybe._seconds * 1000);
    }
    return 0;
}
function truncateText(value, maxLen) {
    return value.length <= maxLen ? value : value.slice(0, maxLen);
}
function dedupe(values) {
    const out = new Set();
    for (const value of values) {
        const clean = value.trim();
        if (clean)
            out.add(clean);
    }
    return Array.from(out);
}
function normalizeSlugText(value) {
    return value.replace(/[\/_-]+/g, " ").replace(/\s+/g, " ").trim();
}
function flattenForText(value, out, depth = 0) {
    if (depth > MAX_FLATTEN_DEPTH || out.length >= MAX_FLATTEN_VALUES)
        return;
    if (value === null || value === undefined)
        return;
    if (typeof value === "string") {
        const clean = value.trim();
        if (clean)
            out.push(clean);
        return;
    }
    if (typeof value === "number" || typeof value === "boolean") {
        out.push(String(value));
        return;
    }
    if (Array.isArray(value)) {
        for (const item of value.slice(0, 20)) {
            flattenForText(item, out, depth + 1);
            if (out.length >= MAX_FLATTEN_VALUES)
                return;
        }
        return;
    }
    if (typeof value === "object") {
        const entries = Object.entries(value).slice(0, 80);
        for (const [key, nested] of entries) {
            const cleanKey = key.trim();
            if (cleanKey)
                out.push(cleanKey);
            flattenForText(nested, out, depth + 1);
            if (out.length >= MAX_FLATTEN_VALUES)
                return;
        }
    }
}
function buildAttributesText(value) {
    const flattened = [];
    flattenForText(value, flattened);
    return truncateText(dedupe(flattened).join(" "), 8000);
}
function joinSearchText(parts) {
    const merged = dedupe(parts
        .flatMap((part) => Array.isArray(part) ? part : [part])
        .map((part) => part.trim())
        .filter((part) => part.length > 0));
    return truncateText(merged.join(" "), MAX_TEXT_LEN);
}
function isActiveMarketDoc(data) {
    const status = asString(data.status).toLowerCase();
    return status === "active";
}
function requiredFields() {
    return [
        { name: "docId", type: "string", optional: true },
        { name: "userId", type: "string", optional: true },
        { name: "title", type: "string", optional: true },
        { name: "description", type: "string", optional: true },
        { name: "categoryKey", type: "string", optional: true },
        { name: "categoryLabel", type: "string", optional: true },
        { name: "categoryPath", type: "string[]", optional: true },
        { name: "city", type: "string", optional: true },
        { name: "district", type: "string", optional: true },
        { name: "locationText", type: "string", optional: true },
        { name: "sellerName", type: "string", optional: true },
        { name: "sellerUsername", type: "string", optional: true },
        { name: "sellerPhotoUrl", type: "string", optional: true },
        { name: "sellerRozet", type: "string", optional: true },
        { name: "sellerPhoneNumber", type: "string", optional: true },
        { name: "showPhone", type: "bool", optional: true },
        { name: "cover", type: "string", optional: true },
        { name: "imageUrls", type: "string[]", optional: true },
        { name: "price", type: "float", optional: true },
        { name: "currency", type: "string", optional: true },
        { name: "favoriteCount", type: "int32", optional: true },
        { name: "offerCount", type: "int32", optional: true },
        { name: "viewCount", type: "int32", optional: true },
        { name: "publishedAt", type: "int64", optional: false },
        { name: "createdAt", type: "int64", optional: false },
        { name: "active", type: "bool", optional: true },
        { name: "contactPreference", type: "string", optional: true },
        { name: "status", type: "string", optional: true },
        { name: "attributesJson", type: "string", optional: true },
        { name: "attributesText", type: "string", optional: true },
        { name: "searchText", type: "string", optional: true },
    ];
}
let ensureCollectionPromise;
async function ensureMarketCollection() {
    if (ensureCollectionPromise)
        return ensureCollectionPromise;
    ensureCollectionPromise = (async () => {
        const baseUrl = getTypesenseBaseUrl();
        if (!baseUrl)
            return;
        try {
            const existing = await axios_1.default.get(`${baseUrl}/collections/${COLLECTION}`, {
                headers: headers(),
                timeout: 8000,
            });
            const fields = Array.isArray(existing.data?.fields)
                ? existing.data.fields
                : [];
            const missing = requiredFields().filter((field) => !fields.some((current) => current?.name === field.name));
            if (missing.length > 0) {
                await axios_1.default.patch(`${baseUrl}/collections/${COLLECTION}`, { fields: missing }, { headers: headers(), timeout: 8000 });
            }
            return;
        }
        catch (err) {
            const status = err?.response?.status;
            if (status !== 404)
                throw err;
        }
        await axios_1.default.post(`${baseUrl}/collections`, {
            name: COLLECTION,
            fields: requiredFields(),
            default_sorting_field: "publishedAt",
        }, { headers: headers(), timeout: 8000 });
    })().catch((err) => {
        ensureCollectionPromise = undefined;
        throw err;
    });
    return ensureCollectionPromise;
}
async function upsertDoc(doc) {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl)
        return;
    await ensureMarketCollection();
    await axios_1.default.post(`${baseUrl}/collections/${COLLECTION}/documents?action=upsert`, doc, { headers: headers(), timeout: 12000 });
}
async function deleteDoc(docId) {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl)
        return;
    await ensureMarketCollection();
    try {
        await axios_1.default.delete(`${baseUrl}/collections/${COLLECTION}/documents/${encodeURIComponent(docId)}`, { headers: headers(), timeout: 12000 });
    }
    catch (err) {
        const status = err?.response?.status;
        if (status === 404)
            return;
        throw err;
    }
}
function buildSearchDoc(docId, data) {
    const seller = (data.seller && typeof data.seller === "object")
        ? data.seller
        : {};
    const categoryPath = asStringArray(data.categoryPath);
    const categoryKey = asString(data.categoryKey);
    const categoryLabel = categoryPath.length > 0 ? categoryPath[categoryPath.length - 1] : "";
    const imageUrls = asStringArray(data.imageUrls);
    const attributesText = buildAttributesText(data.attributes);
    const attributesJson = truncateText(JSON.stringify(data.attributes || {}), 12000);
    const createdAt = asEpochMillis(data.createdAt) || Date.now();
    const publishedAt = asEpochMillis(data.publishedAt) || createdAt;
    const title = asString(data.title);
    const description = asString(data.description);
    const city = asString(data.city);
    const district = asString(data.district);
    const locationText = asString(data.locationText);
    const sellerName = asString(seller.displayName) || asString(seller.name) || asString(data.sellerDisplayName) || asString(data.sellerName);
    const sellerUsername = asString(seller.nickname) || asString(seller.username) || asString(data.sellerNickname) || asString(data.sellerUsername);
    const sellerPhotoUrl = asString(seller.avatarUrl) || asString(seller.photoUrl) || asString(data.sellerAvatarUrl) || asString(data.sellerPhotoUrl);
    const sellerRozet = asString(seller.rozet) || asString(data.sellerRozet);
    const sellerPhoneNumber = asString(seller.phoneNumber) || asString(data.sellerPhoneNumber);
    const showPhone = data.showPhone === true || (asString(data.contactPreference) === "phone");
    const cover = asString(data.coverImageUrl) || firstString(data.imageUrls);
    const status = asString(data.status) || "draft";
    return {
        id: docId,
        docId,
        userId: asString(data.userId),
        title,
        description,
        categoryKey,
        categoryLabel,
        categoryPath,
        city,
        district,
        locationText,
        sellerName,
        sellerUsername,
        sellerPhotoUrl,
        sellerRozet,
        sellerPhoneNumber,
        showPhone,
        cover,
        imageUrls,
        price: Math.max(0, asNumber(data.price)),
        currency: asString(data.currency) || "TRY",
        favoriteCount: Math.max(0, Math.floor(asNumber(data.favoriteCount))),
        offerCount: Math.max(0, Math.floor(asNumber(data.offerCount))),
        viewCount: Math.max(0, Math.floor(asNumber(data.viewCount))),
        publishedAt,
        createdAt,
        active: isActiveMarketDoc(data),
        contactPreference: asString(data.contactPreference) || "message_only",
        status,
        attributesJson,
        attributesText,
        searchText: joinSearchText([
            title,
            description,
            normalizeSlugText(categoryKey),
            categoryLabel,
            categoryPath,
            city,
            district,
            locationText,
            sellerName,
            sellerUsername,
            sellerRozet,
            attributesText,
        ]),
    };
}
function shouldIndex(doc) {
    return doc.active && doc.title.trim().length > 0;
}
function marketDocsEqual(left, right) {
    if (!left || !right)
        return false;
    return JSON.stringify(left) === JSON.stringify(right);
}
async function syncMarketDoc(docId, beforeData, afterData) {
    const beforeDoc = beforeData ? buildSearchDoc(docId, beforeData) : null;
    const afterDoc = afterData ? buildSearchDoc(docId, afterData) : null;
    const beforeIndexed = !!beforeDoc && shouldIndex(beforeDoc);
    const afterIndexed = !!afterDoc && shouldIndex(afterDoc);
    if (!afterData) {
        if (!beforeIndexed) {
            return;
        }
        await deleteDoc(docId);
        return;
    }
    if (!afterIndexed || !afterDoc) {
        if (!beforeIndexed) {
            return;
        }
        await deleteDoc(docId);
        return;
    }
    if (beforeIndexed && marketDocsEqual(beforeDoc, afterDoc)) {
        return;
    }
    await upsertDoc(afterDoc);
}
function quoteFilterValue(value) {
    return `\`${value.replace(/`/g, "\\`")}\``;
}
function buildFilterBy(input) {
    const filters = ["active:=true"];
    const docId = asString(input.docId);
    const docIds = asStringArray(input.docIds);
    const userId = asString(input.userId);
    const categoryKey = asString(input.categoryKey);
    const city = asString(input.city);
    const district = asString(input.district);
    if (docId)
        filters.push(`docId:=${quoteFilterValue(docId)}`);
    if (!docId && docIds.length) {
        filters.push(`docId:=[${docIds.map(quoteFilterValue).join(",")}]`);
    }
    if (userId)
        filters.push(`userId:=${quoteFilterValue(userId)}`);
    if (categoryKey)
        filters.push(`categoryKey:=${quoteFilterValue(categoryKey)}`);
    if (city)
        filters.push(`city:=${quoteFilterValue(city)}`);
    if (district)
        filters.push(`district:=${quoteFilterValue(district)}`);
    return filters.join(" && ");
}
function toHitOutput(hitRaw) {
    const hit = (hitRaw && typeof hitRaw === "object")
        ? hitRaw
        : {};
    const doc = (hit.document && typeof hit.document === "object")
        ? hit.document
        : {};
    return {
        id: String(doc.id || doc.docId || ""),
        docId: String(doc.docId || doc.id || ""),
        userId: String(doc.userId || ""),
        title: String(doc.title || ""),
        description: String(doc.description || ""),
        categoryKey: String(doc.categoryKey || ""),
        categoryLabel: String(doc.categoryLabel || ""),
        categoryPath: asStringArray(doc.categoryPath),
        city: String(doc.city || ""),
        district: String(doc.district || ""),
        locationText: String(doc.locationText || ""),
        sellerName: String(doc.sellerName || ""),
        sellerUsername: String(doc.sellerUsername || ""),
        sellerPhotoUrl: String(doc.sellerPhotoUrl || ""),
        sellerRozet: String(doc.sellerRozet || ""),
        sellerPhoneNumber: String(doc.sellerPhoneNumber || ""),
        showPhone: doc.showPhone === true,
        cover: String(doc.cover || ""),
        imageUrls: asStringArray(doc.imageUrls),
        price: Number(doc.price || 0),
        currency: String(doc.currency || "TRY"),
        favoriteCount: Number(doc.favoriteCount || 0),
        offerCount: Number(doc.offerCount || 0),
        viewCount: Number(doc.viewCount || 0),
        publishedAt: Number(doc.publishedAt || 0),
        createdAt: Number(doc.createdAt || 0),
        active: doc.active === true,
        status: String(doc.status || ""),
        attributesJson: String(doc.attributesJson || ""),
        score: Number(hit.text_match || 0),
    };
}
async function searchMarketFromTypesense(input) {
    const baseUrl = getTypesenseBaseUrl();
    const q = asString(input.q) || "*";
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(input.limit || 20)));
    const page = Math.max(1, Number(input.page || 1));
    const queryFields = [
        "title",
        "description",
        "categoryLabel",
        "categoryPath",
        "categoryKey",
        "city",
        "district",
        "locationText",
        "sellerName",
        "sellerUsername",
        "sellerRozet",
        "attributesText",
        "searchText",
    ];
    await ensureMarketCollection();
    const response = await axios_1.default.get(`${baseUrl}/collections/${COLLECTION}/documents/search`, {
        headers: headers(),
        timeout: 12000,
        params: {
            q,
            query_by: queryFields.join(","),
            per_page: limit,
            page,
            sort_by: q === "*" ? "publishedAt:desc" : "_text_match:desc,publishedAt:desc",
            filter_by: buildFilterBy(input),
            prefix: new Array(queryFields.length).fill("true").join(","),
            num_typos: 2,
            exhaustive_search: true,
        },
    });
    const data = response.data || {};
    const rawHits = Array.isArray(data.hits) ? data.hits : [];
    const hits = rawHits.map((item) => toHitOutput(item));
    return {
        hits,
        found: Number(data.found || hits.length),
        outOf: Number(data.out_of || hits.length),
        searchTimeMs: Number(data.search_time_ms || 0),
    };
}
function marketQuery(limit, cursor) {
    let query = (0, firestore_2.getFirestore)()
        .collection("marketStore")
        .orderBy(firestore_2.FieldPath.documentId())
        .limit(limit);
    if (cursor)
        query = query.startAfter(cursor);
    return query;
}
exports.f25_syncMarketToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "marketStore/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    await syncMarketDoc(docId, beforeData, afterData);
});
exports.f25_ensureMarketTypesenseCollectionCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    ensureAdmin();
    requireAdminAuth(request);
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    await ensureMarketCollection();
    return {
        ok: true,
        collection: COLLECTION,
    };
});
exports.f25_searchMarketCallable = (0, https_1.onCall)({
    region: REGION,
    invoker: "public",
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    rateLimiter_1.RateLimits.general(resolveRateLimitSubject(request));
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    try {
        const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
        const page = Math.max(1, Number(request.data?.page || 1));
        const result = await searchMarketFromTypesense({
            q: request.data?.q,
            limit,
            page,
            docId: request.data?.docId,
            docIds: Array.isArray(request.data?.docIds) ? request.data?.docIds : undefined,
            userId: request.data?.userId,
            categoryKey: request.data?.categoryKey,
            city: request.data?.city,
            district: request.data?.district,
        });
        return {
            q: asString(request.data?.q) || "*",
            page,
            limit,
            found: result.found,
            out_of: result.outOf,
            search_time_ms: result.searchTimeMs,
            hits: result.hits,
        };
    }
    catch (err) {
        const axiosErr = err;
        const detail = axiosErr?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
exports.f25_reindexMarketToTypesenseCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    ensureAdmin();
    requireAdminAuth(request);
    try {
        if (!typesenseReady()) {
            throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
        }
        const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
        const cursor = String(request.data?.cursor || "").trim();
        const dryRun = request.data?.dryRun === true;
        await ensureMarketCollection();
        const snap = await marketQuery(limit, cursor).get();
        let scanned = 0;
        let upserted = 0;
        let deleted = 0;
        let skipped = 0;
        for (const docSnap of snap.docs) {
            scanned += 1;
            const docId = docSnap.id;
            const data = docSnap.data();
            const doc = buildSearchDoc(docId, data);
            if (!shouldIndex(doc)) {
                if (!dryRun) {
                    await deleteDoc(docId);
                }
                deleted += 1;
                continue;
            }
            if (!doc.title.trim()) {
                skipped += 1;
                continue;
            }
            if (!dryRun) {
                await upsertDoc(doc);
            }
            upserted += 1;
        }
        const last = snap.docs[snap.docs.length - 1];
        const nextCursor = last ? last.id : null;
        const done = snap.docs.length < limit;
        return {
            scanned,
            upserted,
            deleted,
            skipped,
            nextCursor,
            done,
        };
    }
    catch (err) {
        const axiosErr = err;
        const detail = axiosErr?.response?.data || err?.message || "unknown_error";
        console.error("f25_reindex_market_failed", {
            detail,
            cursor: request.data?.cursor || null,
        });
        throw new https_1.HttpsError("internal", "typesense_reindex_failed", detail);
    }
});
//# sourceMappingURL=25_typesenseMarket.js.map