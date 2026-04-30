#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

function parseArgs(argv) {
  const args = {
    input: "/Users/turqapp/Desktop/target_Posts_all.json",
    report: "",
  };

  for (let index = 2; index < argv.length; index += 1) {
    const value = String(argv[index] || "").trim();
    if (!value) continue;
    if (value === "--input") {
      args.input = String(argv[index + 1] || "").trim() || args.input;
      index += 1;
      continue;
    }
    if (value === "--report") {
      args.report = String(argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
  }

  return args;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function asString(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

function isUrlString(value) {
  const text = asString(value);
  return text.startsWith("http://") || text.startsWith("https://");
}

function increment(map, key, amount = 1) {
  map.set(key, (map.get(key) || 0) + amount);
}

function pushSample(map, key, sample, limit = 5) {
  if (!map.has(key)) map.set(key, []);
  const list = map.get(key);
  if (list.length < limit && !list.includes(sample)) {
    list.push(sample);
  }
}

function classifyUrl(rawUrl) {
  const text = asString(rawUrl);
  const result = {
    host: "",
    category: "other",
    tokenized: false,
    canonicalPostCdn: false,
    canonicalUserCdn: false,
    shortLink: false,
    parseError: false,
  };

  try {
    const parsed = new URL(text);
    result.host = parsed.hostname;
    result.tokenized = parsed.searchParams.has("token") || parsed.pathname.includes("/v0/b/");

    if (parsed.hostname === "cdn.turqapp.com") {
      if (parsed.pathname.startsWith("/Posts/")) {
        result.category = "cdn_post_path";
        result.canonicalPostCdn = true;
      } else if (parsed.pathname.startsWith("/users/")) {
        result.category = "cdn_user_path";
        result.canonicalUserCdn = true;
      } else if (parsed.pathname.startsWith("/v0/b/")) {
        result.category = "cdn_tokenized_download";
      } else {
        result.category = "cdn_other";
      }
    } else if (
      parsed.hostname === "firebasestorage.googleapis.com" ||
      parsed.hostname === "turqappteknoloji.firebasestorage.app"
    ) {
      result.category = "firebase_download";
    } else if (parsed.hostname === "storage.googleapis.com") {
      result.category = "gcs_direct";
    } else if (parsed.hostname === "turqapp.com" || parsed.hostname === "www.turqapp.com") {
      result.category = "turqapp_link";
      if (/^\/[psumei]\//.test(parsed.pathname)) {
        result.shortLink = true;
      }
    }
  } catch {
    result.parseError = true;
    result.category = "invalid_url";
  }

  return result;
}

function auditObject(value, ctx) {
  if (Array.isArray(value)) {
    value.forEach((entry, index) => {
      auditObject(entry, {
        ...ctx,
        fieldPath: ctx.fieldPath ? `${ctx.fieldPath}[${index}]` : `[${index}]`,
      });
    });
    return;
  }

  if (value && typeof value === "object") {
    for (const [key, entry] of Object.entries(value)) {
      auditObject(entry, {
        ...ctx,
        fieldPath: ctx.fieldPath ? `${ctx.fieldPath}.${key}` : key,
      });
    }
    return;
  }

  if (!isUrlString(value)) return;

  const url = asString(value);
  const fieldPath = ctx.fieldPath || "<root>";
  const meta = classifyUrl(url);

  ctx.summary.totalUrlOccurrences += 1;
  increment(ctx.summary.urlsByField, fieldPath);
  increment(ctx.summary.urlsByHost, meta.host || "<unknown>");
  increment(ctx.summary.urlsByCategory, meta.category);
  if (meta.tokenized) ctx.summary.tokenizedUrlCount += 1;
  if (meta.canonicalPostCdn) ctx.summary.canonicalPostCdnCount += 1;
  if (meta.canonicalUserCdn) ctx.summary.canonicalUserCdnCount += 1;
  if (meta.shortLink) ctx.summary.shortLinkCount += 1;
  if (meta.parseError) ctx.summary.invalidUrlCount += 1;

  pushSample(ctx.summary.fieldSamples, fieldPath, url);
}

function mapToSortedObject(map, limit = 0) {
  const entries = Array.from(map.entries()).sort((a, b) => b[1] - a[1]);
  const sliced = limit > 0 ? entries.slice(0, limit) : entries;
  return Object.fromEntries(sliced);
}

function samplesToObject(map) {
  return Object.fromEntries(Array.from(map.entries()).sort((a, b) => a[0].localeCompare(b[0])));
}

async function run() {
  const options = parseArgs(process.argv);
  const raw = fs.readFileSync(options.input, "utf8");
  const posts = JSON.parse(raw);

  const summary = {
    generatedAt: new Date().toISOString(),
    input: options.input,
    totalPosts: Array.isArray(posts) ? posts.length : 0,
    totalUrlOccurrences: 0,
    tokenizedUrlCount: 0,
    canonicalPostCdnCount: 0,
    canonicalUserCdnCount: 0,
    shortLinkCount: 0,
    invalidUrlCount: 0,
    urlsByField: new Map(),
    urlsByHost: new Map(),
    urlsByCategory: new Map(),
    fieldSamples: new Map(),
  };

  for (const post of posts) {
    auditObject(post, {
      fieldPath: "",
      summary,
    });
  }

  const report = {
    generatedAt: summary.generatedAt,
    input: summary.input,
    totalPosts: summary.totalPosts,
    totalUrlOccurrences: summary.totalUrlOccurrences,
    tokenizedUrlCount: summary.tokenizedUrlCount,
    canonicalPostCdnCount: summary.canonicalPostCdnCount,
    canonicalUserCdnCount: summary.canonicalUserCdnCount,
    shortLinkCount: summary.shortLinkCount,
    invalidUrlCount: summary.invalidUrlCount,
    topFields: mapToSortedObject(summary.urlsByField, 40),
    topHosts: mapToSortedObject(summary.urlsByHost, 20),
    categories: mapToSortedObject(summary.urlsByCategory, 20),
    fieldSamples: samplesToObject(summary.fieldSamples),
  };

  if (options.report) {
    ensureDir(options.report);
    fs.writeFileSync(options.report, JSON.stringify(report, null, 2));
  }

  console.log(JSON.stringify(report, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
