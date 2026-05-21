#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const DEFAULT_PLAN = "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan_fresh_2026-05-21.json";
const DEFAULT_REPORT = "/Users/turqapp/Desktop/turqapp_curated_public_user_counter_reconcile_report_2026-05-21.json";
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

function bump(map, key, amount = 1) {
  map.set(key, (map.get(key) || 0) + amount);
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

async function run() {
  const options = parseArgs(process.argv);
  const plan = JSON.parse(fs.readFileSync(options.plan, "utf8"));
  const posts = Array.isArray(plan.posts) ? plan.posts : [];
  initializeAdmin(options.serviceAccount);
  const db = admin.firestore();

  const expectedPostsByUser = new Map();
  const expectedLikesByUser = new Map();
  for (const item of posts) {
    const doc = item.postDoc || {};
    const uid = asString(doc.userID || item.assignedUserID);
    if (!uid) continue;
    bump(expectedPostsByUser, uid, 1);
    bump(expectedLikesByUser, uid, asInt(doc.stats?.likeCount ?? doc.likeCount));
  }

  const report = {
    startedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    users: expectedPostsByUser.size,
    mismatchedUsersPublic: 0,
    scheduledWrites: 0,
    completedWrites: 0,
    failures: [],
    samples: [],
  };
  const writer = options.apply ? db.bulkWriter() : null;
  if (writer) {
    writer.onWriteResult(() => {
      report.completedWrites += 1;
    });
    writer.onWriteError((error) => {
      report.failures.push({
        path: error.documentRef.path,
        code: error.code,
        message: error.message,
        failedAttempts: error.failedAttempts,
      });
      return false;
    });
  }

  for (const group of chunks([...expectedPostsByUser.keys()].sort(), 250)) {
    const refs = group.map((uid) => db.collection("usersPublic").doc(uid));
    const snaps = await db.getAll(...refs);
    for (let index = 0; index < group.length; index += 1) {
      const uid = group[index];
      const publicUser = snaps[index].data() || {};
      const expectedPostCount = expectedPostsByUser.get(uid) || 0;
      const expectedLikeCount = expectedLikesByUser.get(uid) || 0;
      const currentPostCount = asInt(publicUser.counterOfPosts);
      const currentLikeCount = asInt(publicUser.counterOfLikes);
      if (currentPostCount !== expectedPostCount || currentLikeCount !== expectedLikeCount) {
        report.mismatchedUsersPublic += 1;
        if (report.samples.length < 20) {
          report.samples.push({
            uid,
            expectedPostCount,
            currentPostCount,
            expectedLikeCount,
            currentLikeCount,
          });
        }
        if (writer) {
          report.scheduledWrites += 1;
          writer.set(
            refs[index],
            {
              counterOfPosts: expectedPostCount,
              counterOfLikes: expectedLikeCount,
              curatedCountersReconciledAt: Date.now(),
            },
            { merge: true },
          );
        }
      }
    }
  }

  if (writer) await writer.close();
  report.ok = report.failures.length === 0;
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
