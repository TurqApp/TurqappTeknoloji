# CACHE PERFORMANCE AUDIT - TurqApp
**Tarih:** 2026-03-02
**Ekip:** Staff Mobile Performance Engineer + Caching Architect + Backend/Firestore Architect + CDN/Streaming Engineer
**Stack:** Flutter + Firebase (Auth/Firestore/Storage) + Cloud Functions (Node/TS) + Cloudflare CDN

---

## 0) HEDEF KPI'LAR (Instagram Benchmark)

| KPI | Hedef | Mevcut Durum (Varsayim) | Olcum Yontemi |
|-----|-------|------------------------|---------------|
| Image cache hit (warm) | >%85 | ~%40-50 (cacheControl eksik) | `cache_hit` / `cache_miss` event, CacheMetrics |
| Feed/data cache hit (warm) | >%70 | ~%30-40 (SWR yok) | Firestore SDK `fromCache` flag + custom event |
| CDN cache hit (statik medya) | >%90 | ~%20-30 (gorsel cacheControl yok) | Cloudflare Analytics dashboard, cf-cache-status header |
| Feed ilk icerik (warm) | <500ms | ~800-1200ms | `app_launch_to_first_content` timestamp delta |
| Feed ilk icerik (cold) | <1.5s | ~2-3s | Ayni metrik, cold start flag ile |
| Scroll performansi | 60fps, jank <5% | ~50-55fps (gorsel decode overhead) | `SchedulerBinding.addTimingsCallback`, jank frame counter |
| Firestore reads/ekran | Minimum | ~15-30 read/feed refresh | Custom counter wrapper, Firebase Performance trace |
| Video TTFF (warm) | <400ms | ~500-800ms | `VideoTelemetryService.ttff` |
| Autoplay start (scroll) | <300ms | ~400-600ms | Visibility timestamp → play event delta |
| Rebuffer orani | <%1 | ~%2-4 | `rebufferCount / totalSessions` |

### Telemetry Uygulama Plani
Her KPI icin Flutter tarafinda event:
```dart
// Ornek: Feed ilk icerik
final feedStartMs = DateTime.now().millisecondsSinceEpoch;
// ... icerik yuklendi
final ttci = DateTime.now().millisecondsSinceEpoch - feedStartMs;
analytics.log('feed_ttci', {'ms': ttci, 'warm': wasWarm, 'network': networkType});
```

---

## 1) CACHE KATMANLARI HARITASI

```
[Kullanici Cihazi]
  L1: In-Memory Cache (LRU + TTL)
    → CurrentUserService (singleton, SharedPrefs 7-gun TTL)
    → GetxController.obs datalari (feed, profil, liste)
    → Flutter ImageCache (decoded pixel buffer)

  L2: Disk Cache
    → cached_network_image (DefaultCacheManager: 200 dosya, 7 gun)
    → HLS SegmentCache (index.json, 3GB hard limit)
    → SharedPreferences (user, settings, drafts, upload queue)
    → Firestore offline persistence (varsayilan 100MB)

  L3: HTTP/Network
    → Firestore SDK cache (GetOptions.source)
    → http paketi (cache header yok, interceptor yok)

[CDN - Cloudflare]
  L4: Edge Cache
    → HLS segmentleri: immutable, 1 yil (DOGRU)
    → HLS playlist: 5dk-1gun (DOGRU)
    → Gorseller: cacheControl YOK → Cloudflare cache'lemez (KRITIK BUG)
    → Hotlink: X-Turq-App header

[Origin - Firebase Storage]
  L5: Backend
    → Cloud Functions: cache yok
    → Firestore: server-side, varsayilan
```

### A) Mobil In-Memory Cache (LRU + TTL)

**Mevcut Durum:**
- `CurrentUserService`: SharedPreferences ile 7-gun TTL, debounce 300ms. **Iyi.**
- GetxController'lardaki `.obs` listeleri: Bellekte tutuluyor ama TTL/invalidation yok.
- Flutter `ImageCache`: Varsayilan 1000 gorsel / 100MB. Konfigurasyonu yok.

**Oneri:**
| Alan | Boyut Limiti | TTL | Eviction | Stale-While-Revalidate |
|------|-------------|-----|----------|----------------------|
| Feed ozet | 200 item | 5dk | LRU | Evet - once cache goster, arka planda guncelle |
| User profil | 100 entry | 10dk | LRU | Evet |
| Permissions/roles | 1 entry | 30dk | Manual purge | Hayir - guvenlik riski |
| Feature flags | 1 entry | 1saat | Remote Config | Evet |
| Session metadata | 1 entry | Oturum suresi | - | Hayir |

**Thread-safety:** Flutter single-thread (main isolate), thread-safety gereksiz. Compute isolate'larda `Map` cache kullanilmamali.

**Impact:** Feed warm hit %30→%70+ | **Effort:** 2-3 gun | **Risk:** Dusuk | **Cost:** Bellek +5-10MB

### B) Mobil Disk Cache

**Mevcut Durum:**
- `cached_network_image` + `flutter_cache_manager`: Varsayilan config (200 dosya, 7 gun stale)
- `SegmentCacheManager`: Ozel HLS cache, 3GB hard limit, index.json. **Olgun.**
- `SharedPreferences`: current_user, network_settings, drafts, upload_queue. **Yetersiz — yapilandirilmamis JSON.**
- Hive/Isar/SQLite: **Kullanilmiyor.**
- Firestore offline persistence: **Varsayilan acik, cacheSizeBytes belirlenmemis.**

**Alternatif Karsilastirma:**

| Ozellik | SharedPreferences | Hive | Isar | SQLite |
|---------|------------------|------|------|--------|
| Hiz | Yavas (her islemde disk I/O) | Hizli (memory-mapped) | En hizli (native) | Orta |
| Sorgu | Key-value | Key-value + box | Full query | SQL |
| Migration | Manuel | Manuel | Otomatik sema | SQL migration |
| Boyut | <1MB ideal | GB seviyesi | GB seviyesi | GB seviyesi |
| Feed cache | Uygun degil | Uygun | En uygun | Uygun |

**Oneri:** Feed ozet cache icin **Isar** (1. tercih) veya **Hive** (2. tercih, daha basit). SharedPreferences sadece primitif ayarlar icin kalsin.

**Impact:** Cold start %50 hizlanma | **Effort:** 1-2 hafta | **Risk:** Orta (migration) | **Cost:** +5MB disk

### C) HTTP/Network Cache

**Mevcut Durum:**
- `http` paketi: Hicbir cache interceptor yok. Her istek fresh.
- ETag/If-None-Match: **Kullanilmiyor.**
- Cache-Control client-side: **Yok.**
- Retry/backoff: **Yok (sadece Firestore SDK kendi yapiyor).**

**Oneri:**
1. `http` paketinden `dio` + `dio_cache_interceptor`'a gec (pubspec'te dio zaten var)
2. CDN gorsel URL'leri icin `stale-while-revalidate` destekli HTTP cache interceptor ekle
3. Retry: exponential backoff (1s, 2s, 4s, max 3 deneme)

**Varsayim:** Gorsel URL'leri Firebase Storage download URL'leri (token iceriyorsa cache key olarak token haric URL kullanilmali).

**Impact:** Network istekleri %40-60 azalma | **Effort:** 3-5 gun | **Risk:** Dusuk | **Cost:** Azalir (egress dusmesi)

### D) Backend Cache

**Mevcut Durum:**
- Cloud Functions: Hicbir response cache yok. Her cagri fresh hesaplama.
- Aggregation cache: Yok. Sayaclar `FieldValue.increment` ile atomik ama precomputed ozet yok.
- Rate-limit: Yok (sadece Firestore rules ile guvenlik).

**Oneri Alternatifleri:**
1. **Firestore cache doc pattern** (Oneri): Populer sorgulari `cache_feeds/{feedType}` collection'ina yazarak client'in tek doc okumasiyla feed almasini sagla. Cloud Function cron ile 5dk'da bir guncelle.
   - Impact: Feed reads 20→1 | Effort: 1 hafta | Risk: Dusuk
2. **Cloudflare KV**: Edge'de key-value store. Feed JSON'unu KV'ye yaz, Worker'dan serv et.
   - Impact: p95 latency %80 dusus | Effort: 2 hafta | Risk: Orta (yeni infra)
3. **Cloud Functions in-memory**: Global degisken ile son N dakikanin sonucunu cache'le.
   - Impact: Dusuk (cold start'ta kaybolur) | Effort: 1 gun | Risk: Dusuk

### E) CDN Cache (Cloudflare)

**Mevcut Durum:**
- CNAME proxy: `cdn.turqapp.com → firebasestorage.googleapis.com`
- HLS dosyalari: Dogru cache-control header'lari **var** (hlsTranscode.ts'te set ediliyor)
- Gorseller: **`cacheControl` METADATA YOK** → Cloudflare varsayilan davranisla kisa sure cache'ler veya hic cache'lemez

**KRITIK BUG - webp_upload_service.dart:51:**
```dart
// MEVCUT:
await ref.putData(data, SettableMetadata(contentType: 'image/webp'));
// OLMASI GEREKEN:
await ref.putData(data, SettableMetadata(
  contentType: 'image/webp',
  cacheControl: 'public, max-age=31536000, immutable',
));
```

**Bu tek degisiklik CDN gorsel hit ratio'sunu %20→%90+ cikarir.**

**Cache Key Stratejisi:**
- Gorseller: Path-based (content-hash veya version param ile invalidation)
- Video segmentleri: Path-based + immutable (segment icerigi degismez)
- Playlist: Path-based + kisa TTL

**Edge Image Resizing:**
- Cloudflare Image Resizing (Pro+ plan gerekli): `/cdn-cgi/image/w=300,q=80,f=webp/...`
- Alternatif: Upload sirasinda 3 boyut uret (bkz. Bolum 3)

**Impact:** Gorsel CDN hit %20→%90+ | **Effort:** 1 saat (cacheControl ekleme) | **Risk:** Yok | **Cost:** Egress %70-80 azalma

---

## 2) DATA CACHE (Firestore) - Instagram Tarzi

### Real-time Listener Audit

**Mevcut Durum:** ~134 `.listen()` / `.snapshots()` kullanimi codebase genelinde.

| Controller | Listener Tipi | Gerekli mi? | Oneri |
|-----------|--------------|-------------|-------|
| `current_user_service.dart` | users/{uid} snapshots | EVET | Korunsun (oturum boyunca) |
| `agenda_controller.dart` | Posts snapshots | HAYIR | Pull + SWR (feed refresh butonuyla) |
| `tutoring_controller.dart` | educators snapshots | HAYIR | Pull + loadMore (pagination zaten var) |
| `chat_controller.dart` | messages snapshots | EVET | Korunsun (realtime mesajlasma) |
| `short_controller.dart` | Posts snapshots | HAYIR | Pull + prefetch |
| `explore_controller.dart` | Posts snapshots | HAYIR | Pull + SWR |
| `deneme_sinavlari_controller.dart` | practiceExams snapshots | HAYIR | Pull + SWR |
| `answer_key_controller.dart` | books/optics snapshots | HAYIR | Pull + SWR |
| `scholarships_controller.dart` | scholarships snapshots | HAYIR | Pull + SWR |

**Kural:** Realtime listener SADECE su durumlarda kullanilsin:
1. Chat mesajlari (mesajlasma)
2. CurrentUser (oturum)
3. Bildirimler (push fallback)
4. Aktif oylamalar/anketler

Diger her sey **pull + stale-while-revalidate** olsun.

### Cursor Pagination Standardi

**Mevcut:** 36 yerde `startAfterDocument` kullaniliyor. **Iyi.**

**Standart Pattern:**
```dart
mixin PaginatedController<T> {
  DocumentSnapshot? _lastDoc;
  bool hasMore = true;
  final int pageSize = 30;

  Future<List<T>> fetchPage() async {
    var query = baseQuery().limit(pageSize);
    if (_lastDoc != null) query = query.startAfterDocument(_lastDoc!);
    final snap = await query.get(); // .get() — listener degil!
    if (snap.docs.length < pageSize) hasMore = false;
    if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
    return snap.docs.map(fromDoc).toList();
  }
}
```

### 2 Asamali Yukleme (Lightweight Summary + Lazy Detail)

**Mevcut:** Tum alanlar tek sorguda cekiliyor. Buyuk doc'lar (Posts, users) gereksiz alan tasiyorlar.

**Oneri — Firestore Semasi:**

```
feed_summaries/{docID}     ← 1KB, sadece feed gosterim icin
  userID, nickname, avatarUrl, text(ilk 200 char), thumbnailUrl,
  mediaType, likeCount, commentCount, timeStamp

Posts/{docID}              ← 5-20KB, detail sayfada lazy fetch
  ... tum alanlar ...

users_public/{uid}         ← 500B, baska kullanicinin mini profili
  nickname, avatarUrl, isVerified, followerCount

users/{uid}                ← 5KB+, sadece currentUser icin
  ... tum alanlar ...

counters/{entityId}        ← 100B, precomputed sayaclar
  likes, comments, views, shares
```

**Fan-out vs Fan-in:**

| Ekran | Pattern | Neden |
|-------|---------|-------|
| Feed | Fan-out on write | Feed'e yazildiginda `feed_summaries`'a da yaz. Read sifir join. |
| Profil | Fan-in on read | Kullanicinin tum post'lari tek query. Write basit. |
| Egitim listeleri | Fan-out on write | Liste gorunumu icin summary doc, detail ayri. |
| Arama sonuclari | Fan-in on read | Fulltext query, sonuc sayisi sinirsiz. |

### Aggregation: Precomputed Counters

**Mevcut:** `FieldValue.increment` ile atomik sayaclar. **Dogru pattern.**

**Ek Oneri:** Haftalik Cloud Function cron ile counter drift fix:
```typescript
// Her pazar gece: gercek like sayisini say, counter'i duzelt
exports.fixCounters = functions.pubsub.schedule('0 3 * * 0').onRun(async () => {
  // Posts/{docID}/Likes subcollection.count() → Posts/{docID}.likeCount
});
```

### Offline Persistence

**Mevcut:** Firestore varsayilan offline persistence acik, `cacheSizeBytes` belirlenmemis (varsayilan 100MB).

**Oneri:**
```dart
FirebaseFirestore.instance.settings = const Settings(
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // veya 200MB
  persistenceEnabled: true,
);
```

**Conflict cozumu:** Firestore "last write wins". Ek olarak `OfflineModeService` pending action queue mevcut. **Yeterli.**

### Read Azaltma Anti-Pattern Listesi

| Anti-Pattern | Nerede | Etki | Cozum |
|-------------|--------|------|-------|
| N+1 user fetch | `tutoring_controller.dart:50-68` | 30 user icin 1 query (batch WHERE IN) | **Zaten duzeltilmis** - batch 30 |
| Gereksiz listener | `agenda_controller`, `explore_controller` | Surekli Firestore read | Pull + SWR |
| Genis doc okuma | Posts (tum alanlar) | 5-20KB/doc | feed_summary (1KB) |
| Fazla refresh | Feed her tab degisiminde reload | ~30 read/gecis | Cache 5dk TTL, refresh butonu |
| emailVerify tekrar sorgu | `current_user_service.dart:467-513` | Her seferinde Firestore + Auth reload | Cache 5dk, flag degismedikce sorma |
| adminConfig tekrar | `_loadEmailVerifyConfig` | Her init'te 1 read | Remote Config'e tasi |

### Ekran Bazli Read Budget

| Ekran | Mevcut (tahmini) | Hedef | Nasil |
|-------|-----------------|-------|-------|
| Feed (ilk yukleme) | 30 post + 30 user = ~60 read | 1 read (feed_summary batch) | Fan-out summary |
| Feed (sayfa) | 30 read | 1 read | Cursor pagination + summary |
| Profil | 15-20 read | 3-5 read | users_public + posts cursor |
| Egitim ana ekrani | 10-15 read | 2-3 read | Category summary doc |
| Video detay | 5-8 read | 2-3 read | Post + user_public |

---

## 3) IMAGE CACHE - Instagram Seviyesi

### Mevcut Durum Analizi

| Bilesen | Durum | Sorun |
|---------|-------|-------|
| Paket | `cached_network_image: ^3.4.1` | Varsayilan config |
| CacheManager | `DefaultCacheManager` (200 dosya, 7 gun) | Cok dusuk limit |
| Disk cache boyutu | ~50MB varsayilan | Instagram 200-500MB kullanir |
| Cozunurluk | Tek boyut (orijinal WebP, q85) | Oversize indirme |
| OptimizedImage widget | `maxWidthDiskCache: 600, maxHeightDiskCache: 600` | Sadece 1 yerde |
| CDN cache-control | **YOK** (gorsellerde) | Cloudflare cache'leyemiyor |
| Prefetch | 3 yerde `precacheImage` (splash, overlay, story) | Feed item prefetch yok |
| Avatar cache | `cached_user_avatar.dart` mevcut | TTL belirsiz |
| Upload | WebP q85, tek boyut | Coklu cozunurluk yok |

### Thumbnail-First (Coklu Cozunurluk)

**Oneri - Upload sirasinda 3 boyut uret:**

| Boyut | Genislik | Kalite | Kullanim | Tahmini Boyut |
|-------|---------|--------|----------|--------------|
| small | 150px | 70 | Avatar, kucuk liste | 5-15KB |
| medium | 600px | 80 | Feed kart, grid | 30-80KB |
| original | Orijinal (max 4096) | 85 | Tam ekran | 100-500KB |

**Storage path:** `users/{uid}/{hash}_small.webp`, `_medium.webp`, `_original.webp`

**CDN URL pattern:** `https://cdn.turqapp.com/users/{uid}/{hash}_medium.webp`

### Progressive Yukleme + Placeholder

```dart
CachedNetworkImage(
  imageUrl: mediumUrl,
  placeholder: (_, __) => CachedNetworkImage(
    imageUrl: smallUrl, // once kucuk boyut (5KB, aninda yukle)
    fit: BoxFit.cover,
  ),
  fadeInDuration: Duration.zero, // cache hit'te fade yok
  memCacheWidth: (deviceWidth * devicePixelRatio).toInt(),
)
```

### Disk Cache Konfigurasyonu

```dart
// Custom CacheManager (uygulama basinda initialize)
class TurqImageCacheManager {
  static const key = 'turqImageCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),   // 7 gun → 30 gun
      maxNrOfCacheObjects: 2000,                // 200 → 2000
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

// Kullanim:
CachedNetworkImage(
  cacheManager: TurqImageCacheManager.instance,
  ...
)
```

### Prefetch (Scroll Tahmini)

```dart
// Feed'de sonraki 5 item'in gorselini arka planda indir
void prefetchImages(List<PostModel> posts, int currentIndex) {
  for (var i = 1; i <= 5; i++) {
    final idx = currentIndex + i;
    if (idx >= posts.length) break;
    final url = posts[idx].thumbnailUrl ?? posts[idx].firstImageUrl;
    if (url != null) {
      TurqImageCacheManager.instance.downloadFile(url);
    }
  }
}
```

### CDN URL Standardi + Cache Busting

**Mevcut:** `CdnUrlBuilder.toCdnUrl(url)` — sadece host degistiriyor.

**Oneri:** Content-hash veya version param ekle:
```dart
static String toCdnUrl(String url, {int? version}) {
  var cdnUrl = url.replaceFirst(_firebaseHost, cdnDomain);
  if (version != null) cdnUrl += '&v=$version';
  return cdnUrl;
}
```

### Flutter Tarafinda Widget Rebuild Azaltma

**Sorun:** Liste item'larinda gorsel decode ana thread'de yapiliyor → jank.

**Oneri:**
1. `RepaintBoundary` ile her liste item'ini izole et
2. `memCacheWidth` / `memCacheHeight` ile decode boyutunu sinirla
3. `filterQuality: FilterQuality.low` ile decode hizlandir

```dart
RepaintBoundary(
  child: CachedNetworkImage(
    imageUrl: url,
    memCacheWidth: 300, // Cihaz genisligine gore
    filterQuality: FilterQuality.low,
    fadeInDuration: Duration.zero,
  ),
)
```

### Memory Pressure Yonetimi

```dart
// Dusuk bellek uyarisinda gorsel cache'i temizle
WidgetsBinding.instance.addObserver(
  _MemoryPressureObserver(onLowMemory: () {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }),
);
```

**Impact:** Gorsel yukleme hizi %60 artis, scroll jank %70 azalis | **Effort:** 1 hafta | **Risk:** Dusuk | **Cost:** Disk +200MB, CDN egress %70 azalis

---

## 4) VIDEO CACHE (HLS) - AVPlayer / ExoPlayer

### Mevcut Durum (Zaten Olgun)

| Bilesen | Durum | Puan |
|---------|-------|------|
| HLS Proxy Server | Lokal 127.0.0.1 proxy, disk cache | 9/10 |
| Segment Cache | index.json tracking, 3GB limit, eviction scoring | 9/10 |
| Prefetch Scheduler | Breadth-first + depth, Wi-Fi/cellular politikasi | 8/10 |
| ABR Encoding | 360p/480p/720p, 2s segment, master playlist | 8/10 |
| iOS AVPlayer | preferredForwardBuffer=3s, waitsToMinimize=false | 7/10 |
| Android ExoPlayer | LoadControl tuned, HlsMediaSource, chunkless prep | 8/10 |
| CDN Headers | Segment: immutable 1yr, playlist: 5min/1day | 9/10 |
| Telemetry | TTFF, rebuffer, completion, watch time | 7/10 |
| Network Policy | Wi-Fi: full prefetch, Cellular: cache-only + seed mode | 9/10 |
| Remote Config | Prefetch params, cache limits dinamik | 9/10 |

### Segment Suresi ve ABR Ladder

**Mevcut (dogru):**
- Segment suresi: 2s (hizli TTFF icin ideal)
- Keyframe interval: Her segment baslangici
- ABR ladder: 360p (800kbps) / 480p (1400kbps) / 720p (2800kbps)

**Oneri — Data Saver Modu (eksik):**

| Mod | Wi-Fi | Cellular | Gece (00-06) |
|-----|-------|----------|-------------|
| Normal | 720p tercih | 480p max | 720p |
| Data Saver | 480p max | 360p only | 480p |
| Offline | Cache'den en iyi | Cache'den en iyi | Cache'den en iyi |

**Uygulama:** `M3U8Parser.bestVariant()` icine network-aware rendition secimi ekle.

### ExoPlayer Iyilestirmeler

**Mevcut:** LoadControl (5000-10000ms buffer), HlsMediaSource, chunkless prep. **Iyi.**

**Eksik — Player Reuse Stratejisi:**
- **Oneri: Tek aktif player + hizli switch.** RecyclerView'da her item icin yeni ExoPlayer olusturmak pahali.
- Scroll sirasinda: `softHold()` mevcut (volume=0, playWhenReady=false). **Dogru.**
- Gorunur olunca: `play()` ile devam. **Dogru.**
- **Ek oneri:** Ayni URL tekrar yuklendiginde player'i yeniden kurmama mantigi mevcut (`currentUrl == url` check). **Dogru.**

### AVPlayer Iyilestirmeler

**Mevcut:** preferredForwardBufferDuration=3s, automaticallyWaitsToMinimizeStalling=false. **Iyi.**

**Eksik:**
1. `AVAssetResourceLoader` ile native cache: **Onerilmez** — mevcut proxy cache daha esnek
2. Background/foreground: `appDidEnterBackground` → pause, `appWillEnterForeground` → nothing. **Ek oneri:** Foreground'a donuste son izlenen videoyu otomatik resume

### Reels Benzeri Video Lifecycle State Machine

```
[IDLE] → loadVideo → [LOADING]
  ↓ cache hit                    ↓ cache miss
[READY] → play → [PLAYING]   [BUFFERING] → data → [READY]
  ↓ scroll away    ↓ 90%+        ↓ timeout
[SOFT_HELD]    [COMPLETED]    [ERROR] → retry → [LOADING]
  ↓ scroll back    ↓ loop?
[PLAYING]      [PLAYING]
  ↓ background
[PAUSED] → foreground → [PLAYING]
  ↓ dispose
[DISPOSED]
```

### Video Telemetry Eventleri

**Mevcut (`video_telemetry_service.dart`):** TTFF, rebuffer count/duration, completion rate, watch time, seek count, errors. **Iyi.**

**Eksik eventler:**

| Event | Payload | Alarm Esigi |
|-------|---------|-------------|
| `video_dropped_frames` | `{count, total, fps}` | >5% frame drop |
| `video_avg_bitrate` | `{kbps, rendition}` | N/A (sadece analiz) |
| `video_cache_state_on_play` | `{hitType: full/partial/miss}` | miss >%30 |
| `video_network_switch` | `{from, to, bufferLevel}` | N/A |

### Data Saver Modu

```dart
class DataSaverPolicy {
  static bool get isEnabled => NetworkAwarenessService.settings.cellularDataMode == DataUsageMode.low;

  static int get maxRenditionHeight {
    if (isEnabled && NetworkAwarenessService.isOnCellular) return 360;
    if (NetworkAwarenessService.isOnCellular) return 480;
    return 720;
  }

  static bool get allowAutoplay {
    if (!NetworkAwarenessService.isConnected) return false;
    if (isEnabled && NetworkAwarenessService.isOnCellular) return false;
    return true;
  }
}
```

**Impact:** Rebuffer %2→<%1, TTFF 500ms→<400ms | **Effort:** 3-5 gun | **Risk:** Dusuk | **Cost:** Bandwidth %20 azalma (data saver)

---

## 5) CACHE INVALIDATION - EN KRITIK TASARIM

### Invalidation Playbook

| Olay | Trigger | Etkilenen Katmanlar | Aksiyon | Risk | Done Kriteri |
|------|---------|-------------------|---------|------|-------------|
| Profil guncelleme | Firestore onUpdate | Memory (currentUserRx), Disk (SharedPrefs), CDN (avatar) | 1. CurrentUserService otomatik sync 2. Yeni avatar URL → eski cache'i invalidate etmeye gerek yok (yeni URL) | Dusuk | Profil sayfasi 3sn icinde guncellenmis gosterir |
| Avatar degisimi | Upload + Firestore update | CDN (eski avatar URL), Memory (ImageCache) | 1. Yeni URL ile upload 2. Eski URL CDN'de kalir (zarar yok, ulasilamaz) 3. `imageCache.evict(oldUrl)` | Dusuk | Yeni avatar tum ekranlarda gorunur |
| Post edit/delete | Firestore update/delete | Memory (feed list), Disk (feed cache) | 1. Realtime listener veya pull-refresh ile guncelle 2. `deletedPost: true` flag (soft delete) | Orta (stale feed riski) | Feed'de 5sn icinde guncellenir |
| Like/comment sayac | FieldValue.increment | Memory (sayac), Disk (feed summary) | 1. Optimistic update (local +1) 2. Server confirm 3. Drift fix (haftalik cron) | Dusuk | Anlık UI guncelleme |
| Follow/block | Firestore batch | Memory (follower list, feed filter), Disk | 1. Optimistic update 2. Feed'den bloklanan kullaniciyi filtrele 3. SWR ile arka planda sync | Orta (bloklanan kullanici gecici gorunebilir) | Bloklanan icerik 3sn icinde kaybolur |
| Permission/role degisimi | Firestore update | Memory (currentUser), **TUM cache** | 1. `forceRefresh()` 2. Feed/liste cache temizle 3. Yeniden yukle | **YUKSEK** (guvenlik) | Aninda etkili, stale data 0 |
| Egitim icerik guncelleme | Firestore update | Memory (liste), Disk (summary cache) | 1. Pull-refresh 2. SWR arka plan guncelleme | Dusuk | Sonraki sayfa acilisinda guncel |
| Cevap anahtari (kritik) | Firestore update | Memory, Disk | 1. ASLA cache'leme 2. Her zaman fresh fetch 3. `GetOptions(source: Source.server)` | **YUKSEK** (kopya riski) | Her zaman server'dan |

### Invalidation Standart Kurallari

```dart
abstract class CacheInvalidationRules {
  // ASLA cache'lenmeyen icerikler (guvenlik kritik):
  static const neverCache = ['exam_answers', 'payment_data', 'admin_actions'];

  // Kisa TTL (1-5 dk):
  static const shortTTL = ['feed_summary', 'explore', 'search_results'];

  // Orta TTL (10-30 dk):
  static const mediumTTL = ['user_profile', 'education_lists', 'job_lists'];

  // Uzun TTL (1-7 gun):
  static const longTTL = ['current_user', 'settings', 'static_content'];

  // Immutable (sonsuza dek):
  static const immutable = ['media_files', 'hls_segments', 'uploaded_images'];
}
```

---

## 6) MALIYET (FinOps) - Cache ile Tasarruf

### En Pahali 10 Pattern

| # | Pattern | Tahmini Maliyet/Ay | Cache Cozumu | Tahmini Tasarruf |
|---|---------|-------------------|-------------|-----------------|
| 1 | **Gorsel CDN egress (cache-control yok)** | Yuksek (her istek origin'e gidiyor) | cacheControl ekleme | %70-80 egress azalma |
| 2 | **Feed listener her acilista** | Orta (30+ read/kullanici/acilis) | Pull + SWR, 5dk TTL | %60 read azalma |
| 3 | **Ayni gorsel farkli boyutlarda indirilme** | Orta (oversize image download) | Multi-resolution upload | %50 bandwidth azalma |
| 4 | **Profil sayfasi N+1 query** | Orta (profilin her post'u icin user fetch) | users_public denormalizasyon | %80 read azalma |
| 5 | **emailVerify tekrar sorgu** | Dusuk (her init'te 2-3 read) | 5dk cache, flag | %90 read azalma |
| 6 | **Egitim listeleri realtime listener** | Orta (surekli bagli) | Pull + pagination | %70 read azalma |
| 7 | **adminConfig her init** | Dusuk (1 read/init) | Remote Config | %100 read azalma |
| 8 | **Search history tekrar fetch** | Dusuk | Local cache (SharedPrefs) | %100 read azalma |
| 9 | **Video segment tekrar indirme** | Dusuk (proxy cache var) | Zaten cozulmus | N/A |
| 10 | **Ayni kullanici profili tekrar fetch** | Orta | In-memory LRU (100 entry, 10dk) | %60 read azalma |

### Listener Azaltma Tasarruf Hesabi

**Varsayim:** 10K DAU, ortalama 5 sayfa/oturum, her sayfada 2 listener.

**Mevcut:** 10K × 5 × 2 = 100K listener baglantisi/gun → surekli read
**Hedef:** Sadece chat + currentUser listener = 10K × 2 = 20K listener/gun

**Tahmini read azalma:** %80 → **Firestore okuma maliyeti %80 duser**

### CDN Hit Ratio Artirma

| Degisiklik | Mevcut Hit | Hedef Hit | Egress Azalma |
|-----------|-----------|-----------|---------------|
| Gorsel cacheControl ekle | ~%20 | %90+ | %70 |
| Multi-resolution gorsel | N/A | %95+ | %50 (daha kucuk dosyalar) |
| HLS (zaten iyi) | ~%85 | %95+ | %10 |

### Video ABR + Data Saver Bandwidth Azaltma

| Senaryo | Ortalama Bitrate | Data Saver ile | Tasarruf |
|---------|-----------------|---------------|---------|
| Wi-Fi | 2800kbps (720p) | 1400kbps (480p) | %50 |
| Cellular | 1400kbps (480p) | 800kbps (360p) | %43 |

---

## 7) OBSERVABILITY - Cache Telemetry Standardi

### Mobil Telemetry

| Event Adi | Payload | Ornek Deger | Alarm Esigi (SLO) |
|-----------|---------|-------------|-------------------|
| `image_cache_hit` | `{url_hash, source: memory/disk/network, size_kb, latency_ms}` | `{source: "disk", size_kb: 45, latency_ms: 12}` | hit_rate < %70 |
| `image_cache_miss` | `{url_hash, size_kb, latency_ms, network_type}` | `{size_kb: 120, latency_ms: 350, network: "wifi"}` | miss_rate > %50 |
| `data_cache_hit` | `{collection, source: memory/disk/firestore_cache/server}` | `{collection: "Posts", source: "memory"}` | server_ratio > %40 |
| `data_cache_miss` | `{collection, doc_count, latency_ms}` | `{collection: "Posts", doc_count: 30, latency_ms: 800}` | latency_ms > 2000 |
| `video_cache_hit` | `{doc_id, segment_key, size_bytes}` | Zaten `CacheMetrics`'te var | hit_rate < %80 |
| `video_cache_miss` | `{doc_id, segment_key, size_bytes, latency_ms}` | Zaten `CacheMetrics`'te var | miss_rate > %30 |
| `cache_eviction` | `{layer: image/video/data, count, freed_mb}` | `{layer: "video", count: 3, freed_mb: 150}` | count > 50/saat |
| `cache_size` | `{layer, size_mb, entry_count}` | `{layer: "video", size_mb: 2100, entry_count: 45}` | size_mb > hard_limit * 0.9 |
| `tti_feed` | `{warm, ms, network_type}` | `{warm: true, ms: 380, network: "wifi"}` | warm > 500ms, cold > 1500ms |
| `scroll_jank` | `{fps, jank_frame_count, total_frames, screen}` | `{fps: 58, jank: 3, total: 1800, screen: "feed"}` | jank_ratio > %5 |
| `memory_pressure` | `{used_mb, total_mb, image_cache_mb}` | `{used_mb: 180, total_mb: 300}` | used_mb > 250 |
| `network_p95_latency` | `{endpoint, ms, retry_count}` | `{endpoint: "cdn_image", ms: 450, retries: 0}` | ms > 1000 |

### Backend/CDN Telemetry

| Metrik | Kaynak | Ornek | Alarm |
|--------|--------|-------|-------|
| CDN hit ratio | Cloudflare Analytics | %89 | < %80 |
| Origin fetch rate | Cloudflare Analytics | 1.2K req/dk | > 5K req/dk |
| p95 function latency | Firebase Performance | 320ms | > 1000ms |
| Function error rate | Cloud Functions logs | %0.3 | > %2 |
| Cache purge count | Custom metric | 5/gun | > 50/gun |
| Storage egress GB | Firebase Console | 15GB/gun | > 50GB/gun |

---

## 8) UYGULANABILIR BACKLOG

### FAZ 0: Quick Wins (0-7 gun)

| ID | Baslik | Adimlar | Impact | Effort | Risk | Done |
|----|--------|---------|--------|--------|------|------|
| C-001 | **Gorsel upload'a cacheControl ekle** | `webp_upload_service.dart:51` ve tum `putData` cagrilarina `cacheControl: 'public, max-age=31536000, immutable'` ekle | CDN hit %20→%90+ | 1 saat | Yok | Cloudflare Analytics hit ratio >%80 |
| C-002 | **Image CacheManager ozellesir** | `TurqImageCacheManager` sinifi, 2000 dosya, 30 gun stale | Gorsel disk hit %50→%85 | 2 saat | Yok | Warm acilista gorsel aninda yukle |
| C-003 | **Feed listener → pull + SWR** | `agenda_controller.dart`'ta `.snapshots()` → `.get()` + refresh button + arka plan guncelleme | Read %60 azalma | 1 gun | Dusuk | Feed acilisinda `.get()` log |
| C-004 | **ImageCache boyut artir** | `PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;` | Memory hit artisi | 30 dk | Yok | imageCache.currentSizeBytes log |
| C-005 | **memCacheWidth tum listelere** | Feed, explore, profil grid'deki CachedNetworkImage'lara `memCacheWidth` ekle | Bellek %30 azalma, jank azalma | 3 saat | Yok | Jank frame counter |
| C-006 | **Feed gorsel prefetch** | Scroll pozisyonuna gore sonraki 5 item'in gorselini indir | Scroll sirasinda gorsel hazir | 3 saat | Yok | image_cache_hit rate artisi |
| C-007 | **fadeInDuration sifirla** | Cache hit durumunda fade animasyonu gereksiz → `Duration.zero` | UX iyilesmesi | 1 saat | Yok | Gorsel aninda gorunur |

### FAZ 1: Mimari Duzen (1-4 hafta)

| ID | Baslik | Adimlar | Impact | Effort | Risk | Done |
|----|--------|---------|--------|--------|------|------|
| C-100 | **SWR altyapisi** | Generic `SWRController<T>` mixin: once cache goster, arka planda guncelle, TTL yonetimi | Tum feed/liste ekranlarinda uygulanabilir pattern | 3 gun | Dusuk | 5+ controller'da kullanilir |
| C-101 | **Egitim listeleri pull'a cevir** | `tutoring_controller`, `deneme_sinavlari_controller`, `answer_key_controller`, `scholarships_controller` listener'larini .get()'e cevir | Read %70 azalma | 2 gun | Dusuk | Listener sayisi 134→<50 |
| C-102 | **feed_summary denormalizasyon** | 1. `feed_summaries/{docID}` collection olustur 2. Post yaziminda fan-out 3. Feed'de summary'den oku | Feed read 30→1 | 1 hafta | Orta (migration) | Feed sayfasi 1 query |
| C-103 | **Multi-resolution gorsel** | Upload sirasinda 3 boyut uret (small/medium/original), URL pattern standartlastir | Bandwidth %50, gorsel hiz %60 artis | 1 hafta | Orta | 3 URL post model'de |
| C-104 | **Dio + cache interceptor** | `http` → `dio` + `DioCacheInterceptor` (ETag, If-None-Match destegi) | Tekrar network istekleri %40 azalma | 3 gun | Dusuk | HTTP cache hit log |
| C-105 | **Firestore cacheSizeBytes** | `Settings(cacheSizeBytes: 200 * 1024 * 1024)` | Offline deneyim iyilesmesi | 30 dk | Yok | Offline mod test |
| C-106 | **users_public collection** | Diger kullanicilarin mini profili icin denormalize collection | Profil/feed user fetch %80 azalma | 3 gun | Orta (migration) | user_public doc okumalari |
| C-107 | **RepaintBoundary liste itemlari** | Feed, explore, shorts liste item'larina RepaintBoundary ekle | Scroll jank %30-50 azalma | 2 gun | Yok | jank frame counter |

### FAZ 2: Instagram Seviyesi (1-3 ay)

| ID | Baslik | Adimlar | Impact | Effort | Risk | Done |
|----|--------|---------|--------|--------|------|------|
| C-200 | **Data Saver modu** | Network-aware rendition secimi, autoplay politikasi, gorsel kalite dusurme | Cellular bandwidth %40 azalma | 1 hafta | Dusuk | Ayarlar sayfasinda toggle |
| C-201 | **Video preload gelismis** | Bir sonraki videonun ilk segment'i + thumbnail'i birlikte prefetch | TTFF 500ms→<300ms | 3 gun | Dusuk | TTFF metrik |
| C-202 | **Isar disk cache** | Feed summary, user profile icin Isar veritabani | Cold start 2s→<1s | 2 hafta | Orta | Cold start TTI metrik |
| C-203 | **Cache observability dashboard** | Tum cache metriklerini Firestore'a yazma + basit admin dashboard | SLO takibi | 1 hafta | Dusuk | Dashboard canli |
| C-204 | **Counter drift fix cron** | Haftalik Cloud Function: gercek like/comment sayisini hesapla | Veri butunlugu | 2 gun | Dusuk | Drift <1% |
| C-205 | **Cloudflare KV feed cache** | Populer feed'leri edge'de serv etme (Worker + KV) | Feed p95 latency %80 dusus | 2 hafta | Orta (yeni infra) | KV hit ratio |
| C-206 | **Cloudflare Image Resizing** | Pro plan + edge resize (w, q, f parametreleri) | Origin egress %90 azalma | 1 hafta | Dusuk (plan gerekli) | cf-resized header |
| C-207 | **Cache warming pipeline** | App acilisinda kritik verileri arka planda indir (profil, feed ozet, ayarlar) | Warm hit rate %70→%90 | 3 gun | Dusuk | Warm hit rate metrik |

---

## 9) CIKTI FORMATI

### A) Risk Analizi - Top 15 Cache Sorunu

| # | Sorun | Severity | Etki | Cozum ID |
|---|-------|----------|------|----------|
| 1 | **Gorsellerde cacheControl metadata yok** | KRITIK | CDN hic cache'leyemiyor, her istek origin'e | C-001 |
| 2 | **Feed realtime listener gereksiz kullanim** | YUKSEK | Surekli Firestore read, maliyet + gecikme | C-003, C-101 |
| 3 | **Tek cozunurluk gorsel** | YUKSEK | Oversize indirme, bandwidth israf | C-103 |
| 4 | **Image CacheManager varsayilan (200 dosya)** | YUKSEK | Sik eviction, tekrar indirme | C-002 |
| 5 | **SWR pattern yok** | YUKSEK | Her acilista fresh fetch, yavas warm start | C-100 |
| 6 | **Feed summary/detail ayrimi yok** | ORTA | Buyuk doc okuma, gereksiz bandwidth | C-102 |
| 7 | **HTTP cache interceptor yok** | ORTA | Her HTTP istegi fresh | C-104 |
| 8 | **Gorsel prefetch yok** | ORTA | Scroll sirasinda gorsel yukleme gecikmesi | C-006 |
| 9 | **Data saver modu yok** | ORTA | Cellular'da gereksiz data kullanimi | C-200 |
| 10 | **Cache telemetry/observability eksik** | ORTA | Sorunlari tespit edememe | C-203 |
| 11 | **users_public denormalizasyon yok** | ORTA | Her baska profil icin full user doc okuma | C-106 |
| 12 | **Firestore cacheSizeBytes belirsiz** | DUSUK | Varsayilan 100MB yeterli olmayabilir | C-105 |
| 13 | **memCacheWidth kullanilmiyor** | DUSUK | Gereksiz bellek tuketimi | C-005 |
| 14 | **RepaintBoundary eksik** | DUSUK | Liste scroll jank | C-107 |
| 15 | **emailVerify tekrar sorgu** | DUSUK | Gereksiz 2-3 read/init | C-003 alt gorev |

### B) Onerilen Cache Mimarisi

```
[Kullanici Istegi]
     |
     v
[In-Memory LRU Cache] ← TTL bazli (5dk feed, 10dk profil, 30dk settings)
  hit? → Goster (aninda)
  miss? ↓
[Disk Cache Layer]
  - Isar: feed_summary, user_profile (yapisal, sorgulanabilir)
  - flutter_cache_manager: gorseller (2000 dosya, 30 gun)
  - SegmentCacheManager: HLS video (3GB, index.json)
  - SharedPreferences: current_user, settings
  hit? → Goster + arka planda SWR
  miss? ↓
[CDN (Cloudflare)]
  - Gorseller: immutable, 1 yil (cacheControl ile)
  - HLS segment: immutable, 1 yil
  - HLS playlist: 5dk-1gun
  hit? → Indir → Disk + Memory cache'e yaz
  miss? ↓
[Origin (Firebase Storage / Firestore)]
  → Indir → Tum katmanlara yaz
```

### C) Ekran Bazli Cache Politikalari

| Ekran | Memory TTL | Disk TTL | CDN | Invalidation | Refresh |
|-------|-----------|---------|-----|-------------|---------|
| Feed | 5dk | 1 saat | Gorsel: immutable | Post edit/delete tetikler | Pull-to-refresh |
| Profil | 10dk | 1 gun | Avatar: immutable | Profil update tetikler | Sayfa acilis |
| Egitim listeleri | 10dk | 1 gun | Gorsel: immutable | Icerik update | Pull-to-refresh |
| Video player | Oturum | 3GB disk | Segment: immutable | N/A (immutable) | N/A |
| Chat | Realtime | Firestore offline | N/A | Realtime listener | Otomatik |
| Arama | 2dk | 30dk | N/A | Her yeni arama | Yeni arama |

### D) Invalidation Playbook

Bolum 5'te detayli. Ozet:
1. **Guvenlik kritik:** ASLA cache'leme (sinav cevaplari, admin islemleri)
2. **Kisa omurlu:** 1-5dk TTL + SWR (feed, arama)
3. **Orta omurlu:** 10-30dk TTL + event-driven invalidation (profil, listeler)
4. **Immutable:** Sonsuza dek (medya dosyalari, segmentler)

### E) Telemetry Plani

Bolum 7'de detayli. Ozet:
- **12 mobil event** (cache hit/miss, TTI, jank, memory, network)
- **6 backend metrik** (CDN hit, function latency, error rate)
- **SLO alarmlari** (otomatik bildirim esikleri)

### F) Backlog Ozeti

| Faz | Sure | Kac is | En onemli 3 |
|-----|------|--------|-------------|
| Faz 0 (Quick wins) | 0-7 gun | 7 is | C-001 (cacheControl), C-003 (feed pull), C-002 (CacheManager) |
| Faz 1 (Mimari) | 1-4 hafta | 8 is | C-100 (SWR), C-102 (feed_summary), C-103 (multi-res gorsel) |
| Faz 2 (Instagram) | 1-3 ay | 8 is | C-200 (data saver), C-202 (Isar), C-205 (KV cache) |

### G) "Instagram Hissi" icin Kritik 10 Madde

| # | Madde | KPI | Hedef | Ilgili Backlog |
|---|-------|-----|-------|---------------|
| 1 | **Gorsel aninda yuklensin** (warm) | Image cache hit | >%85 | C-001, C-002, C-006 |
| 2 | **Feed acilisinda icerik hazir** (warm) | Feed TTI | <500ms | C-003, C-100, C-102 |
| 3 | **Scroll sirasinda hic takılma yok** | Jank ratio | <%5 | C-005, C-007, C-107 |
| 4 | **Video baslasin, buffering olmasin** | Video TTFF | <400ms | Video cache zaten iyi |
| 5 | **Profil sayfasi aninda acilsin** | Profil TTI | <300ms | C-100, C-106 |
| 6 | **Offline'da feed gorunsun** | Offline feed | Son 30 post | C-102, C-105, C-202 |
| 7 | **Cellular'da az data harcasin** | Monthly data | <%500MB | C-103, C-200 |
| 8 | **Thumbnail once, HD sonra** | Progressive load | <100ms placeholder | C-103 |
| 9 | **Tab degistirince tekrar yukleme yok** | Tab switch TTI | 0ms (cache) | C-100 (SWR) |
| 10 | **Uygulamayi tekrar acinca hizli** | Cold start TTI | <1.5s | C-202, C-207 |

---

## VARSAYIMLAR

1. **Cloudflare plani:** Free veya Pro. Image Resizing icin Pro+ gerekli.
2. **DAU:** ~10K (maliyet hesaplari buna gore). Buyurse CDN optimizasyonlari daha kritik.
3. **Ortalama gorsel boyutu:** 100-300KB (WebP q85). Multi-resolution ile medium 30-80KB olur.
4. **Ortalama video suresi:** 30-60sn. ABR 720p icin ~5-10MB/video.
5. **Firestore pricing:** Okuma $0.06/100K, Yazma $0.18/100K (varsayilan bolge).
6. **Firebase Storage egress:** $0.12/GB (ilk 1GB/gun ucretsiz).
7. **Kullanici oturum suresi:** ~15-20dk/gun ortalama.
8. **SharedPreferences gorsel cache'i DESTEKLEMEZ** — sadece primitif degerler icin.
9. **Firestore offline persistence varsayilan acik** (Flutter SDK'da default).
10. **Mevcut `http` paketi** dio ile degistirilebilir (pubspec'te zaten `dio: ^5.9.1` var).
