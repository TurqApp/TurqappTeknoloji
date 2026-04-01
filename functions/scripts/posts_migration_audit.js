#!/usr/bin/env node
/* eslint-disable no-console */
const {
  alignStartTimestamp,
  buildOptions,
  deleteApps,
  formatTrTimestamp,
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
    console.log('Mod             : AUDIT');
    console.log(`Kaynak          : ${options.sourceCollection}`);
    console.log(`Hedef           : ${options.targetCollection}`);
    const firstPublishAt = alignStartTimestamp(options.startTimestamp, options);
    console.log(`Baslangic anchor: ${formatTrTimestamp(options.startTimestamp)}`);
    console.log(`Ilk tetik       : ${formatTrTimestamp(firstPublishAt)}`);
    if (options.limitDays > 0) {
      console.log(`Gun limiti      : ${options.limitDays}`);
    }

    const loaded = await loadSourceFloodGroups(apps.sourceDb, options);
    const eligibleGroups = loaded.groups.filter((group) => group.hasRoot);
    const sortedGroups = eligibleGroups.sort((a, b) => {
      if (a.sourceRootTimeStamp !== b.sourceRootTimeStamp) {
        return a.sourceRootTimeStamp - b.sourceRootTimeStamp;
      }
      return a.rootId.localeCompare(b.rootId);
    });

    const limitedGroups =
      options.limitGroups > 0
        ? sortedGroups.slice(0, options.limitGroups)
        : sortedGroups;
    const scheduledGroups = limitGroupsByScheduleWindow(
      limitedGroups,
      firstPublishAt,
      options,
    );

    const skippedRootPlans = loaded.groups
      .filter((group) => !group.hasRoot)
      .map((group) => ({
        baseId: group.baseId,
        rootId: group.rootId,
        status: 'skipped',
        reason: 'missing_root_0',
        scheduleTimestamp: 0,
        scheduleLabel: '',
        docCount: group.docCount,
        kind: group.kind,
        docs: [],
      }));

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

    const report = {
      generatedAt: new Date().toISOString(),
      mode: 'audit',
      options: {
        sourceCollection: options.sourceCollection,
        targetCollection: options.targetCollection,
        startTimestamp: options.startTimestamp,
        anchorLabel: formatTrTimestamp(options.startTimestamp),
        firstTriggerAt: firstPublishAt,
        firstTriggerLabel: formatTrTimestamp(firstPublishAt),
        intervalMinutes: options.intervalMinutes,
        triggerLeadMinutes: options.triggerLeadMinutes,
        dailyStartHour: options.dailyStartHour,
        dailyEndHour: options.dailyEndHour,
        dailyEndMinute: options.dailyEndMinute,
        limitDays: options.limitDays,
        limitGroups: options.limitGroups,
      },
      source: {
        scannedDocs: loaded.scannedDocs,
        scannedFloodDocs: loaded.scannedFloodDocs,
        totalFloodGroups: loaded.groups.length,
        totalEligibleFloodGroups: eligibleGroups.length,
        totalSkippedRootMissingGroups: skippedRootPlans.length,
      },
      summary: summarizePlans([...plans, ...skippedRootPlans]),
      groups: [...plans, ...skippedRootPlans],
    };

    const reportPath = writeReport(options.reportDir, 'posts_migration_audit', report);
    console.log(`Hazir grup      : ${report.summary.readyGroups}`);
    console.log(`Parsiyel grup   : ${report.summary.partialGroups}`);
    console.log(`Atlanan grup    : ${report.summary.skippedGroups}`);
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
