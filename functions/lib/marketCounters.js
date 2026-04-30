"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.backfillMarketCounters = exports.aggregateMarketViewShards = exports.recordMarketViewBatch = exports.onMarketReviewWrite = exports.onMarketOfferCreate = exports.onMarketFavoriteDelete = exports.onMarketFavoriteCreate = void 0;
exports.parseRecordMarketViewBatchRequest = parseRecordMarketViewBatchRequest;
exports.computeMarketReviewAggregatePatch = computeMarketReviewAggregatePatch;
exports.computeMarketBackfillSnapshot = computeMarketBackfillSnapshot;
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const rateLimiter_1 = require("./rateLimiter");
const adminAccess_1 = require("./adminAccess");
const REGION = "europe-west1";
const MARKET_COUNTER_VERSION = 1;
const MARKET_VIEW_SHARD_COUNT = 5;
const MAX_VIEW_BATCH_ITEMS = 50;
const MAX_VIEW_BATCH_COUNT = 20;
const MAX_BACKFILL_LIMIT = 100;
function ensureApp() {
    if ((0, app_1.getApps)().length === 0) {
        (0, app_1.initializeApp)();
    }
}
function db() {
    ensureApp();
    return (0, firestore_2.getFirestore)();
}
function asString(raw) {
    return String(raw ?? "").trim();
}
function asNonNegativeInt(raw) {
    const parsed = Number(raw);
    if (!Number.isFinite(parsed))
        return 0;
    return Math.max(0, Math.trunc(parsed));
}
function asPositiveRating(raw) {
    const value = asNonNegativeInt(raw);
    if (value < 1 || value > 5)
        return 0;
    return value;
}
function round1(raw) {
    return Math.round(raw * 10) / 10;
}
function requireAuth(request) {
    const uid = asString(request.auth?.uid);
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    return uid;
}
async function requireAdminAuth(request) {
    return await (0, adminAccess_1.requireCallableAdminUid)(request.auth, db());
}
function parseRecordMarketViewBatchRequest(data, request) {
    requireAuth(request);
    const payload = data && typeof data === "object" && !Array.isArray(data)
        ? data
        : {};
    const rawItems = Array.isArray(payload.items) ? payload.items : [];
    if (rawItems.length === 0 || rawItems.length > MAX_VIEW_BATCH_ITEMS) {
        throw new https_1.HttpsError("invalid-argument", "items_out_of_range");
    }
    const items = rawItems
        .map((raw) => {
        const item = raw && typeof raw === "object" && !Array.isArray(raw)
            ? raw
            : {};
        return {
            itemId: asString(item.itemId),
            count: Math.max(1, Math.min(MAX_VIEW_BATCH_COUNT, asNonNegativeInt(item.count || 1) || 1)),
        };
    })
        .filter((item) => item.itemId.length > 0);
    if (items.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "items_required");
    }
    return items;
}
function computeMarketReviewAggregatePatch(input) {
    const nextReviewCount = Math.max(0, input.currentReviewCount +
        (input.beforeRating == null && input.afterRating != null ? 1 : 0) -
        (input.beforeRating != null && input.afterRating == null ? 1 : 0));
    const nextRatingTotal = Math.max(0, input.currentRatingTotal - (input.beforeRating ?? 0) + (input.afterRating ?? 0));
    return {
        reviewCount: nextReviewCount,
        ratingTotal: nextRatingTotal,
        averageRating: nextReviewCount == 0 ? null : round1(nextRatingTotal / nextReviewCount),
    };
}
function computeMarketBackfillSnapshot(input) {
    const ratingTotal = input.reviewRatings.reduce((sum, value) => sum + asPositiveRating(value), 0);
    const reviewCount = input.reviewRatings.filter((value) => asPositiveRating(value) > 0)
        .length;
    const lastOfferAt = input.offerCreatedAts.reduce((current, value) => Math.max(current, asNonNegativeInt(value)), 0);
    return {
        viewCount: asNonNegativeInt(input.currentViewCount),
        favoriteCount: asNonNegativeInt(input.favoriteCount),
        offerCount: input.offerCreatedAts.length,
        reviewCount,
        ratingTotal,
        averageRating: reviewCount == 0 ? null : round1(ratingTotal / reviewCount),
        lastOfferAt,
    };
}
function parseMarketBackfillRequest(data) {
    const payload = data && typeof data === "object" && !Array.isArray(data)
        ? data
        : {};
    return {
        itemId: asString(payload.itemId),
        startAfterId: asString(payload.startAfterId),
        limit: Math.max(1, Math.min(MAX_BACKFILL_LIMIT, asNonNegativeInt(payload.limit || 25) || 25)),
    };
}
async function setExistingMarketItem(itemRef, patch) {
    await db().runTransaction(async (transaction) => {
        const itemSnap = await transaction.get(itemRef);
        if (!itemSnap.exists)
            return;
        transaction.set(itemRef, patch, { merge: true });
    });
}
function marketItemRef(itemId) {
    return db().collection("marketStore").doc(itemId);
}
exports.onMarketFavoriteCreate = (0, firestore_1.onDocumentCreated)({
    document: "marketStore/{itemId}/favorites/{favoriteId}",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (event) => {
    const itemId = asString(event.params.itemId);
    if (!itemId)
        return;
    await setExistingMarketItem(marketItemRef(itemId), {
        favoriteCount: firestore_2.FieldValue.increment(1),
        _serverCounters: { version: MARKET_COUNTER_VERSION },
    });
});
exports.onMarketFavoriteDelete = (0, firestore_1.onDocumentDeleted)({
    document: "marketStore/{itemId}/favorites/{favoriteId}",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (event) => {
    const itemId = asString(event.params.itemId);
    if (!itemId)
        return;
    await setExistingMarketItem(marketItemRef(itemId), {
        favoriteCount: firestore_2.FieldValue.increment(-1),
        _serverCounters: { version: MARKET_COUNTER_VERSION },
    });
});
exports.onMarketOfferCreate = (0, firestore_1.onDocumentCreated)({
    document: "marketStore/{itemId}/offers/{offerId}",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (event) => {
    const itemId = asString(event.params.itemId);
    if (!itemId)
        return;
    const createdAt = asNonNegativeInt(event.data?.data()?.createdAt);
    const itemRef = marketItemRef(itemId);
    await db().runTransaction(async (transaction) => {
        const itemSnap = await transaction.get(itemRef);
        if (!itemSnap.exists)
            return;
        const currentLastOfferAt = asNonNegativeInt(itemSnap.get("lastOfferAt"));
        transaction.set(itemRef, {
            offerCount: firestore_2.FieldValue.increment(1),
            lastOfferAt: Math.max(currentLastOfferAt, createdAt),
            _serverCounters: { version: MARKET_COUNTER_VERSION },
        }, { merge: true });
    });
});
exports.onMarketReviewWrite = (0, firestore_1.onDocumentWritten)({
    document: "marketStore/{itemId}/Reviews/{reviewerId}",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (event) => {
    const itemId = asString(event.params.itemId);
    if (!itemId)
        return;
    const beforeRating = event.data?.before?.exists
        ? asPositiveRating(event.data.before.data()?.rating)
        : 0;
    const afterRating = event.data?.after?.exists
        ? asPositiveRating(event.data.after.data()?.rating)
        : 0;
    const patchSource = {
        beforeRating: beforeRating > 0 ? beforeRating : null,
        afterRating: afterRating > 0 ? afterRating : null,
    };
    const itemRef = marketItemRef(itemId);
    await db().runTransaction(async (transaction) => {
        const itemSnap = await transaction.get(itemRef);
        if (!itemSnap.exists)
            return;
        const currentReviewCount = asNonNegativeInt(itemSnap.get("reviewCount"));
        const currentRatingTotal = asNonNegativeInt(itemSnap.get("_serverCounters.ratingTotal"));
        const next = computeMarketReviewAggregatePatch({
            currentReviewCount,
            currentRatingTotal,
            beforeRating: patchSource.beforeRating,
            afterRating: patchSource.afterRating,
        });
        transaction.set(itemRef, {
            reviewCount: next.reviewCount,
            averageRating: next.averageRating,
            _serverCounters: {
                ratingTotal: next.ratingTotal,
                version: MARKET_COUNTER_VERSION,
            },
        }, { merge: true });
    });
});
exports.recordMarketViewBatch = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
}, async (request) => {
    const uid = requireAuth(request);
    rateLimiter_1.RateLimits.general(uid);
    const items = parseRecordMarketViewBatchRequest(request.data, request);
    const firestore = db();
    const uniqueItemIds = [...new Set(items.map((item) => item.itemId))];
    const refs = uniqueItemIds.map((itemId) => marketItemRef(itemId));
    const snaps = refs.length > 0 ? await firestore.getAll(...refs) : [];
    const existingIds = new Set(snaps.filter((snap) => snap.exists).map((snap) => snap.id));
    let processed = 0;
    const batch = firestore.batch();
    const updatedAt = firestore_2.Timestamp.fromMillis(Date.now());
    for (const item of items) {
        if (!existingIds.has(item.itemId))
            continue;
        const shardId = String(Math.floor(Math.random() * MARKET_VIEW_SHARD_COUNT));
        batch.set(marketItemRef(item.itemId).collection("_viewShards").doc(shardId), {
            viewCount: firestore_2.FieldValue.increment(item.count),
            updatedAt,
        }, { merge: true });
        processed += 1;
    }
    if (processed > 0) {
        await batch.commit();
    }
    return {
        ok: true,
        processed,
        requested: items.length,
    };
});
exports.aggregateMarketViewShards = (0, scheduler_1.onSchedule)({
    region: REGION,
    timeoutSeconds: 300,
    memory: "256MiB",
    schedule: "every 1 minutes",
}, async () => {
    const firestore = db();
    const cutoff = firestore_2.Timestamp.fromMillis(Date.now() - 70 * 1000);
    const dirtySnap = await firestore
        .collectionGroup("_viewShards")
        .where("updatedAt", ">=", cutoff)
        .limit(500)
        .get();
    if (dirtySnap.empty) {
        console.log("aggregateMarketViewShards no_dirty_shards");
        return;
    }
    const totals = new Map();
    for (const doc of dirtySnap.docs) {
        const itemRef = doc.ref.parent.parent;
        if (!itemRef)
            continue;
        const itemId = itemRef.id;
        const delta = asNonNegativeInt(doc.get("viewCount"));
        const current = totals.get(itemId) || {
            itemRef,
            delta: 0,
            shardRefs: [],
        };
        current.delta += delta;
        current.shardRefs.push(doc.ref);
        totals.set(itemId, current);
    }
    const itemRefs = [...totals.values()].map((entry) => entry.itemRef);
    const itemSnaps = itemRefs.length > 0 ? await firestore.getAll(...itemRefs) : [];
    const existingIds = new Set(itemSnaps.filter((snap) => snap.exists).map((snap) => snap.id));
    const batch = firestore.batch();
    let processedShards = 0;
    for (const [itemId, entry] of totals.entries()) {
        if (existingIds.has(itemId) && entry.delta > 0) {
            batch.set(entry.itemRef, {
                viewCount: firestore_2.FieldValue.increment(entry.delta),
                _serverCounters: { version: MARKET_COUNTER_VERSION },
            }, { merge: true });
        }
        for (const shardRef of entry.shardRefs) {
            if (existingIds.has(itemId)) {
                batch.set(shardRef, {
                    viewCount: 0,
                    updatedAt: firestore_2.Timestamp.fromMillis(0),
                }, { merge: true });
            }
            else {
                batch.delete(shardRef);
            }
            processedShards += 1;
        }
    }
    await batch.commit();
    console.log("aggregateMarketViewShards applied", {
        processedItems: totals.size,
        processedShards,
    });
});
exports.backfillMarketCounters = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
}, async (request) => {
    await requireAdminAuth(request);
    const firestore = db();
    const parsed = parseMarketBackfillRequest(request.data);
    const now = Date.now();
    let itemDocs = [];
    if (parsed.itemId) {
        itemDocs = [await marketItemRef(parsed.itemId).get()].filter((snap) => snap.exists);
    }
    else {
        let query = firestore
            .collection("marketStore")
            .orderBy(firestore_2.FieldPath.documentId())
            .limit(parsed.limit);
        if (parsed.startAfterId) {
            query = query.startAfter(parsed.startAfterId);
        }
        const snap = await query.get();
        itemDocs = snap.docs;
    }
    let processed = 0;
    let nextCursor = null;
    for (const itemDoc of itemDocs) {
        if (!itemDoc.exists)
            continue;
        const itemData = itemDoc.data() || {};
        const [favoriteSnap, offerSnap, reviewSnap] = await Promise.all([
            itemDoc.ref.collection("favorites").get(),
            itemDoc.ref.collection("offers").get(),
            itemDoc.ref.collection("Reviews").get(),
        ]);
        const snapshot = computeMarketBackfillSnapshot({
            currentViewCount: asNonNegativeInt(itemData.viewCount),
            favoriteCount: favoriteSnap.size,
            offerCreatedAts: offerSnap.docs.map((doc) => asNonNegativeInt(doc.get("createdAt"))),
            reviewRatings: reviewSnap.docs.map((doc) => asPositiveRating(doc.get("rating"))),
        });
        await itemDoc.ref.set({
            favoriteCount: snapshot.favoriteCount,
            offerCount: snapshot.offerCount,
            reviewCount: snapshot.reviewCount,
            averageRating: snapshot.averageRating,
            lastOfferAt: snapshot.lastOfferAt,
            viewCount: snapshot.viewCount,
            _serverCounters: {
                ratingTotal: snapshot.ratingTotal,
                backfilledAt: now,
                version: MARKET_COUNTER_VERSION,
            },
        }, { merge: true });
        processed += 1;
        nextCursor = itemDoc.id;
    }
    return {
        ok: true,
        processed,
        nextCursor,
        done: parsed.itemId.length > 0 || processed < parsed.limit,
    };
});
//# sourceMappingURL=marketCounters.js.map