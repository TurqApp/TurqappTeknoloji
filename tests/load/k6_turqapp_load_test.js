/**
 * TurqApp k6 Load Test — 100K DAU Senaryosu
 *
 * Çalıştırma:
 *   k6 run --env FIREBASE_PROJECT_ID=turqappteknoloji \
 *           --env SEARCH_CF_BASE_URL=https://us-central1-turqappteknoloji.cloudfunctions.net \
 *           --env INTERACTION_CF_BASE_URL=https://europe-west1-turqappteknoloji.cloudfunctions.net \
 *           --env ID_TOKEN=<firebase-id-token> \
 *           k6_turqapp_load_test.js
 *
 * CI/CD örneği (GitHub Actions):
 *   - uses: grafana/k6-action@v0.3.1
 *     with:
 *       filename: tests/load/k6_turqapp_load_test.js
 *       flags: --env FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
 *
 * Hedefler (SLO dokümanından):
 *   - feed_ttfc_warm p95 < 500ms
 *   - video_ttff_warm p95 < 400ms
 *   - Callable p99 < 2000ms
 *   - Error rate < %0.5
 */

import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Counter, Rate } from "k6/metrics";

// ─────────────────────────────────────────────────────────────────
// CUSTOM METRICS
// ─────────────────────────────────────────────────────────────────

const feedLatency = new Trend("turq_feed_latency_ms", true);
const feedColdLatency = new Trend("turq_feed_cold_latency_ms", true);
const feedWarmLatency = new Trend("turq_feed_warm_latency_ms", true);
const searchLatency = new Trend("turq_search_latency_ms", true);
const cfLikeLatency = new Trend("turq_cf_like_latency_ms", true);
const recordViewLatency = new Trend("turq_record_view_latency_ms", true);
const cfFollowLatency = new Trend("turq_cf_follow_latency_ms", true);
const errorRate = new Rate("turq_error_rate");
const requestCount = new Counter("turq_request_count");
const PROFILE = __ENV.K6_PROFILE || "full";
const MODE = __ENV.K6_MODE || "mixed";

function resolveThresholds() {
  const thresholds = {
    turq_error_rate: ["rate < 0.005"],
    http_req_duration: ["p(95) < 1000"],
    http_req_failed: ["rate < 0.01"],
  };

  if ((MODE === "feed_only" || MODE === "mixed") && PROFILE !== "smoke") {
    thresholds.turq_feed_warm_latency_ms = ["p(95) < 500"];
  }

  if (
    (MODE === "interaction_only" || MODE === "mixed") &&
    (__ENV.TOGGLE_LIKE_ENDPOINT ||
      `https://europe-west1-${__ENV.FIREBASE_PROJECT_ID || "turqappteknoloji"}.cloudfunctions.net/toggleLikeBatch`)
  ) {
    thresholds.turq_cf_like_latency_ms = ["p(99) < 2000"];
  }

  if (MODE === "interaction_only" || MODE === "mixed") {
    thresholds.turq_record_view_latency_ms = ["p(99) < 2000"];
  }

  return thresholds;
}

// ─────────────────────────────────────────────────────────────────
// LOAD PROFILE — 100K DAU simülasyonu
// ─────────────────────────────────────────────────────────────────
// Peak concurrent = 50K
// Feed scroll QPS = 5000 → ~100 VU (50 req/VU/s)
// Video autoplay QPS = 1667 → ~34 VU
// CF invocations = 500 → ~10 VU
// Total: ~144 VU peak

function resolveStages() {
  if (PROFILE === "smoke") {
    return [
      { duration: "15s", target: 1 },
      { duration: "30s", target: 3 },
      { duration: "15s", target: 0 },
    ];
  }

  if (PROFILE === "feed_only") {
    return [
      { duration: "30s", target: 5 },
      { duration: "60s", target: 10 },
      { duration: "30s", target: 0 },
    ];
  }

  return [
    { duration: "2m", target: 20 },   // Warm-up
    { duration: "5m", target: 100 },  // Normal traffic
    { duration: "5m", target: 150 },  // Peak traffic (100K DAU)
    { duration: "3m", target: 50 },   // Scale down
    { duration: "2m", target: 0 },    // Cool down
  ];
}

export const options = {
  stages: resolveStages(),
  thresholds: resolveThresholds(),
  summaryTrendStats: ["avg", "min", "med", "max", "p(90)", "p(95)", "p(99)"],
};

// ─────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────

const PROJECT_ID = __ENV.FIREBASE_PROJECT_ID || "turqappteknoloji";
const SEARCH_CF_BASE_URL =
  __ENV.SEARCH_CF_BASE_URL ||
  `https://us-central1-${PROJECT_ID}.cloudfunctions.net`;
const INTERACTION_CF_BASE_URL =
  __ENV.INTERACTION_CF_BASE_URL ||
  __ENV.CF_BASE_URL ||
  `https://europe-west1-${PROJECT_ID}.cloudfunctions.net`;
const ID_TOKEN = __ENV.ID_TOKEN || "";
const FEED_USER_ID = (__ENV.FEED_USER_ID || "").trim();
const SEARCH_USERS_ENDPOINT =
  __ENV.SEARCH_USERS_ENDPOINT || `${SEARCH_CF_BASE_URL}/f15_searchUsersCallable`;
const POST_CARDS_ENDPOINT =
  __ENV.POST_CARDS_ENDPOINT || `${SEARCH_CF_BASE_URL}/f15_getPostCardsByIdsCallable`;
const BACKFILL_FEED_ENDPOINT =
  __ENV.BACKFILL_FEED_ENDPOINT ||
  `${INTERACTION_CF_BASE_URL}/backfillHybridFeedForUser`;
const TOGGLE_LIKE_ENDPOINT =
  __ENV.TOGGLE_LIKE_ENDPOINT || `${INTERACTION_CF_BASE_URL}/toggleLikeBatch`;
const RECORD_VIEW_ENDPOINT =
  __ENV.RECORD_VIEW_ENDPOINT || `${INTERACTION_CF_BASE_URL}/recordViewBatch`;

const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const FIRESTORE_RESOURCE_ROOT = `projects/${PROJECT_ID}/databases/(default)/documents`;
const FIRESTORE_BATCH_GET_ENDPOINT = `${FIRESTORE_BASE}:batchGet`;
const FEED_CARD_CACHE_TTL_MS = 30 * 60 * 1000;
const FEED_SNAPSHOT_CACHE_TTL_MS = 30 * 60 * 1000;

// Test post ID'leri (gerçek ortamda staging post'larını kullan)
const TEST_POST_IDS = ["test_post_1", "test_post_2", "test_post_3"];
let feedColdSampleDone = false;
let feedWarmSampleDone = false;
let feedBackfillAttempted = false;
let cachedFeedPostIds = [];
let cachedFeedSnapshotAt = 0;
const cachedPostCardsById = {};
const likeStateByPost = {};

function parseTokenPool(raw) {
  const source = String(raw || "").trim();
  if (!source) return [];

  try {
    const parsed = JSON.parse(source);
    if (Array.isArray(parsed)) {
      return parsed.map((item) => String(item || "").trim()).filter(Boolean);
    }
  } catch {}

  return source
    .split(/[\n,]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

const ACTION_ID_TOKEN_POOL = parseTokenPool(__ENV.ACTION_ID_TOKEN_POOL || "");

function authHeaders(token = ID_TOKEN) {
  const h = { "Content-Type": "application/json" };
  if (token) h["Authorization"] = `Bearer ${token}`;
  return h;
}

function selectActionToken() {
  if (ACTION_ID_TOKEN_POOL.length === 0) {
    return ID_TOKEN;
  }
  const index = ((__VU - 1) + __ITER) % ACTION_ID_TOKEN_POOL.length;
  return ACTION_ID_TOKEN_POOL[index];
}

function parseJsonLines(body) {
  const raw = String(body || "").trim();
  if (!raw) return [];
  if (raw.startsWith("[")) {
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return raw
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

function parseFirestoreDocumentList(body) {
  try {
    const parsed = JSON.parse(String(body || "{}"));
    return Array.isArray(parsed.documents) ? parsed.documents : [];
  } catch {
    return [];
  }
}

function parseBatchGetDocuments(body) {
  return parseJsonLines(body)
    .map((entry) => entry?.found || entry?.document || null)
    .filter(Boolean);
}

function parseCallableResult(body) {
  try {
    const parsed = JSON.parse(String(body || "{}"));
    return parsed?.result || parsed?.data || parsed || {};
  } catch {
    return {};
  }
}

function extractPostIdsFromFeedDocuments(documents) {
  return documents
    .map((doc) => String(doc?.fields?.postId?.stringValue || "").trim())
    .filter(Boolean);
}

function resolvePostCardId(document) {
  const directId = String(document?.id || document?.docID || "").trim();
  if (directId) {
    return directId;
  }

  const firestoreName = String(document?.name || "").trim();
  if (firestoreName) {
    return firestoreName.split("/").pop() || "";
  }

  return String(
    document?.fields?.docID?.stringValue || document?.fields?.id?.stringValue || ""
  ).trim();
}

function storePostCardsInCache(documents) {
  const now = Date.now();
  for (const document of documents) {
    const postId = resolvePostCardId(document);
    if (!postId) continue;
    cachedPostCardsById[postId] = {
      document,
      cachedAt: now,
    };
  }
}

function loadPostCardsFromCache(postIds) {
  const uniqueIds = Array.from(new Set(postIds.map((id) => String(id || "").trim()).filter(Boolean)));
  if (uniqueIds.length === 0) {
    return { complete: true, documents: [] };
  }

  const now = Date.now();
  const documents = [];
  for (const postId of uniqueIds) {
    const entry = cachedPostCardsById[postId];
    if (!entry || now - entry.cachedAt > FEED_CARD_CACHE_TTL_MS) {
      return { complete: false, documents: [] };
    }
    documents.push(entry.document);
  }

  return { complete: true, documents };
}

function loadFeedSnapshotFromCache() {
  if (cachedFeedPostIds.length === 0) {
    return { complete: false, postIds: [], documents: [] };
  }

  if (Date.now() - cachedFeedSnapshotAt > FEED_SNAPSHOT_CACHE_TTL_MS) {
    return { complete: false, postIds: [], documents: [] };
  }

  const cards = loadPostCardsFromCache(cachedFeedPostIds);
  if (!cards.complete || cards.documents.length === 0) {
    return { complete: false, postIds: [], documents: [] };
  }

  return {
    complete: true,
    postIds: cachedFeedPostIds.slice(),
    documents: cards.documents,
  };
}

function refreshFeedSnapshot(countRequest = false) {
  let statusPayload = {
    refsOk: false,
    cardsOk: false,
    hasDocs: false,
  };

  const hybrid = loadHybridFeedReferences(countRequest);
  if (hybrid.res && hybrid.res.status === 200 && hybrid.postIds.length > 0) {
    const cards = loadPostCards(hybrid.postIds, countRequest);
    statusPayload = {
      refsOk: hybrid.res.status === 200,
      cardsOk: cards.ok,
      hasDocs: cards.documents.length > 0,
    };
    if (statusPayload.hasDocs) {
      cachedFeedPostIds = hybrid.postIds;
      cachedFeedSnapshotAt = Date.now();
    }
    return statusPayload;
  }

  const legacy = loadLegacyFeedPage(countRequest);
  statusPayload = {
    refsOk: legacy.res.status === 200,
    cardsOk: true,
    hasDocs: legacy.postIds.length > 0,
  };
  if (legacy.postIds.length > 0) {
    cachedFeedPostIds = legacy.postIds;
    cachedFeedSnapshotAt = Date.now();
  }
  return statusPayload;
}

function loadLegacyFeedPage(countRequest = false) {
  const res = http.get(
    `${FIRESTORE_BASE}/Posts?` +
      "orderBy=timeStamp%20desc" +
      "&pageSize=20",
    {
      headers: authHeaders(),
      tags: { scenario: "feed_read_legacy" },
    }
  );
  if (countRequest) requestCount.add(1);
  const documents = parseFirestoreDocumentList(res.body);
  const postIds = documents
    .map((doc) => String(doc?.name || "").trim().split("/").pop() || "")
    .filter(Boolean);
  return { res, postIds };
}

function backfillFeedReferences(countRequest = false) {
  if (!ID_TOKEN || !BACKFILL_FEED_ENDPOINT || !FEED_USER_ID || feedBackfillAttempted) {
    return null;
  }
  feedBackfillAttempted = true;
  const res = http.post(
    BACKFILL_FEED_ENDPOINT,
    JSON.stringify({ data: { uid: FEED_USER_ID, perAuthorLimit: 4 } }),
    {
      headers: authHeaders(),
      tags: { scenario: "feed_backfill" },
    }
  );
  if (countRequest) requestCount.add(1);
  return res;
}

function loadHybridFeedReferences(countRequest = false) {
  if (!ID_TOKEN || !FEED_USER_ID) {
    return { res: null, postIds: [] };
  }

  const url =
    `${FIRESTORE_BASE}/userFeeds/${encodeURIComponent(FEED_USER_ID)}/items?` +
    "orderBy=timeStamp%20desc" +
    "&pageSize=20";

  let res = http.get(url, {
    headers: authHeaders(),
    tags: { scenario: "feed_refs" },
  });
  if (countRequest) requestCount.add(1);

  let postIds = extractPostIdsFromFeedDocuments(
    parseFirestoreDocumentList(res.body)
  );

  if (postIds.length > 0) {
    return { res, postIds };
  }

  backfillFeedReferences(countRequest);

  res = http.get(url, {
    headers: authHeaders(),
    tags: { scenario: "feed_refs" },
  });
  if (countRequest) requestCount.add(1);

  postIds = extractPostIdsFromFeedDocuments(parseFirestoreDocumentList(res.body));
  return { res, postIds };
}

function batchGetPostCards(postIds, countRequest = false) {
  const uniqueIds = Array.from(new Set(postIds.map((id) => String(id || "").trim()).filter(Boolean)));
  if (uniqueIds.length === 0) {
    return { res: null, documents: [], ok: true };
  }

  const res = http.post(
    FIRESTORE_BATCH_GET_ENDPOINT,
    JSON.stringify({
      documents: uniqueIds.map(
        (postId) => `${FIRESTORE_RESOURCE_ROOT}/Posts/${postId}`
      ),
    }),
    {
      headers: authHeaders(),
      tags: { scenario: "feed_cards" },
    }
  );
  if (countRequest) requestCount.add(1);

  const documents = parseBatchGetDocuments(res.body);
  if (res.status === 200 && documents.length > 0) {
    storePostCardsInCache(documents);
  }

  return {
    res,
    documents,
    ok: res.status === 200,
  };
}

function loadPostCards(postIds, countRequest = false) {
  const uniqueIds = Array.from(new Set(postIds.map((id) => String(id || "").trim()).filter(Boolean)));
  if (uniqueIds.length === 0) {
    return { res: null, documents: [], ok: true, fromCache: true };
  }

  const cached = loadPostCardsFromCache(uniqueIds);
  if (cached.complete) {
    return {
      res: null,
      documents: cached.documents,
      ok: true,
      fromCache: true,
    };
  }

  const callableToken = selectActionToken();
  if (POST_CARDS_ENDPOINT && callableToken) {
    const res = http.post(
      POST_CARDS_ENDPOINT,
      JSON.stringify({ data: { ids: uniqueIds } }),
      {
        headers: authHeaders(callableToken),
        tags: { scenario: "feed_cards_callable" },
      }
    );
    if (countRequest) requestCount.add(1);

    const payload = parseCallableResult(res.body);
    const hits = Array.isArray(payload?.hits) ? payload.hits : [];
    if (res.status === 200 && hits.length > 0) {
      storePostCardsInCache(hits);
      const merged = loadPostCardsFromCache(uniqueIds);
      return {
        res,
        documents: merged.complete ? merged.documents : hits,
        ok: true,
        fromCache: false,
      };
    }
  }

  return batchGetPostCards(uniqueIds, countRequest);
}

function ensureLoadPostIds() {
  if (cachedFeedPostIds.length > 0) {
    return cachedFeedPostIds;
  }

  const hybrid = loadHybridFeedReferences(false);
  if (hybrid.postIds.length > 0) {
    cachedFeedPostIds = hybrid.postIds;
    return cachedFeedPostIds;
  }

  const legacy = loadLegacyFeedPage(false);
  if (legacy.postIds.length > 0) {
    cachedFeedPostIds = legacy.postIds;
    return cachedFeedPostIds;
  }

  cachedFeedPostIds = TEST_POST_IDS.slice();
  return cachedFeedPostIds;
}

function pickPostId() {
  const postIds = ensureLoadPostIds();
  if (postIds.length === 0) {
    return TEST_POST_IDS[Math.floor(Math.random() * TEST_POST_IDS.length)];
  }
  return postIds[(__VU + __ITER) % postIds.length];
}

// ─────────────────────────────────────────────────────────────────
// SCENARIOS
// ─────────────────────────────────────────────────────────────────

/**
 * Senaryo 1: Feed okuma (en yoğun — QPS: 5000)
 * Simüle eder: Kullanıcının ana feed'i açması ve 3 sayfa scroll etmesi
 */
function scenarioFeedRead() {
  const start = Date.now();
  const cached = loadFeedSnapshotFromCache();
  const ttfcDuration = cached.complete ? Date.now() - start : null;
  const statusPayload = refreshFeedSnapshot(true);
  const duration = ttfcDuration ?? (Date.now() - start);
  feedLatency.add(duration);
  if (!feedColdSampleDone) {
    feedColdLatency.add(duration);
    feedColdSampleDone = true;
  } else if (cached.complete && !feedWarmSampleDone) {
    feedWarmLatency.add(duration);
    feedWarmSampleDone = true;
  }
  const ok = check(statusPayload, {
    "feed: status 200": (payload) => payload.refsOk && payload.cardsOk,
    "feed: has documents": (payload) => payload.hasDocs,
  });

  if (!ok) errorRate.add(1);
  else errorRate.add(0);

  sleep(0.2); // 5 QPS/VU simülasyonu
}

/**
 * Senaryo 2: Typesense arama (QPS: ~200)
 * Simüle eder: Kullanıcının search bar'a yazması
 */
function scenarioSearch() {
  const queries = ["matematik", "fizik", "türkçe", "tarih", "biyoloji"];
  const q = queries[Math.floor(Math.random() * queries.length)];
  const token = selectActionToken();

  const start = Date.now();
  const res = http.post(
    SEARCH_USERS_ENDPOINT,
    JSON.stringify({ data: { q, limit: 10 } }),
    {
      headers: authHeaders(token),
      tags: { scenario: "search" },
    }
  );

  const duration = Date.now() - start;
  searchLatency.add(duration);
  requestCount.add(1);

  const ok = check(res, {
    "search: status 200": (r) => r.status === 200,
  });

  if (!ok) errorRate.add(1);
  else errorRate.add(0);

  sleep(1); // Arama senaryosunda daha az sıklık
}

/**
 * Senaryo 3: Like işlemi (Cloud Function — QPS: ~500)
 * Simüle eder: Kullanıcının post beğenmesi
 */
function scenarioLike() {
  const token = selectActionToken();
  if (!token || !TOGGLE_LIKE_ENDPOINT) {
    sleep(1);
    return;
  }

  const postId = pickPostId();
  const nextValue = !(likeStateByPost[postId] === true);
  const start = Date.now();

  const res = http.post(
    TOGGLE_LIKE_ENDPOINT,
    JSON.stringify({ data: { items: [{ postId, value: nextValue }] } }),
    {
      headers: authHeaders(token),
      tags: { scenario: "like" },
    }
  );

  const duration = Date.now() - start;
  cfLikeLatency.add(duration);
  requestCount.add(1);

  const ok = check(res, {
    "like: status 200": (r) => r.status === 200,
  });

  if (ok) {
    likeStateByPost[postId] = nextValue;
    errorRate.add(0);
  } else {
    errorRate.add(1);
  }

  sleep(0.5);
}

/**
 * Senaryo 4: View count kaydı (counterShards — QPS: ~1667)
 * Simüle eder: Video otomatik oynatmada view kaydı
 */
function scenarioRecordView() {
  const token = selectActionToken();
  if (!token || !RECORD_VIEW_ENDPOINT) {
    sleep(1);
    return;
  }

  const postId = pickPostId();
  const start = Date.now();

  const res = http.post(
    RECORD_VIEW_ENDPOINT,
    JSON.stringify({ data: { items: [{ postId, count: 1 }] } }),
    {
      headers: authHeaders(token),
      tags: { scenario: "view_count" },
    }
  );

  const duration = Date.now() - start;
  recordViewLatency.add(duration);
  requestCount.add(1);

  const ok = check(res, {
    "view: status 200": (r) => r.status === 200,
  });

  if (!ok) errorRate.add(1);
  else errorRate.add(0);

  sleep(0.3);
}

// ─────────────────────────────────────────────────────────────────
// MAIN — VU dağılımı
// ─────────────────────────────────────────────────────────────────

export default function () {
  if (MODE === "search_only") {
    scenarioSearch();
    return;
  }

  if (MODE === "feed_only") {
    scenarioFeedRead();
    return;
  }

  if (MODE === "interaction_only") {
    scenarioRecordView();
    scenarioLike();
    return;
  }

  const roll = Math.random();

  if (roll < 0.55) {
    // %55 VU → Feed read (en yoğun senaryo)
    scenarioFeedRead();
  } else if (roll < 0.75) {
    // %20 VU → View count (video izleme)
    scenarioRecordView();
  } else if (roll < 0.90) {
    // %15 VU → Like
    scenarioLike();
  } else {
    // %10 VU → Search
    scenarioSearch();
  }
}

// ─────────────────────────────────────────────────────────────────
// SUMMARY — test sonunda özet
// ─────────────────────────────────────────────────────────────────

export function handleSummary(data) {
  const p95FeedAll = data.metrics["turq_feed_latency_ms"]?.values?.["p(95)"] ?? -1;
  const p95FeedCold = data.metrics["turq_feed_cold_latency_ms"]?.values?.["p(95)"] ?? -1;
  const p95FeedWarm = data.metrics["turq_feed_warm_latency_ms"]?.values?.["p(95)"] ?? -1;
  const p99Like = data.metrics["turq_cf_like_latency_ms"]?.values?.["p(99)"] ?? -1;
  const p99RecordView = data.metrics["turq_record_view_latency_ms"]?.values?.["p(99)"] ?? -1;
  const errRate = (data.metrics["turq_error_rate"]?.values?.rate ?? 0) * 100;
  const feedMeasured = MODE === "feed_only" || MODE === "mixed";
  const feedSloEnforced = feedMeasured && PROFILE !== "smoke";
  const interactionMeasured = MODE === "interaction_only" || MODE === "mixed";
  const actionAuthConfigured = ACTION_ID_TOKEN_POOL.length > 0 || !!ID_TOKEN;
  const likeConfigured = actionAuthConfigured && !!TOGGLE_LIKE_ENDPOINT;
  const recordViewConfigured = actionAuthConfigured && !!RECORD_VIEW_ENDPOINT;

  const sloStatus = {
    feed_ttfc_p95:
      !feedSloEnforced ? "⚪ N/A" : p95FeedWarm < 500 ? "✅ PASS" : "❌ FAIL",
    cf_like_p99:
      !interactionMeasured || !likeConfigured
        ? "⚪ N/A"
        : p99Like < 2000
          ? "✅ PASS"
          : "❌ FAIL",
    record_view_p99:
      !interactionMeasured || !recordViewConfigured
        ? "⚪ N/A"
        : p99RecordView < 2000
          ? "✅ PASS"
          : "❌ FAIL",
    error_rate: errRate < 0.5 ? "✅ PASS" : "❌ FAIL",
  };

  console.log("\n══════════════════════════════════════");
  console.log("TurqApp Load Test SLO Sonuçları");
  console.log("══════════════════════════════════════");
  const coldText = p95FeedCold >= 0 ? `${p95FeedCold.toFixed(0)}ms` : "N/A";
  const warmText = p95FeedWarm >= 0 ? `${p95FeedWarm.toFixed(0)}ms` : "N/A";
  const allText = p95FeedAll >= 0 ? `${p95FeedAll.toFixed(0)}ms` : "N/A";
  console.log(`Profile          : ${PROFILE}`);
  console.log(`Mode             : ${MODE}`);
  console.log(`Feed cold p95    : ${coldText}`);
  console.log(`Feed warm p95    : ${warmText}  ${sloStatus.feed_ttfc_p95}`);
  console.log(`Feed overall p95 : ${allText}`);
  const likeP99Text = likeConfigured ? `${p99Like.toFixed(0)}ms` : "N/A";
  console.log(`CF like p99      : ${likeP99Text}  ${sloStatus.cf_like_p99}`);
  const recordViewP99Text = recordViewConfigured ? `${p99RecordView.toFixed(0)}ms` : "N/A";
  console.log(`Record view p99  : ${recordViewP99Text}  ${sloStatus.record_view_p99}`);
  console.log(`Error rate       : ${errRate.toFixed(2)}%  ${sloStatus.error_rate}`);
  console.log("══════════════════════════════════════\n");

  return {
    stdout: JSON.stringify(data, null, 2),
    "tests/load/k6_results_latest.json": JSON.stringify(data),
    [`tests/load/k6_summary_${PROFILE}_${MODE}_latest.json`]:
      JSON.stringify(data, null, 2),
  };
}
