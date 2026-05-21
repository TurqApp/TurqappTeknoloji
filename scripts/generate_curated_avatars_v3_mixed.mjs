#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const AVATAR_VERSION = "v3";
const DEFAULT_INPUT = "/Users/turqapp/Desktop/turqapp_curated_user_import_ready_184.json";
const DEFAULT_MAPPING = "/Users/turqapp/Desktop/turqapp_curated_source_user_mapping_fresh_2026-05-21.json";
const DEFAULT_OUT_DIR = "/Users/turqapp/Desktop/TurqApp/artifacts/curated_avatars_v3";
const DEFAULT_MANIFEST = "/Users/turqapp/Desktop/turqapp_curated_avatar_manifest_184.json";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp_Firebase/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";

const require = createRequire(import.meta.url);
const admin = require(path.resolve("functions/node_modules/firebase-admin"));
const sharp = require(path.resolve("functions/node_modules/sharp"));

const TOPIC_COLORS = {
  tech_ai: ["#07111F", "#22D3EE", "#60A5FA", "#A7F3D0"],
  auto_mobility: ["#111827", "#EF4444", "#FBBF24", "#D1D5DB"],
  art_visual: ["#211626", "#F472B6", "#FDE68A", "#93C5FD"],
  home_style: ["#1C1917", "#D6D3D1", "#A3E635", "#FDBA74"],
  knowledge_science: ["#0F172A", "#67E8F9", "#FDE047", "#E0F2FE"],
  faith_values: ["#102018", "#D9F99D", "#FACC15", "#F5E6C8"],
  world_history_news: ["#1F2937", "#D6B37A", "#38BDF8", "#F5E7C4"],
  entertainment_humor: ["#18181B", "#A78BFA", "#F472B6", "#FDE68A"],
  sports: ["#052E16", "#BBF7D0", "#F97316", "#E2E8F0"],
  food_cafe: ["#2A1508", "#FED7AA", "#F59E0B", "#FEF3C7"],
  music: ["#111827", "#C4B5FD", "#FDE047", "#F9A8D4"],
  travel_nature: ["#0C1F17", "#86EFAC", "#38BDF8", "#FDE68A"],
  motivation_life: ["#1E1B4B", "#FDBA74", "#FDE047", "#C7D2FE"],
  craft_work: ["#171717", "#D4D4D4", "#F97316", "#FACC15"],
  health_people: ["#062B2B", "#CCFBF1", "#F472B6", "#FFFFFF"],
  general_culture: ["#111827", "#CBD5E1", "#FBBF24", "#BFDBFE"],
};

function parseArgs(argv) {
  const options = {
    input: DEFAULT_INPUT,
    mapping: DEFAULT_MAPPING,
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
    } else if (arg === "--mapping") {
      options.mapping = String(argv[index + 1] || "").trim() || options.mapping;
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

function hashNumber(input) {
  let hash = 2166136261;
  for (const char of String(input)) {
    hash ^= char.charCodeAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function xml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function pick(list, seed, salt = 0) {
  return list[(seed + salt) % list.length];
}

function hsl(seed, offset = 0, saturation = 70, lightness = 48) {
  return `hsl(${(seed * 43 + offset) % 360} ${saturation}% ${lightness}%)`;
}

function initials(record) {
  const doc = record.usersDoc || {};
  const first = String(doc.firstName || doc.displayName || doc.nickname || record.uid || "")
    .trim()
    .charAt(0);
  const last = String(doc.lastName || "").trim().charAt(0);
  return `${first}${last}`.toLocaleUpperCase("tr-TR") || "T";
}

function loadUserTopics(mappingPath) {
  if (!mappingPath || !fs.existsSync(mappingPath)) return new Map();
  const mapping = JSON.parse(fs.readFileSync(mappingPath, "utf8"));
  const result = new Map();
  for (const pool of mapping.pools || []) {
    if (pool.userID) result.set(pool.userID, pool.topic || "general_culture");
  }
  return result;
}

function collectAssetFiles() {
  const roots = [
    "assets/images/turqapp_suggestions",
    "assets/slider/live",
    "assets/bursSablonlar",
    "assets/tutorings",
    "assets/education",
    "assets/images",
  ];
  const files = [];
  for (const root of roots) {
    if (!fs.existsSync(root)) continue;
    for (const entry of fs.readdirSync(root)) {
      const filePath = path.join(root, entry);
      if (fs.statSync(filePath).isFile() && /\.(webp|png|jpe?g)$/i.test(entry)) files.push(filePath);
    }
  }
  return files.sort();
}

function topicMark(topic, colors) {
  const [dark, main, accent, warm] = colors;
  const common = `stroke-linecap="round" stroke-linejoin="round"`;
  if (topic.includes("tech")) return `<circle cx="60" cy="60" r="34" fill="${dark}"/><path d="M43 60h34M60 43v34M46 47l28 26M74 47L46 73" stroke="${accent}" stroke-width="8" ${common}/>`;
  if (topic.includes("auto")) return `<path d="M28 67c7-20 19-32 35-32h17c12 3 22 15 27 32" fill="${dark}"/><circle cx="47" cy="72" r="10" fill="${warm}"/><circle cx="91" cy="72" r="10" fill="${warm}"/>`;
  if (topic.includes("music")) return `<path d="M75 24v52" stroke="${warm}" stroke-width="12" ${common}/><path d="M75 24l31 12" stroke="${accent}" stroke-width="9" ${common}/><circle cx="53" cy="84" r="17" fill="${warm}"/>`;
  if (topic.includes("sports")) return `<circle cx="64" cy="64" r="39" fill="${warm}"/><path d="M64 25c-11 24-11 54 0 78M29 55c22-10 49-10 70 0M29 75c22 10 49 10 70 0" stroke="${dark}" stroke-width="7" fill="none"/>`;
  if (topic.includes("food")) return `<path d="M42 41h48v31c0 19-12 31-24 31S42 91 42 72V41Z" fill="${warm}"/><path d="M90 52h13c12 0 14 21-4 24" fill="none" stroke="${warm}" stroke-width="9"/>`;
  return `<rect x="32" y="32" width="64" height="64" rx="18" fill="${dark}"/><path d="M46 55h36M46 73h26" stroke="${accent}" stroke-width="9" ${common}/>`;
}

function vectorSvg(record, index, topic, family) {
  const seed = hashNumber(`${record.uid}:${index}:${AVATAR_VERSION}:${family}`);
  const mono = initials(record);
  const colors = TOPIC_COLORS[topic] || TOPIC_COLORS.general_culture;
  const [dark, main, accent, warm] = colors;
  const bg1 = hsl(seed, 0, 78, 28 + (seed % 18));
  const bg2 = hsl(seed, 120, 74, 45 + ((seed >> 4) % 18));
  const bg3 = hsl(seed, 250, 82, 58);
  const skin = pick(["#F5C7A9", "#E8A87C", "#D19163", "#B87550", "#8D563F", "#F1BFA5"], seed);
  const hair = pick(["#111827", "#2D1B48", "#3A2418", "#5B3422", "#6B3F24", "#0F172A"], seed, 8);
  const rounded = 32 + (seed % 96);
  const defs = `<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${bg1}"/><stop offset=".55" stop-color="${bg2}"/><stop offset="1" stop-color="${bg3}"/></linearGradient><filter id="s"><feDropShadow dx="0" dy="16" stdDeviation="18" flood-opacity=".32"/></filter><filter id="n"><feTurbulence baseFrequency=".9" numOctaves="3"/><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncA type="table" tableValues="0 .12"/></feComponentTransfer></filter></defs>`;
  const frame = `<rect width="512" height="512" rx="${rounded}" fill="url(#bg)"/><circle cx="${80 + (seed % 330)}" cy="${80 + ((seed >> 4) % 330)}" r="${60 + ((seed >> 7) % 90)}" fill="#fff" opacity=".11"/><rect width="512" height="512" rx="${rounded}" filter="url(#n)" opacity=".24"/>`;
  const styles = [
    `<text x="256" y="304" text-anchor="middle" font-family="Arial Black, Arial" font-size="${mono.length > 1 ? 152 : 188}" fill="#fff">${xml(mono)}</text><path d="M96 382h320" stroke="${accent}" stroke-width="24" stroke-linecap="round"/>`,
    `<g>${Array.from({ length: 9 }, (_, i) => `<rect x="${46 + ((seed >> i) % 330)}" y="${48 + ((seed >> (i + 2)) % 330)}" width="${44 + ((seed >> (i + 5)) % 98)}" height="${44 + ((seed >> (i + 7)) % 98)}" rx="${4 + ((seed >> (i + 9)) % 34)}" fill="${hsl(seed, i * 51, 82, 54)}" opacity=".78" transform="rotate(${(seed >> i) % 45} 256 256)"/>`).join("")}</g><text x="256" y="292" text-anchor="middle" font-family="Arial Black, Arial" font-size="96" fill="#fff">${xml(mono)}</text>`,
    `<path d="M118 454c20-98 73-154 138-154s118 56 138 154H118Z" fill="${main}" filter="url(#s)"/><ellipse cx="256" cy="214" rx="86" ry="104" fill="${skin}"/><path d="M163 213c11-88 64-136 127-119 47 13 76 58 70 124-70-42-129-45-197-5Z" fill="${hair}"/><path d="M209 245h38M275 245h38" stroke="#111827" stroke-width="12" stroke-linecap="round"/><path d="M222 318c24 19 49 19 74 0" stroke="#7C3F32" stroke-width="9" stroke-linecap="round"/>`,
    `<path d="M91 384 256 87l165 297H91Z" fill="${main}" filter="url(#s)"/><circle cx="256" cy="248" r="76" fill="${accent}"/><text x="256" y="274" text-anchor="middle" font-family="Arial Black, Arial" font-size="74" fill="${dark}">${xml(mono.slice(0, 1))}</text>`,
    `<rect x="92" y="112" width="328" height="288" rx="28" fill="#fff" opacity=".14" filter="url(#s)"/><path d="M135 170h242M135 229h160M135 288h212" stroke="${warm}" stroke-width="18" stroke-linecap="round"/><text x="363" y="367" text-anchor="middle" font-family="Arial Black, Arial" font-size="80" fill="#fff">${xml(mono)}</text>`,
    `<g transform="translate(128 116) scale(2)">${topicMark(topic, colors)}</g><text x="96" y="432" font-family="Arial Black, Arial" font-size="68" fill="#fff">${xml(mono)}</text>`,
    `<g>${Array.from({ length: 64 }, (_, i) => `<rect x="${64 + (i % 8) * 48}" y="${64 + Math.floor(i / 8) * 48}" width="44" height="44" fill="${hsl(seed, (i * 19) + (seed % 60), 72, 46 + ((i + seed) % 18))}"/>`).join("")}</g><rect x="168" y="168" width="176" height="176" rx="24" fill="#111827" opacity=".86"/><text x="256" y="288" text-anchor="middle" font-family="Arial Black, Arial" font-size="78" fill="#fff">${xml(mono)}</text>`,
    `<circle cx="256" cy="256" r="166" fill="${dark}" opacity=".85" filter="url(#s)"/><circle cx="256" cy="256" r="126" fill="none" stroke="${accent}" stroke-width="22"/><text x="256" y="286" text-anchor="middle" font-family="Georgia, serif" font-size="${mono.length > 1 ? 94 : 124}" font-weight="700" fill="${warm}">${xml(mono)}</text>`,
    `<path d="M62 382C116 214 223 109 407 79c-35 155-128 282-345 303Z" fill="${main}" filter="url(#s)"/><path d="M124 347c102-84 177-147 249-229" stroke="${warm}" stroke-width="15" stroke-linecap="round"/><text x="392" y="422" text-anchor="middle" font-family="Arial Black, Arial" font-size="64" fill="#fff">${xml(mono)}</text>`,
    `<rect x="124" y="74" width="264" height="364" rx="132" fill="${skin}" filter="url(#s)"/><path d="M123 206c23-96 81-143 162-130 63 11 101 58 105 130-94-50-180-50-267 0Z" fill="${hair}"/><path d="M190 258h42M281 258h42" stroke="#111827" stroke-width="14" stroke-linecap="round"/><path d="M216 336c29 19 53 19 82 0" stroke="#7C3F32" stroke-width="10" stroke-linecap="round"/>`,
    `<path d="M84 132h344v248H84Z" fill="${warm}" transform="rotate(${(seed % 22) - 11} 256 256)" filter="url(#s)"/><path d="M124 188h264M124 250h190M124 312h236" stroke="${dark}" stroke-width="20" stroke-linecap="round"/><text x="372" y="372" text-anchor="middle" font-family="Arial Black, Arial" font-size="72" fill="#fff">${xml(mono)}</text>`,
  ];
  return `<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">${defs}${frame}${styles[family % styles.length]}<rect x="2" y="2" width="508" height="508" rx="${rounded}" fill="none" stroke="#fff" stroke-opacity=".17" stroke-width="4"/></svg>`;
}

async function renderRasterAvatar({ assetFiles, record, index, topic, outPath }) {
  const seed = hashNumber(`${record.uid}:${index}:${AVATAR_VERSION}:raster`);
  const mono = initials(record);
  const colors = TOPIC_COLORS[topic] || TOPIC_COLORS.general_culture;
  const asset = assetFiles.length ? assetFiles[seed % assetFiles.length] : null;
  const overlay = Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${colors[0]}" stop-opacity=".82"/><stop offset="1" stop-color="${colors[2]}" stop-opacity=".45"/></linearGradient><filter id="s"><feDropShadow dx="0" dy="14" stdDeviation="14" flood-opacity=".35"/></filter></defs><rect width="512" height="512" rx="${48 + (seed % 88)}" fill="url(#g)"/><circle cx="${112 + (seed % 260)}" cy="${98 + ((seed >> 5) % 290)}" r="${80 + ((seed >> 9) % 90)}" fill="#fff" opacity=".14"/><rect x="74" y="${286 + (seed % 44)}" width="364" height="118" rx="28" fill="#111827" opacity=".72" filter="url(#s)"/><text x="256" y="${364 + (seed % 22)}" text-anchor="middle" font-family="Arial Black, Arial" font-size="${mono.length > 1 ? 74 : 96}" fill="#fff">${xml(mono)}</text></svg>`,
  );
  const base = asset
    ? sharp(asset).resize(512, 512, { fit: "cover" }).modulate({
        saturation: 0.65 + ((seed % 50) / 100),
        brightness: 0.72 + (((seed >> 4) % 35) / 100),
      })
    : sharp({ create: { width: 512, height: 512, channels: 4, background: colors[0] } });
  await base.composite([{ input: overlay, blend: "over" }]).webp({ quality: 88 }).toFile(outPath);
}

async function renderAvatar({ assetFiles, record, index, topic, fullPath, thumbPath }) {
  const seed = hashNumber(`${record.uid}:${index}:${AVATAR_VERSION}`);
  const family = seed % 14;
  if (family === 0 || family === 5 || family === 11) {
    await renderRasterAvatar({ assetFiles, record, index, topic, outPath: fullPath });
  } else {
    const svg = vectorSvg(record, index, topic, family);
    await sharp(Buffer.from(svg)).resize(512, 512).webp({ quality: 88 }).toFile(fullPath);
  }
  await sharp(fullPath).resize(150, 150).webp({ quality: 86 }).toFile(thumbPath);
  return family;
}

function initializeAdmin(serviceAccountPath) {
  if (admin.apps.length > 0) return;
  const credential = fs.existsSync(serviceAccountPath)
    ? admin.credential.cert(require(serviceAccountPath))
    : undefined;
  admin.initializeApp({
    credential,
    projectId: PROJECT_ID,
    storageBucket: STORAGE_BUCKET,
  });
}

async function uploadAvatar({ bucket, record, fullPath, thumbPath }) {
  const uid = record.uid;
  const fullStoragePath = `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}.webp`;
  const thumbStoragePath = `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`;
  const metadata = (size) => ({
    contentType: "image/webp",
    cacheControl: "public, max-age=31536000",
    metadata: { curatedAvatar: "true", avatarKind: "mixed_distinct_profile", avatarVersion: AVATAR_VERSION, size },
  });
  await bucket.upload(fullPath, { destination: fullStoragePath, metadata: metadata("512") });
  await bucket.upload(thumbPath, { destination: thumbStoragePath, metadata: metadata("150") });
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
    avatarType: "curated_mixed_distinct_profile",
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

async function run() {
  const options = parseArgs(process.argv);
  const inputJson = JSON.parse(fs.readFileSync(options.input, "utf8"));
  const records = (inputJson.records || []).slice(0, options.limit > 0 ? options.limit : undefined);
  const userTopics = loadUserTopics(options.mapping);
  const assetFiles = collectAssetFiles();
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
    outDir: options.outDir,
    recordCount: records.length,
    assetFileCount: assetFiles.length,
    familyCounts: {},
    topicCounts: {},
    items: [],
  };

  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    const uid = record.uid;
    const topic = userTopics.get(uid) || "general_culture";
    const fullPath = path.join(options.outDir, `${uid}.webp`);
    const thumbPath = path.join(options.outDir, `${uid}_thumb_150.webp`);
    const family = await renderAvatar({ assetFiles, record, index, topic, fullPath, thumbPath });
    const avatar = options.apply
      ? await uploadAvatar({ bucket, record, fullPath, thumbPath })
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
    manifest.familyCounts[family] = (manifest.familyCounts[family] || 0) + 1;
    manifest.topicCounts[topic] = (manifest.topicCounts[topic] || 0) + 1;
    manifest.items.push({
      uid,
      nickname: record.usersDoc?.nickname || "",
      topic,
      family,
      avatarUrl: avatar.avatarUrl,
      fullUrl: avatar.fullUrl,
      localWebp: fullPath,
      localThumb: thumbPath,
    });
  }

  const outputJson = {
    ...inputJson,
    metadata: {
      ...(inputJson.metadata || {}),
      avatarsUpdatedAt: new Date().toISOString(),
      avatarMode: "curated_mixed_distinct_profile",
      avatarVersion: AVATAR_VERSION,
    },
    records,
  };
  if (options.apply) fs.writeFileSync(options.input, JSON.stringify(outputJson, null, 2));
  fs.writeFileSync(options.manifest, JSON.stringify(manifest, null, 2));
  console.log(JSON.stringify({
    ok: true,
    version: AVATAR_VERSION,
    mode: manifest.mode,
    recordCount: manifest.recordCount,
    assetFileCount: manifest.assetFileCount,
    familyCounts: manifest.familyCounts,
    manifest: options.manifest,
    first: manifest.items[0],
    last: manifest.items[manifest.items.length - 1],
  }, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
