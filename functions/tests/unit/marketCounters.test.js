const test = require("node:test");
const assert = require("node:assert/strict");

const {
  computeMarketBackfillSnapshot,
  computeMarketReviewAggregatePatch,
  parseRecordMarketViewBatchRequest,
} = require("../../lib/marketCounters.js");

test("record market view batch rejects unauthenticated requests", () => {
  assert.throws(
    () => parseRecordMarketViewBatchRequest({ items: [{ itemId: "item-1" }] }, {}),
    (error) => error?.code === "unauthenticated",
  );
});

test("record market view batch normalizes valid items", () => {
  const parsed = parseRecordMarketViewBatchRequest(
    {
      items: [
        { itemId: "item-1", count: 3 },
        { itemId: "item-2", count: 999 },
      ],
    },
    { auth: { uid: "viewer-1" } },
  );

  assert.deepEqual(parsed, [
    { itemId: "item-1", count: 3 },
    { itemId: "item-2", count: 20 },
  ]);
});

test("review aggregate patch handles create update and delete deltas", () => {
  assert.deepEqual(
    computeMarketReviewAggregatePatch({
      currentReviewCount: 0,
      currentRatingTotal: 0,
      beforeRating: null,
      afterRating: 5,
    }),
    {
      reviewCount: 1,
      ratingTotal: 5,
      averageRating: 5,
    },
  );

  assert.deepEqual(
    computeMarketReviewAggregatePatch({
      currentReviewCount: 2,
      currentRatingTotal: 7,
      beforeRating: 3,
      afterRating: 5,
    }),
    {
      reviewCount: 2,
      ratingTotal: 9,
      averageRating: 4.5,
    },
  );

  assert.deepEqual(
    computeMarketReviewAggregatePatch({
      currentReviewCount: 1,
      currentRatingTotal: 4,
      beforeRating: 4,
      afterRating: null,
    }),
    {
      reviewCount: 0,
      ratingTotal: 0,
      averageRating: null,
    },
  );
});

test("backfill snapshot derives counts and preserves current root view count", () => {
  const snapshot = computeMarketBackfillSnapshot({
    currentViewCount: 42,
    favoriteCount: 3,
    offerCreatedAts: [100, 250, 200],
    reviewRatings: [5, 4, 1],
  });

  assert.deepEqual(snapshot, {
    viewCount: 42,
    favoriteCount: 3,
    offerCount: 3,
    reviewCount: 3,
    ratingTotal: 10,
    averageRating: 3.3,
    lastOfferAt: 250,
  });
});
