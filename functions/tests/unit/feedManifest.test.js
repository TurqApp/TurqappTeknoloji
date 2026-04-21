const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildFeedManifestItems,
  buildFeedManifestSlot,
  istanbulSlotRangeForDateHour,
  resolveFeedManifestSlotForNow,
  rollingFeedManifestDates,
} = require("../../lib/29_feedManifest.js");

function validCandidate(id, userID = "user-a", overrides = {}) {
  return {
    id,
    userID,
    authorNickname: `nick_${userID}`,
    authorDisplayName: `User ${userID}`,
    authorAvatarUrl: `https://cdn.turqapp.com/${userID}.webp`,
    rozet: "Mavi",
    metin: "caption",
    thumbnail: `https://cdn.turqapp.com/${id}.jpg`,
    img: [`https://cdn.turqapp.com/${id}_alt.jpg`],
    video: "",
    hlsMasterUrl: `https://cdn.turqapp.com/Posts/${id}/hls/master.m3u8`,
    hlsStatus: "ready",
    hasPlayableVideo: true,
    aspectRatio: 0.5625,
    timeStamp: 1776710000000,
    createdAtTs: 1776710000000,
    shortId: id,
    shortUrl: `https://turqapp.com/p/${id}`,
    likeCount: 10,
    commentCount: 2,
    savedCount: 1,
    retryCount: 0,
    statsCount: 100,
    paylasGizliligi: 0,
    deletedPost: false,
    gizlendi: false,
    arsiv: false,
    isUploading: false,
    flood: false,
    floodCount: 1,
    mainFlood: "",
    contentType: "video",
    ...overrides,
  };
}

test("feed manifest keeps self-contained cards, flood roots, and share short urls", () => {
  const items = buildFeedManifestItems(
    [
      validCandidate("ok-1", "user-a"),
      validCandidate("flood-root", "user-b", { floodCount: 4 }),
      validCandidate("flood-child_1", "user-b", {
        flood: true,
        mainFlood: "flood-root",
      }),
      validCandidate("hidden", "user-c", { gizlendi: true }),
      validCandidate("missing-avatar", "user-d", { authorAvatarUrl: "" }),
      validCandidate("fallback-short", "user-e", { shortUrl: "", shortId: "" }),
    ],
    {
      seed: "feed_2026-04-21_slot_00",
      maxItems: 20,
    },
  );

  assert.deepEqual(
    items.map((item) => item.docId).sort(),
    ["fallback-short", "flood-root", "ok-1"],
  );
  assert.equal(
    items.find((item) => item.docId === "flood-root").canonicalId,
    "flood-root",
  );
  assert.equal(
    items.find((item) => item.docId === "fallback-short").shortUrl,
    "https://turqapp.com/p/fallback-short",
  );
  assert.equal(new Set(items.map((item) => item.canonicalId)).size, items.length);
});

test("feed manifest dedupes by canonical flood root", () => {
  const items = buildFeedManifestItems(
    [
      validCandidate("thread-root", "user-a", { floodCount: 3, likeCount: 100 }),
      validCandidate("thread-root_1", "user-b", {
        flood: true,
        mainFlood: "thread-root",
        likeCount: 1000,
      }),
      validCandidate("normal", "user-c", { likeCount: 10 }),
    ],
    {
      seed: "canonical-test",
      maxItems: 10,
    },
  );

  assert.deepEqual(
    items.map((item) => item.docId).sort(),
    ["normal", "thread-root"],
  );
});

test("feed manifest applies per-user cap before overflow", () => {
  const items = buildFeedManifestItems(
    [
      validCandidate("a-1", "user-a", { likeCount: 100 }),
      validCandidate("a-2", "user-a", { likeCount: 90 }),
      validCandidate("a-3", "user-a", { likeCount: 80 }),
      validCandidate("b-1", "user-b", { likeCount: 70 }),
    ],
    {
      seed: "user-cap-test",
      maxItems: 3,
      maxPerUser: 2,
    },
  );

  assert.deepEqual(
    items.map((item) => item.docId),
    ["a-1", "a-2", "b-1"],
  );
});

test("feed manifest slot uses 3-hour Istanbul windows", () => {
  const nowMs = Date.parse("2026-04-21T14:10:00.000+03:00");
  assert.deepEqual(resolveFeedManifestSlotForNow(nowMs), {
    date: "2026-04-21",
    slotHour: 12,
  });

  const range = istanbulSlotRangeForDateHour("2026-04-21", 13);
  assert.equal(range.startMs, Date.parse("2026-04-21T12:00:00.000+03:00"));
  assert.equal(range.endMs, Date.parse("2026-04-21T14:59:59.999+03:00"));

  assert.deepEqual(rollingFeedManifestDates(nowMs), [
    "2026-04-21",
    "2026-04-20",
    "2026-04-19",
  ]);
});

test("feed manifest slot payload path identity is stable", () => {
  const items = buildFeedManifestItems(
    Array.from({ length: 3 }, (_, index) =>
      validCandidate(`doc-${index + 1}`, `user-${index + 1}`),
    ),
    {
      seed: "slot",
      maxItems: 3,
    },
  );
  const slot = buildFeedManifestSlot({
    date: "2026-04-21",
    slotHour: 6,
    manifestId: "feed_2026-04-21_slot_06_v1",
    generatedAt: 1776720000000,
    validFromMs: Date.parse("2026-04-21T06:00:00.000+03:00"),
    validToMs: Date.parse("2026-04-21T08:59:59.999+03:00"),
    items,
  });

  assert.equal(slot.slotId, "slot_06");
  assert.equal(slot.slotHour, 6);
  assert.equal(slot.itemCount, 3);
});
