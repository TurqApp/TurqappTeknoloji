const admin = require('firebase-admin');
const fs = require('fs');

const SRC_KEY = '/Users/turqapp/Downloads/burs-city-firebase-adminsdk-fbsvc-94844a37a9.json';
const DST_KEY = '/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';

function readJsonWithPossiblePrefix(filePath) {
  let raw = fs.readFileSync(filePath, 'utf8');
  const firstBrace = raw.indexOf('{');
  if (firstBrace > 0) raw = raw.slice(firstBrace);
  return JSON.parse(raw);
}

async function countStoragePrefix(bucket, prefix) {
  let count = 0;
  let pageToken;
  do {
    const [files, nextQuery, apiResponse] = await bucket.getFiles({ prefix, autoPaginate: false, pageToken, maxResults: 1000 });
    count += files.length;
    pageToken = apiResponse && apiResponse.nextPageToken;
  } while (pageToken);
  return count;
}

async function countByExt(bucket, prefix, ext) {
  let count = 0;
  let pageToken;
  do {
    const [files, nextQuery, apiResponse] = await bucket.getFiles({ prefix, autoPaginate: false, pageToken, maxResults: 1000 });
    count += files.filter(f => f.name.toLowerCase().endsWith(ext)).length;
    pageToken = apiResponse && apiResponse.nextPageToken;
  } while (pageToken);
  return count;
}

(async () => {
  const srcCred = readJsonWithPossiblePrefix(SRC_KEY);
  const dstCred = readJsonWithPossiblePrefix(DST_KEY);

  const srcApp = admin.initializeApp({ credential: admin.credential.cert(srcCred), storageBucket: 'burs-city.appspot.com' }, 'src-diff');
  const dstApp = admin.initializeApp({ credential: admin.credential.cert(dstCred), storageBucket: 'turqappteknoloji.firebasestorage.app' }, 'dst-diff');

  const srcDb = srcApp.firestore();
  const dstDb = dstApp.firestore();

  const srcBucket = srcApp.storage().bucket('burs-city.appspot.com');
  const dstBucket = dstApp.storage().bucket('turqappteknoloji.firebasestorage.app');

  const out = {};

  out.firestore = {
    source: {
      CikmisSorular_root: (await srcDb.collection('CikmisSorular').count().get()).data().count,
      CikmisSorular_Sorular_sub: (await srcDb.collectionGroup('Sorular').count().get()).data().count,
      SoruBankasi_root: (await srcDb.collection('SoruBankasi').count().get()).data().count,
      SoruBankasi_Cevaplayanlar_sub: (await srcDb.collectionGroup('Cevaplayanlar').count().get()).data().count,
    },
    target: {
      questions_root: (await dstDb.collection('questions').count().get()).data().count,
      questions_questions_sub: (await dstDb.collectionGroup('questions').count().get()).data().count,
      questionBank_root: (await dstDb.collection('questionBank').count().get()).data().count,
      questionBank_Cevaplayanlar_sub: (await dstDb.collectionGroup('Cevaplayanlar').count().get()).data().count,
    },
  };

  out.storage = {
    source: {
      CikmisSorular_all: await countStoragePrefix(srcBucket, 'CikmisSorular/'),
      SoruBankasi_all: await countStoragePrefix(srcBucket, 'SoruBankasi/'),
    },
    target: {
      questions_all: await countStoragePrefix(dstBucket, 'questions/'),
      questions_webp: await countByExt(dstBucket, 'questions/', '.webp'),
      questionBank_all: await countStoragePrefix(dstBucket, 'questionBank/'),
      questionBank_webp: await countByExt(dstBucket, 'questionBank/', '.webp'),
    }
  };

  console.log(JSON.stringify(out, null, 2));

  await srcApp.delete();
  await dstApp.delete();
})();
