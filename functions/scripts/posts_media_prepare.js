#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  buildOptions,
  deleteApps,
  initializeApps,
  loadSourceFloodGroups,
  writeReport,
} = require('./posts_migration_shared');

function asString(value, fallback = '') {
  if (value === null || value === undefined) return fallback;
  return String(value).trim();
}

function extractStorageObjectPath(rawUrl) {
  const text = asString(rawUrl);
  if (!text) return '';

  if (text.startsWith('gs://')) {
    const parts = text.replace('gs://', '').split('/');
    parts.shift();
    return parts.join('/');
  }

  try {
    const parsed = new URL(text);
    const objectIndex = parsed.pathname.indexOf('/o/');
    if (objectIndex >= 0) {
      return decodeURIComponent(parsed.pathname.slice(objectIndex + 3));
    }
  } catch (_) {}

  return '';
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

function extFromPath(objectPath, fallback) {
  const ext = path.extname(asString(objectPath)).toLowerCase();
  return ext || fallback;
}

function contentTypeForExt(ext) {
  switch (ext) {
    case '.webp':
      return 'image/webp';
    case '.png':
      return 'image/png';
    case '.jpeg':
    case '.jpg':
      return 'image/jpeg';
    case '.mp4':
      return 'video/mp4';
    default:
      return 'application/octet-stream';
  }
}

async function copyObject({
  sourceBucket,
  targetBucket,
  sourcePath,
  targetPath,
  apply,
  customMetadata = {},
}) {
  const [sourceExists] = await sourceBucket.file(sourcePath).exists();
  if (!sourceExists) {
    return { ok: false, reason: `missing_source_object:${sourcePath}` };
  }

  const [targetExists] = await targetBucket.file(targetPath).exists();
  if (targetExists) {
    return { ok: true, copied: false, existed: true, targetPath };
  }

  if (!apply) {
    return { ok: true, copied: false, existed: false, dryRun: true, targetPath };
  }

  const ext = extFromPath(targetPath, '');
  const tmpPath = path.join(
    os.tmpdir(),
    `posts_media_${Date.now()}_${Math.floor(Math.random() * 1e6)}${ext}`,
  );

  try {
    await sourceBucket.file(sourcePath).download({ destination: tmpPath });
    await targetBucket.upload(tmpPath, {
      destination: targetPath,
      metadata: {
        contentType: contentTypeForExt(ext),
        cacheControl:
          ext === '.mp4'
            ? 'public, max-age=31536000, immutable'
            : 'public, max-age=86400',
        metadata: customMetadata,
      },
    });
    return { ok: true, copied: true, existed: false, targetPath };
  } finally {
    try {
      if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
    } catch (_) {}
  }
}

function resolveSourceVideoPath(docId, sourceData) {
  const fromUrl = extractStorageObjectPath(sourceData.video);
  if (fromUrl) return fromUrl;
  return `Posts/${docId}/video.mp4`;
}

async function run() {
  const options = buildOptions();
  const apps = await initializeApps(options);

  try {
    console.log(`Mod             : ${options.apply ? 'APPLY' : 'DRY-RUN'}`);
    console.log('Hazirlik        : source media -> target storage');

    const loaded = await loadSourceFloodGroups(apps.sourceDb, options);
    const groups = loaded.groups
      .filter((group) => group.hasRoot)
      .sort((a, b) => {
        if (a.sourceRootTimeStamp !== b.sourceRootTimeStamp) {
          return a.sourceRootTimeStamp - b.sourceRootTimeStamp;
        }
        return a.rootId.localeCompare(b.rootId);
      });

    const limitedGroups =
      options.limitGroups > 0 ? groups.slice(0, options.limitGroups) : groups;

    const report = {
      generatedAt: new Date().toISOString(),
      mode: options.apply ? 'apply' : 'dry-run',
      source: {
        scannedDocs: loaded.scannedDocs,
        scannedFloodDocs: loaded.scannedFloodDocs,
        totalFloodGroups: loaded.groups.length,
      },
      summary: {
        totalGroups: limitedGroups.length,
        readyGroups: 0,
        failedGroups: 0,
        skippedGroups: 0,
        copiedObjects: 0,
        existingObjects: 0,
      },
      groups: [],
    };

    for (const group of limitedGroups) {
      const groupReport = {
        rootId: group.rootId,
        docCount: group.docCount,
        sourceRootTimeStamp: group.sourceRootTimeStamp,
        kind: group.kind,
        status: 'ready',
        reason: '',
        docs: [],
      };

      for (const item of group.docs) {
        const sourceData = item.data || {};
        const docReport = {
          docId: item.id,
          copied: [],
          existing: [],
          failed: [],
        };

        const sourceImages = parseSourceImageUrls(sourceData);
        for (let index = 0; index < sourceImages.length; index += 1) {
          const sourcePath = extractStorageObjectPath(sourceImages[index]);
          if (!sourcePath) {
            docReport.failed.push(`missing_source_image_path:${index}`);
            continue;
          }
          const targetPath = `Posts/${item.id}/image_${index}${extFromPath(
            sourcePath,
            '.jpg',
          )}`;
          const result = await copyObject({
            sourceBucket: apps.sourceBucket,
            targetBucket: apps.targetBucket,
            sourcePath,
            targetPath,
            apply: options.apply,
          });
          if (!result.ok) {
            docReport.failed.push(result.reason);
            continue;
          }
          if (result.existed) {
            docReport.existing.push(targetPath);
            report.summary.existingObjects += 1;
          } else {
            docReport.copied.push(targetPath);
            if (result.copied) report.summary.copiedObjects += 1;
          }
        }

        if (asString(sourceData.video)) {
          const sourceVideoPath = resolveSourceVideoPath(item.id, sourceData);
          const result = await copyObject({
            sourceBucket: apps.sourceBucket,
            targetBucket: apps.targetBucket,
            sourcePath: sourceVideoPath,
            targetPath: `Posts/${item.id}/video.mp4`,
            apply: options.apply,
            customMetadata: {
              migrationMode: 'true',
            },
          });
          if (!result.ok) {
            docReport.failed.push(result.reason);
          } else if (result.existed) {
            docReport.existing.push(`Posts/${item.id}/video.mp4`);
            report.summary.existingObjects += 1;
          } else {
            docReport.copied.push(`Posts/${item.id}/video.mp4`);
            if (result.copied) report.summary.copiedObjects += 1;
          }
        }

        if (docReport.failed.length > 0) {
          groupReport.status = 'failed';
          groupReport.reason = docReport.failed[0];
        }
        groupReport.docs.push(docReport);
      }

      if (groupReport.status === 'failed') {
        report.summary.failedGroups += 1;
      } else {
        report.summary.readyGroups += 1;
      }

      report.groups.push(groupReport);
    }

    const reportPath = writeReport(
      options.reportDir,
      options.apply ? 'posts_media_prepare' : 'posts_media_prepare_dry_run',
      report,
    );
    console.log(`Hazir grup      : ${report.summary.readyGroups}`);
    console.log(`Basarisiz grup  : ${report.summary.failedGroups}`);
    console.log(`Kopyalanan obje : ${report.summary.copiedObjects}`);
    console.log(`Var olan obje   : ${report.summary.existingObjects}`);
    console.log(`Rapor           : ${reportPath}`);
  } finally {
    await deleteApps(apps);
  }
}

run().catch((error) => {
  console.error('HATA:', error.message);
  process.exit(1);
});
