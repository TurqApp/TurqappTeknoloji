#!/usr/bin/env node

const {
  buildFeedManifestActiveIndex,
  buildFeedManifestItems,
  buildFeedManifestSlot,
  istanbulSlotRangeForDateHour,
} = require("../lib/29_feedManifest.js");

function argValue(name, fallback = "") {
  const prefix = `--${name}=`;
  const match = process.argv.find((entry) => entry.startsWith(prefix));
  if (!match) return fallback;
  return match.slice(prefix.length).trim();
}

function asInt(value, fallback) {
  const parsed = Number.parseInt(String(value || "").trim(), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function sampleCandidate(id, userID, overrides = {}) {
  return {
    id,
    userID,
    authorNickname: `nick_${userID}`,
    authorDisplayName: `User ${userID}`,
    authorAvatarUrl: `https://cdn.turqapp.com/${userID}.webp`,
    rozet: "Mavi",
    metin: `sample ${id}`,
    thumbnail: `https://cdn.turqapp.com/${id}.jpg`,
    img: [`https://cdn.turqapp.com/${id}_alt.jpg`],
    video: "",
    hlsMasterUrl: `https://cdn.turqapp.com/Posts/${id}/hls/master.m3u8`,
    hlsStatus: "ready",
    hasPlayableVideo: true,
    aspectRatio: 0.5625,
    timeStamp: 0,
    createdAtTs: 0,
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

function makeCandidates({ startMs, endMs, count }) {
  const step = Math.max(1, Math.floor((endMs - startMs) / Math.max(1, count)));
  return Array.from({ length: count }, (_, index) => {
    const ts = endMs - index * step;
    return sampleCandidate(`doc-${index + 1}`, `user-${(index % 12) + 1}`, {
      timeStamp: ts,
      createdAtTs: ts,
      likeCount: 100 - (index % 40),
      commentCount: 20 - (index % 7),
      savedCount: 10 - (index % 5),
      statsCount: 500 + index * 13,
    });
  });
}

function main() {
  const nowMs = asInt(argValue("nowMs"), Date.now());
  const date = argValue("date", "2026-04-21");
  const slotHour = asInt(argValue("slotHour"), 12);
  const generatedAt = asInt(argValue("generatedAt"), nowMs);
  const count = Math.max(1, asInt(argValue("count"), 320));
  const { startMs, endMs } = istanbulSlotRangeForDateHour(date, slotHour);
  const manifestId = `feed_${date}_slot_${String(slotHour).padStart(2, "0")}_v${generatedAt}`;
  const items = buildFeedManifestItems(makeCandidates({ startMs, endMs, count }), {
    seed: manifestId,
    maxItems: 240,
    maxPerUser: 8,
  });
  const slot = buildFeedManifestSlot({
    date,
    slotHour,
    manifestId,
    generatedAt,
    validFromMs: startMs,
    validToMs: endMs,
    items,
  });
  const active = buildFeedManifestActiveIndex({
    nowMs,
    publishedAt: generatedAt,
    slots: [
      {
        date,
        slotId: slot.slotId,
        slotHour: slot.slotHour,
        itemCount: slot.itemCount,
        generatedAt,
        path: `feedManifest/${date}/slots/${slot.slotId}.json`,
        status: "active",
      },
      {
        date: "2026-04-20",
        slotId: "slot_21",
        slotHour: 21,
        itemCount: 180,
        generatedAt: generatedAt - 86400000,
        path: "feedManifest/2026-04-20/slots/slot_21.json",
        status: "active",
      },
    ],
  });

  console.log(JSON.stringify({
    input: { date, slotHour, generatedAt, count, startMs, endMs },
    slot: {
      slotId: slot.slotId,
      slotHour: slot.slotHour,
      itemCount: slot.itemCount,
      firstDocIds: slot.items.slice(0, 8).map((item) => item.docId),
      firstCanonicalIds: slot.items.slice(0, 8).map((item) => item.canonicalId),
      firstUsers: slot.items.slice(0, 8).map((item) => item.userID),
    },
    active: {
      manifestId: active.manifestId,
      slotCount: active.slots.length,
      slots: active.slots,
    },
  }, null, 2));
}

main();
