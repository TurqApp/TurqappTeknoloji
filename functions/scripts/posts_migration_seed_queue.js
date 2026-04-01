#!/usr/bin/env node
/* eslint-disable no-console */
const {
  alignStartTimestamp,
  asBool,
  asNum,
  asString,
  buildOptions,
  deleteApps,
  formatTrTimestamp,
  initializeApps,
  limitGroupsByScheduleWindow,
  loadSourceFloodGroups,
  nextScheduleTimestamp,
  writeReport,
} = require('./posts_migration_shared');

const QUEUE_COLLECTION = 'postsMigrationQueue';

function asMapList(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      if (!item || typeof item !== 'object' || Array.isArray(item)) return null;
      return {
        url: asString(item.url),
        aspectRatio: asNum(item.aspectRatio, 1),
      };
    })
    .filter(Boolean);
}

function parseSourceImageUrls(data) {
  const out = [];
  if (!Array.isArray(data?.img)) return out;
  for (const item of data.img) {
    if (item && typeof item === 'object' && !Array.isArray(item)) {
      const url = asString(item.url);
      if (url) out.push(url);
      continue;
    }
    const url = asString(item);
    if (url) out.push(url);
  }
  return out;
}

function buildChildSeed(item) {
  const sourceData = item.data || {};
  return {
    docId: item.id,
    index: item.index,
    userID: asString(sourceData.userID),
    ad: asBool(sourceData.ad, false),
    aspectRatio: asNum(sourceData.aspectRatio, 1),
    debugMode: asBool(sourceData.debugMode, false),
    editTime: asNum(sourceData.editTime, 0),
    isAd: asBool(sourceData.isAd, false),
    konum: asString(sourceData.konum),
    locationCity: asString(sourceData.locationCity),
    metin: asString(sourceData.metin),
    originalPostID: asString(sourceData.originalPostID),
    originalUserID: asString(sourceData.originalUserID),
    paylasGizliligi: asNum(sourceData.paylasGizliligi, 0),
    scheduledAt: asNum(sourceData.scheduledAt, 0),
    sourceImgMap: asMapList(sourceData.imgMap),
    sourceImageUrls: parseSourceImageUrls(sourceData),
    sourceThumbnailUrl: asString(sourceData.thumbnail),
    sourceTimeStamp: asNum(sourceData.timeStamp, 0),
    sourceVideoUrl: asString(sourceData.video),
    tags: Array.isArray(sourceData.tags) ? sourceData.tags : [],
    yorum: asBool(sourceData.yorum, true),
  };
}

async function run() {
  const options = buildOptions();
  const apps = await initializeApps(options);

  try {
    console.log(`Mod             : ${options.apply ? 'APPLY' : 'DRY-RUN'}`);
    console.log(`Queue koleksiyon : ${QUEUE_COLLECTION}`);
    const firstPublishAt = alignStartTimestamp(options.startTimestamp, options);
    console.log(`Baslangic anchor: ${formatTrTimestamp(options.startTimestamp)}`);
    console.log(`Ilk tetik       : ${formatTrTimestamp(firstPublishAt)}`);
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

    const limitedGroups =
      options.limitGroups > 0
        ? eligibleGroups.slice(0, options.limitGroups)
        : eligibleGroups;
    const scheduledGroups = limitGroupsByScheduleWindow(
      limitedGroups,
      firstPublishAt,
      options,
    );

    const report = {
      generatedAt: new Date().toISOString(),
      mode: options.apply ? 'apply' : 'dry-run',
      source: {
        scannedDocs: loaded.scannedDocs,
        scannedFloodDocs: loaded.scannedFloodDocs,
        totalFloodGroups: loaded.groups.length,
        skippedMissingRootGroups: loaded.groups.filter((group) => !group.hasRoot).length,
      },
      summary: {
        totalEligibleGroups: limitedGroups.length,
        totalScheduledGroups: scheduledGroups.length,
        seededGroups: 0,
        existingGroups: 0,
        seededDocs: 0,
      },
      groups: [],
    };

    let scheduleTimestamp = firstPublishAt;

    for (const group of scheduledGroups) {
      const queueRef = apps.targetDb.collection(QUEUE_COLLECTION).doc(group.rootId);
      const existing = await queueRef.get();
      const groupReport = {
        rootId: group.rootId,
        docCount: group.docCount,
        kind: group.kind,
        publishAt: scheduleTimestamp,
        publishLabel: formatTrTimestamp(scheduleTimestamp),
        status: existing.exists ? 'existing' : 'seeded',
      };

      if (existing.exists) {
        report.summary.existingGroups += 1;
        report.groups.push(groupReport);
        scheduleTimestamp = nextScheduleTimestamp(scheduleTimestamp, options);
        continue;
      }

      if (options.apply) {
        const batch = apps.targetDb.batch();
        const now = Date.now();
        batch.set(queueRef, {
          active: true,
          baseId: group.baseId,
          createdAt: now,
          docCount: group.docCount,
          kind: group.kind,
          lastError: '',
          lastErrorAt: 0,
          lastProcessAt: 0,
          leaseOwner: '',
          leaseUntil: 0,
          mediaAttempts: 0,
          mediaPreparedAt: 0,
          publishAt: scheduleTimestamp,
          publishAttempts: 0,
          publishedAt: 0,
          rootId: group.rootId,
          sourceRootTimeStamp: group.sourceRootTimeStamp,
          state: 'queued',
          updatedAt: now,
        });

        for (const item of group.docs) {
          const childRef = queueRef.collection('docs').doc(item.id);
          batch.set(childRef, buildChildSeed(item));
          report.summary.seededDocs += 1;
        }

        await batch.commit();
      } else {
        report.summary.seededDocs += group.docCount;
      }

      report.summary.seededGroups += 1;
      report.groups.push(groupReport);
      scheduleTimestamp = nextScheduleTimestamp(scheduleTimestamp, options);
    }

    const reportPath = writeReport(
      options.reportDir,
      options.apply ? 'posts_migration_seed_queue' : 'posts_migration_seed_queue_dry_run',
      report,
    );

    console.log(`Seed grup       : ${report.summary.seededGroups}`);
    console.log(`Var olan grup   : ${report.summary.existingGroups}`);
    console.log(`Planli grup     : ${report.summary.totalScheduledGroups}`);
    console.log(`Seed doc        : ${report.summary.seededDocs}`);
    console.log(`Rapor           : ${reportPath}`);
  } finally {
    await deleteApps(apps);
  }
}

run().catch((error) => {
  console.error('HATA:', error.message);
  process.exit(1);
});
