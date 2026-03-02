const path = require('path');
const { Storage } = require('@google-cloud/storage');
const sharp = require('sharp');

const bucketName = process.env.BUCKET || 'turqappteknoloji.firebasestorage.app';
const prefix = process.env.PREFIX || 'scholarships/templates/';
const quality = Number(process.env.WEBP_QUALITY || 85);
const effort = Number(process.env.WEBP_EFFORT || 4);

const exts = new Set(['.jpg', '.jpeg', '.png']);

async function exists(file) {
  const [ok] = await file.exists();
  return ok;
}

(async () => {
  const storage = new Storage();
  const bucket = storage.bucket(bucketName);

  const [files] = await bucket.getFiles({ prefix });
  const candidates = files.filter((f) => exts.has(path.extname(f.name).toLowerCase()));

  console.log(`Bucket: ${bucketName}`);
  console.log(`Prefix: ${prefix}`);
  console.log(`Candidates: ${candidates.length}`);

  let converted = 0;
  let skipped = 0;
  let failed = 0;
  let totalSrc = 0;
  let totalDst = 0;

  for (const f of candidates) {
    try {
      const parsed = path.parse(f.name);
      const outName = path.posix.join(parsed.dir, `${parsed.name}.webp`);
      const outFile = bucket.file(outName);

      if (await exists(outFile)) {
        skipped++;
        continue;
      }

      const [srcBuf] = await f.download();
      const dstBuf = await sharp(srcBuf).rotate().webp({ quality, effort }).toBuffer();

      await outFile.save(dstBuf, {
        resumable: false,
        metadata: {
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000',
        },
      });

      totalSrc += srcBuf.length;
      totalDst += dstBuf.length;
      converted++;

      if (converted % 50 === 0) {
        console.log(`progress converted=${converted} skipped=${skipped} failed=${failed}`);
      }
    } catch (e) {
      failed++;
      console.error(`FAIL ${f.name}: ${e.message}`);
    }
  }

  const savedPct = totalSrc > 0 ? (100 * (1 - totalDst / totalSrc)).toFixed(1) : '0.0';
  console.log('--- SUMMARY ---');
  console.log(`converted: ${converted}`);
  console.log(`skipped(existing webp): ${skipped}`);
  console.log(`failed: ${failed}`);
  console.log(`Source(conv only): ${(totalSrc/1024/1024).toFixed(2)} MB`);
  console.log(`WebP(conv only): ${(totalDst/1024/1024).toFixed(2)} MB`);
  console.log(`Saved(conv only): ${savedPct}%`);
})();
