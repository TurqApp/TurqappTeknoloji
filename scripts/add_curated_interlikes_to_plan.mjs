#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const DEFAULT_PLAN_INPUT =
  "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan_fresh_2026-05-21.json";
const DEFAULT_PLAN_OUTPUT = DEFAULT_PLAN_INPUT;
const DEFAULT_LIKES_OUTPUT =
  "/Users/turqapp/Desktop/turqapp_curated_interlikes_plan_2026-05-21.json";
const MIN_LIKES_PER_USER = 3;
const MAX_LIKES_PER_USER = 5;

function parseArgs(argv) {
  const options = {
    input: DEFAULT_PLAN_INPUT,
    output: DEFAULT_PLAN_OUTPUT,
    likesOutput: DEFAULT_LIKES_OUTPUT,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const arg = String(argv[index] || "").trim();
    if (arg === "--input") {
      options.input = String(argv[index + 1] || "").trim() || options.input;
      index += 1;
      continue;
    }
    if (arg === "--output") {
      options.output = String(argv[index + 1] || "").trim() || options.output;
      index += 1;
      continue;
    }
    if (arg === "--likes-output") {
      options.likesOutput = String(argv[index + 1] || "").trim() || options.likesOutput;
      index += 1;
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

function asString(value) {
  return String(value || "").trim();
}

function hashNumber(input) {
  return Number.parseInt(
    crypto.createHash("sha1").update(String(input)).digest("hex").slice(0, 8),
    16,
  );
}

function deterministicShuffle(items, seed) {
  return [...items]
    .map((item, index) => ({
      item,
      score: hashNumber(`${seed}:${index}:${item.newDocID || item.userID || ""}`),
    }))
    .sort((a, b) => a.score - b.score)
    .map(({ item }) => item);
}

function likeCountForUser(userID) {
  return MIN_LIKES_PER_USER + (hashNumber(`${userID}:curated-like-count`) % 3);
}

function buildLikeTimestamp(postTimestamp, likerID, postID, order) {
  const offsetMinutes = 7 + (hashNumber(`${likerID}:${postID}:${order}:like-offset`) % 173);
  const timestamp = asNumber(postTimestamp, Date.now()) + offsetMinutes * 60 * 1000;
  return Math.floor(timestamp / 1000) * 1000 + 123;
}

function postStats(postDoc) {
  const stats =
    postDoc.stats && typeof postDoc.stats === "object" && !Array.isArray(postDoc.stats)
      ? { ...postDoc.stats }
      : {};
  return stats;
}

function applyLikes(plan) {
  if (!Array.isArray(plan.posts)) {
    throw new Error("Plan JSON does not contain posts array");
  }

  const posts = plan.posts;
  const users = [...new Set(posts.map((item) => asString(item.assignedUserID || item.postDoc?.userID)).filter(Boolean))]
    .sort();
  const postsByOwner = new Map();
  const postById = new Map();

  for (const item of posts) {
    const ownerID = asString(item.assignedUserID || item.postDoc?.userID);
    const postID = asString(item.newDocID || item.postDoc?.docID || item.postDoc?.docId);
    if (!ownerID || !postID) continue;
    if (!postsByOwner.has(ownerID)) postsByOwner.set(ownerID, []);
    postsByOwner.get(ownerID).push(item);
    postById.set(postID, item);
  }

  for (const ownerPosts of postsByOwner.values()) {
    ownerPosts.sort((a, b) => asNumber(a.timeStamp || a.postDoc?.timeStamp) - asNumber(b.timeStamp || b.postDoc?.timeStamp));
  }

  const plannedLikes = [];
  const likedPairs = new Set();
  const receivedByPost = new Map();
  const receivedByUser = new Map();
  const givenByUser = new Map();

  function addLike(likerID, ownerID, order) {
    const ownerPosts = postsByOwner.get(ownerID) || [];
    if (ownerPosts.length === 0 || ownerID === likerID) return false;
    const orderedPosts = deterministicShuffle(
      ownerPosts,
      `${likerID}:${ownerID}:owner-posts`,
    );
    for (const candidate of orderedPosts) {
      const postDoc = candidate.postDoc || {};
      const postID = asString(candidate.newDocID || postDoc.docID || postDoc.docId);
      if (!postID) continue;
      const pairKey = `${likerID}:${postID}`;
      if (likedPairs.has(pairKey)) continue;
      likedPairs.add(pairKey);

      const timestamp = buildLikeTimestamp(candidate.timeStamp || postDoc.timeStamp, likerID, postID, order);
      plannedLikes.push({
        index: plannedLikes.length,
        postID,
        postDocID: postID,
        postPath: `Posts/${postID}/likes/${likerID}`,
        userLikedPostPath: `users/${likerID}/liked_posts/${postID}`,
        likerUserID: likerID,
        ownerUserID: ownerID,
        timeStamp: timestamp,
        likeDoc: {
          userID: likerID,
          timeStamp: timestamp,
        },
        userLikedPostDoc: {
          post_docID: postID,
          timeStamp: timestamp,
        },
      });

      receivedByPost.set(postID, (receivedByPost.get(postID) || 0) + 1);
      receivedByUser.set(ownerID, (receivedByUser.get(ownerID) || 0) + 1);
      givenByUser.set(likerID, (givenByUser.get(likerID) || 0) + 1);
      return true;
    }
    return false;
  }

  for (let userIndex = 0; userIndex < users.length; userIndex += 1) {
    const likerID = users[userIndex];
    const targetCount = likeCountForUser(likerID);
    const targetOwners = [];
    for (let offset = 1; targetOwners.length < targetCount && offset < users.length; offset += 1) {
      const ownerID = users[(userIndex + offset) % users.length];
      if (ownerID !== likerID) targetOwners.push(ownerID);
    }

    let selected = 0;
    for (const ownerID of targetOwners) {
      if (addLike(likerID, ownerID, selected + 1)) selected += 1;
    }

    if (selected !== targetCount) {
      throw new Error(`Could not assign ${targetCount} likes for ${likerID}; assigned ${selected}`);
    }
  }

  for (const [postID, inc] of receivedByPost) {
    const item = postById.get(postID);
    if (!item?.postDoc) continue;
    const stats = postStats(item.postDoc);
    const nextLikeCount = asNumber(stats.likeCount ?? item.postDoc.likeCount, 0) + inc;
    stats.likeCount = nextLikeCount;
    item.postDoc.stats = stats;
    item.postDoc.likeCount = nextLikeCount;
    item.curatedReceivedLikeCount = inc;
  }

  const summary = {
    generatedAt: new Date().toISOString(),
    strategy: "curated_users_like_other_curated_posts",
    minLikesPerUser: MIN_LIKES_PER_USER,
    maxLikesPerUser: MAX_LIKES_PER_USER,
    userCount: users.length,
    plannedLikeCount: plannedLikes.length,
    usersWithGivenLikes: givenByUser.size,
    usersWithReceivedLikes: receivedByUser.size,
    minGivenLikes: Math.min(...givenByUser.values()),
    maxGivenLikes: Math.max(...givenByUser.values()),
    minReceivedLikes: Math.min(...receivedByUser.values()),
    maxReceivedLikes: Math.max(...receivedByUser.values()),
    givenByUser: Object.fromEntries([...givenByUser].sort((a, b) => a[0].localeCompare(b[0]))),
    receivedByUser: Object.fromEntries([...receivedByUser].sort((a, b) => a[0].localeCompare(b[0]))),
  };

  plan.metadata = {
    ...(plan.metadata || {}),
    curatedInterlikesGeneratedAt: summary.generatedAt,
    curatedInterlikesStrategy: summary.strategy,
    curatedInterlikesCount: summary.plannedLikeCount,
    curatedInterlikesMinPerUser: MIN_LIKES_PER_USER,
    curatedInterlikesMaxPerUser: MAX_LIKES_PER_USER,
  };
  plan.summary = {
    ...(plan.summary || {}),
    curatedInterlikes: summary,
  };
  plan.plannedLikes = plannedLikes;

  return { plan, summary, plannedLikes };
}

function validate(plan, plannedLikes) {
  const errors = [];
  const users = new Set(plan.posts.map((item) => asString(item.assignedUserID || item.postDoc?.userID)).filter(Boolean));
  const postOwners = new Map(
    plan.posts.map((item) => [
      asString(item.newDocID || item.postDoc?.docID || item.postDoc?.docId),
      asString(item.assignedUserID || item.postDoc?.userID),
    ]),
  );
  const pairs = new Set();
  const given = new Map();

  for (const like of plannedLikes) {
    if (!users.has(like.likerUserID)) errors.push({ type: "unknownLiker", like });
    if (!postOwners.has(like.postID)) errors.push({ type: "unknownPost", like });
    if (like.likerUserID === like.ownerUserID || like.likerUserID === postOwners.get(like.postID)) {
      errors.push({ type: "selfLike", like });
    }
    const pair = `${like.likerUserID}:${like.postID}`;
    if (pairs.has(pair)) errors.push({ type: "duplicateLikePair", like });
    pairs.add(pair);
    if (like.postPath !== `Posts/${like.postID}/likes/${like.likerUserID}`) {
      errors.push({ type: "badPostPath", like });
    }
    if (like.userLikedPostPath !== `users/${like.likerUserID}/liked_posts/${like.postID}`) {
      errors.push({ type: "badUserLikePath", like });
    }
    given.set(like.likerUserID, (given.get(like.likerUserID) || 0) + 1);
  }

  for (const userID of users) {
    const count = given.get(userID) || 0;
    if (count < MIN_LIKES_PER_USER || count > MAX_LIKES_PER_USER) {
      errors.push({ type: "userGivenLikeCountOutOfRange", userID, count });
    }
  }

  return errors;
}

function run() {
  const options = parseArgs(process.argv);
  const plan = readJson(options.input);
  const result = applyLikes(plan);
  const errors = validate(result.plan, result.plannedLikes);
  if (errors.length > 0) {
    console.error(JSON.stringify({ ok: false, errors: errors.slice(0, 20) }, null, 2));
    process.exitCode = 1;
    return;
  }

  ensureDir(options.output);
  fs.writeFileSync(options.output, JSON.stringify(result.plan, null, 2));
  ensureDir(options.likesOutput);
  fs.writeFileSync(
    options.likesOutput,
    JSON.stringify(
      {
        metadata: result.summary,
        plannedLikes: result.plannedLikes,
      },
      null,
      2,
    ),
  );

  console.log(
    JSON.stringify(
      {
        ok: true,
        output: options.output,
        likesOutput: options.likesOutput,
        summary: {
          plannedLikeCount: result.summary.plannedLikeCount,
          userCount: result.summary.userCount,
          minGivenLikes: result.summary.minGivenLikes,
          maxGivenLikes: result.summary.maxGivenLikes,
          minReceivedLikes: result.summary.minReceivedLikes,
          maxReceivedLikes: result.summary.maxReceivedLikes,
        },
      },
      null,
      2,
    ),
  );
}

run();
