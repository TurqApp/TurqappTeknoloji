/**
 * TurqApp Rate Limiter
 *
 * Strateji:
 * - In-memory Map: aynı CF instance içinde hızlı koruma (sıfır maliyet)
 * - Firestore tabanlı: cross-instance kalıcı limit (gerektiğinde etkinleştir)
 *
 * Kullanım:
 * ```ts
 * await enforceRateLimit(request.auth.uid, 'like', 100, 60);
 * ```
 */

import { HttpsError } from "firebase-functions/v2/https";

interface RateLimitEntry {
  count: number;
  windowStart: number; // epoch ms
}

// Per-instance in-memory store — fonksiyon soğuk başlatılırsa sıfırlanır
// Yeterli: kısa-süreli saldırıları durdurur, persistent quota için Firestore eklenebilir
const _store = new Map<string, RateLimitEntry>();

// Store temizliği: 5 dakikada bir eski kayıtları sil (bellek sızıntısı önleme)
const CLEANUP_INTERVAL_MS = 5 * 60 * 1000;
let _lastCleanup = Date.now();

function _maybeCleanup(nowMs: number): void {
  if (nowMs - _lastCleanup < CLEANUP_INTERVAL_MS) return;
  _lastCleanup = nowMs;
  for (const [key, entry] of _store.entries()) {
    // 2 pencere ömrü geçmişse sil
    if (nowMs - entry.windowStart > 120_000) {
      _store.delete(key);
    }
  }
}

/**
 * Basit sliding-window rate limiter.
 *
 * @param uid          Firebase Auth UID
 * @param action       İşlem adı ('like', 'comment', 'follow', vb.)
 * @param limit        İzin verilen maksimum istek sayısı
 * @param windowSec    Pencere süresi (saniye)
 * @throws HttpsError  429 benzeri 'resource-exhausted' — limit aşıldığında
 */
export function enforceRateLimit(
  uid: string,
  action: string,
  limit: number,
  windowSec: number
): void {
  const nowMs = Date.now();
  _maybeCleanup(nowMs);

  const key = `${action}:${uid}`;
  _enforceRateLimitForStoreKey(key, action, limit, windowSec, nowMs);
}

export function enforceRateLimitForKey(
  keySubject: string,
  action: string,
  limit: number,
  windowSec: number
): void {
  const normalized = String(keySubject || "").trim().toLowerCase();
  if (!normalized) {
    throw new HttpsError("invalid-argument", "rate_limit_key_required");
  }

  const nowMs = Date.now();
  _maybeCleanup(nowMs);

  const key = `${action}:${normalized}`;
  _enforceRateLimitForStoreKey(key, action, limit, windowSec, nowMs);
}

function _enforceRateLimitForStoreKey(
  key: string,
  action: string,
  limit: number,
  windowSec: number,
  nowMs: number
): void {
  const windowMs = windowSec * 1000;

  const entry = _store.get(key);

  if (!entry || nowMs - entry.windowStart >= windowMs) {
    // Yeni pencere aç
    _store.set(key, { count: 1, windowStart: nowMs });
    return;
  }

  entry.count += 1;

  if (entry.count > limit) {
    const retryAfterSec = Math.ceil((windowMs - (nowMs - entry.windowStart)) / 1000);
    throw new HttpsError(
      "resource-exhausted",
      `Rate limit aşıldı: ${action} — ${limit} istek / ${windowSec}s. ${retryAfterSec}s sonra tekrar deneyin.`
    );
  }
}

/**
 * Ön tanımlı limitler — uygulamaya özgü politika
 */
export const RateLimits = {
  /** Beğeni: 120/dk */
  like: (uid: string) => enforceRateLimit(uid, "like", 120, 60),
  /** Yorum: 30/dk */
  comment: (uid: string) => enforceRateLimit(uid, "comment", 30, 60),
  /** Report: 20 / 10dk */
  report: (uid: string) => enforceRateLimit(uid, "report", 20, 600),
  /** Takip: 60/dk */
  follow: (uid: string) => enforceRateLimit(uid, "follow", 60, 60),
  /** Gönderi oluşturma: 10/dk */
  post: (uid: string) => enforceRateLimit(uid, "post", 10, 60),
  /** Genel API: 300/dk */
  general: (uid: string) => enforceRateLimit(uid, "general", 300, 60),
  /** Admin işlemi: 10/dk */
  admin: (uid: string) => enforceRateLimit(uid, "admin", 10, 60),
} as const;
