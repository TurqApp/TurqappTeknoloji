# TurqApp — Mart 2026 Üretim İş Planı
**Audit Tarihi:** 2026-03-03
**Hazırlayan:** Staff Mobile + Video + Security + Backend + FinOps Ekibi
**Hedef:** Instagram / X seviyesinde akıcılık, güvenlik, ölçeklenebilirlik

---

## 0) HEDEF KPI'LAR (Instagram/X Benchmark)

### Feed KPI'ları

| KPI | Hedef | Telemetry Event | Alarm Eşiği |
|-----|-------|-----------------|-------------|
| Warm first content | < 500ms | `feed_ttfc_warm` | > 800ms → P1 |
| Cold first content | < 1.5s | `feed_ttfc_cold` | > 2.5s → P1 |
| Scroll jank (p95) | < %5 | `scroll_jank_pct` | > %10 → P2 |
| Image cache hit | > %85 | `img_cache_hit_rate` | < %70 → P2 |
| Feed data cache hit | > %70 | `feed_cache_hit_rate` | < %55 → P2 |
| CDN hit ratio | > %90 | `cdn_hit_ratio` | < %80 → P1 |
| Firestore reads/screen | < 8 | `firestore_reads_per_screen` | > 20 → P2 |

### Video KPI'ları

| KPI | Hedef | Telemetry Event | Alarm Eşiği |
|-----|-------|-----------------|-------------|
| TTFF (warm) | < 400ms | `video_ttff_ms` | > 700ms → P1 |
| TTFF (cold) | < 1.2s | `video_ttff_cold_ms` | > 2s → P1 |
| Autoplay start | < 300ms | `video_autoplay_start_ms` | > 500ms → P2 |
| Rebuffer rate | < %1 | `video_rebuffer_rate` | > %3 → P1 |
| Bellek (feed scroll) | < 150MB | `memory_rss_mb` | > 220MB → P1 |
| Dropped frames | < %2 | `video_dropped_frame_pct` | > %5 → P2 |

---

## 1) GERÇEK KOD AUDIT BULGULARI (2026-03-03)

### Kritik Güvenlik Açıkları (Tespit Edildi)

| # | Dosya | Açık | Severity |
|---|-------|------|----------|
| S1 | `firestore.rules:115` | `Posts update: if isAuth()` → herhangi auth user herhangi postu güncelleyebilir | 🔴 CRITICAL |
| S2 | `firestore.rules:421` | `CevapAnahtarlari read: if isAuth()` → tüm cevap anahtarları auth'a açık | 🔴 CRITICAL |
| S3 | `firestore.rules:200` | `Chat/{chatId} read,write: if isAuth()` → herkes herkese ait sohbeti okuyabilir | 🔴 HIGH |
| S4 | `firestore.rules:24` | `users/{uid} update: if isOwner(uid)` → `role`/`stats` field koruması yok | 🔴 HIGH |
| S5 | `storage.rules:18-25` | HLS segmentleri `allow read;` (no auth) → hotlink açığı | 🟡 MEDIUM |
| S6 | `firestore.rules:350` | `Testler/{sub=**} write: if isAuth()` → herkes alt koleksiyonlara yazabilir | 🟡 MEDIUM |
| S7 | `firestore.rules:267` | `SoruBankasi/{sub=**} write: if isAuth()` → benzer wildcard write | 🟡 MEDIUM |

### Performans Bug'ları (Tespit Edildi)

| # | Dosya | Bug | Etki |
|---|-------|-----|------|
| P1 | `short_view.dart:112,268` | `_lastPersistedProgress` video değişimde sıfırlanmıyor | Yanlış progress tracking |
| P2 | `video_state_manager.dart:21` | `_allVideoControllers` Map sınırsız büyüyor | Memory leak → OOM |
| P3 | `short_controller.dart:184` | `_fetchUsersPrivacy` her page'de ayrı Firestore sorgusu | N+1 okuma |
| P4 | `short_controller.dart:126` | Feed query tüm Posts çekiyor, Dart'ta video filtresi yapıyor | Fazla okuma |
| P5 | `short_controller.dart:478` | `_globalShuffleCompleted` static — controller yeniden oluşturulsa sıfırlanmaz | Shuffle kaybolabilir |

### Mevcut İyi Pratikler (Korunacak)

- ✅ `cache_manager.dart` — `_isLowQualityEntry` `_recentlyPlayed` kontrolü var (MEMORY.md'deki bug zaten fix edilmiş)
- ✅ `short_view.dart` — `_videoEndListener` `removeListener` → `addListener` pattern doğru
- ✅ `short_controller.dart` — realtime listener yerine `get()` kullanımı
- ✅ 3-tier cache (HOT/WARM/COLD) doğru çalışıyor
- ✅ Coalesced eviction pattern (`_evictionInFlight`)
- ✅ Per-key write lock (`_writeInFlight`)
- ✅ 3-tier aspect ratio sistemi (`short_view.dart`, `single_short_view.dart`)

---

## 2) UYGULANABİLİR BACKLOG

### PHASE 1: 0-7 Gün — Kritik Hotfix

| # | İş | Dosya | Etki | Efor | Status |
|---|----|----|------|------|--------|
| **H1** | `Posts` update rule'u düzelt: sadece sahip güncelleyebilir + field whitelist | `firestore.rules` | CRITICAL güvenlik | 2s | ✅ 2026-03-03 |
| **H2** | `CevapAnahtarlari` okumayı kapat: `allow read: if false` | `firestore.rules` | CRITICAL güvenlik | 30dk | ✅ 2026-03-03 |
| **H3** | `Chat/{chatId}` legacy rule'u katılımcı kontrolüne al | `firestore.rules` | HIGH güvenlik | 1s | ✅ 2026-03-03 |
| **H4** | `users/{uid}` update'de `role`/`stats` field koruması ekle | `firestore.rules` | HIGH güvenlik | 1s | ✅ 2026-03-03 |
| **H5** | `short_view.dart` — `_lastPersistedProgress` video değişimde sıfırla | `short_view.dart` | Progress bug fix | 30dk | ✅ 2026-03-03 |
| **H6** | `VideoStateManager._allVideoControllers` max 30 entry limiti ekle | `video_state_manager.dart` | Memory leak fix | 1s | ✅ 2026-03-03 |
| **H7** | `Testler` + `SoruBankasi` wildcard write kurallarını daralt | `firestore.rules` | MEDIUM güvenlik | 1s | ✅ 2026-03-03 |

### PHASE 2: 1-4 Hafta — Mimari Düzen

| # | İş | Dosya | Etki | Efor | Status |
|---|----|----|------|------|--------|
| **A1** | L1 LRU cache (feed summaries + user profiles) | Yeni: `lru_cache.dart` | -70% Firestore read | 1h | ✅ 2026-03-03 |
| **A2** | Feed query'e `videoHLSMasterUrl != ''` filtresi ekle (DB seviyesi) | `short_controller.dart` | -30% okuma | 2s | ⏭️ Firestore index kısıtı |
| **A3** | `_fetchUsersPrivacy` sonuçlarını oturum boyunca cache'le | `short_controller.dart` | -N extra read/page | 2s | ✅ 2026-03-03 |
| **A4** | Rate limiter (Cloud Functions) — like/yorum/follow sınırı | `functions/src/rateLimiter.ts` | Spam önleme | 3g | ✅ 2026-03-03 |
| **A5** | Cloud Functions auth check audit — purge fonksiyonları admin zorunluluğu | `functions/src/index.ts` | Güvenlik | 1h | ✅ 2026-03-03 |
| **A6** | ExoPlayer LoadControl buffer tuning (2s min, 15s max) | `ExoPlayerView.kt` | -200ms TTFF | 2h | ✅ 2026-03-03 |
| **A7** | AVPlayer preferredForwardBufferDuration = 10s | `HLSPlayerView.swift` | -150ms TTFF | 2h | ✅ 2026-03-03 |
| **A8** | Disk cache — feed pages offline | `IndexPoolStore` (zaten mevcut) | Offline support | - | ✅ Mevcut |
| **A9** | Aggregation counter sharding (likes/views) | `functions/src/counterShards.ts` | Ölçeklenme | 2h | ✅ 2026-03-03 |
| **A10** | Video telemetry (TTFF, rebuffer, position) | `short_view.dart` + `video_telemetry_service.dart` | Observability | 1h | ✅ 2026-03-03 |

### PHASE 3: 1-3 Ay — Instagram Seviyesine Çıkış

| # | İş | Etki | Efor | Status |
|---|----|----|------|--------|
| **B1** | SWR controller base class | `lib/Core/Services/swr_controller.dart` | Anında yükleme hissi | ✅ 2026-03-03 |
| **B2** | HLS ABR ladder optimize (FPS tespiti, 1s init, 1080p) | `functions/src/hlsTranscode.ts` | Rebuffer < %1 | ✅ 2026-03-03 |
| **B3** | Typesense entegrasyon (search) | Zaten mevcut (`explore_controller.dart`) | Search p95 < 200ms | ✅ Mevcut |
| **B4** | Hybrid feed fan-out/fan-in (>10K takipçi) | `functions/src/hybridFeed.ts` | 100K+ ölçeklenme | ✅ 2026-03-03 |
| **B5** | Design system token'ları (Dart) | `lib/Themes/app_tokens.dart` | UI tutarlılık | ✅ 2026-03-03 |
| **B6** | Skeleton loader standardize | `lib/Core/Widgets/skeleton_loader.dart` | Perceived performance | ✅ 2026-03-03 |
| **B7** | Observability SLO tanımları | `docs/observability/slo_definitions.yaml` | SLO görünürlük | ✅ 2026-03-03 |
| **B8** | Load test k6 scripti | `tests/load/k6_turqapp_load_test.js` | Regression önleme | ✅ 2026-03-03 |
| **B9** | WebP thumbnail pipeline | `functions/src/hlsTranscode.ts` + `thumbnails.ts` | -30% bandwidth | ✅ 2026-03-03 |
| **B10** | Feed denormalizasyon (author inline) | `PostsModel` + `functions/src/authorDenorm.ts` | N+1 → 1 okuma | ✅ 2026-03-03 |

---

## 3) GÜVENLİK AUDIT — Top 20 Risk

| # | Açık | Severity | Exploit | Çözüm |
|---|------|----------|---------|-------|
| 1 | `Posts` update rule — herkes günceller | 🔴 CRITICAL | `stats.likeCount = 9999` | Field whitelist + owner check |
| 2 | `CevapAnahtarlari` herkese açık | 🔴 CRITICAL | `.get()` → tüm cevaplar | `allow read: if false` |
| 3 | `Chat` legacy — herkese açık | 🔴 HIGH | Başkasının mesajlarını oku | Participant check |
| 4 | `users.role` field korumasız | 🔴 HIGH | `role: 'admin'` yaz | update field blacklist |
| 5 | Rate limit yok | 🔴 HIGH | Sonsuz like/spam | Redis sliding window |
| 6 | HLS Signed URL TTL belirsiz | 🟡 MEDIUM | URL paylaşımıyla hotlink | TTL = 1 saat |
| 7 | CF auth check eksik olabilir | 🟡 MEDIUM | Unauthenticated CF call | Her CF'de `if (!request.auth)` |
| 8 | Subscription check client-side | 🟡 MEDIUM | Premium bypass | Custom claim + CF verify |
| 9 | `Testler/{sub=**}` wildcard write | 🟡 MEDIUM | Herkes sınav alt koleksiyonuna yazar | Daralt |
| 10 | `SoruBankasi/{sub=**}` wildcard write | 🟡 MEDIUM | Benzer | Daralt |
| 11 | Firebase Auth token revocation yok | 🟡 MEDIUM | Stolen token uzun süre geçerli | Token revoke + short TTL |
| 12 | OTP/PIN brute force koruması yok | 🟡 MEDIUM | Sınav PIN deneme | 5 hata → 30dk kilit |
| 13 | FCM token farming sınırsız | 🟡 LOW | Push spam | Max 10 device/user |
| 14 | CORS wildcard CF | 🟡 LOW | Herhangi domain CF çağırır | Origin allowlist |
| 15 | Deep link validation yok | 🟡 LOW | Phishing | Universal Links + PKCE |
| 16 | Bundle'da hardcoded key riski | 🟡 LOW | APK analizi | Secrets CF'e taşı |
| 17 | Unvalidated redirect | 🟡 LOW | `?next=evil.com` | Allowlist |
| 18 | Comment injection | 🟡 LOW | Markdown exploit | Server-side sanitize |
| 19 | Video thumbnail public (intentional) | 🟢 INFO | Hotlink | Signed thumbnail (opsiyonel) |
| 20 | `VideoStateManager` memory leak | 🟡 MEDIUM | OOM → crash | Max 30 controller limit |

---

## 4) MALİYET (FinOps) — En Pahalı 10 Pattern

| # | Pattern | Tahmini Maliyet | Çözüm |
|---|---------|-----------------|-------|
| 1 | Feed her scroll → full Firestore | $800/ay | L1 cache |
| 2 | `_fetchUsersPrivacy` her sayfada | $200/ay | Session cache |
| 3 | Sınav sorularını her açılışta çek | $200/ay | Disk cache |
| 4 | View count realtime increment | $200/ay | Shard + batch |
| 5 | Video progress sync her 2s | $150/ay | Debounce 30s |
| 6 | Comment count realtime listener | $150/ay | SWR 60s |
| 7 | Follow/follower list full read | $100/ay | Count only |
| 8 | Search: Firestore full-scan | $100/ay | Typesense |
| 9 | Notification badge listener | $100/ay | FCM data + polling |
| 10 | User profile N+1 read | $300/ay | Denormalizasyon |

---

## 5) OBSERVABILITY — SLO Tanımları

```yaml
slos:
  feed_availability: 99.9% (43.8 dk/ay downtime)
  video_ttff_p95: < 400ms
  feed_ttfc_warm_p95: < 500ms
  rebuffer_rate: < %1
```

---

## 6) LOAD TEST — 100K DAU Hesaplama

```
DAU = 100,000
Peak concurrent = ~50,000
Feed scroll QPS = 5,000
Video autoplay QPS = 1,667
Firestore read QPS (cache'li) = 1,500
CF invoke QPS = ~500
CDN bandwidth (peak) = ~75 Gbps
```

---

## 7) EN YÜKSEK ROI 10 İŞ

| # | İş | ROI |
|---|----|----|
| 1 | Posts update rule fix | Kritik güvenlik, 30dk efor |
| 2 | CevapAnahtarlari kapat | Kritik güvenlik, 30dk efor |
| 3 | L1 LRU cache | -70% Firestore, -300ms TTFC |
| 4 | Chat rule fix | HIGH güvenlik |
| 5 | users field protection | HIGH güvenlik |
| 6 | ExoPlayer/AVPlayer buffer tuning | -200ms TTFF |
| 7 | `_lastPersistedProgress` reset | Doğru progress sync |
| 8 | VideoStateManager limit | Memory crash önleme |
| 9 | Rate limiter CF | Spam/abuse önleme |
| 10 | Video telemetry | Tüm iyileştirmeler ölçülebilir |

---

## 8) YÜRÜTME TAKVİMİ

```
HAFTA 1 (Mart 1-7):   H1-H7 güvenlik hotfix'leri
HAFTA 2-3 (Mart 8-21): A1-A5 cache + rate limit
HAFTA 4-6 (Mart 22 - Nisan 5): A6-A10 video + telemetry
AY 2-3 (Nisan-Mayıs): B1-B10 Instagram seviyesi
```

---

*Bu doküman otomatik olarak güncellenmektedir. Her tamamlanan item için checkbox işaretleyin.*
