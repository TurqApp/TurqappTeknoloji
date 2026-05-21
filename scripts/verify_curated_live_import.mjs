#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const DEFAULT_PLAN = "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan_fresh_2026-05-21.json";
const DEFAULT_REPORT = "/Users/turqapp/Desktop/turqapp_curated_live_verify_report_2026-05-21.json";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp_Firebase/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";

const require = createRequire(import.meta.url);
const admin = require(path.resolve("functions/node_modules/firebase-admin"));

function parseArgs(argv) {
  const options = {
    plan: DEFAULT_PLAN,
    report: DEFAULT_REPORT,
    serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT,
  };
  for (let index = 2; index < argv.length; index += 1) {
    const arg = String(argv[index] || "").trim();
    if (arg === "--plan") {
      options.plan = String(argv[index + 1] || "").trim() || options.plan;
      index += 1;
    } else if (arg === "--report") {
      options.report = String(argv[index + 1] || "").trim() || options.report;
      index += 1;
    } else if (arg === "--service-account") {
      options.serviceAccount = String(argv[index + 1] || "").trim() || options.serviceAccount;
      index += 1;
    }
  }
  return options;
}

function initializeAdmin(serviceAccountPath) {
  if (admin.apps.length > 0) return;
  if (fs.existsSync(serviceAccountPath)) {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
      projectId: PROJECT_ID,
    });
    return;
  }
  admin.initializeApp({ projectId: PROJECT_ID });
}

function asString(value) {
  return String(value || "").trim();
}

function asInt(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.floor(number) : fallback;
}

function chunks(items, size) {
  const out = [];
  for (let index = 0; index < items.length; index += size) {
    out.push(items.slice(index, index + size));
  }
  return out;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function bump(map, key, amount = 1) {
  map.set(key, (map.get(key) || 0) + amount);
}

function sample(report, type, payload) {
  if (!report.samples[type]) report.samples[type] = [];
  if (report.samples[type].length < 10) report.samples[type].push(payload);
}

async function run() {
  const options = parseArgs(process.argv);
  const plan = JSON.parse(fs.readFileSync(options.plan, "utf8"));
  const posts = Array.isArray(plan.posts) ? plan.posts : [];
  const likes = Array.isArray(plan.plannedLikes) ? plan.plannedLikes : [];
  initializeAdmin(options.serviceAccount);
  const db = admin.firestore();

  const expectedPostsByUser = new Map();
  const expectedLikesByUser = new Map();
  const userIds = new Set();
  const expectedAvatarUrls = new Set();
  for (const item of posts) {
    const doc = item.postDoc || {};
    const uid = asString(doc.userID || item.assignedUserID);
    if (!uid) continue;
    userIds.add(uid);
    bump(expectedPostsByUser, uid, 1);
    bump(expectedLikesByUser, uid, asInt(doc.stats?.likeCount ?? doc.likeCount));
    expectedAvatarUrls.add(asString(doc.authorAvatarUrl || doc.avatarUrl));
  }

  const report = {
    startedAt: new Date().toISOString(),
    posts: posts.length,
    likes: likes.length,
    users: userIds.size,
    uniqueExpectedAvatarUrls: expectedAvatarUrls.size,
    missingPost: 0,
    mismatchedShortRoot: 0,
    mismatchedShortPublic: 0,
    missingPublicShortLink: 0,
    missingRoute: 0,
    mismatchedRoute: 0,
    mismatchedAvatar: 0,
    mismatchedTimestamp: 0,
    missingMedia: 0,
    nonReadyVideoHls: 0,
    missingLikeDoc: 0,
    missingUserLikedDoc: 0,
    missingUser: 0,
    missingPublicUser: 0,
    mismatchedUserCounters: 0,
    mismatchedPublicUserCounters: 0,
    samples: {},
  };

  for (const group of chunks(posts, 250)) {
    const postRefs = group.map((item) => db.collection("Posts").doc(asString(item.newDocID || item.postDoc?.docID || item.postDoc?.docId)));
    const publicRefs = group.map((_, index) => postRefs[index].collection("shortLinks").doc("public"));
    const routeRefs = group.map((item) => db.collection("shortRoutes").doc(`p:${asString(item.postDoc?.shortId)}`));
    const [postSnaps, publicSnaps, routeSnaps] = await Promise.all([
      db.getAll(...postRefs),
      db.getAll(...publicRefs),
      db.getAll(...routeRefs),
    ]);

    for (let index = 0; index < group.length; index += 1) {
      const item = group[index];
      const planned = item.postDoc || {};
      const postId = asString(item.newDocID || planned.docID || planned.docId);
      const shortId = asString(planned.shortId);
      const shortUrl = `https://turqapp.com/p/${shortId}`;
      const postSnap = postSnaps[index];
      const publicSnap = publicSnaps[index];
      const routeSnap = routeSnaps[index];
      const live = postSnap.data() || {};
      const publicDoc = publicSnap.data() || {};
      const route = routeSnap.data() || {};

      if (!postSnap.exists) {
        report.missingPost += 1;
        sample(report, "missingPost", { postId });
        continue;
      }
      if (asString(live.shortId) !== shortId || asString(live.shortUrl) !== shortUrl) {
        report.mismatchedShortRoot += 1;
        sample(report, "mismatchedShortRoot", { postId, expected: shortId, actual: live.shortId });
      }
      if (!publicSnap.exists) {
        report.missingPublicShortLink += 1;
        sample(report, "missingPublicShortLink", { postId });
      } else if (asString(publicDoc.shortId) !== shortId || asString(publicDoc.shortUrl) !== shortUrl || asString(publicDoc.entityId) !== postId) {
        report.mismatchedShortPublic += 1;
        sample(report, "mismatchedShortPublic", { postId, expected: shortId, actual: publicDoc.shortId, entityId: publicDoc.entityId });
      }
      if (!routeSnap.exists) {
        report.missingRoute += 1;
        sample(report, "missingRoute", { postId, shortId });
      } else if (asString(route.shortId) !== shortId || asString(route.entityId) !== postId || asString(route.entityPath) !== `Posts/${postId}/shortLinks/public`) {
        report.mismatchedRoute += 1;
        sample(report, "mismatchedRoute", { postId, shortId, route });
      }
      if (asString(live.authorAvatarUrl) !== asString(planned.authorAvatarUrl) || asString(live.avatarUrl) !== asString(planned.avatarUrl)) {
        report.mismatchedAvatar += 1;
        sample(report, "mismatchedAvatar", { postId, expected: planned.authorAvatarUrl, actual: live.authorAvatarUrl });
      }
      if (asInt(live.timeStamp) !== asInt(planned.timeStamp) || asInt(live.timeStamp) % 1000 !== 123) {
        report.mismatchedTimestamp += 1;
        sample(report, "mismatchedTimestamp", { postId, expected: planned.timeStamp, actual: live.timeStamp });
      }
      const hasVideo = Boolean(asString(live.video) || asString(live.hlsMasterUrl));
      const hasImage = (Array.isArray(live.img) && live.img.length > 0) || (Array.isArray(live.imgMap) && live.imgMap.length > 0);
      if (!hasVideo && !hasImage) {
        report.missingMedia += 1;
        sample(report, "missingMedia", { postId, video: live.video, hlsMasterUrl: live.hlsMasterUrl, img: live.img, imgMap: live.imgMap });
      }
      if (hasVideo && asString(live.hlsStatus) !== "ready") {
        report.nonReadyVideoHls += 1;
        sample(report, "nonReadyVideoHls", { postId, hlsStatus: live.hlsStatus });
      }
    }
  }

  for (const group of chunks(likes, 250)) {
    const postLikeRefs = group.map((like) =>
      db.collection("Posts").doc(asString(like.postID || like.postDocID)).collection("likes").doc(asString(like.likerUserID)),
    );
    const userLikeRefs = group.map((like) =>
      db.collection("users").doc(asString(like.likerUserID)).collection("liked_posts").doc(asString(like.postID || like.postDocID)),
    );
    const [postLikeSnaps, userLikeSnaps] = await Promise.all([db.getAll(...postLikeRefs), db.getAll(...userLikeRefs)]);
    for (let index = 0; index < group.length; index += 1) {
      const like = group[index];
      const postId = asString(like.postID || like.postDocID);
      const likerUserID = asString(like.likerUserID);
      if (!postLikeSnaps[index].exists) {
        report.missingLikeDoc += 1;
        sample(report, "missingLikeDoc", { postId, likerUserID });
      }
      if (!userLikeSnaps[index].exists) {
        report.missingUserLikedDoc += 1;
        sample(report, "missingUserLikedDoc", { postId, likerUserID });
      }
    }
  }

  const userList = [...userIds].sort();
  for (const group of chunks(userList, 250)) {
    const userRefs = group.map((uid) => db.collection("users").doc(uid));
    const publicUserRefs = group.map((uid) => db.collection("usersPublic").doc(uid));
    const [userSnaps, publicUserSnaps] = await Promise.all([db.getAll(...userRefs), db.getAll(...publicUserRefs)]);
    for (let index = 0; index < group.length; index += 1) {
      const uid = group[index];
      const expectedPostCount = expectedPostsByUser.get(uid) || 0;
      const expectedLikeCount = expectedLikesByUser.get(uid) || 0;
      const user = userSnaps[index].data() || {};
      const publicUser = publicUserSnaps[index].data() || {};
      if (!userSnaps[index].exists) {
        report.missingUser += 1;
        sample(report, "missingUser", { uid });
      } else if (asInt(user.counterOfPosts) !== expectedPostCount || asInt(user.counterOfLikes) !== expectedLikeCount) {
        report.mismatchedUserCounters += 1;
        sample(report, "mismatchedUserCounters", {
          uid,
          expectedPostCount,
          actualPostCount: user.counterOfPosts,
          expectedLikeCount,
          actualLikeCount: user.counterOfLikes,
        });
      }
      if (!publicUserSnaps[index].exists) {
        report.missingPublicUser += 1;
        sample(report, "missingPublicUser", { uid });
      } else if (asInt(publicUser.counterOfPosts) !== expectedPostCount || asInt(publicUser.counterOfLikes) !== expectedLikeCount) {
        report.mismatchedPublicUserCounters += 1;
        sample(report, "mismatchedPublicUserCounters", {
          uid,
          expectedPostCount,
          actualPostCount: publicUser.counterOfPosts,
          expectedLikeCount,
          actualLikeCount: publicUser.counterOfLikes,
        });
      }
    }
  }

  report.ok =
    report.missingPost === 0 &&
    report.mismatchedShortRoot === 0 &&
    report.mismatchedShortPublic === 0 &&
    report.missingPublicShortLink === 0 &&
    report.missingRoute === 0 &&
    report.mismatchedRoute === 0 &&
    report.mismatchedAvatar === 0 &&
    report.mismatchedTimestamp === 0 &&
    report.missingMedia === 0 &&
    report.nonReadyVideoHls === 0 &&
    report.missingLikeDoc === 0 &&
    report.missingUserLikedDoc === 0 &&
    report.missingUser === 0 &&
    report.missingPublicUser === 0 &&
    report.mismatchedUserCounters === 0 &&
    report.mismatchedPublicUserCounters === 0;
  report.finishedAt = new Date().toISOString();
  ensureDir(options.report);
  fs.writeFileSync(options.report, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  if (!report.ok) process.exitCode = 1;
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
