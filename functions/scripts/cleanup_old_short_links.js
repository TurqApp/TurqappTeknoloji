#!/usr/bin/env node
/* eslint-disable no-console */

const admin = require("firebase-admin");

const SHORT_ROUTES = "shortRoutes";
const PREFERRED_ID_RE = /^[A-Za-z0-9_-]{4,12}$/;

function parseArgs(argv) {
  return {
    apply: argv.includes("--apply"),
  };
}

function isPreferredShortId(value) {
  const v = String(value || "").trim();
  return PREFERRED_ID_RE.test(v);
}

function shouldDeleteRoute(data) {
  const key = String(data.key || "").trim();
  const shortId = String(data.shortId || "").trim();
  return !isPreferredShortId(key) || !isPreferredShortId(shortId);
}

function ensureAdmin() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
}

async function main() {
  const { apply } = parseArgs(process.argv.slice(2));
  ensureAdmin();
  const db = admin.firestore();

  const routesSnap = await db.collection(SHORT_ROUTES).get();
  console.log(`Total shortRoutes: ${routesSnap.size}`);

  const routeDeletes = [];
  const entityDeletes = [];

  for (const doc of routesSnap.docs) {
    const data = doc.data() || {};
    if (!shouldDeleteRoute(data)) continue;

    routeDeletes.push(doc.ref);

    const entityPath = String(data.entityPath || "").trim();
    const routeShortId = String(data.shortId || "").trim();
    if (entityPath) {
      try {
        const entityRef = db.doc(entityPath);
        const entitySnap = await entityRef.get();
        if (entitySnap.exists) {
          const entityData = entitySnap.data() || {};
          const entityShortId = String(entityData.shortId || "").trim();
          if (!entityShortId || entityShortId === routeShortId || !isPreferredShortId(entityShortId)) {
            entityDeletes.push(entityRef);
          }
        }
      } catch (e) {
        console.warn(`Entity read failed for ${entityPath}:`, e.message || e);
      }
    }
  }

  const dedupEntityPaths = new Set(entityDeletes.map((r) => r.path));
  const uniqueEntityDeletes = Array.from(dedupEntityPaths).map((p) => db.doc(p));

  console.log(`Old/invalid route candidates: ${routeDeletes.length}`);
  console.log(`Linked shortLinks/public candidates: ${uniqueEntityDeletes.length}`);

  if (!apply) {
    console.log("Dry run complete. Re-run with --apply to delete.");
    process.exit(0);
  }

  let deletedRoutes = 0;
  let deletedEntities = 0;

  const chunk = 400;
  for (let i = 0; i < routeDeletes.length; i += chunk) {
    const batch = db.batch();
    for (const ref of routeDeletes.slice(i, i + chunk)) {
      batch.delete(ref);
      deletedRoutes += 1;
    }
    await batch.commit();
  }

  for (let i = 0; i < uniqueEntityDeletes.length; i += chunk) {
    const batch = db.batch();
    for (const ref of uniqueEntityDeletes.slice(i, i + chunk)) {
      batch.delete(ref);
      deletedEntities += 1;
    }
    await batch.commit();
  }

  console.log(`Deleted routes: ${deletedRoutes}`);
  console.log(`Deleted entity shortLinks/public: ${deletedEntities}`);
  console.log("Cleanup finished.");
}

main().catch((e) => {
  console.error("cleanup_old_short_links failed:", e);
  process.exit(1);
});

