import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const FIREBASE_CLIENT_ID =
  process.env.FIREBASE_CLIENT_ID ||
  "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const FIREBASE_CLIENT_SECRET =
  process.env.FIREBASE_CLIENT_SECRET || "j9iVZfS8kkCEFUPaAeJV0sAi";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..", "..");

let cachedAdminClients;

async function ensureAdminClients() {
  if (cachedAdminClients) return cachedAdminClients;
  const rawServiceAccount = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || "").trim();
  if (!rawServiceAccount) {
    return null;
  }

  const [{ applicationDefault, cert, getApps, initializeApp }, { getAuth }, { getFirestore }] =
    await Promise.all([
      import("firebase-admin/app"),
      import("firebase-admin/auth"),
      import("firebase-admin/firestore"),
    ]);

  if (getApps().length === 0) {
    initializeApp({
      credential: rawServiceAccount
        ? cert(JSON.parse(rawServiceAccount))
        : applicationDefault(),
    });
  }

  cachedAdminClients = {
    auth: getAuth(),
    db: getFirestore(),
  };
  return cachedAdminClients;
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

async function resolveLoginUserViaAdmin(auth) {
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

function isIntegerLike(value) {
  return Number.isInteger(value) && Number.isSafeInteger(value);
}

function toFirestoreValue(value) {
  if (value === null) {
    return { nullValue: null };
  }
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((item) => toFirestoreValue(item)),
      },
    };
  }
  if (typeof value === "boolean") {
    return { booleanValue: value };
  }
  if (typeof value === "number") {
    if (isIntegerLike(value)) {
      return { integerValue: String(value) };
    }
    return { doubleValue: value };
  }
  if (typeof value === "string") {
    return { stringValue: value };
  }
  if (isPlainObject(value)) {
    const fields = {};
    for (const [key, inner] of Object.entries(value)) {
      fields[key] = toFirestoreValue(inner);
    }
    return { mapValue: { fields } };
  }
  fail(`unsupported fixture value type: ${typeof value}`);
}

function toFirestoreFields(value) {
  const fields = {};
  for (const [key, inner] of Object.entries(value)) {
    fields[key] = toFirestoreValue(inner);
  }
  return fields;
}

async function jsonFetch(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }
  return { response, json };
}

async function readJsonIfExists(filePath) {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch (_) {
    return null;
  }
}

async function resolveProjectId() {
  const explicit = (
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    ""
  ).trim();
  if (explicit) return explicit;

  const firebaseRc = await readJsonIfExists(path.join(REPO_ROOT, ".firebaserc"));
  const defaultProject = firebaseRc?.projects?.default;
  if (typeof defaultProject === "string" && defaultProject.trim()) {
    return defaultProject.trim();
  }

  const firebaseJson = await readJsonIfExists(path.join(REPO_ROOT, "firebase.json"));
  const dartProjectId = firebaseJson?.flutter?.platforms?.dart?.["lib/firebase_options.dart"]?.projectId;
  if (typeof dartProjectId === "string" && dartProjectId.trim()) {
    return dartProjectId.trim();
  }

  fail("unable to resolve Firebase project id for integration seed");
}

async function resolveFirebaseApiKey() {
  const explicit = (
    process.env.FIREBASE_API_KEY ||
    process.env.FIREBASE_WEB_API_KEY ||
    ""
  ).trim();
  if (explicit) return explicit;

  const googleServices = await readJsonIfExists(
    path.join(REPO_ROOT, "android", "app", "google-services.json"),
  );
  const googleServicesKey =
    googleServices?.client?.[0]?.api_key?.[0]?.current_key;
  if (typeof googleServicesKey === "string" && googleServicesKey.trim()) {
    return googleServicesKey.trim();
  }

  fail("unable to resolve Firebase API key for integration seed");
}

async function resolveFirebaseCliConfig() {
  const candidatePaths = [
    path.join(os.homedir(), ".config", "configstore", "firebase-tools.json"),
    path.join(
      os.homedir(),
      "Library",
      "Preferences",
      "configstore",
      "firebase-tools.json",
    ),
  ];
  for (const candidate of candidatePaths) {
    const config = await readJsonIfExists(candidate);
    if (config) {
      return { path: candidate, config };
    }
  }
  return null;
}

async function refreshFirebaseCliAccessToken(refreshToken) {
  const body = new URLSearchParams({
    refresh_token: refreshToken,
    client_id: FIREBASE_CLIENT_ID,
    client_secret: FIREBASE_CLIENT_SECRET,
    grant_type: "refresh_token",
  });
  const { response, json } = await jsonFetch(
    "https://www.googleapis.com/oauth2/v4/token",
    {
      method: "POST",
      headers: {
        "content-type": "application/x-www-form-urlencoded",
      },
      body,
    },
  );
  if (!response.ok || !json.access_token) {
    fail(`firebase CLI token refresh failed: ${JSON.stringify(json)}`);
  }
  return {
    accessToken: json.access_token,
    expiresAt:
      Date.now() + Math.max(0, Number(json.expires_in || 0)) * 1000,
  };
}

async function resolveGoogleAccessToken() {
  const explicit = (
    process.env.FIREBASE_CLI_ACCESS_TOKEN ||
    process.env.GOOGLE_OAUTH_ACCESS_TOKEN ||
    ""
  ).trim();
  if (explicit) return explicit;

  const cliConfig = await resolveFirebaseCliConfig();
  const tokens = cliConfig?.config?.tokens ?? {};
  const accessToken = String(tokens.access_token || "").trim();
  const expiresAt = Number(tokens.expires_at || 0);
  if (accessToken && expiresAt > Date.now() + 60_000) {
    return accessToken;
  }

  const refreshToken = String(tokens.refresh_token || "").trim();
  if (!refreshToken) {
    fail(
      "set FIREBASE_SERVICE_ACCOUNT_JSON or refresh local firebase CLI auth for integration seed",
    );
  }

  const refreshed = await refreshFirebaseCliAccessToken(refreshToken);
  return refreshed.accessToken;
}

async function signInIntegrationUser(apiKey) {
  const email = normalizeEmail(process.env.INTEGRATION_LOGIN_EMAIL);
  const password = String(process.env.INTEGRATION_LOGIN_PASSWORD || "");
  if (!email || !password) {
    fail("set INTEGRATION_LOGIN_EMAIL and INTEGRATION_LOGIN_PASSWORD for integration seed");
  }

  const { response, json } = await jsonFetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
      },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );
  if (!response.ok || !json.localId) {
    fail(`integration seed sign-in failed: ${JSON.stringify(json)}`);
  }
  return {
    email,
    uid: String(json.localId),
  };
}

function documentUrl(projectId, targetPath, query = "") {
  const normalized = String(targetPath || "").trim().replace(/^\/+/, "");
  return (
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/${normalized}${query}`
  );
}

async function patchDocument({
  projectId,
  accessToken,
  targetPath,
  payload,
  updateMaskPaths = [],
}) {
  const query = updateMaskPaths.length
    ? `?${updateMaskPaths
        .map(
          (fieldPath) =>
            `updateMask.fieldPaths=${encodeURIComponent(fieldPath)}`,
        )
        .join("&")}`
    : "";
  const { response, json } = await jsonFetch(
    documentUrl(projectId, targetPath, query),
    {
      method: "PATCH",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        fields: toFirestoreFields(payload),
      }),
    },
  );
  if (!response.ok) {
    fail(`seed patch failed (${targetPath}): ${JSON.stringify(json)}`);
  }
}

async function deleteDocument({
  projectId,
  accessToken,
  targetPath,
}) {
  const { response, json } = await jsonFetch(documentUrl(projectId, targetPath), {
    method: "DELETE",
    headers: {
      authorization: `Bearer ${accessToken}`,
    },
  });
  if (!response.ok && response.status !== 404) {
    fail(`seed delete failed (${targetPath}): ${JSON.stringify(json)}`);
  }
}

async function applyFixtureViaRest({ fixtureFile, fixture }) {
  const projectId = await resolveProjectId();
  const apiKey = await resolveFirebaseApiKey();
  const accessToken = await resolveGoogleAccessToken();
  const loginUser = await signInIntegrationUser(apiKey);

  const baseVariables = buildDefaultVariables(loginUser);
  const variables = {
    ...baseVariables,
    ...deepResolve(fixture.variables || {}, baseVariables),
  };

  const operations = Array.isArray(fixture.apply) ? fixture.apply : [];
  const appliedPaths = [];
  for (const rawOperation of operations) {
    const operation = deepResolve(rawOperation, variables);
    const op = String(operation.op || "merge").trim().toLowerCase();
    const targetPath = String(operation.path || "").trim();
    if (!targetPath) continue;

    if (op === "delete") {
      await deleteDocument({
        projectId,
        accessToken,
        targetPath,
      });
      appliedPaths.push(targetPath);
      continue;
    }

    const payload = isPlainObject(operation.data) ? operation.data : {};
    await patchDocument({
      projectId,
      accessToken,
      targetPath,
      payload,
      updateMaskPaths: op === "set" ? [] : Object.keys(payload),
    });
    appliedPaths.push(targetPath);
  }

  const cleanupPaths = sortPathsForCleanup([
    ...appliedPaths,
    ...((Array.isArray(fixture.cleanup) ? deepResolve(fixture.cleanup, variables) : [])),
  ]);

  return {
    fixtureFile,
    variables,
    appliedPaths,
    cleanupPaths,
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

  const adminClients = await ensureAdminClients();
  let result;
  if (adminClients) {
    const loginUser = await resolveLoginUserViaAdmin(adminClients.auth);
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
        await adminClients.db.doc(targetPath).delete().catch(() => {});
        appliedPaths.push(targetPath);
        continue;
      }

      const payload = isPlainObject(operation.data) ? operation.data : {};
      if (op === "set") {
        await adminClients.db.doc(targetPath).set(payload);
      } else {
        await adminClients.db.doc(targetPath).set(payload, { merge: true });
      }
      appliedPaths.push(targetPath);
    }

    result = {
      fixtureFile,
      variables,
      appliedPaths,
      cleanupPaths: sortPathsForCleanup([
        ...appliedPaths,
        ...((Array.isArray(fixture.cleanup) ? deepResolve(fixture.cleanup, variables) : [])),
      ]),
    };
  } else {
    result = await applyFixtureViaRest({ fixtureFile, fixture });
  }

  await fs.mkdir(path.dirname(stateFile), { recursive: true });
  await fs.writeFile(
    stateFile,
    JSON.stringify(
      {
        fixtureFile: result.fixtureFile,
        appliedAt: new Date().toISOString(),
        variables: result.variables,
        cleanupPaths: result.cleanupPaths,
      },
      null,
      2,
    ),
  );

  console.log(
    `[integration-seed] applied=${result.appliedPaths.length} cleanup=${result.cleanupPaths.length} state=${stateFile}`,
  );
}

main().catch((error) => {
  console.error("[integration-seed] failed", error);
  process.exit(1);
});
