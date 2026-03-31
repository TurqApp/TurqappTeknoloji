#!/usr/bin/env node
/* eslint-disable no-console */
const shared = require('./posts_migration_shared');

function stringify(value) {
  return JSON.stringify(value ?? null);
}

async function run() {
  const options = shared.buildOptions();
  const apps = await shared.initializeApps(options);
  const userCache = new Map();

  try {
    const source = await shared.loadSourceFloodGroups(apps.sourceDb, options);
    const groupMap = new Map(source.groups.map((group) => [group.rootId, group]));
    const queueSnap = await apps.targetDb.collection('postsMigrationQueue').get();

    let repairedGroups = 0;
    let repairedDocs = 0;
    const touchedRoots = [];
    let batch = apps.targetDb.batch();
    let opCount = 0;

    for (const queueDoc of queueSnap.docs) {
      const queueData = queueDoc.data() || {};
      const state = shared.asString(queueData.state);
      if (!['published', 'published_partial'].includes(state)) continue;

      const group = groupMap.get(queueDoc.id);
      if (!group || !group.hasRoot) continue;

      const publishAt = shared.asNum(queueData.publishAt, 0);
      const plan = await shared.prepareGroupPlan(
        group,
        publishAt,
        apps.targetDb,
        apps.targetBucket,
        options,
        userCache,
      );
      if (plan.status !== 'ready') continue;

      let groupTouched = false;

      for (const item of plan.docs) {
        const ref = apps.targetDb.collection(options.targetCollection).doc(item.docId);
        const snap = await ref.get();
        if (!snap.exists) continue;

        const data = snap.data() || {};
        const patch = {};

        if (stringify(data.img) !== stringify(item.payload.img)) {
          patch.img = item.payload.img;
          patch.imgMap = item.payload.imgMap;
        }

        if (shared.asString(data.thumbnail) !== shared.asString(item.payload.thumbnail)) {
          patch.thumbnail = item.payload.thumbnail;
        }

        if (Object.keys(patch).length === 0) continue;

        batch.set(ref, patch, { merge: true });
        opCount += 1;
        repairedDocs += 1;
        groupTouched = true;

        if (opCount >= 350) {
          await batch.commit();
          batch = apps.targetDb.batch();
          opCount = 0;
        }
      }

      if (groupTouched) {
        repairedGroups += 1;
        touchedRoots.push(queueDoc.id);
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }

    console.log(JSON.stringify({
      repairedGroups,
      repairedDocs,
      touchedRoots,
    }, null, 2));
  } finally {
    await shared.deleteApps(apps);
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
