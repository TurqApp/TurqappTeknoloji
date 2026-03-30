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

async function run() {
  const docId = asString(process.argv[2]);
  if (!docId) {
    throw new Error('docId gerekli');
  }
  const rehide = process.argv.includes('--rehide-root');
  const options = buildOptions();
  const apps = await initializeApps(options);
  try {
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

    console.log(JSON.stringify({
      docId,
      exists: postSnap.exists,
      post: postSnap.exists ? postSnap.data() : null,
      queueRoot,
      queue: queueSnap.exists ? queueSnap.data() : null,
      repair,
    }, null, 2));
  } finally {
    await deleteApps(apps);
  }
}

run().catch((error) => {
  console.error('HATA:', error.message);
  process.exit(1);
});
