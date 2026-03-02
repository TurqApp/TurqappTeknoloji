const path = require('path');
const { Storage } = require('@google-cloud/storage');
const sharp = require('sharp');

const bucketName = process.env.BUCKET || 'turqappteknoloji.firebasestorage.app';
const prefix = process.env.PREFIX || 'scholarships/templates/';
const quality = Number(process.env.WEBP_QUALITY || 85);
const effort = Number(process.env.WEBP_EFFORT || 4);
const limit = Number(process.env.LIMIT || 10);

const exts = new Set(['.jpg', '.jpeg', '.png']);

(async () => {
  const storage = new Storage();
  const bucket = storage.bucket(bucketName);
  const [files] = await bucket.getFiles({ prefix });

  const candidates = files
    .filter((f) => exts.has(path.extname(f.name).toLowerCase()))
    .slice(0, limit);

  console.log(`Bucket: ${bucketName}`);
  console.log(`Prefix: ${prefix}`);
  console.log(`Pilot files: ${candidates.length}`);

  let totalSrc = 0;
  let totalDst = 0;

  for (const f of candidates) {
    const parsed = path.parse(f.name);
    const outName = path.posix.join(parsed.dir, `${parsed.name}.webp`);
    const outFile = bucket.file(outName);

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

    console.log(`${f.name} -> ${outName} | ${(srcBuf.length/1024).toFixed(1)}KB -> ${(dstBuf.length/1024).toFixed(1)}KB`);
  }

  const savedPct = totalSrc > 0 ? (100 * (1 - totalDst / totalSrc)).toFixed(1) : '0.0';
  console.log('--- PILOT SUMMARY ---');
  console.log(`Source: ${(totalSrc/1024/1024).toFixed(2)} MB`);
  console.log(`WebP:   ${(totalDst/1024/1024).toFixed(2)} MB`);
  console.log(`Saved:  ${savedPct}%`);
})();
