#!/usr/bin/env node

/**
 * Lightweight live Firestore story create probe.
 *
 * Purpose:
 * - create one temporary Firebase Auth user
 * - try multiple story create payload shapes against live Firestore rules
 * - report whether rejection is collection-wide or payload-specific
 * - clean up probe documents afterwards
 *
 * Notes:
 * - Temporary Firebase Auth users remain in Auth unless removed separately.
 * - This script uses the live project and should stay narrow.
 */

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "turqappteknoloji";
const FIREBASE_API_KEY =
  process.env.FIREBASE_API_KEY || "AIzaSyA6I8_TtqE8iMARFZClNIxjlEnmi3-hhOI";
const KEEP_DOCS = String(process.env.KEEP_STORY_PROBE_DOCS || "")
  .trim()
  .toLowerCase() === "true";

const FIRESTORE_BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function nowMs() {
  return Date.now();
}

function randomId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}

function fireString(value) {
  return { stringValue: String(value) };
}

function fireInt(value) {
  return { integerValue: String(Math.trunc(Number(value) || 0)) };
}

function fireDouble(value) {
  return { doubleValue: Number(value) || 0 };
}

function fireBool(value) {
  return { booleanValue: Boolean(value) };
}

function fireArray(values = []) {
  return { arrayValue: { values } };
}

function fireMap(fields = {}) {
  return { mapValue: { fields } };
}

function storyElementFields({ type, content }) {
  return fireMap({
    type: fireString(type),
    content: fireString(content),
    width: fireDouble(1080),
    height: fireDouble(1920),
    position: fireMap({
      x: fireDouble(0),
      y: fireDouble(0),
    }),
    rotation: fireDouble(0),
    zIndex: fireInt(1),
    isMuted: fireBool(type === "video"),
    fontSize: fireDouble(0),
    aspectRatio: fireDouble(0.5625),
    textColor: fireInt(0),
    textBgColor: fireInt(0),
    hasTextBg: fireBool(false),
    textAlign: fireString("left"),
    fontWeight: fireString("normal"),
    italic: fireBool(false),
    underline: fireBool(false),
    shadowBlur: fireDouble(0),
    shadowOpacity: fireDouble(0),
    fontFamily: fireString(""),
    hasOutline: fireBool(false),
    outlineColor: fireInt(0),
    stickerType: fireString(""),
    stickerData: fireString(""),
    mediaLookPreset: fireString(""),
  });
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

async function createTempUser() {
  const email = `${randomId("codex.story.probe")}@example.com`;
  const password = `CodexProbe!${Math.random().toString(36).slice(2, 10)}A1`;
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

async function writeDoc({ token, path, fields, exists = false }) {
  const query = `?currentDocument.exists=${exists ? "true" : "false"}`;
  const { res, json } = await jsonFetch(`${FIRESTORE_BASE}/${path}${query}`, {
    method: "PATCH",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ fields }),
  });
  return { ok: res.ok, status: res.status, json };
}

async function deleteDoc({ token, path }) {
  const { res, json } = await jsonFetch(`${FIRESTORE_BASE}/${path}`, {
    method: "DELETE",
    headers: { authorization: `Bearer ${token}` },
  });
  return { ok: res.ok || res.status === 404, status: res.status, json };
}

function buildMinimalStoryFields(uid) {
  return {
    userId: fireString(uid),
  };
}

function buildAppLikeStoryFields(uid, type) {
  const now = nowMs();
  const content =
    type === "video"
      ? "https://example.com/codex-probe-video.mp4"
      : "https://example.com/codex-probe-image.webp";
  return {
    userId: fireString(uid),
    createdDate: fireInt(now),
    backgroundColor: fireInt(4278190080),
    musicId: fireString(""),
    musicUrl: fireString(""),
    musicTitle: fireString(""),
    musicArtist: fireString(""),
    musicCoverUrl: fireString(""),
    elements: fireArray([storyElementFields({ type, content })]),
    deleted: fireBool(false),
    deletedAt: fireInt(0),
  };
}

async function runCase({ token, uid, label, fields }) {
  const storyId = randomId(`codex_story_probe_${label}`);
  const path = `stories/${storyId}`;
  const startedAt = nowMs();
  const result = await writeDoc({
    token,
    path,
    fields,
    exists: false,
  });
  const durationMs = nowMs() - startedAt;

  const summary = {
    label,
    path,
    durationMs,
    ok: result.ok,
    status: result.status,
    uid,
  };

  if (!result.ok) {
    summary.error = result.json?.error || result.json;
  }

  if (result.ok && !KEEP_DOCS) {
    await deleteDoc({ token, path });
  }

  return summary;
}

async function main() {
  const user = await createTempUser();
  const cases = [
    {
      label: "minimal",
      fields: buildMinimalStoryFields(user.uid),
    },
    {
      label: "photo_like",
      fields: buildAppLikeStoryFields(user.uid, "image"),
    },
    {
      label: "video_like",
      fields: buildAppLikeStoryFields(user.uid, "video"),
    },
  ];

  const results = [];
  for (const testCase of cases) {
    results.push(
      await runCase({
        token: user.idToken,
        uid: user.uid,
        label: testCase.label,
        fields: testCase.fields,
      }),
    );
  }

  const output = {
    projectId: PROJECT_ID,
    uid: user.uid,
    email: user.email,
    keepDocs: KEEP_DOCS,
    results,
  };

  console.log(JSON.stringify(output, null, 2));
}

main().catch((error) => {
  console.error(
    JSON.stringify(
      {
        projectId: PROJECT_ID,
        fatal: String(error?.stack || error),
      },
      null,
      2,
    ),
  );
  process.exitCode = 1;
});
