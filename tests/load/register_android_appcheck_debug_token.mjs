#!/usr/bin/env node

/**
 * Registers an Android App Check debug token using the local firebase-tools login.
 *
 * Required env:
 * - APP_CHECK_DEBUG_TOKEN: UUID printed by DebugAppCheckProvider
 *
 * Optional env:
 * - FIREBASE_PROJECT_NUMBER: defaults to Android sender/project number
 * - FIREBASE_ANDROID_APP_ID: defaults to local android app id
 * - APP_CHECK_DEBUG_DISPLAY_NAME: defaults to hostname + date
 */

import fs from "fs";
import os from "os";
import path from "path";
import auth from "/opt/homebrew/lib/node_modules/firebase-tools/lib/auth.js";

const PROJECT_NUMBER =
  process.env.FIREBASE_PROJECT_NUMBER || "7235832399";
const ANDROID_APP_ID =
  process.env.FIREBASE_ANDROID_APP_ID ||
  "1:7235832399:android:f5b07965c1cb59db8ff83a";
const DEBUG_TOKEN = String(process.env.APP_CHECK_DEBUG_TOKEN || "").trim();
const DISPLAY_NAME = String(
  process.env.APP_CHECK_DEBUG_DISPLAY_NAME ||
    `codex-${os.hostname()}-${new Date().toISOString()}`,
).trim();

function readFirebaseCliTokens() {
  const configPath = path.join(
    process.env.HOME,
    ".config",
    "configstore",
    "firebase-tools.json",
  );
  const data = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const tokens = data?.tokens || {};
  return {
    accessToken:
      typeof tokens.access_token === "string" ? tokens.access_token : "",
    refreshToken:
      typeof tokens.refresh_token === "string" ? tokens.refresh_token : "",
    expiresAt:
      typeof tokens.expires_at === "number" ? tokens.expires_at : 0,
  };
}

async function main() {
  if (!DEBUG_TOKEN) {
    throw new Error("APP_CHECK_DEBUG_TOKEN is required");
  }

  const cliTokens = readFirebaseCliTokens();
  let bearerToken = "";
  if (cliTokens.accessToken && cliTokens.expiresAt > Date.now()) {
    bearerToken = cliTokens.accessToken;
  } else if (cliTokens.refreshToken) {
    const accessToken = await auth.getAccessToken(cliTokens.refreshToken, [
      "https://www.googleapis.com/auth/firebase",
    ]);
    bearerToken = accessToken.access_token || "";
  }
  if (!bearerToken) {
    throw new Error("firebase-tools access token not available");
  }

  const parent = `projects/${PROJECT_NUMBER}/apps/${ANDROID_APP_ID}`;
  const res = await fetch(
    `https://firebaseappcheck.googleapis.com/v1/${parent}/debugTokens`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${bearerToken}`,
      },
      body: JSON.stringify({
        displayName: DISPLAY_NAME,
        token: DEBUG_TOKEN,
      }),
    },
  );

  const text = await res.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }

  if (!res.ok) {
    throw new Error(
      `register debug token failed (${res.status}): ${JSON.stringify(json)}`,
    );
  }

  console.log(
    JSON.stringify(
      {
        ok: true,
        projectNumber: PROJECT_NUMBER,
        appId: ANDROID_APP_ID,
        name: json.name || "",
        displayName: json.displayName || DISPLAY_NAME,
        updateTime: json.updateTime || "",
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(
    JSON.stringify(
      {
        ok: false,
        error: String(error?.stack || error),
      },
      null,
      2,
    ),
  );
  process.exitCode = 1;
});
