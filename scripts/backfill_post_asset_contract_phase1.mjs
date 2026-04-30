#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const admin = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/firebase-admin",
));

function parseArgs(argv) {
  const args = {
    manifest: "",
    apply: false,
    limit: 0,
    offset: 0,
    docId: "",
    report: "",
    verifyLive: false,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = argv[index];
    if (!args.manifest && !value.startsWith("--")) {
      args.manifest = value;
      continue;
    }
    if (value === "--apply") {
      args.apply = true;
      continue;
    }
    if (value === "--limit") {
      args.limit = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
    if (value === "--offset") {
      args.offset = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
    if (value === "--doc-id") {
      args.docId = String(argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
    if (value === "--report") {
      args.report = String(argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
    if (value === "--verify-live") {
      args.verifyLive = true;
    }
  }

  if (!args.manifest) {
    throw new Error(
      "Usage: node scripts/backfill_post_asset_contract_phase1.mjs <manifest.ndjson> [--apply] [--verify-live] [--limit N] [--doc-id ID] [--report report.json]",
    );
  }

  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function readManifest(filePath) {
  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) return [];
  return raw
    .split(/\n+/)
    .map((line) => JSON.parse(line))
    .filter((entry) => entry && typeof entry === "object");
}

function asString(value) {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function stableJson(value) {
  return JSON.stringify(value ?? null);
}

function buildPhase1Patch(entry) {
  const patch = entry?.safePatch && typeof entry.safePatch === "object"
    ? entry.safePatch
    : {};
  return patch;
}

function pickEntries(entries, options) {
  let next = entries.filter((entry) => Object.keys(buildPhase1Patch(entry)).length > 0);
  if (options.docId) {
    next = next.filter((entry) => asString(entry.docId) === options.docId);
  }
  if (options.offset > 0) {
    next = next.slice(options.offset);
  }
  if (options.limit > 0) {
    next = next.slice(0, options.limit);
  }
  return next;
}

function initializeAdmin() {
  if (admin.apps.length > 0) return;
  admin.initializeApp();
}

function diffPatch(currentData, patch) {
  const changed = {};
  for (const [key, nextValue] of Object.entries(patch)) {
    const currentValue = currentData?.[key];
    if (stableJson(currentValue) !== stableJson(nextValue)) {
      changed[key] = {
        before: currentValue ?? null,
        after: nextValue,
      };
    }
  }
  return changed;
}

async function run() {
  const options = parseArgs(process.argv);
  const entries = pickEntries(readManifest(options.manifest), options);

  const summary = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    manifest: options.manifest,
    verifyLive: options.verifyLive,
    scannedManifestEntries: entries.length,
    offset: options.offset,
    touchedDocs: 0,
    skippedDocs: 0,
    missingDocs: 0,
    unchangedDocs: 0,
    patchFields: {
      thumbnail: 0,
      video: 0,
    },
    samples: [],
  };

  if (entries.length === 0) {
    if (options.report) {
      ensureDir(options.report);
      fs.writeFileSync(options.report, JSON.stringify(summary, null, 2));
    }
    console.log(JSON.stringify(summary, null, 2));
    return;
  }

  const requiresFirestore = options.apply || options.verifyLive;
  let db = null;
  let batch = null;
  let bulkWriter = null;
  let opCount = 0;

  if (requiresFirestore) {
    initializeAdmin();
    db = admin.firestore();
    if (options.apply && !options.verifyLive) {
      bulkWriter = db.bulkWriter();
    } else {
      batch = db.batch();
    }
  }

  for (const entry of entries) {
    const docId = asString(entry.docId);
    const patch = buildPhase1Patch(entry);
    if (!docId || Object.keys(patch).length === 0) {
      summary.skippedDocs += 1;
      continue;
    }

    let changed = {};
    if (requiresFirestore) {
      const ref = db.collection("Posts").doc(docId);
      const snap = await ref.get();
      if (!snap.exists) {
        summary.missingDocs += 1;
        continue;
      }

      changed = diffPatch(snap.data() || {}, patch);
      if (Object.keys(changed).length === 0) {
        summary.unchangedDocs += 1;
        continue;
      }
    } else {
      changed = Object.fromEntries(
        Object.entries(patch).map(([key, nextValue]) => [
          key,
          { before: "[manifest-only]", after: nextValue },
        ]),
      );
    }

    if (changed.thumbnail) summary.patchFields.thumbnail += 1;
    if (changed.video) summary.patchFields.video += 1;
    summary.touchedDocs += 1;

    if (summary.samples.length < 10) {
      summary.samples.push({
        docId,
        reasons: Array.isArray(entry.safeReasons) ? entry.safeReasons : [],
        changed,
      });
    }

    if (options.apply) {
      const ref = db.collection("Posts").doc(docId);
      if (bulkWriter) {
        bulkWriter.set(ref, patch, { merge: true });
      } else {
        batch.set(ref, patch, { merge: true });
        opCount += 1;
      }
      if (summary.touchedDocs % 1000 === 0) {
        console.log(
          JSON.stringify({
            progress: summary.touchedDocs,
            scannedManifestEntries: summary.scannedManifestEntries,
            mode: "apply",
          }),
        );
      }
      if (!bulkWriter && opCount >= 350) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }
  }

  if (options.apply && bulkWriter) {
    await bulkWriter.close();
  } else if (options.apply && opCount > 0) {
    await batch.commit();
  }

  if (options.report) {
    ensureDir(options.report);
    fs.writeFileSync(options.report, JSON.stringify(summary, null, 2));
  }

  console.log(JSON.stringify(summary, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
