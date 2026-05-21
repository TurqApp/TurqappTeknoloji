#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const DEFAULT_POSTS_INPUT = "/Users/turqapp/Desktop/turqapp_listed_users_posts_full.json";
const DEFAULT_USERS_INPUT = "/Users/turqapp/Desktop/turqapp_curated_user_import_ready_184.json";
const DEFAULT_PLAN_OUTPUT = "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan.json";
const DEFAULT_SUMMARY_OUTPUT = "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan_summary.txt";
const DEFAULT_MAPPING_OUTPUT = "/Users/turqapp/Desktop/turqapp_curated_source_user_mapping.json";
const DEFAULT_START_DATE = "2026-05-22";
const POSTS_PER_DAY = 539;
const FIRST_MINUTE = 1;
const LAST_MINUTE = 539; // 08:59 inclusive
const TIMESTAMP_MILLISECOND_SUFFIX = 123;
const TARGET_POSTS_PER_USER = 234;
const BIN_SOFT_MAX = 252;
const SHORT_LINK_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const SHORT_LINK_DOMAIN = "turqapp.com";

function parseArgs(argv) {
  const options = {
    postsInput: DEFAULT_POSTS_INPUT,
    usersInput: DEFAULT_USERS_INPUT,
    planOutput: DEFAULT_PLAN_OUTPUT,
    summaryOutput: DEFAULT_SUMMARY_OUTPUT,
    mappingOutput: DEFAULT_MAPPING_OUTPUT,
    startDate: DEFAULT_START_DATE,
    limit: 0,
    strictFloodCount: false,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const arg = String(argv[index] || "").trim();
    if (!arg) continue;
    if (arg === "--posts") {
      options.postsInput = String(argv[index + 1] || "").trim() || options.postsInput;
      index += 1;
      continue;
    }
    if (arg === "--users") {
      options.usersInput = String(argv[index + 1] || "").trim() || options.usersInput;
      index += 1;
      continue;
    }
    if (arg === "--out") {
      options.planOutput = String(argv[index + 1] || "").trim() || options.planOutput;
      index += 1;
      continue;
    }
    if (arg === "--summary") {
      options.summaryOutput = String(argv[index + 1] || "").trim() || options.summaryOutput;
      index += 1;
      continue;
    }
    if (arg === "--mapping") {
      options.mappingOutput = String(argv[index + 1] || "").trim() || options.mappingOutput;
      index += 1;
      continue;
    }
    if (arg === "--start-date") {
      options.startDate = String(argv[index + 1] || "").trim() || options.startDate;
      index += 1;
      continue;
    }
    if (arg === "--limit") {
      options.limit = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
    if (arg === "--strict-flood-count") {
      options.strictFloodCount = true;
    }
  }

  return options;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function hashNumber(input) {
  return Number.parseInt(
    crypto.createHash("sha1").update(String(input)).digest("hex").slice(0, 8),
    16,
  );
}

function isNonFloodPost(post, strictFloodCount) {
  const floodCount = asNumber(post?.floodCount, 0);
  const aspectRatio = asNumber(post?.aspectRatio, 0);
  const metin = String(post?.metin || "").trim();
  const hasVideo = String(post?.video || post?.hlsMasterUrl || "").trim().length > 0;
  const hasImage = Array.isArray(post?.img) && post.img.length > 0;
  const hasMedia = hasVideo || hasImage || String(post?.thumbnail || "").trim().length > 0;
  if (post?.deletedPost === true || post?.arsiv === true || post?.gizlendi === true) {
    return false;
  }
  if (!Number.isFinite(aspectRatio) || aspectRatio <= 0 || aspectRatio > 4) {
    return false;
  }
  if (!metin) {
    return false;
  }
  if (!hasMedia) {
    return false;
  }
  if (hasVideo) {
    if (String(post?.hlsStatus || "") !== "ready") return false;
    if (!String(post?.hlsMasterUrl || "").trim()) return false;
  }
  if (strictFloodCount) return floodCount <= 1;
  return (
    post?.flood !== true &&
    floodCount <= 1 &&
    String(post?.mainFlood || "").trim().length === 0
  );
}

function withoutOldShortLinkFields(post) {
  const next = { ...post };
  delete next.shortId;
  delete next.shortUrl;
  delete next.shortLinkStatus;
  delete next.shortLinkUpdatedAt;
  return next;
}

function buildNewPostId(sourceDocId, index) {
  const hash = crypto
    .createHash("sha1")
    .update(`${sourceDocId}:${index}`)
    .digest("hex")
    .slice(0, 20);
  return `curated_${String(index + 1).padStart(6, "0")}_${hash}`;
}

function buildShortId(newDocID) {
  const digest = crypto.createHash("sha1").update(String(newDocID)).digest();
  let value = 0n;
  for (const byte of digest.subarray(0, 8)) {
    value = (value << 8n) + BigInt(byte);
  }
  let out = "C";
  for (let index = 0; index < 8; index += 1) {
    out += SHORT_LINK_ALPHABET[Number(value % BigInt(SHORT_LINK_ALPHABET.length))];
    value /= BigInt(SHORT_LINK_ALPHABET.length);
  }
  return out;
}

function postDocId(post, fallback = "") {
  return String(post?.docID || post?.docId || post?.id || fallback).trim();
}

function buildTimestamp(startDate, dayIndex, minuteIndex) {
  const date = new Date(`${startDate}T00:00:00.000+03:00`);
  date.setUTCDate(date.getUTCDate() + dayIndex);
  date.setUTCMinutes(date.getUTCMinutes() + minuteIndex);
  date.setUTCMilliseconds(TIMESTAMP_MILLISECOND_SUFFIX);
  return date.getTime();
}

function formatIstanbulDateTime(timestamp) {
  const date = new Date(timestamp);
  const parts = new Intl.DateTimeFormat("tr-TR", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (type) => parts.find((part) => part.type === type)?.value || "";
  return `${get("year")}-${get("month")}-${get("day")} ${get("hour")}:${get("minute")}:${get("second")}.123`;
}

function buildAuthorPatch(user) {
  const doc = user.usersPublicDoc || user.usersDoc || {};
  return {
    userID: user.uid,
    authorNickname: doc.nickname || "",
    authorDisplayName: doc.displayName || "",
    nickname: doc.nickname || "",
    username: doc.username || doc.usernameLower || doc.nickname || "",
    usernameLower: doc.usernameLower || doc.username || doc.nickname || "",
    fullName: [doc.firstName, doc.lastName].filter(Boolean).join(" ").trim(),
    displayName: doc.displayName || "",
    rozet: "Mavi",
    avatarUrl: doc.avatarUrl || "",
    authorAvatarUrl: doc.authorAvatarUrl || doc.avatarUrl || "",
    avatarType: doc.avatarType || "asset",
    avatarAsset: doc.avatarAsset || "assets/icons/default_profile_avatar.svg",
    authorAvatarAsset: doc.authorAvatarAsset || doc.avatarAsset || "assets/icons/default_profile_avatar.svg",
  };
}

function buildStatsPatch(source, newDocID, index) {
  const statsCount = 80 + (hashNumber(`${newDocID}:${index}:statsCount`) % 71);
  const sourceStats =
    source.stats && typeof source.stats === "object" && !Array.isArray(source.stats)
      ? source.stats
      : {};
  const likeCount = Math.max(
    0,
    Math.floor(asNumber(sourceStats.likeCount ?? source.likeCount, 0)),
  );
  return {
    commentCount: 0,
    likeCount,
    reportedCount: 0,
    retryCount: 0,
    savedCount: 0,
    statsCount,
  };
}

function sourceNickname(post) {
  return String(post?.nickname || post?.authorNickname || "unknown").trim() || "unknown";
}

function sourceTopic(source) {
  const value = source.toLowerCase();
  const rules = [
    [
      "tech_ai",
      [
        "digital",
        "teknoloji",
        "technology",
        "yapayzeka",
        "elektronik",
        "mucit",
        "inovasyon",
        "ioscapes",
        "neogeo",
        "stan.3dprints",
      ],
    ],
    [
      "auto_mobility",
      [
        "modifiye",
        "car",
        "otomobil",
        "fast",
        "trafik",
        "motor",
        "garaj",
        "driver",
        "formula",
        "togg",
        "bisiklet",
      ],
    ],
    [
      "art_visual",
      [
        "artist",
        "art",
        "sanat",
        "fotograf",
        "ressam",
        "viral_art",
        "creative",
        "picture",
        "colour",
        "polyfjord",
        "design",
        "dizayn",
      ],
    ],
    [
      "home_style",
      [
        "dekor",
        "stil",
        "mimar",
        "architect",
        "myhome",
        "marangoz",
      ],
    ],
    [
      "knowledge_science",
      [
        "dakika",
        "bilgi",
        "pusula",
        "anahtar",
        "bilim",
        "pratik",
        "fikir",
        "kultur",
        "fen",
        "egitim",
        "matematik",
        "zeka",
        "harita",
        "bilinmeyen",
      ],
    ],
    [
      "faith_values",
      [
        "islam",
        "kelam",
        "nasihat",
        "sancak",
        "muhammed",
        "abdullah",
        "omerfaruk",
        "berat",
      ],
    ],
    [
      "world_history_news",
      [
        "world",
        "tarih",
        "saray",
        "mevzu",
        "milli",
        "konya",
        "istanbul",
        "savunma",
        "belgesel",
        "boykot",
        "gazete",
        "banknote",
        "trtblgsl",
      ],
    ],
    [
      "entertainment_humor",
      [
        "media",
        "komedi",
        "sinema",
        "mizah",
        "kahkaha",
        "replik",
        "keyfekeder",
        "viral",
      ],
    ],
    [
      "sports",
      [
        "futbol",
        "spor",
        "sports",
        "fitness",
        "masatenisi",
        "adrenalin",
      ],
    ],
    [
      "food_cafe",
      [
        "enfes",
        "lezzet",
        "restaurant",
        "cooking",
        "latte",
        "kararinda",
        "coff",
        "eliasladerach",
      ],
    ],
    [
      "music",
      [
        "muzik",
        "music",
        "sarki",
        "klasik",
        "muzikal",
      ],
    ],
    [
      "travel_nature",
      [
        "seyyah",
        "gezgin",
        "nature",
        "visible_world",
        "garipvarlik",
        "rotasiz",
      ],
    ],
    [
      "motivation_life",
      [
        "motiv",
        "insan",
        "basari",
        "lider",
        "degisim",
        "alinti",
        "goodjob",
        "psikoloji",
        "realadamrose",
      ],
    ],
    [
      "craft_work",
      [
        "engineer",
        "technician",
        "muhendis",
        "tamir",
        "madenci",
        "winchumbo",
        "matt_swack",
        "taotaoaima",
      ],
    ],
    [
      "health_people",
      [
        "doktor",
        "klinik",
        "tgs.dr",
        "attar",
      ],
    ],
  ];

  for (const [topic, keywords] of rules) {
    if (keywords.some((keyword) => value.includes(keyword))) {
      return topic;
    }
  }
  return "general_culture";
}

function buildSourceGroups(posts) {
  const groups = new Map();
  for (const post of posts) {
    const source = sourceNickname(post);
    if (!groups.has(source)) groups.set(source, []);
    groups.get(source).push(post);
  }
  return [...groups]
    .map(([source, sourcePosts]) => ({
      source,
      topic: sourceTopic(source),
      count: sourcePosts.length,
      posts: sourcePosts,
    }))
    .sort((a, b) => b.count - a.count || a.source.localeCompare(b.source));
}

function buildSourceUnits(sourceGroups) {
  const units = [];
  for (const group of sourceGroups) {
    const splitCount = Math.max(1, Math.round(group.count / TARGET_POSTS_PER_USER));
    const weight = group.count / splitCount;
    for (let index = 0; index < splitCount; index += 1) {
      units.push({
        id: `${group.source}#${index + 1}`,
        source: group.source,
        topic: group.topic,
        weight,
        sourceTotal: group.count,
        splitIndex: index,
        splitCount,
      });
    }
  }
  return units;
}

function packTopicBins(units) {
  const byTopic = new Map();
  for (const unit of units) {
    if (!byTopic.has(unit.topic)) byTopic.set(unit.topic, []);
    byTopic.get(unit.topic).push(unit);
  }

  const bins = [];
  for (const [topic, topicUnits] of byTopic) {
    const topicBins = [];
    const ordered = [...topicUnits].sort((a, b) => b.weight - a.weight);
    for (const unit of ordered) {
      let target = null;
      for (const bin of topicBins) {
        if (bin.weight + unit.weight <= BIN_SOFT_MAX) {
          target = bin;
          break;
        }
      }
      if (!target) {
        target = { topic, weight: 0, units: [] };
        topicBins.push(target);
      }
      target.units.push(unit);
      target.weight += unit.weight;
      topicBins.sort((a, b) => a.weight - b.weight);
    }
    bins.push(...topicBins);
  }
  return bins;
}

function mergeSmallestBins(bins) {
  let best = null;
  for (let left = 0; left < bins.length; left += 1) {
    for (let right = left + 1; right < bins.length; right += 1) {
      const sameTopic = bins[left].topic === bins[right].topic;
      const score = (sameTopic ? 0 : 100000) + bins[left].weight + bins[right].weight;
      if (!best || score < best.score) best = { left, right, score };
    }
  }
  if (!best) return bins;
  const a = bins[best.left];
  const b = bins[best.right];
  const merged = {
    topic: a.topic === b.topic ? a.topic : `${a.topic}+${b.topic}`,
    weight: a.weight + b.weight,
    units: [...a.units, ...b.units],
  };
  return bins.filter((_, index) => index !== best.left && index !== best.right).concat(merged);
}

function splitLargestBin(bins) {
  const ordered = [...bins]
    .map((bin, index) => ({ bin, index }))
    .sort((a, b) => b.bin.weight - a.bin.weight);
  const target = ordered[0];
  if (!target) return bins;
  const left = { topic: target.bin.topic, weight: 0, units: [] };
  const right = { topic: target.bin.topic, weight: 0, units: [] };
  const units = [...target.bin.units].sort((a, b) => b.weight - a.weight);
  for (const unit of units) {
    const bucket = left.weight <= right.weight ? left : right;
    bucket.units.push(unit);
    bucket.weight += unit.weight;
  }
  if (right.units.length === 0) {
    const unit = left.units.pop();
    left.weight -= unit.weight;
    const halfWeight = unit.weight / 2;
    left.units.push({ ...unit, id: `${unit.id}a`, weight: halfWeight });
    left.weight += halfWeight;
    right.units.push({ ...unit, id: `${unit.id}b`, weight: halfWeight });
    right.weight += halfWeight;
  }
  return bins.filter((_, index) => index !== target.index).concat(left, right);
}

function normalizeBinCount(bins, userCount) {
  let next = [...bins];
  while (next.length > userCount) next = mergeSmallestBins(next);
  while (next.length < userCount) next = splitLargestBin(next);
  return next
    .sort((a, b) => a.topic.localeCompare(b.topic) || b.weight - a.weight)
    .map((bin, index) => ({ ...bin, id: `pool_${String(index + 1).padStart(3, "0")}` }));
}

function assignUsersToBins(bins, users) {
  return bins.map((bin, index) => ({
    ...bin,
    user: users[index],
    author: buildAuthorPatch(users[index]),
    queue: [],
    cursor: 0,
  }));
}

function assignPostsToBins(sourceGroups, bins) {
  const binsBySource = new Map();
  for (const bin of bins) {
    for (const unit of bin.units) {
      if (!binsBySource.has(unit.source)) binsBySource.set(unit.source, []);
      const list = binsBySource.get(unit.source);
      if (!list.includes(bin)) list.push(bin);
    }
  }

  for (const group of sourceGroups) {
    const sourceBins = binsBySource.get(group.source) || [];
    if (sourceBins.length === 0) {
      throw new Error(`No bin found for source ${group.source}`);
    }
    for (const post of group.posts) {
      sourceBins.sort((a, b) => a.queue.length - b.queue.length || a.id.localeCompare(b.id));
      sourceBins[0].queue.push(post);
    }
  }
}

function nextPostFromBin(bin) {
  if (bin.cursor >= bin.queue.length) return null;
  const post = bin.queue[bin.cursor];
  bin.cursor += 1;
  return post;
}

function scheduleBins(bins, totalPosts) {
  const scheduled = [];
  let dayIndex = 0;
  while (scheduled.length < totalPosts) {
    for (let slotIndex = 0; slotIndex < POSTS_PER_DAY && scheduled.length < totalPosts; slotIndex += 1) {
      const offset = dayIndex % bins.length;
      let selected = null;
      for (let probe = 0; probe < bins.length; probe += 1) {
        const bin = bins[(slotIndex + offset + probe) % bins.length];
        if (bin.cursor < bin.queue.length) {
          selected = bin;
          break;
        }
      }
      if (!selected) break;
      scheduled.push({
        bin: selected,
        source: nextPostFromBin(selected),
      });
    }
    dayIndex += 1;
  }
  return scheduled;
}

function buildMapping(bins, sourceGroups) {
  const sourceTotals = new Map(sourceGroups.map((group) => [group.source, group.count]));
  const sourceAssignments = new Map();
  for (const bin of bins) {
    for (const unit of bin.units) {
      if (!sourceAssignments.has(unit.source)) {
        sourceAssignments.set(unit.source, {
          source: unit.source,
          topic: unit.topic,
          sourcePostCount: sourceTotals.get(unit.source) || 0,
          users: [],
        });
      }
      const row = sourceAssignments.get(unit.source);
      if (!row.users.some((entry) => entry.userID === bin.user.uid)) {
        row.users.push({
          poolId: bin.id,
          userID: bin.user.uid,
          nickname: bin.author.nickname,
          estimatedPoolWeight: Math.round(bin.weight),
        });
      }
    }
  }

  return {
    generatedAt: new Date().toISOString(),
    strategy: "topic_pool_balanced",
    targetPostsPerUser: TARGET_POSTS_PER_USER,
    poolCount: bins.length,
    pools: bins.map((bin) => {
      const sourceCounts = new Map();
      for (const post of bin.queue) {
        const source = sourceNickname(post);
        sourceCounts.set(source, (sourceCounts.get(source) || 0) + 1);
      }
      return {
        poolId: bin.id,
        topic: bin.topic,
        userID: bin.user.uid,
        nickname: bin.author.nickname,
        displayName: bin.author.displayName,
        plannedPostCount: bin.queue.length,
        sources: [...sourceCounts]
          .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
          .map(([source, count]) => ({ source, count })),
      };
    }),
    sourceAssignments: [...sourceAssignments.values()]
      .sort((a, b) => b.sourcePostCount - a.sourcePostCount || a.source.localeCompare(b.source)),
  };
}

function buildPlan(posts, users, options) {
  const selected = posts.filter((post) => isNonFloodPost(post, options.strictFloodCount));
  const limited = options.limit > 0 ? selected.slice(0, options.limit) : selected;
  const sourceGroups = buildSourceGroups(limited);
  const bins = assignUsersToBins(
    normalizeBinCount(packTopicBins(buildSourceUnits(sourceGroups)), users.length),
    users,
  );
  assignPostsToBins(sourceGroups, bins);
  const scheduled = scheduleBins(bins, limited.length);
  const planned = [];
  const dailyCounts = new Map();
  const userCounts = new Map();
  const userCountsByDay = new Map();
  const topicCounts = new Map();

  for (let index = 0; index < scheduled.length; index += 1) {
    const source = scheduled[index].source;
    const bin = scheduled[index].bin;
    const dayIndex = Math.floor(index / POSTS_PER_DAY);
    const slotIndex = index % POSTS_PER_DAY;
    const minuteIndex = FIRST_MINUTE + slotIndex;
    if (minuteIndex > LAST_MINUTE) {
      throw new Error(`Invalid minute index ${minuteIndex}`);
    }
    const user = bin.user;
    const timestamp = buildTimestamp(options.startDate, dayIndex, minuteIndex);
    const dayKey = formatIstanbulDateTime(timestamp).slice(0, 10);
    const userKey = user.uid;
    const dayUserKey = `${dayKey}:${userKey}`;

    dailyCounts.set(dayKey, (dailyCounts.get(dayKey) || 0) + 1);
    userCounts.set(userKey, (userCounts.get(userKey) || 0) + 1);
    userCountsByDay.set(dayUserKey, (userCountsByDay.get(dayUserKey) || 0) + 1);
    topicCounts.set(bin.topic, (topicCounts.get(bin.topic) || 0) + 1);

    const sourceDocID = postDocId(source);
    const newDocID = buildNewPostId(sourceDocID || `post_${index}`, index);
    const statsPatch = buildStatsPatch(source, newDocID, index);
    const shortId = buildShortId(newDocID);
    const shortLinkUpdatedAt = Date.now();
    const postDoc = {
      ...withoutOldShortLinkFields(source),
      ...bin.author,
      docID: newDocID,
      docId: newDocID,
      sourcePostID: sourceDocID,
      originalPostID: source.originalPostID || sourceDocID,
      originalUserID: source.originalUserID || source.userID || "",
      flood: false,
      floodCount: 0,
      followedPostNotificationSentAt: 0,
      likeCount: statsPatch.likeCount,
      mainFlood: "",
      stats: statsPatch,
      statsCount: statsPatch.statsCount,
      timeStamp: timestamp,
      updatedAt: timestamp,
      izBirakYayinTarihi: timestamp,
      scheduledAt: 0,
      shortId,
      shortLinkStatus: "active",
      shortLinkUpdatedAt,
      shortUrl: `https://${SHORT_LINK_DOMAIN}/p/${shortId}`,
      counterOfPostsCountedAt: 0,
      counterOfPostsReconciledAt: 0,
      curatedRepost: true,
      curatedRepostSourceNickname: source.nickname || source.authorNickname || "",
      curatedTopic: bin.topic,
      curatedSourcePoolId: bin.id,
      curatedRepostPlannedAt: Date.now(),
    };

    planned.push({
      index,
      newDocID,
      sourceDocID,
      assignedUserID: user.uid,
      assignedNickname: postDoc.nickname,
      topic: bin.topic,
      sourcePoolId: bin.id,
      sourceNickname: postDoc.curatedRepostSourceNickname,
      dayIndex,
      day: dayKey,
      minute: formatIstanbulDateTime(timestamp).slice(11, 16),
      timeStamp: timestamp,
      timeStampHuman: formatIstanbulDateTime(timestamp),
      postDoc,
    });
  }

  return {
    metadata: {
      generatedAt: new Date().toISOString(),
      startDate: options.startDate,
      timezone: "Europe/Istanbul",
      timestampFormat: "unix_epoch_milliseconds_number",
      timestampMillisecondSuffix: TIMESTAMP_MILLISECOND_SUFFIX,
      firstDailyMinute: "00:01",
      lastDailyMinute: "08:59",
      postsPerDay: POSTS_PER_DAY,
      strictFloodCount: options.strictFloodCount,
      sourcePostCount: posts.length,
      selectedPostCount: selected.length,
      plannedPostCount: planned.length,
      curatedUserCount: users.length,
      sourceGroupCount: sourceGroups.length,
      sourcePoolStrategy: "topic_pool_balanced",
      targetPostsPerUser: TARGET_POSTS_PER_USER,
      requiredDayCount: Math.ceil(planned.length / POSTS_PER_DAY),
    },
    summary: {
      dailyCounts: Object.fromEntries(dailyCounts),
      userCounts: Object.fromEntries(userCounts),
      perDayUserCounts: Object.fromEntries(userCountsByDay),
      topicCounts: Object.fromEntries([...topicCounts].sort((a, b) => b[1] - a[1])),
    },
    mapping: buildMapping(bins, sourceGroups),
    posts: planned,
  };
}

function writeSummary(plan, summaryOutput) {
  const dailyCounts = Object.entries(plan.summary.dailyCounts);
  const userCounts = Object.values(plan.summary.userCounts).map(Number);
  const minUserPosts = userCounts.length ? Math.min(...userCounts) : 0;
  const maxUserPosts = userCounts.length ? Math.max(...userCounts) : 0;
  const lines = [
    `generatedAt=${plan.metadata.generatedAt}`,
    `startDate=${plan.metadata.startDate}`,
    `timezone=${plan.metadata.timezone}`,
    `timeWindow=00:01-08:59`,
    `postsPerDay=${plan.metadata.postsPerDay}`,
    `timestampFormat=${plan.metadata.timestampFormat}`,
    `timestampMillisecondSuffix=${plan.metadata.timestampMillisecondSuffix}`,
    `sourcePostCount=${plan.metadata.sourcePostCount}`,
    `selectedPostCount=${plan.metadata.selectedPostCount}`,
    `plannedPostCount=${plan.metadata.plannedPostCount}`,
    `requiredDayCount=${plan.metadata.requiredDayCount}`,
    `curatedUserCount=${plan.metadata.curatedUserCount}`,
    `sourceGroupCount=${plan.metadata.sourceGroupCount}`,
    `sourcePoolStrategy=${plan.metadata.sourcePoolStrategy}`,
    `targetPostsPerUser=${plan.metadata.targetPostsPerUser}`,
    `minPostsPerUser=${minUserPosts}`,
    `maxPostsPerUser=${maxUserPosts}`,
    "",
    "topicCounts:",
    ...Object.entries(plan.summary.topicCounts).map(([topic, count]) => `${topic}=${count}`),
    "",
    "dailyCounts:",
    ...dailyCounts.map(([day, count]) => `${day}=${count}`),
  ];
  ensureDir(summaryOutput);
  fs.writeFileSync(summaryOutput, `${lines.join("\n")}\n`);
}

function run() {
  const options = parseArgs(process.argv);
  const postsJson = readJson(options.postsInput);
  const usersJson = readJson(options.usersInput);
  const posts = Array.isArray(postsJson) ? postsJson : postsJson.posts || [];
  const users = (usersJson.records || []).filter((record) => record?.uid);
  const plan = buildPlan(posts, users, options);

  ensureDir(options.planOutput);
  fs.writeFileSync(options.planOutput, JSON.stringify(plan, null, 2));
  ensureDir(options.mappingOutput);
  fs.writeFileSync(options.mappingOutput, JSON.stringify(plan.mapping, null, 2));
  writeSummary(plan, options.summaryOutput);

  console.log(JSON.stringify({
    ok: true,
    planOutput: options.planOutput,
    summaryOutput: options.summaryOutput,
    mappingOutput: options.mappingOutput,
    metadata: plan.metadata,
    firstPost: plan.posts[0]
      ? {
          newDocID: plan.posts[0].newDocID,
          sourceDocID: plan.posts[0].sourceDocID,
          assignedNickname: plan.posts[0].assignedNickname,
          sourceNickname: plan.posts[0].sourceNickname,
          topic: plan.posts[0].topic,
          timeStamp: plan.posts[0].timeStamp,
          timeStampHuman: plan.posts[0].timeStampHuman,
        }
      : null,
    lastPost: plan.posts.length
      ? {
          newDocID: plan.posts[plan.posts.length - 1].newDocID,
          sourceDocID: plan.posts[plan.posts.length - 1].sourceDocID,
          assignedNickname: plan.posts[plan.posts.length - 1].assignedNickname,
          sourceNickname: plan.posts[plan.posts.length - 1].sourceNickname,
          topic: plan.posts[plan.posts.length - 1].topic,
          timeStamp: plan.posts[plan.posts.length - 1].timeStamp,
          timeStampHuman: plan.posts[plan.posts.length - 1].timeStampHuman,
        }
      : null,
  }, null, 2));
}

run();
