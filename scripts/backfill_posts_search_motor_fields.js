#!/usr/bin/env node

const path = require("path");

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "turqappteknoloji";
const POSTS_COLLECTION = "posts_search";
const SHORT_SURFACE_LANDSCAPE_ASPECT_THRESHOLD = 1.2;
const DEFAULT_PER_PAGE = Math.max(
  1,
  Math.min(250, Number(process.env.TYPESENSE_BACKFILL_PER_PAGE || 250)),
);
const DEFAULT_IMPORT_CHUNK = Math.max(
  1,
  Math.min(DEFAULT_PER_PAGE, Number(process.env.TYPESENSE_BACKFILL_IMPORT_CHUNK || 25)),
);
const DEFAULT_START_PAGE = Math.max(
  1,
  Number(process.env.TYPESENSE_BACKFILL_START_PAGE || 1),
);
const DEFAULT_MAX_PAGES = Math.max(
  0,
  Number(process.env.TYPESENSE_BACKFILL_MAX_PAGES || 0),
);
const DEFAULT_MAX_UPDATES = Math.max(
  0,
  Number(process.env.TYPESENSE_BACKFILL_MAX_UPDATES || 0),
);
const DEFAULT_SORT_BY =
  String(process.env.TYPESENSE_BACKFILL_SORT_BY || "timeStamp:desc").trim() ||
  "timeStamp:desc";
const SINGLE_DOC_UPSERT =
  Number(process.env.TYPESENSE_BACKFILL_SINGLE_DOC_UPSERT || 0) > 0;
const PATCH_ONLY_FIELDS =
  Number(process.env.TYPESENSE_BACKFILL_PATCH_ONLY_FIELDS || 0) > 0;
const DEBUG_SAMPLE = Number(process.env.TYPESENSE_BACKFILL_DEBUG_SAMPLE || 0) > 0;

function toBool(value) {
  return value === true;
}

function toNumber(value, fallback = 0) {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : fallback;
}

function resolveMinuteOfHour(timeStamp) {
  const numeric = toNumber(timeStamp, 0);
  if (numeric <= 0) return 0;
  return new Date(numeric).getUTCMinutes();
}

function resolveSurfaceTargets(doc) {
  const isVisiblePublic =
    toNumber(doc.paylasGizliligi, 0) === 0 &&
    !toBool(doc.arsiv) &&
    !toBool(doc.deletedPost) &&
    !toBool(doc.gizlendi) &&
    !toBool(doc.isUploading);
  if (!isVisiblePublic) {
    return [];
  }

  const targets = ["feed"];
  const isShortEligible =
    toBool(doc.hasPlayableVideo) &&
    String(doc.hlsStatus || "").toLowerCase() === "ready" &&
    toNumber(doc.aspectRatio, 0) > 0 &&
    toNumber(doc.aspectRatio, 0) <= SHORT_SURFACE_LANDSCAPE_ASPECT_THRESHOLD &&
    !toBool(doc.flood);
  if (isShortEligible) {
    targets.push("short", "quota");
  }
  return targets;
}

function sameTargets(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
  return a.every((value, index) => String(value) === String(b[index]));
}

function decodeSecretPayload(payload) {
  const encoded = payload?.payload?.data;
  if (!encoded) {
    throw new Error("secret_payload_missing");
  }
  return Buffer.from(encoded, "base64").toString("utf8").trim();
}

async function getAccessToken() {
  const firebaseToolsRoot = path.join(
    __dirname,
    "..",
    "functions",
    "node_modules",
    "firebase-tools",
    "lib",
  );
  const auth = require(path.join(firebaseToolsRoot, "auth"));
  const apiv2 = require(path.join(firebaseToolsRoot, "apiv2"));

  const projectRoot = path.join(__dirname, "..");
  const account =
    auth.getProjectDefaultAccount(projectRoot) || auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) {
    throw new Error("firebase_cli_auth_missing");
  }

  apiv2.setRefreshToken(account.tokens.refresh_token);
  return apiv2.getAccessToken();
}

async function fetchGoogleJson(url, accessToken) {
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(`google_api_failed:${response.status}:${JSON.stringify(data)}`);
  }
  return data;
}

async function fetchSecret(projectId, secretName, accessToken) {
  const url =
    `https://secretmanager.googleapis.com/v1/projects/${projectId}` +
    `/secrets/${secretName}/versions/latest:access`;
  const payload = await fetchGoogleJson(url, accessToken);
  return decodeSecretPayload(payload);
}

async function fetchTypesenseJson(url, apiKey, init = {}) {
  const response = await fetch(url, {
    ...init,
    headers: {
      "X-TYPESENSE-API-KEY": apiKey,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
  const text = await response.text();
  let data = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (_) {
      data = text;
    }
  }
  if (!response.ok) {
    throw new Error(`typesense_api_failed:${response.status}:${text}`);
  }
  return data;
}

async function ensurePostsCollection(baseUrl, apiKey) {
  const existing = await fetchTypesenseJson(
    `${baseUrl}/collections/${POSTS_COLLECTION}`,
    apiKey,
  );
  const fields = Array.isArray(existing?.fields) ? existing.fields : [];
  const missing = [];
  if (!fields.some((field) => field?.name === "minuteOfHour")) {
    missing.push({ name: "minuteOfHour", type: "int32", optional: true });
  }
  if (!fields.some((field) => field?.name === "surfaceTargets")) {
    missing.push({ name: "surfaceTargets", type: "string[]", optional: true });
  }
  if (!missing.length) {
    return { patched: false };
  }

  await fetchTypesenseJson(`${baseUrl}/collections/${POSTS_COLLECTION}`, apiKey, {
    method: "PATCH",
    body: JSON.stringify({ fields: missing }),
  });
  return { patched: true, missingCount: missing.length };
}

async function fetchPage(baseUrl, apiKey, page, perPage) {
  const url = new URL(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/search`);
  url.searchParams.set("q", "*");
  url.searchParams.set("query_by", "metin");
  url.searchParams.set("sort_by", DEFAULT_SORT_BY);
  url.searchParams.set("page", String(page));
  url.searchParams.set("per_page", String(perPage));
  const data = await fetchTypesenseJson(url.toString(), apiKey);
  const hits = Array.isArray(data?.hits) ? data.hits : [];
  return hits
    .map((hit) => (hit && typeof hit === "object" ? hit.document || hit : null))
    .filter(Boolean);
}

async function importDocs(baseUrl, apiKey, docs) {
  if (!docs.length) return [];
  const response = await fetch(`${baseUrl}/collections/${POSTS_COLLECTION}/documents/import?action=upsert`, {
    method: "POST",
    headers: {
      "X-TYPESENSE-API-KEY": apiKey,
      "Content-Type": "text/plain",
    },
    body: docs.map((doc) => JSON.stringify(doc)).join("\n"),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`typesense_import_failed:${response.status}:${text}`);
  }
  return text
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

async function upsertDoc(baseUrl, apiKey, doc) {
  const response = await fetch(
    `${baseUrl}/collections/${POSTS_COLLECTION}/documents?action=upsert`,
    {
      method: "POST",
      headers: {
        "X-TYPESENSE-API-KEY": apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(doc),
    },
  );
  const text = await response.text();
  let data = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (_) {
      data = text;
    }
  }
  if (!response.ok) {
    throw new Error(`typesense_single_upsert_failed:${response.status}:${text}`);
  }
  return data;
}

async function patchDocFields(baseUrl, apiKey, doc) {
  const docId = String(doc.id || doc.docId || "").trim();
  if (!docId) {
    throw new Error("typesense_patch_missing_id");
  }
  const response = await fetch(
    `${baseUrl}/collections/${POSTS_COLLECTION}/documents/${encodeURIComponent(docId)}`,
    {
      method: "PATCH",
      headers: {
        "X-TYPESENSE-API-KEY": apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        minuteOfHour: doc.minuteOfHour,
        surfaceTargets: doc.surfaceTargets,
      }),
    },
  );
  const text = await response.text();
  let data = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (_) {
      data = text;
    }
  }
  if (!response.ok) {
    throw new Error(`typesense_patch_failed:${response.status}:${text}`);
  }
  return data;
}

async function importDocsInChunks(baseUrl, apiKey, docs, chunkSize) {
  if (!docs.length) return [];
  if (PATCH_ONLY_FIELDS) {
    const results = [];
    for (const doc of docs) {
      const result = await patchDocFields(baseUrl, apiKey, doc);
      results.push(result);
    }
    return results;
  }
  if (SINGLE_DOC_UPSERT) {
    const results = [];
    for (const doc of docs) {
      const result = await upsertDoc(baseUrl, apiKey, doc);
      results.push(result);
    }
    return results;
  }
  const results = [];
  for (let index = 0; index < docs.length; index += chunkSize) {
    const chunk = docs.slice(index, index + chunkSize);
    const chunkResults = await importDocs(baseUrl, apiKey, chunk);
    results.push(...chunkResults);
  }
  return results;
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");
  const accessToken = await getAccessToken();
  const host = await fetchSecret(PROJECT_ID, "TYPESENSE_HOST", accessToken);
  const apiKey = await fetchSecret(PROJECT_ID, "TYPESENSE_API_KEY", accessToken);
  const baseUrl = host.replace(/\/+$/, "");

  const ensureResult = await ensurePostsCollection(baseUrl, apiKey);
  let page = DEFAULT_START_PAGE;
  let pagesScanned = 0;
  let scanned = 0;
  let updated = 0;
  let unchanged = 0;
  const samples = [];
  let limitReached = false;

  while (true) {
    if (DEFAULT_MAX_PAGES > 0 && pagesScanned >= DEFAULT_MAX_PAGES) break;
    const docs = await fetchPage(baseUrl, apiKey, page, DEFAULT_PER_PAGE);
    if (!docs.length) break;
    pagesScanned += 1;

    const changedDocs = [];
    for (const doc of docs) {
      scanned += 1;
      const minuteOfHour = resolveMinuteOfHour(doc.timeStamp || doc.createdAtTs || 0);
      const surfaceTargets = resolveSurfaceTargets(doc);
      const existingMinute = toNumber(doc.minuteOfHour, -1);
      const existingTargets = Array.isArray(doc.surfaceTargets) ? doc.surfaceTargets : [];
      if (existingMinute === minuteOfHour && sameTargets(existingTargets, surfaceTargets)) {
        unchanged += 1;
        if (DEBUG_SAMPLE && samples.length < 5) {
          samples.push({
            id: doc.id || doc.docId || null,
            status: "unchanged",
            existingMinute,
            existingTargets,
            computedMinute: minuteOfHour,
            computedTargets: surfaceTargets,
            timeStamp: doc.timeStamp || doc.createdAtTs || null,
          });
        }
        continue;
      }

      if (DEBUG_SAMPLE && samples.length < 5) {
        samples.push({
          id: doc.id || doc.docId || null,
          status: "changed",
          existingMinute,
          existingTargets,
          computedMinute: minuteOfHour,
          computedTargets: surfaceTargets,
          timeStamp: doc.timeStamp || doc.createdAtTs || null,
        });
      }

      if (DEFAULT_MAX_UPDATES > 0 && changedDocs.length >= DEFAULT_MAX_UPDATES) {
        limitReached = true;
        break;
      }

      changedDocs.push({
        ...doc,
        minuteOfHour,
        surfaceTargets,
      });
    }

    if (!dryRun && changedDocs.length) {
      const results = await importDocsInChunks(
        baseUrl,
        apiKey,
        changedDocs,
        DEFAULT_IMPORT_CHUNK,
      );
      const failed = results.filter((entry) => entry?.success === false);
      if (failed.length) {
        throw new Error(`typesense_import_partial_failure:${JSON.stringify(failed.slice(0, 5))}`);
      }
    }

    updated += changedDocs.length;
    console.log(
      JSON.stringify({
        page,
        scanned,
        updated,
        unchanged,
        pageChanged: changedDocs.length,
        dryRun,
      }),
    );

    if (docs.length < DEFAULT_PER_PAGE) break;
    if (limitReached) break;
    page += 1;
  }

  console.log(
    JSON.stringify({
      ok: true,
      projectId: PROJECT_ID,
      collection: POSTS_COLLECTION,
      patchedSchema: ensureResult?.patched === true,
      startPage: DEFAULT_START_PAGE,
      pagesScanned,
      sortBy: DEFAULT_SORT_BY,
      scanned,
      updated,
      unchanged,
      dryRun,
      maxUpdates: DEFAULT_MAX_UPDATES || null,
      limitReached,
      sampleCount: samples.length,
      samples: DEBUG_SAMPLE ? samples : undefined,
    }),
  );
}

main().catch((error) => {
  console.error(
    JSON.stringify({
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    }),
  );
  process.exitCode = 1;
});
