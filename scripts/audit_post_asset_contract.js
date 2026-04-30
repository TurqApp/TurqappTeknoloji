#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

function parseArgs(argv) {
  const args = {
    input: "",
    report: "",
    manifest: "",
  };
  for (let index = 2; index < argv.length; index += 1) {
    const value = argv[index];
    if (!args.input && !value.startsWith("--")) {
      args.input = value;
      continue;
    }
    if (value === "--report") {
      args.report = argv[index + 1] || "";
      index += 1;
      continue;
    }
    if (value === "--manifest") {
      args.manifest = argv[index + 1] || "";
      index += 1;
      continue;
    }
  }
  if (!args.input) {
    throw new Error(
      "Usage: node scripts/audit_post_asset_contract.js <input.ndjson> [--report report.json] [--manifest manifest.ndjson]"
    );
  }
  return args;
}

function readLines(filePath) {
  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) return [];
  return raw.split(/\n+/);
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function isCanonicalShortUrl(url) {
  return /^https:\/\/turqapp\.com\/(p|s|u|e|i|m)\/[A-Za-z0-9]{6,10}$/.test(url);
}

function decodeFirebaseObjectPath(urlValue) {
  try {
    const parsed = new URL(urlValue);
    const marker = "/o/";
    const index = parsed.pathname.indexOf(marker);
    if (index === -1) return "";
    return decodeURIComponent(parsed.pathname.slice(index + marker.length));
  } catch {
    return "";
  }
}

function canonicalPostAssetUrl(docId, relativeName) {
  return `https://cdn.turqapp.com/Posts/${docId}/${relativeName}`;
}

function classifyThumbnail(docId, thumbnail) {
  if (!thumbnail) return { kind: "missing" };
  if (thumbnail.startsWith(`https://cdn.turqapp.com/Posts/${docId}/`)) {
    return { kind: "canonical" };
  }
  if (thumbnail.startsWith("https://cdn.turqapp.com/v0/b/")) {
    const objectPath = decodeFirebaseObjectPath(thumbnail);
    return { kind: "tokenized_cdn", objectPath };
  }
  return { kind: "other" };
}

function classifyVideo(docId, video) {
  if (!video) return { kind: "missing" };
  if (video === canonicalPostAssetUrl(docId, "hls/master.m3u8")) {
    return { kind: "canonical_hls" };
  }
  if (video.startsWith("https://cdn.turqapp.com/v0/b/")) {
    const objectPath = decodeFirebaseObjectPath(video);
    return { kind: "tokenized_cdn", objectPath };
  }
  return { kind: "other" };
}

function classifyAvatar(avatar) {
  if (!avatar) return "missing";
  if (avatar.startsWith("https://firebasestorage.googleapis.com/v0/b/")) {
    return "firebase_tokenized";
  }
  if (avatar.startsWith("https://cdn.turqapp.com/")) {
    return "cdn";
  }
  return "other";
}

function buildPatch(docId, data) {
  const safePatch = {};
  const safeReasons = [];
  const phase2Patch = {};
  const phase2Reasons = [];
  const thumbnail = asString(data.thumbnail);
  const thumbInfo = classifyThumbnail(docId, thumbnail);
  if (thumbInfo.kind === "tokenized_cdn") {
    const expected = `Posts/${docId}/thumbnail.webp`;
    if (thumbInfo.objectPath === expected) {
      safePatch.thumbnail = canonicalPostAssetUrl(docId, "thumbnail.webp");
      safeReasons.push("thumbnail_tokenized_to_canonical");
    }
  }

  const imgs = Array.isArray(data.img) ? data.img : [];
  if (imgs.length > 0) {
    const rewritten = [];
    let changed = false;
    for (const current of imgs) {
      const urlValue = asString(current);
      if (!urlValue) {
        rewritten.push(urlValue);
        continue;
      }
      if (!urlValue.startsWith("https://cdn.turqapp.com/v0/b/")) {
        rewritten.push(urlValue);
        continue;
      }
      const objectPath = decodeFirebaseObjectPath(urlValue);
      const prefix = `Posts/${docId}/`;
      if (!objectPath.startsWith(prefix)) {
        rewritten.push(urlValue);
        continue;
      }
      const relativeName = objectPath.slice(prefix.length);
      const canonical = canonicalPostAssetUrl(docId, relativeName);
      rewritten.push(canonical);
      changed = changed || canonical !== urlValue;
    }
    if (changed) {
      safePatch.img = rewritten;
      safeReasons.push("img_tokenized_to_canonical");
    }
  }

  return { safePatch, safeReasons, phase2Patch, phase2Reasons };
}

function pushLimited(target, value, limit = 10) {
  if (target.length < limit) target.push(value);
}

function main() {
  const args = parseArgs(process.argv);
  const lines = readLines(args.input);

  const summary = {
    total: 0,
    docIdWithUnderscore: 0,
    hlsReady: 0,
    hlsFailed: 0,
    thumbnail: {
      missing: 0,
      canonical: 0,
      tokenizedCdn: 0,
      other: 0,
    },
    video: {
      missing: 0,
      canonicalHls: 0,
      tokenizedCdn: 0,
      other: 0,
    },
    avatar: {
      missing: 0,
      firebaseTokenized: 0,
      cdn: 0,
      other: 0,
    },
    shortUrl: {
      missing: 0,
      canonical: 0,
      other: 0,
    },
    img: {
      emptyPosts: 0,
      tokenizedEntries: 0,
      canonicalEntries: 0,
      otherEntries: 0,
    },
    patchablePosts: 0,
    patchableFields: {
      thumbnail: 0,
      video: 0,
      img: 0,
    },
    patchableNowPosts: 0,
    patchablePhase2Posts: 0,
  };

  const samples = {
    thumbnailOther: [],
    videoOther: [],
    shortUrlMissing: [],
    shortUrlOther: [],
    avatarOther: [],
    tokenizedVideoPosts: [],
    canonicalThumbnailPosts: [],
  };

  const manifestEntries = [];

  for (const line of lines) {
    if (!line.trim()) continue;
    const row = JSON.parse(line);
    const docId = asString(row.docId);
    const data = row.data || {};
    summary.total += 1;
    if (docId.includes("_")) summary.docIdWithUnderscore += 1;

    const hlsStatus = asString(data.hlsStatus);
    if (hlsStatus === "ready") summary.hlsReady += 1;
    if (hlsStatus === "failed") summary.hlsFailed += 1;

    const thumbnail = asString(data.thumbnail);
    const thumbnailInfo = classifyThumbnail(docId, thumbnail);
    if (thumbnailInfo.kind === "missing") summary.thumbnail.missing += 1;
    if (thumbnailInfo.kind === "canonical") {
      summary.thumbnail.canonical += 1;
      pushLimited(samples.canonicalThumbnailPosts, {
        docId,
        thumbnail,
        video: asString(data.video),
      });
    }
    if (thumbnailInfo.kind === "tokenized_cdn") summary.thumbnail.tokenizedCdn += 1;
    if (thumbnailInfo.kind === "other") {
      summary.thumbnail.other += 1;
      pushLimited(samples.thumbnailOther, { docId, thumbnail });
    }

    const video = asString(data.video);
    const videoInfo = classifyVideo(docId, video);
    if (videoInfo.kind === "missing") summary.video.missing += 1;
    if (videoInfo.kind === "canonical_hls") summary.video.canonicalHls += 1;
    if (videoInfo.kind === "tokenized_cdn") {
      summary.video.tokenizedCdn += 1;
      pushLimited(samples.tokenizedVideoPosts, { docId, video, hlsStatus });
    }
    if (videoInfo.kind === "other") {
      summary.video.other += 1;
      pushLimited(samples.videoOther, { docId, video, hlsStatus });
    }

    const shortUrl = asString(data.shortUrl);
    if (!shortUrl) {
      summary.shortUrl.missing += 1;
      pushLimited(samples.shortUrlMissing, {
        docId,
        shortId: data.shortId || null,
        shortLinkStatus: data.shortLinkStatus || null,
      });
    } else if (isCanonicalShortUrl(shortUrl)) {
      summary.shortUrl.canonical += 1;
    } else {
      summary.shortUrl.other += 1;
      pushLimited(samples.shortUrlOther, {
        docId,
        shortUrl,
        shortId: data.shortId || null,
      });
    }

    const avatar = asString(data.avatarUrl || data.authorAvatarUrl);
    const avatarKind = classifyAvatar(avatar);
    if (avatarKind === "missing") summary.avatar.missing += 1;
    if (avatarKind === "firebase_tokenized") summary.avatar.firebaseTokenized += 1;
    if (avatarKind === "cdn") summary.avatar.cdn += 1;
    if (avatarKind === "other") {
      summary.avatar.other += 1;
      pushLimited(samples.avatarOther, { docId, avatar });
    }

    const imgs = Array.isArray(data.img) ? data.img : [];
    if (imgs.length === 0) {
      summary.img.emptyPosts += 1;
    } else {
      for (const value of imgs) {
        const current = asString(value);
        if (!current) continue;
        if (current.startsWith("https://cdn.turqapp.com/v0/b/")) {
          summary.img.tokenizedEntries += 1;
        } else if (current.startsWith(`https://cdn.turqapp.com/Posts/${docId}/`)) {
          summary.img.canonicalEntries += 1;
        } else {
          summary.img.otherEntries += 1;
        }
      }
    }

    const { safePatch, safeReasons, phase2Patch, phase2Reasons } = buildPatch(docId, data);
    if (safeReasons.length > 0 || phase2Reasons.length > 0) {
      summary.patchablePosts += 1;
      if (safeReasons.length > 0) {
        summary.patchableNowPosts += 1;
      }
      if (phase2Reasons.length > 0) {
        summary.patchablePhase2Posts += 1;
      }
      if (Object.prototype.hasOwnProperty.call(safePatch, "thumbnail")) {
        summary.patchableFields.thumbnail += 1;
      }
      if (Object.prototype.hasOwnProperty.call(safePatch, "video")) {
        summary.patchableFields.video += 1;
      }
      if (Object.prototype.hasOwnProperty.call(phase2Patch, "img")) {
        summary.patchableFields.img += 1;
      }
      manifestEntries.push({
        docId,
        safePatch,
        safeReasons,
        phase2Patch,
        phase2Reasons,
      });
    }
  }

  const report = {
    input: args.input,
    generatedAt: new Date().toISOString(),
    summary,
    samples,
  };

  if (args.report) {
    ensureDir(args.report);
    fs.writeFileSync(args.report, JSON.stringify(report, null, 2));
  }

  if (args.manifest) {
    ensureDir(args.manifest);
    const content = manifestEntries.map((entry) => JSON.stringify(entry)).join("\n");
    fs.writeFileSync(args.manifest, content ? `${content}\n` : "");
  }

  console.log(JSON.stringify(report, null, 2));
  if (args.manifest) {
    console.log(
      JSON.stringify(
        {
          manifest: args.manifest,
          entries: manifestEntries.length,
        },
        null,
        2
      )
    );
  }
}

main();
