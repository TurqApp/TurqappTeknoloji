#!/usr/bin/env node

const FIREBASE_API_KEY =
  process.env.FIREBASE_API_KEY || "AIzaSyA6I8_TtqE8iMARFZClNIxjlEnmi3-hhOI";
const BASE_ID_TOKEN = String(process.env.K6_BASE_ID_TOKEN || "").trim();
const TEMP_TOKEN_COUNT = Math.max(0, Number(process.env.K6_TEMP_TOKEN_COUNT || "0"));
const TEMP_TOKEN_PREFIX = String(process.env.K6_TEMP_TOKEN_PREFIX || "k6-temp").trim() || "k6-temp";

function decodeJwtPayload(token) {
  const parts = String(token || "").split(".");
  if (parts.length < 2) return {};
  const normalized = parts[1].replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4 || 4)) % 4);
  try {
    return JSON.parse(Buffer.from(padded, "base64").toString("utf8"));
  } catch {
    return {};
  }
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

async function createTempUser(index) {
  const email = `${TEMP_TOKEN_PREFIX}-${index}-${Date.now()}-${Math.random()
    .toString(36)
    .slice(2, 8)}@example.com`;
  const password = `K6Temp!${Math.random().toString(36).slice(2, 10)}A1`;
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
    uid: String(json.localId),
    email,
    idToken: String(json.idToken),
  };
}

async function main() {
  const payload = decodeJwtPayload(BASE_ID_TOKEN);
  const feedUid = String(payload.user_id || payload.uid || payload.sub || "").trim();
  const tempUsers = [];
  for (let i = 0; i < TEMP_TOKEN_COUNT; i += 1) {
    tempUsers.push(await createTempUser(i + 1));
  }

  process.stdout.write(
    JSON.stringify({
      feedUid,
      actionTokens: tempUsers.map((user) => user.idToken),
      cleanupTokens: tempUsers.map((user) => user.idToken),
      tempUsers: tempUsers.map((user) => ({
        uid: user.uid,
        email: user.email,
      })),
    })
  );
}

main().catch((error) => {
  console.error("[k6-auth-context] failed", error);
  process.exit(1);
});
