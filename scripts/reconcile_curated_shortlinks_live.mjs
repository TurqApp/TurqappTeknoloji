#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const DEFAULT_PLAN = "/Users/turqapp/Desktop/turqapp_curated_post_repost_plan_fresh_2026-05-21.json";
const DEFAULT_REPORT = "/Users/turqapp/Desktop/turqapp_curated_shortlink_reconcile_report_2026-05-21.json";
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

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function chunks(items, size) {
  const out = [];
  for (let index = 0; index < items.length; index += size) {
    out.push(items.slice(index, index + size));
  }
  return out;
}

function buildPostMeta(postDoc) {
  return {
    title: asString(postDoc.displayName || postDoc.authorDisplayName || postDoc.nickname || "TurqApp"),
    desc: asString(postDoc.metin).slice(0, 280),
    imageUrl: asString(postDoc.thumbnail || postDoc.authorAvatarUrl || postDoc.avatarUrl),
  };
}

function payloads(postDoc) {
  const postId = asString(postDoc.docID || postDoc.docId);
  const shortId = asString(postDoc.shortId);
  const shortUrl = `https://turqapp.com/p/${shortId}`;
  const updatedAt = Date.now();
  const meta = buildPostMeta(postDoc);
  return {
    root: {
      shortId,
      shortUrl,
      shortLinkUpdatedAt: updatedAt,
      shortLinkStatus: "active",
    },
    publicDoc: {
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

async function run() {
  const options = parseArgs(process.argv);
  const plan = JSON.parse(fs.readFileSync(options.plan, "utf8"));
  const posts = Array.isArray(plan.posts) ? plan.posts : [];
  initializeAdmin(options.serviceAccount);
  const db = admin.firestore();

  const report = {
    startedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    posts: posts.length,
    mismatchedRoot: 0,
    mismatchedPublic: 0,
    missingPost: 0,
    missingPublic: 0,
    missingPlannedRoute: 0,
    extraRoutesToDelete: 0,
    samples: [],
    writeFailures: [],
  };

  const writer = options.apply ? db.bulkWriter() : null;
  if (writer) {
    writer.onWriteError((error) => {
      report.writeFailures.push({
        path: error.documentRef.path,
        code: error.code,
        message: error.message,
        failedAttempts: error.failedAttempts,
      });
      return false;
    });
  }

  for (const group of chunks(posts, 250)) {
    const postRefs = group.map((item) => db.collection("Posts").doc(asString(item.newDocID || item.postDoc?.docID || item.postDoc?.docId)));
    const publicRefs = group.map((item, index) => postRefs[index].collection("shortLinks").doc("public"));
    const routeRefs = group.map((item) => db.collection("shortRoutes").doc(`p:${asString(item.postDoc?.shortId)}`));
    const [postSnaps, publicSnaps, routeSnaps] = await Promise.all([
      db.getAll(...postRefs),
      db.getAll(...publicRefs),
      db.getAll(...routeRefs),
    ]);
    const extraRouteRefs = [];
    const extraRouteIndexes = [];

    for (let index = 0; index < group.length; index += 1) {
      const item = group[index];
      const doc = item.postDoc || {};
      const postId = asString(item.newDocID || doc.docID || doc.docId);
      const plannedShortId = asString(doc.shortId);
      const postSnap = postSnaps[index];
      const publicSnap = publicSnaps[index];
      const routeSnap = routeSnaps[index];
      const root = postSnap.data() || {};
      const publicDoc = publicSnap.data() || {};
      const beforeRootShortId = asString(root.shortId);
      const beforePublicShortId = asString(publicDoc.shortId);

      if (!postSnap.exists) report.missingPost += 1;
      if (!publicSnap.exists) report.missingPublic += 1;
      if (!routeSnap.exists) report.missingPlannedRoute += 1;
      if (beforeRootShortId !== plannedShortId) report.mismatchedRoot += 1;
      if (beforePublicShortId !== plannedShortId) report.mismatchedPublic += 1;

      const payload = payloads(doc);
      if (report.samples.length < 12 && (beforeRootShortId !== plannedShortId || beforePublicShortId !== plannedShortId || !routeSnap.exists)) {
        report.samples.push({ postId, plannedShortId, beforeRootShortId, beforePublicShortId, plannedRouteExists: routeSnap.exists });
      }

      if (writer) {
        if (beforeRootShortId !== plannedShortId || asString(root.shortUrl) !== payload.root.shortUrl) {
          writer.set(postRefs[index], payload.root, { merge: true });
        }
        if (beforePublicShortId !== plannedShortId || !publicSnap.exists) {
          writer.set(publicRefs[index], payload.publicDoc, { merge: true });
        }
        if (!routeSnap.exists) {
          writer.set(routeRefs[index], payload.route, { merge: true });
        }
      }

      if (beforeRootShortId && beforeRootShortId !== plannedShortId) {
        extraRouteRefs.push(db.collection("shortRoutes").doc(`p:${beforeRootShortId}`));
        extraRouteIndexes.push(index);
      }
    }

    if (extraRouteRefs.length > 0) {
      const extraRouteSnaps = await db.getAll(...extraRouteRefs);
      for (let index = 0; index < extraRouteSnaps.length; index += 1) {
        const routeSnap = extraRouteSnaps[index];
        const route = routeSnap.data() || {};
        const groupIndex = extraRouteIndexes[index];
        const item = group[groupIndex];
        const postId = asString(item.newDocID || item.postDoc?.docID || item.postDoc?.docId);
        if (routeSnap.exists && asString(route.entityId) === postId) {
          report.extraRoutesToDelete += 1;
          if (writer) writer.delete(extraRouteRefs[index]);
        }
      }
    }
  }

  if (writer) await writer.close();
  report.ok = report.writeFailures.length === 0;
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
