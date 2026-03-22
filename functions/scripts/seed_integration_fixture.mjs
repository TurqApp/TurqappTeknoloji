import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

import { applicationDefault, cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

function ensureAdminApp() {
  if (getApps().length > 0) return getApps()[0];
  const rawServiceAccount = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || "").trim();
  if (rawServiceAccount) {
    return initializeApp({
      credential: cert(JSON.parse(rawServiceAccount)),
    });
  }
  return initializeApp({
    credential: applicationDefault(),
  });
}

function fail(message) {
  console.error(`[integration-seed] ${message}`);
  process.exit(1);
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function isPlainObject(value) {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

function deepResolve(value, variables) {
  if (Array.isArray(value)) {
    return value.map((item) => deepResolve(item, variables));
  }
  if (isPlainObject(value)) {
    const output = {};
    for (const [key, inner] of Object.entries(value)) {
      output[key] = deepResolve(inner, variables);
    }
    return output;
  }
  if (typeof value !== "string") {
    return value;
  }

  const exact = value.match(/^{{([A-Z0-9_]+)}}$/);
  if (exact) {
    return variables[exact[1]] ?? value;
  }

  return value.replace(/{{([A-Z0-9_]+)}}/g, (_, key) => {
    const resolved = variables[key];
    return resolved == null ? "" : String(resolved);
  });
}

function sortPathsForCleanup(paths) {
  return [...new Set(paths)]
    .filter((item) => item.trim().length > 0)
    .sort((a, b) => b.split("/").length - a.split("/").length);
}

async function resolveLoginUser(auth) {
  const email = normalizeEmail(process.env.INTEGRATION_LOGIN_EMAIL);
  if (!email) {
    fail("set INTEGRATION_LOGIN_EMAIL for seeded integration fixtures");
  }
  const user = await auth.getUserByEmail(email);
  return {
    email,
    uid: user.uid,
  };
}

function buildDefaultVariables(loginUser) {
  const peerUid = (process.env.INTEGRATION_SEED_PEER_UID || "it_seed_peer").trim();
  const peerEmail = normalizeEmail(
    process.env.INTEGRATION_SEED_PEER_EMAIL || "integration-peer@turqapp.local",
  );
  const chatId = `${loginUser.uid}_${peerUid}`;
  return {
    LOGIN_EMAIL: loginUser.email,
    LOGIN_UID: loginUser.uid,
    PEER_UID: peerUid,
    PEER_EMAIL: peerEmail,
    CHAT_ID: chatId,
    NOW_MS: Date.now(),
    MESSAGE_ID: "it_seed_message_1",
    NOTIFICATION_ID: "it_notification_follow_profile",
  };
}

async function main() {
  const fixtureFile =
    process.argv[2] ||
    process.env.INTEGRATION_SEED_FILE ||
    "integration_test/core/fixtures/smoke_seed.device_baseline.json";
  const stateFile =
    process.env.INTEGRATION_SEED_STATE_FILE ||
    path.join("artifacts", "integration_seed", "seed_state.json");

  const fixtureRaw = await fs.readFile(fixtureFile, "utf8");
  const fixture = JSON.parse(fixtureRaw);
  const operations = Array.isArray(fixture.apply) ? fixture.apply : [];
  if (operations.length === 0) {
    fail(`fixture has no apply operations: ${fixtureFile}`);
  }

  ensureAdminApp();
  const auth = getAuth();
  const db = getFirestore();
  const loginUser = await resolveLoginUser(auth);

  const baseVariables = buildDefaultVariables(loginUser);
  const variables = {
    ...baseVariables,
    ...deepResolve(fixture.variables || {}, baseVariables),
  };

  const appliedPaths = [];
  for (const rawOperation of operations) {
    const operation = deepResolve(rawOperation, variables);
    const op = String(operation.op || "merge").trim().toLowerCase();
    const targetPath = String(operation.path || "").trim();
    if (!targetPath) continue;

    if (op === "delete") {
      await db.doc(targetPath).delete().catch(() => {});
      appliedPaths.push(targetPath);
      continue;
    }

    const payload = isPlainObject(operation.data) ? operation.data : {};
    if (op === "set") {
      await db.doc(targetPath).set(payload);
    } else {
      await db.doc(targetPath).set(payload, { merge: true });
    }
    appliedPaths.push(targetPath);
  }

  const cleanupPaths = sortPathsForCleanup([
    ...appliedPaths,
    ...((Array.isArray(fixture.cleanup) ? deepResolve(fixture.cleanup, variables) : [])),
  ]);

  await fs.mkdir(path.dirname(stateFile), { recursive: true });
  await fs.writeFile(
    stateFile,
    JSON.stringify(
      {
        fixtureFile,
        appliedAt: new Date().toISOString(),
        variables,
        cleanupPaths,
      },
      null,
      2,
    ),
  );

  console.log(
    `[integration-seed] applied=${appliedPaths.length} cleanup=${cleanupPaths.length} state=${stateFile}`,
  );
}

main().catch((error) => {
  console.error("[integration-seed] failed", error);
  process.exit(1);
});
