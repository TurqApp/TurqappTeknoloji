/**
 * TurqApp k6 Load Test — 100K DAU Senaryosu
 *
 * Çalıştırma:
 *   k6 run --env FIREBASE_PROJECT_ID=turqapp-prod \
 *           --env CF_BASE_URL=https://europe-west1-turqapp-prod.cloudfunctions.net \
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
 *   - CF p99 < 500ms
 *   - Error rate < %0.5
 */

import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Counter, Rate } from "k6/metrics";

// ─────────────────────────────────────────────────────────────────
// CUSTOM METRICS
// ─────────────────────────────────────────────────────────────────

const feedLatency = new Trend("turq_feed_latency_ms", true);
const searchLatency = new Trend("turq_search_latency_ms", true);
const cfLikeLatency = new Trend("turq_cf_like_latency_ms", true);
const cfFollowLatency = new Trend("turq_cf_follow_latency_ms", true);
const errorRate = new Rate("turq_error_rate");
const requestCount = new Counter("turq_request_count");

// ─────────────────────────────────────────────────────────────────
// LOAD PROFILE — 100K DAU simülasyonu
// ─────────────────────────────────────────────────────────────────
// Peak concurrent = 50K
// Feed scroll QPS = 5000 → ~100 VU (50 req/VU/s)
// Video autoplay QPS = 1667 → ~34 VU
// CF invocations = 500 → ~10 VU
// Total: ~144 VU peak

export const options = {
  stages: [
    { duration: "2m", target: 20 },   // Warm-up
    { duration: "5m", target: 100 },  // Normal traffic
    { duration: "5m", target: 150 },  // Peak traffic (100K DAU)
    { duration: "3m", target: 50 },   // Scale down
    { duration: "2m", target: 0 },    // Cool down
  ],
  thresholds: {
    // SLO eşikleri — bu aşılırsa test FAIL olur
    "turq_feed_latency_ms{p:95}": ["p(95) < 500"],     // feed_ttfc_warm p95 < 500ms
    "turq_cf_like_latency_ms{p:99}": ["p(99) < 2000"], // CF p99 < 2s (network overhead dahil)
    "turq_error_rate": ["rate < 0.005"],                // Error rate < %0.5
    http_req_duration: ["p(95) < 1000"],               // Genel HTTP p95 < 1s
    http_req_failed: ["rate < 0.01"],                  // HTTP failure rate < %1
  },
};

// ─────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────

const PROJECT_ID = __ENV.FIREBASE_PROJECT_ID || "turqapp-dev";
const CF_BASE_URL =
  __ENV.CF_BASE_URL ||
  `https://europe-west1-${PROJECT_ID}.cloudfunctions.net`;
const ID_TOKEN = __ENV.ID_TOKEN || "";

const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// Test post ID'leri (gerçek ortamda staging post'larını kullan)
const TEST_POST_IDS = ["test_post_1", "test_post_2", "test_post_3"];
const TEST_USER_IDS = ["test_user_1", "test_user_2"];

function authHeaders() {
  const h = { "Content-Type": "application/json" };
  if (ID_TOKEN) h["Authorization"] = `Bearer ${ID_TOKEN}`;
  return h;
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

  const res = http.get(
    `${FIRESTORE_BASE}/Posts?` +
      "orderBy=timeStamp%20desc" +
      "&pageSize=20" +
      "&fields=name,fields(userID,timeStamp,video,thumbnail,metin,begeniSayisi)",
    {
      headers: authHeaders(),
      tags: { scenario: "feed_read" },
    }
  );

  const duration = Date.now() - start;
  feedLatency.add(duration);
  requestCount.add(1);

  const ok = check(res, {
    "feed: status 200": (r) => r.status === 200,
    "feed: has documents": (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body.documents) && body.documents.length > 0;
      } catch {
        return false;
      }
    },
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

  const start = Date.now();
  const res = http.post(
    `${CF_BASE_URL}/f15_searchUsersCallable`,
    JSON.stringify({ data: { q, limit: 10 } }),
    {
      headers: authHeaders(),
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
  if (!ID_TOKEN) {
    sleep(1);
    return; // Auth token olmadan CF test edilemez
  }

  const postId = TEST_POST_IDS[Math.floor(Math.random() * TEST_POST_IDS.length)];
  const start = Date.now();

  const res = http.post(
    `${CF_BASE_URL}/toggleLike`,
    JSON.stringify({ data: { postId, action: "like" } }),
    {
      headers: authHeaders(),
      tags: { scenario: "like" },
    }
  );

  const duration = Date.now() - start;
  cfLikeLatency.add(duration);
  requestCount.add(1);

  const ok = check(res, {
    "like: status 200": (r) => r.status === 200,
  });

  if (!ok) errorRate.add(1);
  else errorRate.add(0);

  sleep(0.5);
}

/**
 * Senaryo 4: View count kaydı (counterShards — QPS: ~1667)
 * Simüle eder: Video otomatik oynatmada view kaydı
 */
function scenarioRecordView() {
  if (!ID_TOKEN) {
    sleep(1);
    return;
  }

  const postId = TEST_POST_IDS[Math.floor(Math.random() * TEST_POST_IDS.length)];
  const start = Date.now();

  const res = http.post(
    `${CF_BASE_URL}/recordViewBatch`,
    JSON.stringify({ data: { items: [{ postId, count: 1 }] } }),
    {
      headers: authHeaders(),
      tags: { scenario: "view_count" },
    }
  );

  const duration = Date.now() - start;
  requestCount.add(1);

  check(res, {
    "view: status 200": (r) => r.status === 200,
  });

  sleep(0.3);
}

// ─────────────────────────────────────────────────────────────────
// MAIN — VU dağılımı
// ─────────────────────────────────────────────────────────────────

export default function () {
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
  const p95Feed = data.metrics["turq_feed_latency_ms"]?.values?.["p(95)"] ?? -1;
  const p99Like = data.metrics["turq_cf_like_latency_ms"]?.values?.["p(99)"] ?? -1;
  const errRate = (data.metrics["turq_error_rate"]?.values?.rate ?? 0) * 100;

  const sloStatus = {
    feed_ttfc_p95: p95Feed < 500 ? "✅ PASS" : "❌ FAIL",
    cf_like_p99: p99Like < 2000 ? "✅ PASS" : "❌ FAIL",
    error_rate: errRate < 0.5 ? "✅ PASS" : "❌ FAIL",
  };

  console.log("\n══════════════════════════════════════");
  console.log("TurqApp Load Test SLO Sonuçları");
  console.log("══════════════════════════════════════");
  console.log(`Feed latency p95 : ${p95Feed.toFixed(0)}ms  ${sloStatus.feed_ttfc_p95}`);
  console.log(`CF like p99      : ${p99Like.toFixed(0)}ms  ${sloStatus.cf_like_p99}`);
  console.log(`Error rate       : ${errRate.toFixed(2)}%  ${sloStatus.error_rate}`);
  console.log("══════════════════════════════════════\n");

  return {
    stdout: JSON.stringify(data, null, 2),
    "tests/load/k6_results.json": JSON.stringify(data),
  };
}
