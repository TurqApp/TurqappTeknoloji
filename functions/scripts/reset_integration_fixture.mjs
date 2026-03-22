import fs from "node:fs/promises";
import process from "node:process";

import { applicationDefault, cert, getApps, initializeApp } from "firebase-admin/app";
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

  ensureAdminApp();
  const db = getFirestore();
  const cleanupPaths = Array.isArray(state.cleanupPaths) ? state.cleanupPaths : [];

  for (const targetPath of cleanupPaths) {
    const normalized = String(targetPath || "").trim();
    if (!normalized) continue;
    try {
      await db.doc(normalized).delete();
    } catch (_) {}
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
