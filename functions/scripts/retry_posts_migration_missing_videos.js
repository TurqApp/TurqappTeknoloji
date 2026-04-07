#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');
const os = require('os');
const path = require('path');
const shared = require('./posts_migration_shared');

function arg(name, fallback = '') {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1] || fallback;
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

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

function parseDocIds(payload) {
  if (Array.isArray(payload?.docs)) {
    return payload.docs
      .map((item) => asString(item.docId))
      .filter(Boolean);
  }

  if (Array.isArray(payload?.groups)) {
    const out = [];
    for (const group of payload.groups) {
      for (const issue of group.issues || []) {
        if (issue.issue === 'missing_video') {
          const docId = asString(issue.docId);
          if (docId) out.push(docId);
        }
      }
    }
    return out;
  }

  return [];
}

function resolveSourceVideoPath(docId, sourceData) {
  const fromUrl = extractStorageObjectPath(sourceData.video);
  if (fromUrl) return fromUrl;
  return `Posts/${docId}/video.mp4`;
}

async function copyVideo({
  sourceBucket,
  targetBucket,
  sourcePath,
  docId,
  apply,
}) {
  const [sourceExists] = await sourceBucket.file(sourcePath).exists();
  if (!sourceExists) {
    return { ok: false, reason: `missing_source_object:${sourcePath}` };
  }

  if (!apply) {
    return {
      ok: true,
      dryRun: true,
      sourcePath,
      targetPath: `Posts/${docId}/video.mp4`,
    };
  }

  const tmpPath = path.join(
    os.tmpdir(),
    `retry_posts_migration_${Date.now()}_${Math.floor(Math.random() * 1e6)}.mp4`,
  );

  try {
    await sourceBucket.file(sourcePath).download({ destination: tmpPath });
    await targetBucket.upload(tmpPath, {
      destination: `Posts/${docId}/video.mp4`,
      metadata: {
        contentType: 'video/mp4',
        cacheControl: 'public, max-age=31536000, immutable',
        metadata: {
          migrationMode: 'true',
        },
      },
    });
    return {
      ok: true,
      sourcePath,
      targetPath: `Posts/${docId}/video.mp4`,
    };
  } finally {
    try {
      if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath);
    } catch (_) {}
  }
}

async function findThumbPath(bucket, docId) {
  const candidates = [
    `Posts/${docId}/thumbnail.webp`,
    `Posts/${docId}/thumbnail.jpg`,
    `Posts/${docId}/thumbnail.jpeg`,
    `Posts/${docId}/thumbnail.png`,
  ];

  for (const candidate of candidates) {
    const [exists] = await bucket.file(candidate).exists();
    if (exists) return candidate;
  }

  return '';
}

async function waitForArtifacts(targetBucket, docIds, timeoutMs, intervalMs) {
  const pending = new Set(docIds);
  const status = new Map();
  const deadline = Date.now() + timeoutMs;

  while (pending.size > 0 && Date.now() < deadline) {
    for (const docId of [...pending]) {
      const [hlsExists] = await targetBucket
        .file(`Posts/${docId}/hls/master.m3u8`)
        .exists();
      const thumbPath = await findThumbPath(targetBucket, docId);
      const ready = hlsExists && Boolean(thumbPath);
      status.set(docId, {
        docId,
        hlsExists,
        thumbPath,
        ready,
      });
      if (ready) pending.delete(docId);
    }

    if (pending.size === 0) break;
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }

  for (const docId of pending) {
    const [hlsExists] = await targetBucket
      .file(`Posts/${docId}/hls/master.m3u8`)
      .exists();
    const thumbPath = await findThumbPath(targetBucket, docId);
    status.set(docId, {
      docId,
      hlsExists,
      thumbPath,
      ready: hlsExists && Boolean(thumbPath),
    });
  }

  return [...status.values()].sort((a, b) => a.docId.localeCompare(b.docId));
}

async function run() {
  const inspectFile = arg('inspect-file');
  if (!inspectFile) {
    throw new Error('--inspect-file zorunlu');
  }

  const timeoutMinutes = Number(arg('timeout-minutes', '20'));
  const pollSeconds = Number(arg('poll-seconds', '15'));
  const apply = hasFlag('apply');
  const payload = JSON.parse(fs.readFileSync(inspectFile, 'utf8'));
  const docIds = [...new Set(parseDocIds(payload))];

  if (docIds.length === 0) {
    throw new Error('Eksik video doc bulunamadi');
  }

  const options = shared.buildOptions();
  const apps = await shared.initializeApps(options);

  try {
    console.log(`Mod             : ${apply ? 'APPLY' : 'DRY-RUN'}`);
    console.log(`Inspect dosya   : ${inspectFile}`);
    console.log(`Eksik video doc : ${docIds.length}`);

    const results = [];
    let uploaded = 0;
    let failed = 0;

    for (let index = 0; index < docIds.length; index += 1) {
      const docId = docIds[index];
      const sourceSnap = await apps.sourceDb
        .collection(options.sourceCollection)
        .doc(docId)
        .get();

      if (!sourceSnap.exists) {
        failed += 1;
        results.push({
          docId,
          ok: false,
          reason: 'missing_source_doc',
        });
        continue;
      }

      const sourceData = sourceSnap.data() || {};
      const sourcePath = resolveSourceVideoPath(docId, sourceData);
      const result = await copyVideo({
        sourceBucket: apps.sourceBucket,
        targetBucket: apps.targetBucket,
        sourcePath,
        docId,
        apply,
      });

      results.push({
        docId,
        ...result,
      });

      if (result.ok) uploaded += 1;
      else failed += 1;

      console.log(`UPLOAD=${index + 1}/${docIds.length} OK=${uploaded} FAIL=${failed}`);
    }

    let artifacts = [];
    if (apply) {
      artifacts = await waitForArtifacts(
        apps.targetBucket,
        docIds.filter((docId) => {
          const item = results.find((entry) => entry.docId === docId);
          return item && item.ok;
        }),
        Math.max(1, timeoutMinutes) * 60 * 1000,
        Math.max(5, pollSeconds) * 1000,
      );
    }

    const readyCount = artifacts.filter((item) => item.ready).length;
    const pendingCount = artifacts.length - readyCount;

    const report = {
      generatedAt: new Date().toISOString(),
      mode: apply ? 'apply' : 'dry-run',
      inspectFile,
      summary: {
        totalDocs: docIds.length,
        uploaded,
        failed,
        readyCount,
        pendingCount,
      },
      uploads: results,
      artifacts,
    };

    const reportPath = shared.writeReport(
      options.reportDir,
      apply ? 'retry_posts_migration_missing_videos' : 'retry_posts_migration_missing_videos_dry_run',
      report,
    );

    console.log(`Hazir video     : ${readyCount}`);
    console.log(`Bekleyen video  : ${pendingCount}`);
    console.log(`Basarisiz doc   : ${failed}`);
    console.log(`Rapor           : ${reportPath}`);
  } finally {
    await shared.deleteApps(apps);
  }
}

run().catch((error) => {
  console.error('HATA:', error.message);
  process.exit(1);
});
