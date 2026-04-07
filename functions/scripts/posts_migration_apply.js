#!/usr/bin/env node
/* eslint-disable no-console */
const {
  alignStartTimestamp,
  buildOptions,
  deleteApps,
  filterGroupsMissingTargetRoots,
  formatTrTimestamp,
  getHlsTriggerTimestamp,
  initializeApps,
  limitGroupsByScheduleWindow,
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
    const firstPublishAt = alignStartTimestamp(options.startTimestamp, options);
    const firstHlsTriggerAt = getHlsTriggerTimestamp(firstPublishAt, options);
    console.log(`Baslangic anchor: ${formatTrTimestamp(options.startTimestamp)}`);
    console.log(`Ilk tetik       : ${formatTrTimestamp(firstPublishAt)}`);
    if (options.hlsTriggerLeadMinutes > 0) {
      console.log(`Ilk HLS tetik   : ${formatTrTimestamp(firstHlsTriggerAt)}`);
    }
    if (options.limitDays > 0) {
      console.log(`Gun limiti      : ${options.limitDays}`);
    }

    const loaded = await loadSourceFloodGroups(apps.sourceDb, options);
    const eligibleGroups = loaded.groups
      .filter((group) => group.hasRoot)
      .sort((a, b) => {
        if (a.sourceRootTimeStamp !== b.sourceRootTimeStamp) {
          return a.sourceRootTimeStamp - b.sourceRootTimeStamp;
        }
        return a.rootId.localeCompare(b.rootId);
      });

    const remainingGroups = options.skipExistingRoot
      ? await filterGroupsMissingTargetRoots(
          apps.targetDb,
          options.targetCollection,
          eligibleGroups,
        )
      : eligibleGroups;

    const limitedGroups =
      options.limitGroups > 0
        ? remainingGroups.slice(0, options.limitGroups)
        : remainingGroups;
    const scheduledGroups = limitGroupsByScheduleWindow(
      limitedGroups,
      firstPublishAt,
      options,
    );

    const plans = [];
    let scheduleTimestamp = firstPublishAt;
    for (const group of scheduledGroups) {
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
        for (const skipped of plan.skipped || []) {
          batch.delete(
            apps.targetDb.collection(options.targetCollection).doc(skipped.docId),
          );
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
        anchorLabel: formatTrTimestamp(options.startTimestamp),
        firstTriggerAt: firstPublishAt,
        firstTriggerLabel: formatTrTimestamp(firstPublishAt),
        hlsTriggerLeadMinutes: options.hlsTriggerLeadMinutes,
        firstHlsTriggerAt,
        firstHlsTriggerLabel: formatTrTimestamp(firstHlsTriggerAt),
        intervalMinutes: options.intervalMinutes,
        triggerLeadMinutes: options.triggerLeadMinutes,
        dailyStartHour: options.dailyStartHour,
        dailyEndHour: options.dailyEndHour,
        dailyEndMinute: options.dailyEndMinute,
        limitDays: options.limitDays,
        limitGroups: options.limitGroups,
        deferHls: options.deferHls,
        skipExistingRoot: options.skipExistingRoot,
      },
      source: {
        scannedDocs: loaded.scannedDocs,
        scannedFloodDocs: loaded.scannedFloodDocs,
        totalFloodGroups: loaded.groups.length,
        eligibleFloodGroups: eligibleGroups.length,
        existingRootGroups: eligibleGroups.length - remainingGroups.length,
        remainingFloodGroups: remainingGroups.length,
      },
      summary: {
        ...summarizePlans(plans),
        plannedGroups: scheduledGroups.length,
        remainingGroupsAfterRun: Math.max(
          remainingGroups.length - (options.apply ? writtenGroups : 0),
          0,
        ),
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
    console.log(`Parsiyel grup   : ${report.summary.partialGroups}`);
    console.log(`Mevcut root     : ${report.source.existingRootGroups}`);
    console.log(`Planli grup     : ${report.summary.plannedGroups}`);
    console.log(`Yazilan grup    : ${writtenGroups}`);
    console.log(`Yazilan doc     : ${writtenDocs}`);
    console.log(`Kalan grup      : ${report.summary.remainingGroupsAfterRun}`);
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
