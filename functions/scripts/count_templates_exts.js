const path = require('path');
const { Storage } = require('@google-cloud/storage');

const bucketName = process.env.BUCKET || 'turqappteknoloji.firebasestorage.app';
const prefix = process.env.PREFIX || 'scholarships/templates/';

(async () => {
  const storage = new Storage();
  const bucket = storage.bucket(bucketName);
  const [files] = await bucket.getFiles({ prefix });

  let jpg = 0, jpeg = 0, png = 0, webp = 0, other = 0;
  for (const f of files) {
    const e = path.extname(f.name).toLowerCase();
    if (e === '.jpg') jpg++;
    else if (e === '.jpeg') jpeg++;
    else if (e === '.png') png++;
    else if (e === '.webp') webp++;
    else other++;
  }

  console.log({ total: files.length, jpg, jpeg, png, webp, other });
})();
