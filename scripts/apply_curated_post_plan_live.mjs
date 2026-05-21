#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_PLAN = "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan_fresh_2026-05-21.json";
const DEFAULT_REPORT = "/Users/turqapp/Desktop/turqapp_curated_post_repost_apply_report_2026-05-21.json";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp_Firebase/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";

const require = createRequire(import.meta.url);
const admin = require(path.resolve("functions/node_modules/firebase-admin"));

function parseArgs(argv) {
  const options = {
    plan: DEFAULT_PLAN,
    report: DEFAULT_REPORT,
    serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT,
    apply: false,
    skipPreflight: false,
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
    } else if (arg === "--apply") {
      options.apply = true;
    } else if (arg === "--skip-preflight") {
      options.skipPreflight = true;
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
      storageBucket: STORAGE_BUCKET,
    });
    return;
  }
  admin.initializeApp({ projectId: PROJECT_ID, storageBucket: STORAGE_BUCKET });
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return String(value || "").trim();
}

function asInt(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.max(0, Math.floor(number)) : fallback;
}

function chunks(items, size) {
  const out = [];
  for (let index = 0; index < items.length; index += size) {
    out.push(items.slice(index, index + size));
  }
  return out;
}

function buildPostMeta(postDoc) {
  const title = asString(postDoc.displayName || postDoc.authorDisplayName || postDoc.nickname || "TurqApp");
  const desc = asString(postDoc.metin).slice(0, 280);
  const imageUrl = asString(postDoc.thumbnail || postDoc.authorAvatarUrl || postDoc.avatarUrl);
  return { title, desc, imageUrl };
}

function shortLinkPayload(postDoc) {
  const postId = asString(postDoc.docID || postDoc.docId);
  const shortId = asString(postDoc.shortId);
  const shortUrl = asString(postDoc.shortUrl) || `https://turqapp.com/p/${shortId}`;
  const updatedAt = asInt(postDoc.shortLinkUpdatedAt, Date.now());
  const meta = buildPostMeta(postDoc);
  return {
    entity: {
      routeKind: "p",
      type: "post",
      entityId: postId,
      shortId,
      shortUrl,
      title: meta.title,
      desc: meta.desc,
      imageUrl: meta.imageUrl,
      status: "active",
      expiresAt: 0,
      updatedAt,
    },
    route: {
      routeKind: "p",
      key: shortId,
      type: "post",
      entityId: postId,
      entityPath: `Posts/${postId}/shortLinks/public`,
      shortId,
      shortUrl,
      status: "active",
      expiresAt: 0,
      updatedAt,
    },
  };
}

function summarizePlan(plan) {
  const posts = Array.isArray(plan.posts) ? plan.posts : [];
  const likes = Array.isArray(plan.plannedLikes) ? plan.plannedLikes : [];
  const postIds = new Set();
  const shortIds = new Set();
  const likePairs = new Set();
  const errors = [];
  const counterOfPosts = new Map();
  const counterOfLikesBase = new Map();
  const counterOfLikesAdded = new Map();

  for (const item of posts) {
    const doc = item.postDoc || {};
    const postId = asString(item.newDocID || doc.docID || doc.docId);
    const shortId = asString(doc.shortId);
    const uid = asString(doc.userID || item.assignedUserID);
    if (!postId) errors.push({ type: "missingPostId", index: item.index });
    if (postIds.has(postId)) errors.push({ type: "duplicatePostId", postId });
    postIds.add(postId);
    if (!/^C[0-9A-Za-z]{8}$/.test(shortId)) errors.push({ type: "badShortId", postId, shortId });
    if (shortIds.has(shortId)) errors.push({ type: "duplicateShortId", shortId });
    shortIds.add(shortId);
    if (!uid) errors.push({ type: "missingUserId", postId });
    counterOfPosts.set(uid, (counterOfPosts.get(uid) || 0) + 1);
    counterOfLikesBase.set(uid, (counterOfLikesBase.get(uid) || 0) + asInt(doc.stats?.likeCount ?? doc.likeCount));
  }

  for (const like of likes) {
    const liker = asString(like.likerUserID);
    const owner = asString(like.ownerUserID);
    const postId = asString(like.postID || like.postDocID);
    const pair = `${liker}:${postId}`;
    if (!liker || !owner || !postId) errors.push({ type: "badLike", like });
    if (liker === owner) errors.push({ type: "selfLike", liker, postId });
    if (likePairs.has(pair)) errors.push({ type: "duplicateLike", liker, postId });
    likePairs.add(pair);
    counterOfLikesAdded.set(owner, (counterOfLikesAdded.get(owner) || 0) + 1);
  }

  // Post docs already include planned inter-like increments. For pre-seed counters,
  // subtract the like docs that Cloud Functions will mirror after creation.
  for (const [uid, added] of counterOfLikesAdded) {
    counterOfLikesBase.set(uid, Math.max(0, (counterOfLikesBase.get(uid) || 0) - added));
  }

  return { posts, likes, postIds, shortIds, errors, counterOfPosts, counterOfLikesBase, counterOfLikesAdded };
}

async function preflight(db, summary) {
  const result = {
    existingPosts: [],
    existingRoutes: [],
    existingPostLikes: [],
    existingUserLikes: [],
  };
  const postRefs = [...summary.postIds].map((id) => db.collection("Posts").doc(id));
  const routeRefs = [...summary.shortIds].map((id) => db.collection("shortRoutes").doc(`p:${id}`));
  const postLikeRefs = summary.likes.map((like) =>
    db.collection("Posts").doc(asString(like.postID)).collection("likes").doc(asString(like.likerUserID)),
  );
  const userLikeRefs = summary.likes.map((like) =>
    db.collection("users").doc(asString(like.likerUserID)).collection("liked_posts").doc(asString(like.postID)),
  );

  async function collectExisting(refs, target) {
    for (const part of chunks(refs, 400)) {
      const snaps = await db.getAll(...part);
      for (const snap of snaps) {
        if (snap.exists && target.length < 20) target.push(snap.ref.path);
      }
      if (target.length >= 20) break;
    }
  }

  await Promise.all([
    collectExisting(postRefs, result.existingPosts),
    collectExisting(routeRefs, result.existingRoutes),
    collectExisting(postLikeRefs, result.existingPostLikes),
    collectExisting(userLikeRefs, result.existingUserLikes),
  ]);
  return result;
}

async function runBulk(label, db, enqueue) {
  const writer = db.bulkWriter();
  let scheduled = 0;
  let completed = 0;
  const failures = [];
  writer.onWriteError((error) => {
    failures.push({
      path: error.documentRef.path,
      code: error.code,
      message: error.message,
      failedAttempts: error.failedAttempts,
    });
    return false;
  });
  writer.onWriteResult(() => {
    completed += 1;
    if (completed % 5000 === 0) {
      console.log(JSON.stringify({ phase: label, completed }));
    }
  });
  scheduled = await enqueue(writer);
  await writer.close();
  return { label, scheduled, completed, failureCount: failures.length, failures: failures.slice(0, 20) };
}

async function run() {
  const options = parseArgs(process.argv);
  const plan = JSON.parse(fs.readFileSync(options.plan, "utf8"));
  const summary = summarizePlan(plan);
  initializeAdmin(options.serviceAccount);
  const db = admin.firestore();

  const report = {
    startedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    plan: options.plan,
    posts: summary.posts.length,
    likes: summary.likes.length,
    uniquePostIds: summary.postIds.size,
    uniqueShortIds: summary.shortIds.size,
    userCount: summary.counterOfPosts.size,
    validationErrors: summary.errors.slice(0, 20),
    preflight: null,
    phases: [],
  };

  if (summary.errors.length > 0) {
    report.ok = false;
    report.error = "validation_failed";
    ensureDir(options.report);
    fs.writeFileSync(options.report, JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
    process.exitCode = 1;
    return;
  }

  if (!options.skipPreflight) {
    report.preflight = await preflight(db, summary);
    const collisions =
      report.preflight.existingPosts.length +
      report.preflight.existingRoutes.length +
      report.preflight.existingPostLikes.length +
      report.preflight.existingUserLikes.length;
    if (collisions > 0) {
      report.ok = false;
      report.error = "preflight_collisions";
      ensureDir(options.report);
      fs.writeFileSync(options.report, JSON.stringify(report, null, 2));
      console.log(JSON.stringify(report, null, 2));
      process.exitCode = 1;
      return;
    }
  }

  if (!options.apply) {
    report.ok = true;
    report.finishedAt = new Date().toISOString();
    ensureDir(options.report);
    fs.writeFileSync(options.report, JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  report.phases.push(await runBulk("seed_user_counters", db, async (writer) => {
    let count = 0;
    for (const [uid, postCount] of summary.counterOfPosts) {
      const likeBase = summary.counterOfLikesBase.get(uid) || 0;
      const patch = {
        counterOfPosts: postCount,
        counterOfLikes: likeBase,
        updatedDate: Date.now(),
      };
      writer.set(db.collection("users").doc(uid), patch, { merge: true });
      writer.set(db.collection("usersPublic").doc(uid), patch, { merge: true });
      count += 2;
    }
    return count;
  }));

  report.phases.push(await runBulk("create_posts", db, async (writer) => {
    let count = 0;
    for (const item of summary.posts) {
      const doc = item.postDoc || {};
      const postId = asString(item.newDocID || doc.docID || doc.docId);
      writer.create(db.collection("Posts").doc(postId), doc);
      count += 1;
    }
    return count;
  }));

  report.phases.push(await runBulk("write_shortlinks", db, async (writer) => {
    let count = 0;
    for (const item of summary.posts) {
      const doc = item.postDoc || {};
      const postId = asString(item.newDocID || doc.docID || doc.docId);
      const shortId = asString(doc.shortId);
      const payload = shortLinkPayload(doc);
      writer.set(db.collection("Posts").doc(postId).collection("shortLinks").doc("public"), payload.entity, { merge: true });
      writer.set(db.collection("shortRoutes").doc(`p:${shortId}`), payload.route, { merge: true });
      count += 2;
    }
    return count;
  }));

  report.phases.push(await runBulk("create_likes", db, async (writer) => {
    let count = 0;
    for (const like of summary.likes) {
      const postId = asString(like.postID || like.postDocID);
      const liker = asString(like.likerUserID);
      writer.create(
        db.collection("Posts").doc(postId).collection("likes").doc(liker),
        like.likeDoc || { userID: liker, timeStamp: Date.now() },
      );
      writer.create(
        db.collection("users").doc(liker).collection("liked_posts").doc(postId),
        like.userLikedPostDoc || { post_docID: postId, timeStamp: Date.now() },
      );
      count += 2;
    }
    return count;
  }));

  const failed = report.phases.reduce((sum, phase) => sum + phase.failureCount, 0);
  report.ok = failed === 0;
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
