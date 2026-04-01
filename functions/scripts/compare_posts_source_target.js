#!/usr/bin/env node
/* eslint-disable no-console */
const shared = require('./posts_migration_shared');

function hasContent(data) {
  return (
    shared.asString(data?.metin).length > 0 ||
    (Array.isArray(data?.img) && data.img.length > 0) ||
    shared.asString(data?.video).length > 0 ||
    shared.asString(data?.thumbnail).length > 0
  );
}

function compareDocs(source, target) {
  const checks = [
    ['metin', shared.asString(source?.metin), shared.asString(target?.metin)],
    ['userID', shared.asString(source?.userID), shared.asString(target?.userID)],
    ['scheduledAt', shared.asNum(source?.scheduledAt, 0), shared.asNum(target?.scheduledAt, 0)],
    ['yorum', shared.asBool(source?.yorum, true), shared.asBool(target?.yorum, true)],
    ['paylasGizliligi', shared.asNum(source?.paylasGizliligi, 0), shared.asNum(target?.paylasGizliligi, 0)],
    ['floodCount', shared.asNum(source?.floodCount, 0), shared.asNum(target?.floodCount, 0)],
    ['mainFlood', shared.asString(source?.mainFlood), shared.asString(target?.mainFlood)],
    ['targetHasAnyContent', true, hasContent(target)],
  ];

  return checks
    .filter(([, sourceValue, targetValue]) => JSON.stringify(sourceValue) !== JSON.stringify(targetValue))
    .map(([field, sourceValue, targetValue]) => ({
      field,
      source: sourceValue,
      target: targetValue,
    }));
}

function classifySource(data) {
  return {
    hasText: shared.asString(data?.metin).length > 0,
    hasImg: Array.isArray(data?.img) && data.img.length > 0,
    hasVideo: shared.asString(data?.video).length > 0,
    hasThumb: shared.asString(data?.thumbnail).length > 0,
    flood: shared.asBool(data?.flood, false),
    floodCount: shared.asNum(data?.floodCount, 0),
    mainFlood: shared.asString(data?.mainFlood),
    userID: shared.asString(data?.userID),
  };
}

async function run() {
  const options = shared.buildOptions();
  const apps = await shared.initializeApps(options);

  try {
    const targetSnap = await apps.targetDb.collection(options.targetCollection).get();
    const rows = [];
    let sourceMissing = 0;
    let compared = 0;
    let exactMatch = 0;
    let mismatch = 0;

    for (const doc of targetSnap.docs) {
      const docId = doc.id;
      const sourceSnap = await apps.sourceDb.collection(options.sourceCollection).doc(docId).get();
      if (!sourceSnap.exists) {
        sourceMissing += 1;
        rows.push({ docId, status: 'source_missing' });
        continue;
      }

      compared += 1;
      const sourceData = sourceSnap.data() || {};
      const targetData = doc.data() || {};
      const diffs = compareDocs(sourceData, targetData);

      if (diffs.length === 0) {
        exactMatch += 1;
        continue;
      }

      mismatch += 1;
      rows.push({
        docId,
        status: 'mismatch',
        source: classifySource(sourceData),
        diffs,
      });
    }

    rows.sort((a, b) => a.docId.localeCompare(b.docId));
    console.log(JSON.stringify({
      targetDocs: targetSnap.size,
      compared,
      exactMatch,
      mismatch,
      sourceMissing,
      sampleMismatches: rows.slice(0, 50),
    }, null, 2));
  } finally {
    await shared.deleteApps(apps);
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
