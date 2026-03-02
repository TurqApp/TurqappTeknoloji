const path = require('path');
const { Storage } = require('@google-cloud/storage');

const bucketName = process.env.BUCKET || 'turqappteknoloji.firebasestorage.app';
const prefix = process.env.PREFIX || 'scholarships/templates/';
const dryRun = process.env.DRY_RUN === '1';

const exts = new Set(['.jpg', '.jpeg', '.png']);

async function exists(file) {
  const [ok] = await file.exists();
  return ok;
}

(async () => {
  const storage = new Storage();
  const bucket = storage.bucket(bucketName);
  const [files] = await bucket.getFiles({ prefix });

  const originals = files.filter((f) => exts.has(path.extname(f.name).toLowerCase()));

  let deletable = 0;
  let deleted = 0;
  let skippedNoWebp = 0;
  let failed = 0;

  for (const f of originals) {
    const parsed = path.parse(f.name);
    const webpName = path.posix.join(parsed.dir, `${parsed.name}.webp`);
    const webpFile = bucket.file(webpName);

    if (!(await exists(webpFile))) {
      skippedNoWebp++;
      continue;
    }

    deletable++;
    if (dryRun) continue;

    try {
      await f.delete();
      deleted++;
      if (deleted % 100 === 0) {
        console.log(`progress deleted=${deleted}`);
      }
    } catch (e) {
      failed++;
      console.error(`FAIL ${f.name}: ${e.message}`);
    }
  }

  console.log('--- SUMMARY ---');
  console.log(`original candidates: ${originals.length}`);
  console.log(`deletable(with webp): ${deletable}`);
  console.log(`deleted: ${deleted}`);
  console.log(`skipped(no webp): ${skippedNoWebp}`);
  console.log(`failed: ${failed}`);
})();
