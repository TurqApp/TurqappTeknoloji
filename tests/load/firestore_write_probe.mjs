#!/usr/bin/env node

/**
 * Lightweight live Firestore write probe for TurqApp.
 *
 * Purpose:
 * - create temporary auth users
 * - seed one temporary post
 * - exercise like/follow edge writes with live auth + rules
 * - clean up probe documents afterwards
 *
 * Notes:
 * - This intentionally avoids mutating top-level post stats counters.
 * - Temporary Firebase Auth users remain in Auth unless removed separately.
 */

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "turqappteknoloji";
const FIREBASE_API_KEY =
  process.env.FIREBASE_API_KEY || "AIzaSyA6I8_TtqE8iMARFZClNIxjlEnmi3-hhOI";
const USER_COUNT = Number(process.env.PROBE_USER_COUNT || "4");
const LIKE_ROUNDS = Number(process.env.PROBE_LIKE_ROUNDS || "2");
const FOLLOW_ROUNDS = Number(process.env.PROBE_FOLLOW_ROUNDS || "2");

const FIRESTORE_BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function nowMs() {
  return Date.now();
}

function randomId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function p95(values) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.ceil(sorted.length * 0.95) - 1);
  return sorted[idx];
}

function metricSummary(values) {
  if (!values.length) {
    return { count: 0, avg: 0, p95: 0, max: 0 };
  }
  const avg = values.reduce((sum, n) => sum + n, 0) / values.length;
  return {
    count: values.length,
    avg: Math.round(avg),
    p95: Math.round(p95(values)),
    max: Math.max(...values),
  };
}

function fireString(value) {
  return { stringValue: String(value) };
}

function fireInt(value) {
  return { integerValue: String(value) };
}

function fireBool(value) {
  return { booleanValue: !!value };
}

function fireMap(value) {
  return { mapValue: { fields: value } };
}

function buildPostFields(authorUid) {
  return {
    userID: fireString(authorUid),
    text: fireString("codex write probe"),
    timeStamp: fireInt(nowMs()),
    arsiv: fireBool(false),
    flood: fireBool(false),
    deletedPost: fireBool(false),
    stats: fireMap({
      statsCount: fireInt(0),
      likeCount: fireInt(0),
      commentCount: fireInt(0),
      savedCount: fireInt(0),
      retryCount: fireInt(0),
      reportedCount: fireInt(0),
    }),
  };
}

async function jsonFetch(url, options = {}) {
  const res = await fetch(url, options);
  const text = await res.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }
  return { res, json };
}

async function createTempUser(label) {
  const email = `${label}.${Date.now()}.${Math.random()
    .toString(36)
    .slice(2, 8)}@example.com`;
  const password = `CodexProbe!${Math.random().toString(36).slice(2, 8)}A1`;
  const url =
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${encodeURIComponent(FIREBASE_API_KEY)}`;
  const { res, json } = await jsonFetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });
  if (!res.ok || !json.idToken || !json.localId) {
    throw new Error(`createTempUser failed: ${JSON.stringify(json)}`);
  }
  return {
    email,
    password,
    idToken: json.idToken,
    uid: json.localId,
  };
}

async function writeDoc({ token, path, fields, exists = null }) {
  const qs =
    exists === null ? "" : `?currentDocument.exists=${exists ? "true" : "false"}`;
  const { res, json } = await jsonFetch(`${FIRESTORE_BASE}/${path}${qs}`, {
    method: "PATCH",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) {
    throw new Error(`writeDoc failed (${path}): ${JSON.stringify(json)}`);
  }
  return json;
}

async function deleteDoc({ token, path }) {
  const { res, json } = await jsonFetch(`${FIRESTORE_BASE}/${path}`, {
    method: "DELETE",
    headers: {
      authorization: `Bearer ${token}`,
    },
  });
  if (!res.ok && res.status !== 404) {
    throw new Error(`deleteDoc failed (${path}): ${JSON.stringify(json)}`);
  }
  return json;
}

async function timedMetric(bucket, fn) {
  const started = nowMs();
  await fn();
  bucket.push(nowMs() - started);
}

async function main() {
  const users = [];
  const metrics = {
    likeCreateMs: [],
    likeDeleteMs: [],
    followCreateMs: [],
    followDeleteMs: [],
  };
  const failures = [];

  const postId = randomId("codex_write_probe_post");

  try {
    for (let i = 0; i < USER_COUNT; i += 1) {
      users.push(await createTempUser(`codex.write.probe.${i + 1}`));
      await sleep(150);
    }

    const author = users[0];
    const actors = users.slice(1);
    if (!actors.length) {
      throw new Error("Need at least 2 users for write probe");
    }

    await writeDoc({
      token: author.idToken,
      path: `Posts/${postId}`,
      fields: buildPostFields(author.uid),
      exists: false,
    });

    for (let round = 0; round < LIKE_ROUNDS; round += 1) {
      for (const actor of actors) {
        const likePath = `Posts/${postId}/likes/${actor.uid}`;
        const likedPostPath = `users/${actor.uid}/liked_posts/${postId}`;
        const payload = {
          userID: fireString(actor.uid),
          timeStamp: fireInt(nowMs()),
        };

        try {
          await timedMetric(metrics.likeCreateMs, async () => {
            await writeDoc({
              token: actor.idToken,
              path: likePath,
              fields: payload,
              exists: false,
            });
            await writeDoc({
              token: actor.idToken,
              path: likedPostPath,
              fields: payload,
              exists: false,
            });
          });

          await timedMetric(metrics.likeDeleteMs, async () => {
            await deleteDoc({ token: actor.idToken, path: likePath });
            await deleteDoc({ token: actor.idToken, path: likedPostPath });
          });
        } catch (error) {
          failures.push({
            phase: "like",
            uid: actor.uid,
            round,
            error: String(error?.message || error),
          });
        }
      }
    }

    for (let round = 0; round < FOLLOW_ROUNDS; round += 1) {
      for (const actor of actors) {
        const followingPath = `users/${actor.uid}/followings/${author.uid}`;
        const followerPath = `users/${author.uid}/followers/${actor.uid}`;
        const payload = {
          timeStamp: fireInt(nowMs()),
        };

        try {
          await timedMetric(metrics.followCreateMs, async () => {
            await writeDoc({
              token: actor.idToken,
              path: followingPath,
              fields: payload,
              exists: false,
            });
            await writeDoc({
              token: actor.idToken,
              path: followerPath,
              fields: payload,
              exists: false,
            });
          });

          await timedMetric(metrics.followDeleteMs, async () => {
            await deleteDoc({ token: actor.idToken, path: followingPath });
            await deleteDoc({ token: actor.idToken, path: followerPath });
          });
        } catch (error) {
          failures.push({
            phase: "follow",
            uid: actor.uid,
            round,
            error: String(error?.message || error),
          });
        }
      }
    }

    const output = {
      ok: failures.length === 0,
      projectId: PROJECT_ID,
      probe: {
        userCount: USER_COUNT,
        likeRounds: LIKE_ROUNDS,
        followRounds: FOLLOW_ROUNDS,
        postId,
      },
      metrics: {
        likeCreate: metricSummary(metrics.likeCreateMs),
        likeDelete: metricSummary(metrics.likeDeleteMs),
        followCreate: metricSummary(metrics.followCreateMs),
        followDelete: metricSummary(metrics.followDeleteMs),
      },
      failures,
    };

    console.log(JSON.stringify(output, null, 2));
    process.exitCode = failures.length === 0 ? 0 : 1;
  } finally {
    if (users[0]?.idToken) {
      try {
        await deleteDoc({ token: users[0].idToken, path: `Posts/${postId}` });
      } catch {}
    }
  }
}

main().catch((error) => {
  console.error(error?.stack || String(error));
  process.exit(1);
});
