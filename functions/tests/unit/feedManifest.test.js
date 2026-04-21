const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildFeedManifestItems,
  buildFeedManifestActiveIndex,
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

test("feed manifest keeps the strongest candidate for the same canonical id", () => {
  const items = buildFeedManifestItems(
    [
      validCandidate("thread-root_1", "user-a", {
        likeCount: 5,
        commentCount: 0,
        savedCount: 0,
        statsCount: 20,
      }),
      validCandidate("thread-root", "user-a", {
        likeCount: 50,
        commentCount: 10,
        savedCount: 3,
        statsCount: 500,
      }),
      validCandidate("normal", "user-b", { likeCount: 10 }),
    ],
    {
      seed: "best-canonical",
      maxItems: 10,
    },
  );

  assert.deepEqual(
    items.map((item) => item.docId),
    ["thread-root", "normal"],
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

test("feed manifest active index keeps only active non-empty slots and sorts newest first", () => {
  const active = buildFeedManifestActiveIndex({
    nowMs: Date.parse("2026-04-21T16:00:00.000+03:00"),
    publishedAt: 1776776400000,
    slots: [
      {
        date: "2026-04-20",
        slotId: "slot_21",
        slotHour: 21,
        itemCount: 120,
        generatedAt: 1776690000000,
        path: "feedManifest/2026-04-20/slots/slot_21.json",
        status: "active",
      },
      {
        date: "2026-04-21",
        slotId: "slot_03",
        slotHour: 3,
        itemCount: 0,
        generatedAt: 1776720000000,
        path: "feedManifest/2026-04-21/slots/slot_03.json",
        status: "active",
      },
      {
        date: "2026-04-21",
        slotId: "slot_12",
        slotHour: 12,
        itemCount: 200,
        generatedAt: 1776752400000,
        path: "feedManifest/2026-04-21/slots/slot_12.json",
        status: "active",
      },
      {
        date: "2026-04-21",
        slotId: "slot_21",
        slotHour: 21,
        itemCount: 180,
        generatedAt: 1776784800000,
        path: "",
        status: "active",
      },
      {
        date: "2026-04-19",
        slotId: "slot_21",
        slotHour: 21,
        itemCount: 180,
        generatedAt: 1776600000000,
        path: "feedManifest/2026-04-19/slots/slot_21.json",
        status: "draft",
      },
      {
        date: "2026-04-21",
        slotId: "slot_09",
        slotHour: 9,
        itemCount: 160,
        generatedAt: 1776741600000,
        path: "feedManifest/2026-04-21/slots/slot_09.json",
        status: "active",
      },
    ],
  });

  assert.deepEqual(
    active.slots.map((slot) => `${slot.date}:${slot.slotId}`),
    [
      "2026-04-21:slot_12",
      "2026-04-21:slot_09",
      "2026-04-20:slot_21",
    ],
  );
  assert.equal(active.manifestId, "feed_active_v1776776400000");
  assert.equal(active.itemsPerSlot, 240);
  assert.equal(active.slotHours, 3);
});

test("feed manifest order can vary by seed when scores are tied", () => {
  const candidates = [
    validCandidate("doc-a", "user-a", {
      likeCount: 10,
      commentCount: 0,
      savedCount: 0,
      statsCount: 100,
      timeStamp: 1776710000000,
    }),
    validCandidate("doc-b", "user-b", {
      likeCount: 10,
      commentCount: 0,
      savedCount: 0,
      statsCount: 100,
      timeStamp: 1776710000000,
    }),
    validCandidate("doc-c", "user-c", {
      likeCount: 10,
      commentCount: 0,
      savedCount: 0,
      statsCount: 100,
      timeStamp: 1776710000000,
    }),
  ];

  const first = buildFeedManifestItems(candidates, {
    seed: "seed-a",
    maxItems: 3,
  }).map((item) => item.docId);
  const second = buildFeedManifestItems(candidates, {
    seed: "seed-b",
    maxItems: 3,
  }).map((item) => item.docId);

  assert.notDeepEqual(first, second);
});
