const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildShortManifestItems,
  buildIndexAndSlots,
  resolveShortManifestDateForNow,
  istanbulDayRangeForDate,
} = require("../../lib/28_shortManifest.js");

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
    ...overrides,
  };
}

test("short manifest items keep only self-contained playable non-flood videos", () => {
  const items = buildShortManifestItems(
    [
      validCandidate("ok-1", "user-a"),
      validCandidate("flood-root", "user-b", { floodCount: 2 }),
      validCandidate("missing-avatar", "user-c", { authorAvatarUrl: "" }),
      validCandidate("missing-short-url", "user-d", { shortUrl: "", shortId: "" }),
      validCandidate("not-ready", "user-e", { hlsStatus: "processing" }),
      validCandidate("hidden", "user-f", { gizlendi: true }),
      validCandidate("duplicate", "user-g"),
      validCandidate("duplicate", "user-h"),
    ],
    {
      seed: "short_2026-04-21",
      maxItems: 20,
    },
  );

  assert.deepEqual(
    items.map((item) => item.docId).sort(),
    ["duplicate", "missing-short-url", "ok-1"],
  );
  assert.equal(
    items.find((item) => item.docId === "missing-short-url").shortUrl,
    "https://turqapp.com/p/missing-short-url",
  );
  assert.equal(new Set(items.map((item) => item.docId)).size, items.length);
});

test("short manifest ordering avoids adjacent same-author picks when nearby alternatives exist", () => {
  const items = buildShortManifestItems(
    [
      validCandidate("a-1", "user-a", { likeCount: 100 }),
      validCandidate("a-2", "user-a", { likeCount: 90 }),
      validCandidate("b-1", "user-b", { likeCount: 80 }),
      validCandidate("c-1", "user-c", { likeCount: 70 }),
    ],
    {
      seed: "short_2026-04-21",
      maxItems: 4,
    },
  );

  assert.deepEqual(
    items.map((item) => item.docId),
    ["a-1", "b-1", "a-2", "c-1"],
  );
});

test("short manifest slot builder keeps only full 240-item slots", () => {
  const items = Array.from({ length: 481 }, (_, index) =>
    validCandidate(`doc-${index + 1}`, `user-${index + 1}`),
  );
  const normalized = buildShortManifestItems(items, {
    seed: "slot_test",
    maxItems: 481,
  });

  const { index, slots } = buildIndexAndSlots({
    date: "2026-04-21",
    manifestId: "short_2026-04-21_v1",
    generatedAt: 1776720000000,
    items: normalized,
  });

  assert.equal(slots.length, 2);
  assert.equal(index.slotCount, 2);
  assert.equal(index.itemCount, 480);
  assert.equal(slots[0].itemCount, 240);
  assert.equal(slots[1].itemCount, 240);
  assert.equal(index.slots[0].path, "shortManifest/2026-04-21/slots/slot_001.json");
  assert.equal(index.slots[1].path, "shortManifest/2026-04-21/slots/slot_002.json");
});

test("short manifest defaults to previous Istanbul day and exact day bounds", () => {
  const nowMs = Date.parse("2026-04-21T01:10:54.036+03:00");
  assert.equal(resolveShortManifestDateForNow(nowMs), "2026-04-17");

  const range = istanbulDayRangeForDate("2026-04-17");
  assert.equal(range.startMs, Date.parse("2026-04-17T00:00:00.000+03:00"));
  assert.equal(range.endMs, Date.parse("2026-04-17T23:59:59.999+03:00"));
});
