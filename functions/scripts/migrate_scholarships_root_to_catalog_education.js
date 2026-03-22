const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const DEFAULT_KEY_PATH =
  "/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";
const DEFAULT_STATE_FILE = path.join(
  __dirname,
  "migrate_scholarships_root_to_catalog_education.state.json",
);

const SRC_COLLECTION = "scholarships";
const DST_COLLECTION_PATH = ["catalog", "education", "scholarships"];
const DEFAULT_BATCH = Number(process.env.MIGRATE_BATCH || 100);

function arg(name, fallback = null) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  const next = process.argv[idx + 1];
  if (!next || next.startsWith("--")) return true;
  return next;
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function readMaybeBrokenJson(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  const firstBrace = raw.indexOf("{");
  return JSON.parse(firstBrace > 0 ? raw.slice(firstBrace) : raw);
}

function loadState(stateFile) {
  if (!fs.existsSync(stateFile)) {
    return {
      startedAt: Date.now(),
      finishedAt: null,
      mode: null,
      lastDocId: null,
      processed: 0,
      rootCopied: 0,
      subCopied: 0,
      skippedExisting: 0,
      failed: {},
      done: false,
    };
  }
  return JSON.parse(fs.readFileSync(stateFile, "utf8"));
}

function saveState(stateFile, state) {
  fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
}

function getDestinationCollection(db) {
  return db
    .collection(DST_COLLECTION_PATH[0])
    .doc(DST_COLLECTION_PATH[1])
    .collection(DST_COLLECTION_PATH[2]);
}

async function copyDocRecursive(srcRef, dstRef, applyMode) {
  const srcSnap = await srcRef.get();
  if (!srcSnap.exists) return { root: 0, sub: 0 };

  if (applyMode) {
    await dstRef.set(srcSnap.data() || {}, { merge: true });
  }

  let subCopied = 0;
  const subCols = await srcRef.listCollections();
  for (const subCol of subCols) {
    const subSnap = await subCol.get();
    for (const subDoc of subSnap.docs) {
      const childResult = await copyDocRecursive(
        subDoc.ref,
        dstRef.collection(subCol.id).doc(subDoc.id),
        applyMode,
      );
      subCopied += 1 + childResult.sub;
    }
  }

  return { root: 1, sub: subCopied };
}

async function main() {
  const keyPath = String(arg("key", DEFAULT_KEY_PATH));
  const stateFile = String(arg("state-file", DEFAULT_STATE_FILE));
  const batch = Number(arg("batch", DEFAULT_BATCH));
  const applyMode = hasFlag("apply");
  const resetState = hasFlag("reset-state");

  if (!fs.existsSync(keyPath)) {
    console.error("Key file not found:", keyPath);
    process.exit(1);
  }

  if (resetState && fs.existsSync(stateFile)) {
    fs.unlinkSync(stateFile);
  }

  const cred = readMaybeBrokenJson(keyPath);
  const app = admin.initializeApp(
    { credential: admin.credential.cert(cred) },
    "migrate-scholarships-root-to-catalog-education",
  );
  const db = app.firestore();

  const srcCol = db.collection(SRC_COLLECTION);
  const dstCol = getDestinationCollection(db);

  const sourceCount = (await srcCol.count().get()).data().count;
  const destinationCount = (await dstCol.count().get()).data().count;

  const state = loadState(stateFile);
  state.mode = applyMode ? "apply" : "dry-run";

  if (state.done && !resetState) {
    console.log("State already done. Use --reset-state to rerun.");
    console.log(state);
    return;
  }

  console.log("migration:start", {
    mode: state.mode,
    sourceCollection: SRC_COLLECTION,
    destinationPath: DST_COLLECTION_PATH.join("/"),
    sourceCount,
    destinationCount,
    resumeFrom: state.lastDocId,
    batch,
    stateFile,
    keyPath,
  });

  while (true) {
    let query = srcCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batch);

    if (state.lastDocId) {
      query = query.startAfter(state.lastDocId);
    }

    const snap = await query.get();
    if (snap.empty) {
      state.done = true;
      state.finishedAt = Date.now();
      saveState(stateFile, state);
      console.log("migration:done", {
        mode: state.mode,
        processed: state.processed,
        rootCopied: state.rootCopied,
        subCopied: state.subCopied,
        skippedExisting: state.skippedExisting,
        failed: Object.keys(state.failed).length,
      });
      return;
    }

    for (const doc of snap.docs) {
      state.lastDocId = doc.id;
      state.processed += 1;

      try {
        const dstDocRef = dstCol.doc(doc.id);
        const dstSnap = await dstDocRef.get();

        if (dstSnap.exists) {
          state.skippedExisting += 1;
        }

        const copied = await copyDocRecursive(doc.ref, dstDocRef, applyMode);
        state.rootCopied += copied.root;
        state.subCopied += copied.sub;
      } catch (e) {
        state.failed[doc.id] = String(e && e.message ? e.message : e);
      }

      if (state.processed % 20 === 0) {
        saveState(stateFile, state);
        console.log("migration:progress", {
          mode: state.mode,
          processed: state.processed,
          rootCopied: state.rootCopied,
          subCopied: state.subCopied,
          skippedExisting: state.skippedExisting,
          failed: Object.keys(state.failed).length,
          lastDocId: state.lastDocId,
        });
      }
    }

    saveState(stateFile, state);
  }
}

main().catch((e) => {
  console.error("migration:fatal", e);
  process.exit(1);
});
