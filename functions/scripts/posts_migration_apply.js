#!/usr/bin/env node
/* eslint-disable no-console */
const {
  alignStartTimestamp,
  buildOptions,
  deleteApps,
  formatTrTimestamp,
  initializeApps,
  loadSourceFloodGroups,
  nextScheduleTimestamp,
  prepareGroupPlan,
  summarizePlans,
  writeReport,
} = require('./posts_migration_shared');

async function run() {
  const options = buildOptions();
  const apps = await initializeApps(options);
  const userCache = new Map();

  try {
    console.log(`Mod             : ${options.apply ? 'APPLY' : 'DRY-RUN'}`);
    console.log(`Baslangic slotu : ${formatTrTimestamp(options.startTimestamp)}`);

    const loaded = await loadSourceFloodGroups(apps.sourceDb, options);
    const eligibleGroups = loaded.groups
      .filter((group) => group.hasRoot)
      .sort((a, b) => {
        if (a.sourceRootTimeStamp !== b.sourceRootTimeStamp) {
          return a.sourceRootTimeStamp - b.sourceRootTimeStamp;
        }
        return a.rootId.localeCompare(b.rootId);
      });

    const limitedGroups =
      options.limitGroups > 0
        ? eligibleGroups.slice(0, options.limitGroups)
        : eligibleGroups;

    const plans = [];
    let scheduleTimestamp = alignStartTimestamp(options.startTimestamp, options);
    for (const group of limitedGroups) {
      const plan = await prepareGroupPlan(
        group,
        scheduleTimestamp,
        apps.targetDb,
        apps.targetBucket,
        options,
        userCache,
      );
      plans.push(plan);
      scheduleTimestamp = nextScheduleTimestamp(scheduleTimestamp, options);
    }

    let writtenGroups = 0;
    let writtenDocs = 0;

    if (options.apply) {
      for (const plan of plans) {
        if (plan.status !== 'ready') continue;
        const batch = apps.targetDb.batch();
        for (const doc of plan.docs) {
          const ref = apps.targetDb
            .collection(options.targetCollection)
            .doc(doc.docId);
          batch.set(ref, doc.payload, { merge: true });
          writtenDocs += 1;
        }
        await batch.commit();
        writtenGroups += 1;
      }
    }

    const report = {
      generatedAt: new Date().toISOString(),
      mode: options.apply ? 'apply' : 'dry-run',
      options: {
        sourceCollection: options.sourceCollection,
        targetCollection: options.targetCollection,
        startTimestamp: options.startTimestamp,
        startLabel: formatTrTimestamp(options.startTimestamp),
        intervalMinutes: options.intervalMinutes,
        dailyStartHour: options.dailyStartHour,
        dailyEndHour: options.dailyEndHour,
        dailyEndMinute: options.dailyEndMinute,
        limitGroups: options.limitGroups,
      },
      source: {
        scannedDocs: loaded.scannedDocs,
        scannedFloodDocs: loaded.scannedFloodDocs,
        totalFloodGroups: loaded.groups.length,
      },
      summary: {
        ...summarizePlans(plans),
        writtenGroups,
        writtenDocs,
      },
      groups: plans,
    };

    const reportPath = writeReport(
      options.reportDir,
      options.apply ? 'posts_migration_apply' : 'posts_migration_dry_run',
      report,
    );

    console.log(`Hazir grup      : ${report.summary.readyGroups}`);
    console.log(`Yazilan grup    : ${writtenGroups}`);
    console.log(`Yazilan doc     : ${writtenDocs}`);
    console.log(`Basarisiz grup  : ${report.summary.failedGroups}`);
    console.log(`Rapor           : ${reportPath}`);
  } finally {
    await deleteApps(apps);
  }
}

run().catch((error) => {
  console.error('HATA:', error.message);
  process.exit(1);
});
