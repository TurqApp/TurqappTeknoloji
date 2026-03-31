#!/usr/bin/env node
/* eslint-disable no-console */
const {initializeApps, deleteApps, buildOptions, asString} = require('./posts_migration_shared');

function hasMedia(data) {
  return (
    asString(data.video).length > 0 ||
    asString(data.hlsMasterUrl).length > 0 ||
    asString(data.thumbnail).length > 0 ||
    (Array.isArray(data.img) && data.img.length > 0)
  );
}

function hasImage(data) {
  return Array.isArray(data?.img) && data.img.length > 0;
}

function hasText(data) {
  return asString(data?.metin).length > 0;
}

function hasVideo(data) {
  return asString(data?.video).length > 0;
}

function buildSummary(docId, sourceSnap, postSnap, queueRoot, queueSnap) {
  const sourceData = sourceSnap.exists ? sourceSnap.data() || {} : {};
  const targetData = postSnap.exists ? postSnap.data() || {} : {};
  const queueData = queueSnap.exists ? queueSnap.data() || {} : {};
  return {
    docId,
    sourceExists: sourceSnap.exists,
    sourceHasImg: hasImage(sourceData),
    sourceHasText: hasText(sourceData),
    sourceHasVideo: hasVideo(sourceData),
    targetExists: postSnap.exists,
    targetHasImg: hasImage(targetData),
    targetHasText: hasText(targetData),
    targetHasVideo: hasVideo(targetData),
    targetUploading: Boolean(targetData.isUploading),
    targetHlsStatus: asString(targetData.hlsStatus),
    queueRoot,
    queueState: asString(queueData.state),
    queuePublishAt: Number(queueData.publishAt || 0),
  };
}

async function run() {
  const docIds = process.argv
    .slice(2)
    .filter((value) => !String(value).startsWith('--'))
    .map((value) => asString(value))
    .filter(Boolean);
  if (docIds.length === 0) {
    throw new Error('docId gerekli');
  }
  const rehide = process.argv.includes('--rehide-root');
  const summaryMode = process.argv.includes('--summary') || docIds.length > 1;
  const options = buildOptions();
  const apps = await initializeApps(options);
  try {
    const results = [];

    for (const docId of docIds) {
      const sourceSnap = await apps.sourceDb.collection(options.sourceCollection).doc(docId).get();
      const postSnap = await apps.targetDb.collection(options.targetCollection).doc(docId).get();
      const queueRoot = docId.replace(/_[0-9]+$/, '_0');
      const queueSnap = await apps.targetDb.collection('postsMigrationQueue').doc(queueRoot).get();
      let repair = null;

      if (rehide && postSnap.exists) {
        const rootData = postSnap.data() || {};
        const floodCount = Number(rootData.floodCount || 0);
        const baseId = queueRoot.replace(/_0$/, '');
        const batch = apps.targetDb.batch();
        let touched = 0;
        const repairedIds = [];
        for (let i = 0; i < floodCount; i += 1) {
          const childId = `${baseId}_${i}`;
          const childRef = apps.targetDb.collection(options.targetCollection).doc(childId);
          const childSnap = await childRef.get();
          if (!childSnap.exists) continue;
          const childData = childSnap.data() || {};
          if (childData.isUploading === false && !hasMedia(childData)) {
            batch.set(childRef, {
              isUploading: true,
              updatedAt: Date.now(),
            }, {merge: true});
            touched += 1;
            repairedIds.push(childId);
          }
        }
        if (touched > 0) {
          await batch.commit();
        }
        repair = {touched, repairedIds};
      }

      if (summaryMode) {
        results.push(buildSummary(docId, sourceSnap, postSnap, queueRoot, queueSnap));
      } else {
        results.push({
          docId,
          sourceExists: sourceSnap.exists,
          sourcePost: sourceSnap.exists ? sourceSnap.data() : null,
          exists: postSnap.exists,
          post: postSnap.exists ? postSnap.data() : null,
          queueRoot,
          queue: queueSnap.exists ? queueSnap.data() : null,
          repair,
        });
      }
    }
    console.log(JSON.stringify(summaryMode ? results : results[0], null, 2));
  } finally {
    await deleteApps(apps);
  }
}

run().catch((error) => {
  console.error('HATA:', error.message);
  process.exit(1);
});
