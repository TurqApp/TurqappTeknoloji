#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const AVATAR_VERSION = "v4";
const DEFAULT_INPUT = "/Users/turqapp/Desktop/turqapp_curated_user_import_ready_184.json";
const DEFAULT_IMAGE_DIR = "/Users/turqapp/Desktop/adsız klasör";
const DEFAULT_OUT_DIR = "/Users/turqapp/Desktop/TurqApp/artifacts/curated_avatars_v4_uploaded";
const DEFAULT_MANIFEST = "/Users/turqapp/Desktop/turqapp_curated_avatar_manifest_184.json";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp_Firebase/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";

const require = createRequire(import.meta.url);
const admin = require(path.resolve("functions/node_modules/firebase-admin"));
const sharp = require(path.resolve("functions/node_modules/sharp"));

function parseArgs(argv) {
  const options = {
    input: DEFAULT_INPUT,
    imageDir: DEFAULT_IMAGE_DIR,
    outDir: DEFAULT_OUT_DIR,
    manifest: DEFAULT_MANIFEST,
    serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT,
    apply: false,
    limit: 0,
  };
  for (let index = 2; index < argv.length; index += 1) {
    const arg = String(argv[index] || "").trim();
    if (arg === "--input") {
      options.input = String(argv[index + 1] || "").trim() || options.input;
      index += 1;
    } else if (arg === "--image-dir") {
      options.imageDir = String(argv[index + 1] || "").trim() || options.imageDir;
      index += 1;
    } else if (arg === "--out-dir") {
      options.outDir = String(argv[index + 1] || "").trim() || options.outDir;
      index += 1;
    } else if (arg === "--manifest") {
      options.manifest = String(argv[index + 1] || "").trim() || options.manifest;
      index += 1;
    } else if (arg === "--service-account") {
      options.serviceAccount = String(argv[index + 1] || "").trim() || options.serviceAccount;
      index += 1;
    } else if (arg === "--limit") {
      options.limit = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
    } else if (arg === "--apply") {
      options.apply = true;
    }
  }
  return options;
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function naturalCompare(a, b) {
  return a.localeCompare(b, "tr", { numeric: true, sensitivity: "base" });
}

function imageFiles(imageDir) {
  return fs
    .readdirSync(imageDir)
    .filter((entry) => /\.(jpe?g|png|webp)$/i.test(entry))
    .sort(naturalCompare)
    .map((entry) => path.join(imageDir, entry));
}

function initializeAdmin(serviceAccountPath) {
  if (admin.apps.length > 0) return;
  if (fs.existsSync(serviceAccountPath)) {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    });
    return;
  }
  admin.initializeApp({ projectId: PROJECT_ID, storageBucket: STORAGE_BUCKET });
}

async function renderAvatarFiles(sourcePath, uid, outDir) {
  const fullPath = path.join(outDir, `${uid}.webp`);
  const thumbPath = path.join(outDir, `${uid}_thumb_150.webp`);
  const source = sharp(sourcePath).rotate();
  await source
    .clone()
    .resize(512, 512, { fit: "cover", position: "attention" })
    .sharpen({ sigma: 0.45 })
    .webp({ quality: 90 })
    .toFile(fullPath);
  await sharp(fullPath)
    .resize(150, 150, { fit: "cover", position: "attention" })
    .webp({ quality: 88 })
    .toFile(thumbPath);
  return { fullPath, thumbPath };
}

async function uploadAvatar({ bucket, uid, files }) {
  const fullStoragePath = `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}.webp`;
  const thumbStoragePath = `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`;
  const metadata = (size) => ({
    contentType: "image/webp",
    cacheControl: "public, max-age=31536000",
    metadata: {
      curatedAvatar: "true",
      avatarKind: "provided_real_photo",
      avatarVersion: AVATAR_VERSION,
      size,
    },
  });
  await bucket.upload(files.fullPath, {
    destination: fullStoragePath,
    metadata: metadata("512"),
  });
  await bucket.upload(files.thumbPath, {
    destination: thumbStoragePath,
    metadata: metadata("150"),
  });
  return {
    fullStoragePath,
    thumbStoragePath,
    fullUrl: `https://cdn.turqapp.com/${fullStoragePath}`,
    avatarUrl: `https://cdn.turqapp.com/${thumbStoragePath}`,
  };
}

function patchRecord(record, avatar) {
  const patch = {
    avatarUrl: avatar.avatarUrl,
    authorAvatarUrl: avatar.avatarUrl,
    avatarFullUrl: avatar.fullUrl,
    avatarType: "curated_provided_real_photo",
    avatarVersion: AVATAR_VERSION,
    avatarAsset: "",
    authorAvatarAsset: "",
    curatedAvatarStoragePath: avatar.thumbStoragePath,
    curatedAvatarFullStoragePath: avatar.fullStoragePath,
    updatedDate: Date.now(),
  };
  record.usersDoc = { ...(record.usersDoc || {}), ...patch };
  record.usersPublicDoc = { ...(record.usersPublicDoc || {}), ...patch };
  return patch;
}

async function writePreview(items, outDir) {
  const cellW = 150;
  const cellH = 182;
  const cols = 10;
  const rows = Math.ceil(Math.min(items.length, 60) / cols);
  const composites = [];
  for (let index = 0; index < Math.min(items.length, 60); index += 1) {
    const item = items[index];
    const x = (index % cols) * cellW;
    const y = Math.floor(index / cols) * cellH;
    const image = await sharp(item.localThumb).resize(118, 118).png().toBuffer();
    const label = Buffer.from(
      `<svg xmlns="http://www.w3.org/2000/svg" width="${cellW}" height="${cellH}">
        <rect width="${cellW}" height="${cellH}" fill="#101827"/>
        <rect x="8" y="8" width="134" height="166" rx="10" fill="#1F2937"/>
        <text x="75" y="149" text-anchor="middle" font-family="Arial" font-size="11" fill="#E5E7EB">${item.index}. ${item.nickname}</text>
        <text x="75" y="165" text-anchor="middle" font-family="Arial" font-size="9" fill="#9CA3AF">${item.sourceFile}</text>
      </svg>`,
    );
    composites.push({ input: label, left: x, top: y });
    composites.push({ input: image, left: x + 16, top: y + 18 });
  }
  const previewPath = path.join(outDir, "preview_001_060.png");
  await sharp({
    create: {
      width: cols * cellW,
      height: rows * cellH,
      channels: 4,
      background: "#101827",
    },
  })
    .composite(composites)
    .png()
    .toFile(previewPath);
  return previewPath;
}

async function run() {
  const options = parseArgs(process.argv);
  const inputJson = JSON.parse(fs.readFileSync(options.input, "utf8"));
  const records = (inputJson.records || []).slice(0, options.limit > 0 ? options.limit : undefined);
  const files = imageFiles(options.imageDir);
  if (files.length !== records.length) {
    throw new Error(`Image count (${files.length}) must match user count (${records.length})`);
  }
  ensureDir(options.outDir);
  ensureDir(path.dirname(options.manifest));

  let bucket = null;
  let db = null;
  if (options.apply) {
    initializeAdmin(options.serviceAccount);
    bucket = admin.storage().bucket();
    db = admin.firestore();
  }

  const manifest = {
    generatedAt: new Date().toISOString(),
    version: AVATAR_VERSION,
    mode: options.apply ? "apply" : "dry-run",
    input: options.input,
    imageDir: options.imageDir,
    outDir: options.outDir,
    recordCount: records.length,
    sourceImageCount: files.length,
    items: [],
  };

  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    const uid = record.uid;
    const sourcePath = files[index];
    const rendered = await renderAvatarFiles(sourcePath, uid, options.outDir);
    const avatar = options.apply
      ? await uploadAvatar({ bucket, uid, files: rendered })
      : {
          fullStoragePath: `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}.webp`,
          thumbStoragePath: `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`,
          fullUrl: `https://cdn.turqapp.com/users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}.webp`,
          avatarUrl: `https://cdn.turqapp.com/users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`,
        };
    const patch = patchRecord(record, avatar);
    if (options.apply) {
      await Promise.all([
        db.collection("users").doc(uid).set(patch, { merge: true }),
        db.collection("usersPublic").doc(uid).set(patch, { merge: true }),
      ]);
    }
    manifest.items.push({
      index: index + 1,
      uid,
      nickname: record.usersDoc?.nickname || "",
      sourcePath,
      sourceFile: path.basename(sourcePath),
      avatarUrl: avatar.avatarUrl,
      fullUrl: avatar.fullUrl,
      localWebp: rendered.fullPath,
      localThumb: rendered.thumbPath,
    });
  }

  const previewPath = await writePreview(manifest.items, options.outDir);
  manifest.previewPath = previewPath;

  const outputJson = {
    ...inputJson,
    metadata: {
      ...(inputJson.metadata || {}),
      avatarsUpdatedAt: new Date().toISOString(),
      avatarMode: "curated_provided_real_photo",
      avatarVersion: AVATAR_VERSION,
    },
    records,
  };
  if (options.apply) fs.writeFileSync(options.input, JSON.stringify(outputJson, null, 2));
  fs.writeFileSync(options.manifest, JSON.stringify(manifest, null, 2));

  console.log(
    JSON.stringify(
      {
        ok: true,
        version: AVATAR_VERSION,
        mode: manifest.mode,
        recordCount: manifest.recordCount,
        sourceImageCount: manifest.sourceImageCount,
        previewPath,
        manifest: options.manifest,
        first: manifest.items[0],
        last: manifest.items[manifest.items.length - 1],
      },
      null,
      2,
    ),
  );
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
