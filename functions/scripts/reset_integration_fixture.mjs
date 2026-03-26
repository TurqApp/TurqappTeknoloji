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

function fail(message) {
  console.error(`[integration-seed-reset] ${message}`);
  process.exit(1);
}

async function ensureAdminClients() {
  if (cachedAdminClients) return cachedAdminClients;
  const rawServiceAccount = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || "").trim();
  if (!rawServiceAccount) {
    return null;
  }
  const [{ applicationDefault, cert, getApps, initializeApp }, { getFirestore }] =
    await Promise.all([
      import("firebase-admin/app"),
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
    db: getFirestore(),
  };
  return cachedAdminClients;
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

  fail("unable to resolve Firebase project id for integration seed reset");
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
      "set FIREBASE_SERVICE_ACCOUNT_JSON or refresh local firebase CLI auth for integration seed reset",
    );
  }

  const refreshed = await refreshFirebaseCliAccessToken(refreshToken);
  return refreshed.accessToken;
}

function documentUrl(projectId, targetPath) {
  const normalized = String(targetPath || "").trim().replace(/^\/+/, "");
  return (
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/${normalized}`
  );
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
    fail(`seed reset delete failed (${targetPath}): ${JSON.stringify(json)}`);
  }
}

async function main() {
  const stateFile =
    process.argv[2] ||
    process.env.INTEGRATION_SEED_STATE_FILE ||
    "artifacts/integration_seed/seed_state.json";

  let state;
  try {
    state = JSON.parse(await fs.readFile(stateFile, "utf8"));
  } catch (_) {
    console.log(`[integration-seed-reset] state file missing: ${stateFile}`);
    return;
  }

  const cleanupPaths = Array.isArray(state.cleanupPaths) ? state.cleanupPaths : [];
  const adminClients = await ensureAdminClients();

  if (adminClients) {
    for (const targetPath of cleanupPaths) {
      const normalized = String(targetPath || "").trim();
      if (!normalized) continue;
      try {
        await adminClients.db.doc(normalized).delete();
      } catch (_) {}
    }
  } else {
    const projectId = await resolveProjectId();
    const accessToken = await resolveGoogleAccessToken();
    for (const targetPath of cleanupPaths) {
      const normalized = String(targetPath || "").trim();
      if (!normalized) continue;
      await deleteDocument({
        projectId,
        accessToken,
        targetPath: normalized,
      });
    }
  }

  await fs.unlink(stateFile).catch(() => {});
  console.log(
    `[integration-seed-reset] deleted=${cleanupPaths.length} state=${stateFile}`,
  );
}

main().catch((error) => {
  console.error("[integration-seed-reset] failed", error);
  process.exit(1);
});
