#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const DEFAULT_SOURCE_KEY =
  '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-2a9c7ed65e.json';
const DEFAULT_TARGET_KEY =
  '/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json';

const DEFAULT_SOURCE_BUCKET = 'burs-city.appspot.com';
const DEFAULT_TARGET_BUCKET = 'turqappteknoloji.firebasestorage.app';
const DEFAULT_CDN_DOMAIN = 'cdn.turqapp.com';
const DEFAULT_SOURCE_COLLECTION = 'Posts';
const DEFAULT_TARGET_COLLECTION = 'Posts';
const DEFAULT_USERS_COLLECTION = 'users';
const DEFAULT_START_TIMESTAMP = 1774857600000;
const DEFAULT_INTERVAL_MINUTES = 60;
const DEFAULT_TRIGGER_LEAD_MINUTES = 10;
const DEFAULT_DAILY_START_HOUR = 11;
const DEFAULT_DAILY_END_HOUR = 23;
const DEFAULT_DAILY_END_MINUTE = 59;
const DEFAULT_PAGE_SIZE = 1000;
const DEFAULT_LIMIT_DAYS = 0;
const DEFAULT_REPORT_DIR = path.resolve(
  __dirname,
  '..',
  'reports',
);
const TR_OFFSET_MS = 3 * 60 * 60 * 1000;
const IMAGE_EXT_CANDIDATES = ['webp', 'jpg', 'jpeg', 'png'];
const THUMB_EXT_CANDIDATES = ['webp', 'jpg', 'jpeg', 'png'];

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function asString(value, fallback = '') {
  if (value === null || value === undefined) return fallback;
  return String(value).trim();
}

function asBool(value, fallback = false) {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') return true;
    if (normalized === 'false' || normalized === '0') return false;
  }
  return fallback;
}

function asNum(value, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value.trim());
    if (Number.isFinite(parsed)) return parsed;
  }
  if (value && typeof value.toMillis === 'function') {
    return value.toMillis();
  }
  return fallback;
}

function asStringList(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      if (item && typeof item === 'object' && !Array.isArray(item)) {
        return asString(item.url);
      }
      return asString(item);
    })
    .filter((item) => item.length > 0);
}

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

function loadServiceAccount(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    throw new Error(`Service account bulunamadi: ${filePath}`);
  }
  let raw = fs.readFileSync(filePath, 'utf8');
  const firstBrace = raw.indexOf('{');
  if (firstBrace > 0) raw = raw.slice(firstBrace);
  return JSON.parse(raw);
}

function buildOptions() {
  return {
    sourceKey: arg('source-key', DEFAULT_SOURCE_KEY),
    targetKey: arg('target-key', DEFAULT_TARGET_KEY),
    sourceBucket: arg('source-bucket', DEFAULT_SOURCE_BUCKET),
    targetBucket: arg('target-bucket', DEFAULT_TARGET_BUCKET),
    cdnDomain: arg('cdn-domain', DEFAULT_CDN_DOMAIN),
    sourceCollection: arg('source-collection', DEFAULT_SOURCE_COLLECTION),
    targetCollection: arg('target-collection', DEFAULT_TARGET_COLLECTION),
    usersCollection: arg('users-collection', DEFAULT_USERS_COLLECTION),
    startTimestamp: Number(arg('start-timestamp', DEFAULT_START_TIMESTAMP)),
    intervalMinutes: Number(arg('interval-minutes', DEFAULT_INTERVAL_MINUTES)),
    triggerLeadMinutes: Number(
      arg('trigger-lead-minutes', DEFAULT_TRIGGER_LEAD_MINUTES),
    ),
    dailyStartHour: Number(arg('daily-start-hour', DEFAULT_DAILY_START_HOUR)),
    dailyEndHour: Number(arg('daily-end-hour', DEFAULT_DAILY_END_HOUR)),
    dailyEndMinute: Number(arg('daily-end-minute', DEFAULT_DAILY_END_MINUTE)),
    pageSize: Number(arg('page-size', DEFAULT_PAGE_SIZE)),
    limitDays: Number(arg('limit-days', DEFAULT_LIMIT_DAYS)),
    reportDir: arg('report-dir', DEFAULT_REPORT_DIR),
    limitGroups: Number(arg('limit-groups', '0')),
    apply: hasFlag('apply'),
  };
}

function buildCdnUrl(cdnDomain, storagePath) {
  return `https://${cdnDomain}/${storagePath}`;
}

function buildHlsUrl(cdnDomain, docId) {
  return buildCdnUrl(cdnDomain, `Posts/${docId}/hls/master.m3u8`);
}

function buildVideoMp4Url(cdnDomain, docId) {
  return buildCdnUrl(cdnDomain, `Posts/${docId}/video.mp4`);
}

function buildThumbUrl(cdnDomain, storagePath) {
  return buildCdnUrl(cdnDomain, storagePath);
}

function parseFloodIdentity(docId) {
  const lastUnderscore = docId.lastIndexOf('_');
  if (lastUnderscore <= 0) return null;
  const baseId = docId.substring(0, lastUnderscore);
  const index = Number.parseInt(docId.substring(lastUnderscore + 1), 10);
  if (!Number.isFinite(index)) return null;
  return {
    baseId,
    index,
    isRoot: index === 0,
    rootId: `${baseId}_0`,
  };
}

function getTrParts(timestamp) {
  const d = new Date(timestamp + TR_OFFSET_MS);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth(),
    day: d.getUTCDate(),
    hour: d.getUTCHours(),
    minute: d.getUTCMinutes(),
    second: d.getUTCSeconds(),
    millisecond: d.getUTCMilliseconds(),
  };
}

function buildTrTimestamp(parts) {
  return (
    Date.UTC(
      parts.year,
      parts.month,
      parts.day,
      parts.hour,
      parts.minute,
      parts.second || 0,
      parts.millisecond || 0,
    ) - TR_OFFSET_MS
  );
}

function floorToInterval(timestamp, intervalMinutes) {
  const parts = getTrParts(timestamp);
  const totalMinutes = parts.hour * 60 + parts.minute;
  const floored = Math.floor(totalMinutes / intervalMinutes) * intervalMinutes;
  return buildTrTimestamp({
    ...parts,
    hour: Math.floor(floored / 60),
    minute: floored % 60,
    second: 0,
    millisecond: 0,
  });
}

function getWindowBounds(options) {
  return {
    startMinutes: options.dailyStartHour * 60,
    endMinutes: options.dailyEndHour * 60 + options.dailyEndMinute,
  };
}

function getTriggerLeadMs(options) {
  return Math.max(0, asNum(options.triggerLeadMinutes, 0)) * 60 * 1000;
}

function diffTrCalendarDays(fromTimestamp, toTimestamp) {
  const from = getTrParts(fromTimestamp);
  const to = getTrParts(toTimestamp);
  const fromDay = Date.UTC(from.year, from.month, from.day);
  const toDay = Date.UTC(to.year, to.month, to.day);
  return Math.floor((toDay - fromDay) / (24 * 60 * 60 * 1000));
}

function alignAnchorTimestamp(timestamp, options) {
  let aligned = floorToInterval(timestamp, options.intervalMinutes);
  let parts = getTrParts(aligned);
  const bounds = getWindowBounds(options);
  const totalMinutes = parts.hour * 60 + parts.minute;

  if (totalMinutes < bounds.startMinutes) {
    aligned = buildTrTimestamp({
      ...parts,
      hour: options.dailyStartHour,
      minute: 0,
      second: 0,
      millisecond: 0,
    });
    parts = getTrParts(aligned);
  }

  if (parts.hour * 60 + parts.minute > bounds.endMinutes) {
    aligned = buildTrTimestamp({
      year: parts.year,
      month: parts.month,
      day: parts.day + 1,
      hour: options.dailyStartHour,
      minute: 0,
      second: 0,
      millisecond: 0,
    });
  }

  return aligned;
}

function nextAnchorTimestamp(timestamp, options) {
  const next = timestamp + options.intervalMinutes * 60 * 1000;
  const parts = getTrParts(next);
  const bounds = getWindowBounds(options);
  const totalMinutes = parts.hour * 60 + parts.minute;
  if (totalMinutes < bounds.startMinutes) {
    return buildTrTimestamp({
      year: parts.year,
      month: parts.month,
      day: parts.day,
      hour: options.dailyStartHour,
      minute: 0,
      second: 0,
      millisecond: 0,
    });
  }
  if (totalMinutes > bounds.endMinutes) {
    return buildTrTimestamp({
      year: parts.year,
      month: parts.month,
      day: parts.day + 1,
      hour: options.dailyStartHour,
      minute: 0,
      second: 0,
      millisecond: 0,
    });
  }
  return next;
}

function alignStartTimestamp(timestamp, options) {
  const anchor = alignAnchorTimestamp(timestamp, options);
  return anchor - getTriggerLeadMs(options);
}

function nextScheduleTimestamp(timestamp, options) {
  const anchor = timestamp + getTriggerLeadMs(options);
  return nextAnchorTimestamp(anchor, options) - getTriggerLeadMs(options);
}

function limitGroupsByScheduleWindow(groups, firstScheduleTimestamp, options) {
  if (asNum(options.limitDays, 0) <= 0) return groups;
  return groups.filter((_, index) => {
    let scheduleTimestamp = firstScheduleTimestamp;
    for (let i = 0; i < index; i += 1) {
      scheduleTimestamp = nextScheduleTimestamp(scheduleTimestamp, options);
    }
    return diffTrCalendarDays(firstScheduleTimestamp, scheduleTimestamp) < options.limitDays;
  });
}

function formatTrTimestamp(timestamp) {
  const parts = getTrParts(timestamp);
  const pad = (value) => String(value).padStart(2, '0');
  return `${parts.year}-${pad(parts.month + 1)}-${pad(parts.day)} ${pad(
    parts.hour,
  )}:${pad(parts.minute)}:${pad(parts.second)} +03`;
}

async function initializeApps(options) {
  const sourceApp = admin.initializeApp(
    {
      credential: admin.credential.cert(loadServiceAccount(options.sourceKey)),
      storageBucket: options.sourceBucket,
    },
    `posts-source-${Date.now()}`,
  );
  const targetApp = admin.initializeApp(
    {
      credential: admin.credential.cert(loadServiceAccount(options.targetKey)),
      storageBucket: options.targetBucket,
    },
    `posts-target-${Date.now()}`,
  );

  return {
    sourceApp,
    targetApp,
    sourceDb: sourceApp.firestore(),
    targetDb: targetApp.firestore(),
    sourceBucket: sourceApp.storage().bucket(options.sourceBucket),
    targetBucket: targetApp.storage().bucket(options.targetBucket),
  };
}

async function deleteApps(apps) {
  await Promise.all([
    apps.sourceApp?.delete?.().catch(() => {}),
    apps.targetApp?.delete?.().catch(() => {}),
  ]);
}

async function loadSourceFloodGroups(sourceDb, options) {
  const groups = new Map();
  let lastDoc = null;
  let scannedDocs = 0;
  let scannedFloodDocs = 0;

  while (true) {
    let query = sourceDb
      .collection(options.sourceCollection)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(options.pageSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      scannedDocs += 1;
      const data = doc.data() || {};
      if (asNum(data.floodCount, 1) <= 1) continue;

      const identity = parseFloodIdentity(doc.id);
      if (!identity) continue;

      scannedFloodDocs += 1;
      if (!groups.has(identity.baseId)) {
        groups.set(identity.baseId, {
          baseId: identity.baseId,
          rootId: identity.rootId,
          docs: [],
        });
      }
      groups.get(identity.baseId).docs.push({
        id: doc.id,
        index: identity.index,
        data,
      });
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < options.pageSize) break;
  }

  const result = [];
  for (const group of groups.values()) {
    group.docs.sort((a, b) => a.index - b.index || a.id.localeCompare(b.id));
    group.root = group.docs.find((item) => item.id === group.rootId) || null;
    group.hasRoot = Boolean(group.root);
    group.sourceRootTimeStamp = group.root
      ? asNum(group.root.data.timeStamp, 0)
      : 0;
    group.kind = classifyGroup(group.docs);
    group.docCount = group.docs.length;
    result.push(group);
  }

  result.sort((a, b) => {
    if (a.hasRoot !== b.hasRoot) return a.hasRoot ? -1 : 1;
    if (a.sourceRootTimeStamp !== b.sourceRootTimeStamp) {
      return a.sourceRootTimeStamp - b.sourceRootTimeStamp;
    }
    return a.rootId.localeCompare(b.rootId);
  });

  return {
    scannedDocs,
    scannedFloodDocs,
    groups: result,
  };
}

function classifyGroup(docs) {
  let hasVideo = false;
  let hasImage = false;
  let hasText = false;

  for (const doc of docs) {
    const data = doc.data || {};
    if (asString(data.video).length > 0) {
      hasVideo = true;
    }
    if (parseSourceImageUrls(data).length > 0) {
      hasImage = true;
    }
    if (asString(data.metin).length > 0) {
      hasText = true;
    }
  }

  if (hasVideo && (hasImage || hasText)) return 'mixed';
  if (hasVideo) return 'video';
  if (hasImage) return hasText ? 'image_text' : 'image';
  return hasText ? 'text' : 'empty';
}

function parseSourceImageUrls(data) {
  const urls = [];
  if (Array.isArray(data.img)) {
    for (const item of data.img) {
      if (item && typeof item === 'object' && !Array.isArray(item)) {
        const url = asString(item.url);
        if (url) urls.push(url);
      } else {
        const url = asString(item);
        if (url) urls.push(url);
      }
    }
  }
  return urls;
}

function buildSourceImgAspectMap(data, imageCount) {
  const sourceImgMap = asMapList(data.imgMap);
  const fallbackAspect = asNum(data.aspectRatio, 1);
  const result = [];
  for (let index = 0; index < imageCount; index += 1) {
    const entry = sourceImgMap[index];
    result.push({
      aspectRatio: entry ? asNum(entry.aspectRatio, fallbackAspect) : fallbackAspect,
    });
  }
  return result;
}

async function pickExistingStoragePath(bucket, candidates) {
  for (const candidate of candidates) {
    const [exists] = await bucket.file(candidate).exists();
    if (exists) return candidate;
  }
  return '';
}

async function resolveTargetMedia(sourceData, docId, targetBucket, options) {
  const sourceImages = parseSourceImageUrls(sourceData);
  const hasVideo = asString(sourceData.video).length > 0;
  const hasText = asString(sourceData.metin).length > 0;

  if (!hasVideo && sourceImages.length === 0 && !hasText) {
    return {
      ok: false,
      reason: 'empty_content',
    };
  }

  const result = {
    ok: true,
    img: [],
    imgMap: [],
    thumbnail: '',
    video: '',
    hlsMasterUrl: '',
    hlsStatus: 'none',
    hlsUpdatedAt: 0,
    aspectRatio: asNum(sourceData.aspectRatio, 1),
    mediaKind: hasVideo ? 'video' : sourceImages.length > 0 ? 'image' : 'text',
  };

  if (sourceImages.length > 0) {
    const aspectMap = buildSourceImgAspectMap(sourceData, sourceImages.length);
    for (let index = 0; index < sourceImages.length; index += 1) {
      const storagePath = await pickExistingStoragePath(
        targetBucket,
        IMAGE_EXT_CANDIDATES.map(
          (ext) => `Posts/${docId}/image_${index}.${ext}`,
        ),
      );
      if (!storagePath) {
        return {
          ok: false,
          reason: `missing_image_${index}`,
        };
      }
      const url = buildCdnUrl(options.cdnDomain, storagePath);
      result.img.push(url);
      result.imgMap.push({
        url,
        aspectRatio: asNum(aspectMap[index]?.aspectRatio, 1),
      });
    }
    if (!hasVideo && result.imgMap.length > 0) {
      result.aspectRatio = asNum(result.imgMap[0].aspectRatio, result.aspectRatio);
    }
  }

  if (hasVideo) {
    const hlsStoragePath = 'Posts/' + docId + '/hls/master.m3u8';
    const [hlsExists] = await targetBucket.file(hlsStoragePath).exists();
    if (!hlsExists) {
      return {
        ok: false,
        reason: 'missing_hls_master',
      };
    }
    const thumbnailStoragePath = await pickExistingStoragePath(
      targetBucket,
      THUMB_EXT_CANDIDATES.map((ext) => `Posts/${docId}/thumbnail.${ext}`),
    );
    if (!thumbnailStoragePath) {
      return {
        ok: false,
        reason: 'missing_video_thumbnail',
      };
    }
    result.video = buildHlsUrl(options.cdnDomain, docId);
    result.hlsMasterUrl = result.video;
    result.hlsStatus = 'ready';
    result.thumbnail = buildThumbUrl(options.cdnDomain, thumbnailStoragePath);
  } else if (asString(sourceData.thumbnail).length > 0) {
    const thumbnailStoragePath = await pickExistingStoragePath(
      targetBucket,
      THUMB_EXT_CANDIDATES.map((ext) => `Posts/${docId}/thumbnail.${ext}`),
    );
    if (thumbnailStoragePath) {
      result.thumbnail = buildThumbUrl(options.cdnDomain, thumbnailStoragePath);
    }
  }

  return result;
}

async function loadTargetUserProfile(targetDb, usersCollection, userCache, uid) {
  if (userCache.has(uid)) return userCache.get(uid);
  const snap = await targetDb.collection(usersCollection).doc(uid).get();
  if (!snap.exists) {
    userCache.set(uid, null);
    return null;
  }
  const data = snap.data() || {};
  const profile = {
    avatarUrl: asString(data.avatarUrl),
    nickname: asString(data.nickname),
    displayName:
      asString(data.displayName) || asString(data.fullName) || asString(data.nickname),
    rozet: asString(data.rozet),
    username: asString(data.username),
    fullName: asString(data.fullName) || asString(data.displayName),
  };
  userCache.set(uid, profile);
  return profile;
}

function buildTargetMainFlood(docId, index) {
  return index === 0 ? '' : `${docId}_0`;
}

function buildYorumMap(sourceData) {
  if (sourceData.yorumMap && typeof sourceData.yorumMap === 'object') {
    const visibility = asNum(sourceData.yorumMap.visibility, 0);
    return { visibility };
  }
  return { visibility: asBool(sourceData.yorum, true) ? 0 : 3 };
}

function buildReshareMap(sourceData) {
  if (sourceData.reshareMap && typeof sourceData.reshareMap === 'object') {
    const visibility = asNum(sourceData.reshareMap.visibility, 0);
    return { visibility };
  }
  return { visibility: asNum(sourceData.paylasGizliligi, 0) };
}

async function prepareGroupPlan(group, scheduleTimestamp, targetDb, targetBucket, options, userCache) {
  if (!group.hasRoot) {
    return {
      baseId: group.baseId,
      rootId: group.rootId,
      status: 'skipped',
      reason: 'missing_root_0',
      scheduleTimestamp,
      scheduleLabel: formatTrTimestamp(scheduleTimestamp),
      docCount: group.docCount,
      kind: group.kind,
      docs: [],
    };
  }

  const docs = [];
  const skipped = [];
  for (const item of group.docs) {
    const sourceData = item.data || {};
    const userId = asString(sourceData.userID);
    if (!userId) {
      if (item.index !== 0) {
        skipped.push({
          docId: item.id,
          reason: `missing_user_id:${item.id}`,
        });
        continue;
      }
      return {
        baseId: group.baseId,
        rootId: group.rootId,
        status: 'failed',
        reason: `missing_user_id:${item.id}`,
        scheduleTimestamp,
        scheduleLabel: formatTrTimestamp(scheduleTimestamp),
        docCount: group.docCount,
        kind: group.kind,
        docs: [],
      };
    }

    const profile = await loadTargetUserProfile(
      targetDb,
      options.usersCollection,
      userCache,
      userId,
    );
    if (!profile) {
      if (item.index !== 0) {
        skipped.push({
          docId: item.id,
          reason: `missing_target_user:${userId}`,
        });
        continue;
      }
      return {
        baseId: group.baseId,
        rootId: group.rootId,
        status: 'failed',
        reason: `missing_target_user:${userId}`,
        scheduleTimestamp,
        scheduleLabel: formatTrTimestamp(scheduleTimestamp),
        docCount: group.docCount,
        kind: group.kind,
        docs: [],
      };
    }

    const media = await resolveTargetMedia(sourceData, item.id, targetBucket, options);
    if (!media.ok) {
      if (item.index !== 0) {
        skipped.push({
          docId: item.id,
          reason: `${media.reason}:${item.id}`,
        });
        continue;
      }
      return {
        baseId: group.baseId,
        rootId: group.rootId,
        status: 'failed',
        reason: `${media.reason}:${item.id}`,
        scheduleTimestamp,
        scheduleLabel: formatTrTimestamp(scheduleTimestamp),
        docCount: group.docCount,
        kind: group.kind,
        docs: [],
      };
    }

    const payload = {
      ad: asBool(sourceData.ad, false),
      arsiv: false,
      aspectRatio: media.aspectRatio,
      debugMode: asBool(sourceData.debugMode, false),
      deletedPost: false,
      deletedPostTime: 0,
      editTime: asNum(sourceData.editTime, 0),
      flood: item.index !== 0,
      floodCount: group.docCount,
      gizlendi: false,
      img: media.img,
      imgMap: media.imgMap,
      isAd: asBool(sourceData.isAd, false),
      isUploading: false,
      izBirakYayinTarihi: scheduleTimestamp,
      konum: asString(sourceData.konum),
      locationCity: asString(sourceData.locationCity),
      mainFlood: buildTargetMainFlood(item.id, item.index),
      metin: asString(sourceData.metin),
      originalPostID: asString(sourceData.originalPostID),
      originalUserID: asString(sourceData.originalUserID),
      paylasGizliligi: asNum(sourceData.paylasGizliligi, 0),
      scheduledAt: asNum(sourceData.scheduledAt, 0),
      sikayetEdildi: false,
      stabilized: false,
      stats: {
        commentCount: 0,
        likeCount: 0,
        reportedCount: 0,
        retryCount: 0,
        savedCount: 0,
        statsCount: 0,
      },
      tags: Array.isArray(sourceData.tags) ? sourceData.tags : [],
      thumbnail: media.thumbnail,
      timeStamp: scheduleTimestamp,
      updatedAt: scheduleTimestamp,
      userID: userId,
      authorNickname: profile.nickname,
      authorDisplayName: profile.displayName,
      authorAvatarUrl: profile.avatarUrl,
      nickname: profile.nickname,
      username: profile.username,
      fullName: profile.fullName,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      rozet: profile.rozet,
      video: media.video,
      hlsMasterUrl: media.hlsMasterUrl,
      hlsStatus: media.hlsStatus,
      hlsUpdatedAt: media.hlsStatus === 'ready' ? scheduleTimestamp : 0,
      yorum: asBool(sourceData.yorum, true),
      yorumMap: buildYorumMap(sourceData),
      reshareMap: buildReshareMap(sourceData),
    };

    docs.push({
      docId: item.id,
      index: item.index,
      mediaKind: media.mediaKind,
      payload,
    });
  }

  return {
    baseId: group.baseId,
    rootId: group.rootId,
    status: 'ready',
    reason: '',
    scheduleTimestamp,
    scheduleLabel: formatTrTimestamp(scheduleTimestamp),
    docCount: group.docCount,
    kind: group.kind,
    partial: skipped.length > 0,
    skipped,
    docs,
  };
}

function ensureReportDir(reportDir) {
  fs.mkdirSync(reportDir, { recursive: true });
}

function writeReport(reportDir, prefix, report) {
  ensureReportDir(reportDir);
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filePath = path.join(reportDir, `${prefix}_${stamp}.json`);
  fs.writeFileSync(filePath, JSON.stringify(report, null, 2));
  return filePath;
}

function summarizePlans(plans) {
  const summary = {
    totalGroups: plans.length,
    readyGroups: 0,
    partialGroups: 0,
    skippedGroups: 0,
    failedGroups: 0,
    totalDocs: 0,
    readyDocs: 0,
    partialDocs: 0,
    skippedDocs: 0,
    failedDocs: 0,
  };

  for (const plan of plans) {
    summary.totalDocs += plan.docCount || 0;
    if (plan.status === 'ready') {
      summary.readyGroups += 1;
      summary.readyDocs += plan.docCount || 0;
      if (Array.isArray(plan.skipped) && plan.skipped.length > 0) {
        summary.partialGroups += 1;
        summary.partialDocs += plan.skipped.length;
      }
    } else if (plan.status === 'skipped') {
      summary.skippedGroups += 1;
      summary.skippedDocs += plan.docCount || 0;
    } else {
      summary.failedGroups += 1;
      summary.failedDocs += plan.docCount || 0;
    }
  }

  return summary;
}

module.exports = {
  arg,
  asBool,
  asNum,
  asString,
  asStringList,
  buildOptions,
  buildTargetMainFlood,
  deleteApps,
  formatTrTimestamp,
  initializeApps,
  loadSourceFloodGroups,
  limitGroupsByScheduleWindow,
  nextScheduleTimestamp,
  alignStartTimestamp,
  prepareGroupPlan,
  summarizePlans,
  writeReport,
};
