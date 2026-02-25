#!/usr/bin/env node

/**
 * Seeds short links by calling Firebase callable `upsertShortLink`
 * with a real Firebase Auth user token.
 *
 * Required env:
 *   FIREBASE_API_KEY
 *   FIREBASE_EMAIL
 *   FIREBASE_PASSWORD
 *
 * Optional env:
 *   POST_SHORT_ID (default: Ab39Kd)
 *   STORY_SHORT_ID (default: St39Kd)
 *   USER_SLUG (default: testuser)
 */

const PROJECT_ID = "turqappteknoloji";
const REGION = "us-central1";
const CALLABLE_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/upsertShortLink`;

function mustGet(name) {
  const v = String(process.env[name] || "").trim();
  if (!v) {
    throw new Error(`Missing env: ${name}`);
  }
  return v;
}

async function signIn(email, password, apiKey) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });
  const json = await res.json();
  if (!res.ok || !json.idToken) {
    throw new Error(`signIn failed: ${JSON.stringify(json)}`);
  }
  return json.idToken;
}

async function callUpsert(idToken, payload) {
  const res = await fetch(CALLABLE_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ data: payload }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json?.error) {
    throw new Error(`upsertShortLink failed (${payload.type}): ${JSON.stringify(json)}`);
  }
  return json.result || json;
}

async function main() {
  const apiKey = mustGet("FIREBASE_API_KEY");
  const email = mustGet("FIREBASE_EMAIL");
  const password = mustGet("FIREBASE_PASSWORD");

  const postShortId = String(process.env.POST_SHORT_ID || "Ab39Kd").trim();
  const storyShortId = String(process.env.STORY_SHORT_ID || "St39Kd").trim();
  const userSlug = String(process.env.USER_SLUG || "testuser").trim().toLowerCase();

  const now = Date.now();
  const postEntityId = String(process.env.POST_ENTITY_ID || `test-post-${now}`).trim();
  const storyEntityId = String(process.env.STORY_ENTITY_ID || `test-story-${now}`).trim();
  const userEntityId = String(process.env.USER_ENTITY_ID || `test-user-${now}`).trim();

  const idToken = await signIn(email, password, apiKey);

  const post = await callUpsert(idToken, {
    type: "post",
    entityId: postEntityId,
    shortId: postShortId,
    title: "TurqApp Test Post",
    desc: "Cloudflare worker test post link",
    imageUrl: "https://cdn.turqapp.com/og/default.jpg",
  });

  const story = await callUpsert(idToken, {
    type: "story",
    entityId: storyEntityId,
    shortId: storyShortId,
    title: "TurqApp Test Story",
    desc: "Cloudflare worker test story link",
    imageUrl: "https://cdn.turqapp.com/og/default.jpg",
    expiresAt: now + 1000 * 60 * 60 * 24,
  });

  const user = await callUpsert(idToken, {
    type: "user",
    entityId: userEntityId,
    slug: userSlug,
    title: "TurqApp Test User",
    desc: "Cloudflare worker test user link",
    imageUrl: "https://cdn.turqapp.com/og/default.jpg",
  });

  const output = {
    ok: true,
    post,
    story,
    user,
    testUrls: {
      post: `https://turqapp.com/p/${postShortId}`,
      story: `https://turqapp.com/s/${storyShortId}`,
      user: `https://turqapp.com/u/${userSlug}`,
    },
  };

  console.log(JSON.stringify(output, null, 2));
}

main().catch((e) => {
  console.error(e?.stack || String(e));
  process.exit(1);
});
