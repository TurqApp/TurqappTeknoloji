# TurqApp Video & Streaming Performans Denetim Raporu
## Staff-Level Engineering Audit — Mart 2026

---

# 0) GLOBAL HEDEF METRİKLER & TELEMETRİ PLANI

## Mevcut Durum vs Hedef

| Metrik | Mevcut (Tahmini) | Hedef | Gap |
|--------|----------|-------|-----|
| TTFF (warm cache) | ~800-1200ms | <400ms | KRİTİK |
| TTFF (cold) | ~2-4s | <1.5s | YÜKSEK |
| Scroll autoplay start | ~500-800ms | <300ms | YÜKSEK |
| Buffering oranı | ~3-5% | <%1 | KRİTİK |
| Rebuffer süresi | ~300-500ms | <100ms | YÜKSEK |
| ABR adaptasyon | Yok (single rendition) | <1 segment | KRİTİK |
| Bellek (feed scroll) | ~200-300MB | <150MB | ORTA |
| Feed FPS | ~45-55fps | 60fps | ORTA |
| Cold start → content | ~2-3s | <1.5s | ORTA |

## Telemetri Event Tasarımı

```dart
// Firebase Analytics Custom Events
class VideoTelemetry {
  // TTFF: loadVideo() çağrısı → ilk "ready" event arası
  static void trackTTFF(String docID, Duration ttff, {
    required bool isCacheHit,
    required String networkType, // wifi/cellular
    required int segmentsCached,
  }) {
    FirebaseAnalytics.instance.logEvent(
      name: 'video_ttff',
      parameters: {
        'doc_id': docID,
        'ttff_ms': ttff.inMilliseconds,
        'cache_hit': isCacheHit ? 1 : 0,
        'network': networkType,
        'segments_cached': segmentsCached,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
  }

  // Rebuffer: "buffering:true" → "buffering:false" arası
  static void trackRebuffer(String docID, Duration rebufferDuration, {
    required Duration position,
    required String networkType,
  }) {
    FirebaseAnalytics.instance.logEvent(
      name: 'video_rebuffer',
      parameters: {
        'doc_id': docID,
        'rebuffer_ms': rebufferDuration.inMilliseconds,
        'position_s': position.inSeconds,
        'network': networkType,
      },
    );
  }

  // Session: oynatma bittiğinde/ayrılırken
  static void trackSession(String docID, {
    required Duration watchDuration,
    required Duration totalDuration,
    required int rebufferCount,
    required int droppedFrames,
    required double averageBitrateMbps,
    required String networkType,
  }) {
    FirebaseAnalytics.instance.logEvent(
      name: 'video_session',
      parameters: {
        'doc_id': docID,
        'watch_s': watchDuration.inSeconds,
        'total_s': totalDuration.inSeconds,
        'rebuffers': rebufferCount,
        'dropped_frames': droppedFrames,
        'avg_bitrate_kbps': (averageBitrateMbps * 1000).round(),
        'completion_pct': totalDuration.inMilliseconds > 0
          ? (watchDuration.inMilliseconds / totalDuration.inMilliseconds * 100).round()
          : 0,
        'network': networkType,
      },
    );
  }

  // Player error
  static void trackError(String docID, String errorCode, String message) {
    FirebaseAnalytics.instance.logEvent(
      name: 'video_error',
      parameters: {
        'doc_id': docID,
        'error_code': errorCode,
        'message': message.substring(0, min(100, message.length)),
      },
    );
  }
}
```

### Ölçüm Noktaları (Instrumentation Points)

| Metrik | Başlangıç | Bitiş | Dosya |
|--------|-----------|-------|-------|
| TTFF | `loadVideo()` çağrısı | İlk `"ready"` event | `hls_controller.dart` → `HLSPlayerView.swift:233` / `ExoPlayerView.kt:126` |
| Rebuffer | `"buffering": true` | `"buffering": false` | Event channel stream listener |
| Scroll autoplay | `onPageChanged()` | İlk `"play"` event | `short_view.dart:100` → native event |
| Dropped frames | iOS: `AVPlayerItemAccessLog` / Android: `DecoderCounters` | Per-session | Native code eklenmeli |
| Bellek | `ProcessInfo.processInfo.physicalFootprint` / `Debug.getNativeHeapSize()` | Periyodik (30s) | Yeni service |

---

# 1) HLS MİMARİ DENETİMİ

## 1.1 KRİTİK BULGU: Tek Rendition — ABR Yok

**Dosya:** `functions/src/hlsTranscode.ts:243-310`

**Sorun:** ffmpeg tek bir quality ile transcode ediyor. Master playlist sadece 1 variant stream içeriyor. Bu Instagram/X'te olmayan ciddi bir eksiklik:
- Zayıf ağda → video durur (downshift yapamaz)
- Güçlü ağda → kalite düşük kalır (upshift yapamaz)
- Buffering oranı artıyor

**Mevcut:**
```
master.m3u8
  └── seg_000.ts, seg_001.ts ... (tek quality, CRF 23)
```

**Hedef ABR Ladder:**
```
master.m3u8
  ├── 360p/playlist.m3u8  →  360p  @  800kbps  (mobil veri, zayıf sinyal)
  ├── 480p/playlist.m3u8  →  480p  @ 1500kbps  (mobil veri, normal)
  ├── 720p/playlist.m3u8  →  720p  @ 3000kbps  (wifi, default)
  └── 1080p/playlist.m3u8 → 1080p  @ 5000kbps  (wifi, yüksek kalite)
```

**Önerilen ffmpeg Komutu (Multi-rendition):**
```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split=4[v1][v2][v3][v4]; \
    [v1]scale=640:360[v360]; \
    [v2]scale=854:480[v480]; \
    [v3]scale=1280:720[v720]; \
    [v4]scale=1920:1080[v1080]" \
  -map "[v360]" -map 0:a -c:v libx264 -profile:v baseline -level 3.1 \
    -b:v 800k -maxrate 960k -bufsize 1600k -r 30 -g 60 -c:a aac -b:a 64k \
    -hls_time 4 -hls_list_size 0 -hls_playlist_type vod \
    -hls_segment_filename "360p/seg_%03d.ts" 360p/playlist.m3u8 \
  -map "[v480]" -map 0:a -c:v libx264 -profile:v main -level 3.1 \
    -b:v 1500k -maxrate 1800k -bufsize 3000k -r 30 -g 60 -c:a aac -b:a 96k \
    -hls_time 4 -hls_list_size 0 -hls_playlist_type vod \
    -hls_segment_filename "480p/seg_%03d.ts" 480p/playlist.m3u8 \
  -map "[v720]" -map 0:a -c:v libx264 -profile:v main -level 4.0 \
    -b:v 3000k -maxrate 3600k -bufsize 6000k -r 30 -g 60 -c:a aac -b:a 128k \
    -hls_time 4 -hls_list_size 0 -hls_playlist_type vod \
    -hls_segment_filename "720p/seg_%03d.ts" 720p/playlist.m3u8 \
  -map "[v1080]" -map 0:a -c:v libx264 -profile:v high -level 4.1 \
    -b:v 5000k -maxrate 6000k -bufsize 10000k -r 30 -g 60 -c:a aac -b:a 128k \
    -hls_time 4 -hls_list_size 0 -hls_playlist_type vod \
    -hls_segment_filename "1080p/seg_%03d.ts" 1080p/playlist.m3u8 \
  -master_pl_name master.m3u8
```

**Etki:** Buffering oranı %3-5 → <%1, TTFF ~%30 iyileşme (360p ilk segment çok küçük)

## 1.2 Segment Süresi Analizi

**Dosya:** `functions/src/hlsTranscode.ts:209-210`

**Mevcut:** `segment1=2s` (ilk segment), `segment2=6s` (geri kalan)

**Sorun:** 6 saniyelik segmentler çok büyük:
- TTFF yüksek: oynatıcı 6s'lik segment indirene kadar bekler
- Granüler ABR mümkün değil: adaptasyon 6s'de bir
- Seek hassasiyeti düşük

**Öneri:**
```
segment1 = 2s (ilk segment — hızlı başlangıç, MEVCUT)
segment2 = 4s (geri kalan — 6s'den düşür)
```

**Gerekçe:**
- 4s segment: ~300-750KB @720p → 300ms indirme @4Mbps
- Daha hızlı ABR adaptasyonu
- Apple HLS authoring spec: 6s önerir ama Instagram/X/YouTube 2-4s kullanır
- **Trade-off:** Daha fazla HTTP request, ama CDN keep-alive ile ihmal edilebilir

## 1.3 Keyframe Interval

**Dosya:** `functions/src/hlsTranscode.ts:270-279`

**Mevcut:** `GOP = segment2 * 30` (6*30=180 frame) — segment sınırına hizalı, doğru.

**Segment 4s'e düşürülünce:** `GOP = 4 * 30 = 120 frame` — güncellenmeli.

**Ek öneri:** `-force_key_frames "expr:gte(t,n_forced*4)"` kullanarak her segment başına keyframe garanti et.

## 1.4 Low-Latency HLS (LL-HLS)

**Sonuç:** Gerekli değil. TurqApp VOD içerik sunuyor (feed, hikaye). LL-HLS live streaming için tasarlanmış, burada overhead eklenmesi gereksiz. Mevcut VOD playlist tipi doğru.

## 1.5 CDN Cache-Control Header Önerisi

**Mevcut:** Storage rules ile public read izni var, ama explicit cache header yok.

**Önerilen Cloudflare Page Rules / Transform Rules:**

```
# HLS segments (immutable — hash/index ile adlandırılmış)
Match: *.ts
Cache-Control: public, max-age=31536000, immutable
CDN Cache TTL: 1 year

# HLS playlists (VOD — değişmez ama yeni video eklenebilir)
Match: *.m3u8
Cache-Control: public, max-age=86400
CDN Cache TTL: 24 hours

# Thumbnails
Match: */thumbnail.jpg OR */thumbnail.webp
Cache-Control: public, max-age=604800
CDN Cache TTL: 7 days
```

**HLS Proxy zaten doğru yapıyor** (`hls_proxy_server.dart`): Cache hit'te `Cache-Control: public, max-age=31536000, immutable` dönüyor.

## 1.6 Signed URL Stratejisi

**Mevcut:** Storage rules ile public read izni + CDN CNAME. Signed URL yok.

**Öneri (Faz 2):**
- HLS segment'leri için Cloudflare Signed URLs (HMAC)
- Token 24h TTL + IP binding
- Master playlist URL'de token, segment URL'ler relative (token inherit)

## 1.7 Segment Prefetch

**Mevcut:** Mükemmel. `prefetch_scheduler.dart` breadth-first strateji ile çalışıyor:
- Wi-Fi: 10 video × 3 segment + 5 video full cache
- Cellular: 5 video × 2 segment + 3 video

**İyileştirme:** ABR ile birlikte, prefetch'te 360p segmentleri önceliklendir (hızlı start garantisi), sonra 720p upgrade yap.

## 1.8 Thumbnail Sprite / Preview

**Mevcut:** Sadece JPEG thumbnail (1. saniyeden tek frame). Video sprite/preview yok.

**Öneri:**
```bash
# Her 2 saniyeden 1 sprite frame üret (seek preview için)
ffmpeg -i input.mp4 -vf "fps=0.5,scale=160:90,tile=10x10" sprite_%d.jpg
```
- Grid sprite: 160×90px, 10×10 tile = 100 frame per image
- Seek bar üzerinde preview göster (Instagram tarzı)
- WebVTT dosyası ile timing eşleştir

---

# 2) iOS AVPlayer PERFORMANS OPTİMİZASYONU

## 2.1 preferredForwardBufferDuration

**Dosya:** `ios/Runner/HLSPlayerView.swift:96`

**Mevcut:** `preferredForwardBufferDuration = 6.0`

**Sorun:** 6s forward buffer çok yüksek:
- 720p@3Mbps ile 6s = ~2.25MB buffer → TTFF'yi artırır
- Kullanıcı genellikle Short video'da 3-5s izler, 6s buffer israf

**Öneri — Dinamik buffer:**
```swift
// Aktif video: 3s (hızlı start)
// Komşu video (preload): 1.5s (minimal buffer)
func setPreferredBufferDuration(_ duration: Double) {
    playerItem?.preferredForwardBufferDuration = duration
}

// Dart tarafında zaten var (short_controller.dart:41-46):
// _activeBufferSeconds = 3.0 (iOS), 2.4 (Android)
// _neighborBufferSeconds = 2.4, _prepBufferSeconds = 2.1
```

**Ancak:** Dart tarafındaki buffer değerleri `setPreferredBufferDuration` ile native'e iletiliyor mu? Kontrol edilmeli.

**Eylem:** `hls_controller.dart`'ta `setBufferDuration()` method channel çağrısının bulunduğunu doğrula ve `loadVideo` sonrası dynamic buffer'ı set et.

## 2.2 automaticallyWaitsToMinimizeStalling

**Dosya:** `HLSPlayerView.swift:101`

**Mevcut:** `player?.automaticallyWaitsToMinimizeStalling = true`

**Sorun:** Bu `true` olduğunda AVPlayer başlangıçta yeterli buffer dolana kadar bekler. Bu TTFF'yi artırır.

**Öneri:**
```swift
// Hızlı start: false yap, kendi buffer management'ımız var
player?.automaticallyWaitsToMinimizeStalling = false
// Proxy server zaten cache-first çalışıyor, segment hazır olduğunda oynatıcı hemen başlasın
```

**Etki:** TTFF ~200-400ms iyileşme (warm cache durumunda)

## 2.3 AVPlayerItem Preload Stratejisi

**Mevcut:** Her yeni video için `AVPlayerItem` + `AVPlayer` oluşturuluyor (`HLSPlayerView.swift:90-100`).

**Sorun:** Player oluşturma + asset hazırlama ~200-400ms

**Öneri — AVPlayerItem Pre-creation:**
```swift
// Bir sonraki videonun AVPlayerItem'ını önceden oluştur
class PreloadedItem {
    let item: AVPlayerItem
    let docID: String

    init(url: URL, docID: String) {
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false // Preload'da hassasiyet gerekmez
        ])
        self.item = AVPlayerItem(asset: asset)
        self.item.preferredForwardBufferDuration = 1.5 // Minimal preload buffer
        self.docID = docID
    }
}
```

## 2.4 Player Reuse Stratejisi

**Mevcut:** `GlobalHLSPlayerManager.swift` singleton var ama kullanılmıyor.

**Sorun:** Her platform view yeni `AVPlayer` + `AVPlayerLayer` oluşturuyor. Scroll'da sürekli create/destroy = TTFF yüksek.

**Öneri:** GlobalHLSPlayerManager'ı aktive et:
```swift
// Tek AVPlayer instance, surface attach/detach
class GlobalHLSPlayerManager {
    static let shared = GlobalHLSPlayerManager()
    private var player: AVPlayer
    private var surfaces: [Int: AVPlayerLayer] = [:]

    func attachSurface(viewId: Int, layer: AVPlayerLayer) {
        layer.player = player
        surfaces[viewId] = layer
    }

    func detachSurface(viewId: Int) {
        surfaces[viewId]?.player = nil
        surfaces.removeValue(forKey: viewId)
    }

    func switchContent(url: URL, targetViewId: Int) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        // Sadece hedef view'a attach
    }
}
```

**Etki:** TTFF ~200ms iyileşme, bellek ~30-50MB tasarruf

## 2.5 Memory Leak Riski

**Dosya:** `HLSPlayerView.swift:66-68`

**Mevcut:** `deinit` içinde `cleanup()` çağrılıyor — iyi. KVO observer'lar `invalidate()` ile temizleniyor — doğru.

**Potansiyel risk:** `NotificationCenter.default.removeObserver(self)` (satır 399) tüm observer'ları kaldırıyor ama `addObserver(forName:object:queue:closure:)` ile eklenen token-based observer'lar zaten manuel kaldırılıyor (satır 383-396). **Çift temizlik zararsız ama gereksiz.**

**Gerçek risk:** `cleanup()` sonrası `eventSink` nil yapılmıyor (`stopPlayback` hariç). `dispose()` fonksiyonunda yapılıyor ama `stopPlayback()` → tekrar `loadVideo()` döngüsünde eski eventSink referansı kalabilir. **Düşük risk.**

## 2.6 Background/Foreground

**Dosya:** `HLSPlayerView.swift:350-356`

**Mevcut:** Background'a geçişte sadece pause. Foreground'da otomatik resume yok.

**İyileştirme:**
```swift
@objc private func appWillEnterForeground() {
    // Sadece şu an görünür olan video resume etmeli
    // Bu Dart tarafından kontrol ediliyor (VideoStateManager) — doğru yaklaşım
}
```

**Sorun yok** — Dart tarafındaki `VideoStateManager.pauseAllExcept()` zaten doğru yönetiyor.

---

# 3) Android ExoPlayer PERFORMANS OPTİMİZASYONU

## 3.1 LoadControl Analizi

**Dosya:** `ExoPlayerView.kt:93-102`

**Mevcut:**
```kotlin
minBufferMs = maxBufferMs * 0.5  // 7.5s (15s default)
maxBufferMs = 15000              // 15s
bufferForPlaybackMs = 1000       // 1s
bufferForPlaybackAfterRebufferMs = 2000  // 2s
```

**Sorun:** `bufferForPlaybackMs = 1000ms` iyi bir değer ama `minBufferMs = 7.5s` gereksiz yüksek.

**Öneri — Feed-optimized LoadControl:**
```kotlin
// Short video feed için aggressive configuration
val loadControl = DefaultLoadControl.Builder()
    .setBufferDurationsMs(
        2500,    // minBufferMs: 2.5s yeterli (segment sınırı koruması)
        8000,    // maxBufferMs: 8s (short video genellikle <60s)
        500,     // bufferForPlaybackMs: 0.5s → agresif hızlı start
        1500     // bufferForPlaybackAfterRebufferMs: 1.5s
    )
    .setPrioritizeTimeOverSizeThresholds(true) // Bellek yerine süre odaklı
    .build()
```

**Etki:** TTFF ~300ms iyileşme, bellek ~20-30MB tasarruf

## 3.2 CacheDataSourceFactory (Eksik)

**Dosya:** `ExoPlayerView.kt`

**Mevcut:** ExoPlayer doğrudan URL'den okuma yapıyor. Native Android cache katmanı YOK.

**Sorun:** Dart tarafındaki `HLSProxyServer` cache layer sağlıyor (localhost proxy), ama bu ekstra HTTP hop = latency.

**Öneri — ExoPlayer Native Cache:**
```kotlin
// SimpleCache ile native segment caching
private val cacheDir = File(context.cacheDir, "exo_hls_cache")
private val cache = SimpleCache(
    cacheDir,
    LeastRecentlyUsedCacheEvictor(256 * 1024 * 1024), // 256MB
    StandaloneDatabaseProvider(context)
)

private fun buildCacheDataSourceFactory(): DataSource.Factory {
    val upstreamFactory = DefaultHttpDataSource.Factory()
        .setConnectTimeoutMs(8000)
        .setReadTimeoutMs(8000)
    return CacheDataSource.Factory()
        .setCache(cache)
        .setUpstreamDataSourceFactory(upstreamFactory)
        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
}
```

**NOT:** Bu durumda Dart proxy'den doğrudan CDN URL'lere geçilebilir (Android'de). İki katmanlı cache gereksiz olur.

## 3.3 SurfaceView vs TextureView

**Dosya:** `ExoPlayerView.kt:41-50`

**Mevcut:** `PlayerView` kullanılıyor (default SurfaceView).

**Durum:** SurfaceView doğru seçim. TextureView GPU copy overhead ekler. PlayerView zaten SurfaceView kullanıyor.

**Potansiyel sorun:** PlatformView (Flutter) içinde SurfaceView, Android'de "Virtual Display" veya "Hybrid Composition" moduna bağlı:
- **Hybrid Composition:** SurfaceView OK ama z-order sorunları olabilir
- **Virtual Display:** Performans kaybı

**Kontrol edilmeli:** `ExoPlayerFactory.kt` veya `ExoPlayerPlugin.kt`'da `PlatformViewsServiceProxy` modu.

## 3.4 setKeepContentOnPlayerReset

**Dosya:** `ExoPlayerView.kt:45`

**Mevcut:** `setKeepContentOnPlayerReset(true)` — **Mükemmel.** Scroll sırasında son frame'i korur, siyah flash önler.

## 3.5 Soft Hold Pattern

**Dosya:** `ExoPlayerView.kt:191-200`

**Mevcut:** Scroll detach'te `softHold()` — pause + volume=0. **Akıllı çözüm.** Player'ı destroy etmeden tutuyor.

**İyileştirme:** softHold'da decoder'ları da serbest bırak:
```kotlin
fun softHold() {
    player?.let { p ->
        if (!isSoftHeld) heldVolume = p.volume
        p.playWhenReady = false
        p.volume = 0f
        // Codec kaynağını serbest bırak ama position'ı koru
        p.setVideoSurface(null) // GPU memory serbest
        isSoftHeld = true
    }
}

fun resumeFromHold() {
    player?.let { p ->
        playerView.player = p // Surface yeniden bağla
        p.volume = heldVolume
        p.playWhenReady = true
        isSoftHeld = false
    }
}
```

---

# 4) FLUTTER VIDEO KATMANI OPTİMİZASYONU

## 4.1 PlatformView Maliyeti

**Mevcut:** Her video için ayrı `UiKitView` (iOS) / `AndroidView` (Android) oluşturuluyor.

**Maliyet:**
- Her PlatformView ~2-5ms frame time ekler
- Feed'de 3-5 aynı anda görünürse: 10-25ms → 60fps'i zorlar

**Öneri — Texture Widget:**
```dart
// PlatformView yerine Texture widget kullan
// Native tarafta: player → SurfaceTexture → textureId
// Flutter: Texture(textureId: id)
// Avantaj: Compositing overhead yok, doğrudan GPU render
```

**Etki:** Frame time ~3-5ms iyileşme per video widget

## 4.2 Short Feed Scroll Mimarisi (Mevcut — İyi)

**Dosya:** `short_view.dart`, `short_controller.dart`

**Güçlü yanlar:**
- 3-katmanlı cache (HOT/WARM/COLD) — Instagram pattern'i
- Platform-specific player limitleri (Android: 5, iOS: 10)
- Debounced scroll (24ms Android, 60ms iOS)
- Momentum-based custom physics (1-4 sayfa fling)

**İyileştirme fırsatları:**

### 4.2.1 Scroll → Play gecikmesi
```dart
// short_view.dart:100-109 — Mevcut debounce
_scrollDebounce = Timer(
  defaultTargetPlatform == TargetPlatform.android
    ? Duration.zero        // Android: anında
    : Duration(milliseconds: 60),  // iOS: 60ms bekleme
  () => _schedulePlayForPage(currentPage),
);
```

**Sorun:** iOS'ta 60ms debounce + play komutu method channel'dan geçiyor (~5-10ms) + AVPlayer başlatma (~200ms) = ~270ms total.

**Öneri:** `_playDebounce`'u 30ms'ye düşür (50ms'den):
```dart
_playDebounce = Timer(Duration(milliseconds: 30), () { ... });
```

### 4.2.2 Widget Rebuild Azaltma

**Mevcut:** `RepaintBoundary` kullanılıyor (`agenda_view.dart:323`), `Obx` per-post granularity var.

**Ek öneri — short_content.dart için:**
```dart
// Video overlay (play button, progress bar) ayrı Obx
// Video player widget const veya key-based
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Video player — sadece URL değişince rebuild
      _VideoPlayerWidget(key: ValueKey(model.docID), adapter: adapter),
      // Controls — state değişince rebuild
      Obx(() => _ControlsOverlay(
        isPlaying: adapter.isPlaying,
        position: adapter.position,
      )),
    ],
  );
}
```

## 4.3 Preload Next Video

**Mevcut:** `backgroundPreload()` ilk 3 videoyu preload ediyor. `updateCacheTiers()` hot/warm/cold yönetiyor.

**İyileştirme — Proaktif AVPlayerItem oluşturma:**
```dart
// Scroll yönüne göre sonraki 1-2 video için native preload başlat
void _preloadNextNative(int direction) {
  final nextIdx = lastIndex.value + direction;
  if (nextIdx < 0 || nextIdx >= shorts.length) return;

  final adapter = cache[nextIdx];
  if (adapter != null && !adapter.isInitialized) {
    // Native tarafta AVPlayerItem/MediaItem oluştur ama play etme
    adapter.prepare(); // Yeni method: sadece prepare, play değil
  }
}
```

---

# 5) VIDEO CDN & NETWORK OPTİMİZASYONU

## 5.1 HTTP/3 (QUIC)

**Mevcut:** Cloudflare CDN — HTTP/3 Cloudflare tarafında otomatik desteklenir.

**İstemci tarafı:**
- iOS: `NSURLSession` HTTP/3 destekler (iOS 15+) — **otomatik**
- Android: ExoPlayer `DefaultHttpDataSource` → OkHttp backend ile HTTP/3 gerekir

**Öneri Android:**
```kotlin
// OkHttp + HTTP/3 backend
implementation("com.squareup.okhttp3:okhttp:4.12.0")
implementation("com.squareup.okhttp3:okhttp-brotli:4.12.0")

val okHttpClient = OkHttpClient.Builder()
    .protocols(listOf(Protocol.H2_PRIOR_KNOWLEDGE, Protocol.HTTP_1_1))
    .build()

val dataSourceFactory = OkHttpDataSource.Factory(okHttpClient)
```

## 5.2 TCP Slow Start

**Sorun:** Her yeni HTTP connection TCP slow start yaşar. HLS'de segment bazlı bağlantılar bunu tetikler.

**Çözümler:**
1. **Connection keep-alive:** Cloudflare zaten destekliyor
2. **Connection pooling:** iOS NSURLSession ve Android OkHttp otomatik
3. **HTTP/2 multiplexing:** Tek TCP connection üzerinden tüm segment'ler

**HLS Proxy'de:**
```dart
// hls_proxy_server.dart — Mevcut: her segment için yeni http.get()
// İyileştirme: Persistent HTTP client (zaten var: _httpClient field)
// Ama http package connection pooling için dio daha iyi:
final _dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 10),
))..httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () => HttpClient()
    ..maxConnectionsPerHost = 6
    ..idleTimeout = Duration(minutes: 2),
);
```

## 5.3 Segment Cache Süresi

**CDN Edge:**
- `.ts` segmentleri: 1 yıl (immutable content)
- `.m3u8` playlist: 24 saat (VOD, nadir değişir)
- Thumbnail: 7 gün

**İstemci disk cache:**
- Mevcut: 2.5-3GB soft/hard limit — **uygun**
- Eviction: Score-based (playing korumalı) — **mükemmel**

## 5.4 Egress Azaltma

**Stratejiler:**
1. ABR: Düşük kalitede başla, gerekirse yükselt → %40-60 egress azalma
2. Thumbnail-first: Video autoplay yerine thumbnail göster, tap'te play → %70 egress azalma (opsiyonel)
3. Wi-Fi aggressive prefetch + cellular cache-only: **mevcut** (`network_policy.dart`)
4. Watched video skip: `watchProgress > 50%` → sadece kalan segment'leri prefetch: **mevcut** (`prefetch_scheduler.dart:487`)

---

# 6) ANTI-ABUSE & GÜVENLİK

## 6.1 Hotlink Protection

**Mevcut:** YOK. HLS segment'leri public read (`storage.rules`). `cdn.turqapp.com` üzerinden herkes erişebilir.

**Öneri — Cloudflare Hotlink Protection:**
```
# Cloudflare → Scrape Shield → Hotlink Protection
# veya Worker ile Referer/Origin check

// Cloudflare Worker middleware
if (request.headers.get('Referer') &&
    !request.headers.get('Referer').includes('turqapp.com') &&
    !request.headers.get('Referer').includes('127.0.0.1')) {
  return new Response('Forbidden', { status: 403 });
}
```

## 6.2 Token Bazlı Stream Erişimi

**Öneri — Cloudflare Signed URLs:**
```typescript
// Cloud Function: Video URL isteğinde signed token üret
const token = crypto.createHmac('sha256', SECRET)
  .update(`${docID}:${userId}:${expiry}`)
  .digest('hex');

const signedUrl = `https://cdn.turqapp.com/Posts/${docID}/hls/master.m3u8?token=${token}&exp=${expiry}`;
```

## 6.3 Rate Limiting

**Öneri — Segment bazlı:**
```
# Cloudflare Rate Limiting Rule
# Path: *.ts
# Limit: 100 requests / 10 seconds per IP
# Action: Challenge (CAPTCHA)
```

## 6.4 Download Engelleme

**Mevcut:** HLS segmentleri .ts formatında — doğrudan indirilebilir.

**Öneri:**
1. Segment encryption (AES-128 veya SAMPLE-AES):
```bash
# ffmpeg ile AES-128 encrypted HLS
-hls_key_info_file keyinfo.txt
```
2. Key URL'yi token-protected yap
3. iOS: FairPlay DRM (enterprise seviye)

---

# 7) MALİYET OPTİMİZASYONU

## Hız vs Maliyet Matrisi

| Optimizasyon | Hız Kazanımı | Maliyet Etkisi | Öncelik |
|-------------|-------------|----------------|---------|
| ABR multi-rendition | TTFF -300ms, buffering -%80 | Storage +3x, transcode +4x | P0 |
| Segment 6s→4s | TTFF -100ms, ABR hızlanır | Segment sayısı +%50 (ihmal edilir) | P0 |
| automaticallyWaits=false | TTFF -200ms | $0 | P0 |
| ExoPlayer LoadControl tune | TTFF -200ms | $0 | P0 |
| Thumbnail WebP (JPEG→WebP) | Thumbnail load -40% | Egress -%30 thumbnail | P1 |
| 360p default start | TTFF -400ms | Egress -%50 first segment | P1 |
| Native cache (Android) | Proxy hop kaldır -50ms | $0 | P1 |
| GlobalPlayer reuse (iOS) | TTFF -200ms | Bellek -%30 | P1 |
| Wi-Fi aggressive cache | Rebuffer azalır | Egress artışı (Wi-Fi'da ucuz) | P2 |
| Sprite thumbnail | UX artışı | Storage +%1 | P2 |
| Signed URLs | $0 (güvenlik) | CDN cache hit azalabilir | P2 |
| AES-128 encryption | $0 (güvenlik) | CPU +%5 | P3 |

## En Pahalı Patternler

1. **Tek rendition 720p/1080p:** Her kullanıcı yüksek kalite çeker → CDN egress yüksek
2. **6s segment:** Büyük initial buffer → bandwidth israfı (kullanıcı 3s izleyip geçer)
3. **JPEG thumbnail:** WebP'ye göre ~%40 daha büyük
4. **Orijinal MP4 saklanması (posts):** Story'lerde siliniyor ama post'larda kalmaya devam ediyor

**Tahmini aylık tasarruf (ABR + 4s segment):**
- Kullanıcı başına ortalama %40 daha az egress
- 360p first segment ile ilk segment %75 küçülür

---

# 8) OBSERVABILITY & TELEMETRİ

## Mevcut Durum

**Dosya:** `cache_metrics.dart`

- Cache hit/miss tracking: **var**
- Download byte tracking: **var** (1MB batch)
- Player telemetry: **YOK** (en kritik eksiklik)

## Önerilen Event Şeması

### Firebase Analytics Events

| Event | Parametreler | Tetikleme |
|-------|-------------|-----------|
| `video_ttff` | doc_id, ttff_ms, cache_hit, network, platform | İlk "ready" event |
| `video_rebuffer` | doc_id, rebuffer_ms, position_s, network | Her rebuffer |
| `video_session` | doc_id, watch_s, total_s, rebuffers, dropped_frames, avg_bitrate | Video'dan çıkma |
| `video_error` | doc_id, error_code, message | Player error |
| `video_startup` | doc_id, network, cached_segments, proxy_latency_ms | loadVideo çağrısı |
| `cache_summary` | total_mb, entries, hit_rate_pct, evictions | 5 dakikada bir |

### Custom Dashboard Metrikleri

```
P50 TTFF: < 400ms (warm), < 1s (cold)
P95 TTFF: < 800ms (warm), < 2s (cold)
Rebuffer rate: < 1%
Error rate: < 0.1%
Average watch time: tracking only
Cache hit rate: > 80%
```

### Native Dropped Frame Tracking

**iOS eklemesi** (`HLSPlayerView.swift`'e):
```swift
func getDroppedFrames() -> Int {
    guard let accessLog = playerItem?.accessLog() else { return 0 }
    return accessLog.events.reduce(0) { $0 + $1.numberOfDroppedVideoFrames }
}
```

**Android eklemesi** (`ExoPlayerView.kt`'ye):
```kotlin
fun getDroppedFrames(): Long {
    return player?.videoDecoderCounters?.droppedBufferCount ?: 0
}
```

---

# 9) RİSK ANALİZİ — EN KRİTİK 15 HATA

| # | Severity | Hata | Nasıl Oluşur | Düzeltme |
|---|----------|------|-------------|----------|
| 1 | **KRİTİK** | Tek rendition → buffering | Zayıf ağda 720p segment indirilemez | ABR multi-rendition |
| 2 | **KRİTİK** | TTFF > 1s (warm) | `automaticallyWaitsToMinimizeStalling=true` + 6s forward buffer | false + 3s buffer |
| 3 | **KRİTİK** | Telemetri yok | Üretimde sorun tespiti imkansız | VideoTelemetry service |
| 4 | **YÜKSEK** | 6s segment → yavaş ABR | ABR olsa bile 6s'de bir adapte olur | 4s segment |
| 5 | **YÜKSEK** | Android proxy hop | Dart HTTP proxy → localhost → cache/CDN | Native ExoPlayer cache |
| 6 | **YÜKSEK** | Hotlink protection yok | Herkes segment URL'lerini scrape edebilir | Cloudflare signed URL |
| 7 | **YÜKSEK** | ExoPlayer buffer oversize | minBuffer=7.5s, maxBuffer=15s | 2.5s/8s |
| 8 | **YÜKSEK** | Player oluşturma overhead | Her scroll'da yeni AVPlayer/ExoPlayer | GlobalPlayer reuse |
| 9 | **ORTA** | PlatformView frame cost | Her video widget ~3-5ms | Texture widget |
| 10 | **ORTA** | Thumbnail JPEG (WebP değil) | %40 daha büyük → yavaş load | WebP thumbnail |
| 11 | **ORTA** | Cloud Function 2GB RAM | Tek rendition bile 2GB kullanıyor, multi = 4GB+ gerekir | `runWith({ memory: "4GB" })` |
| 12 | **ORTA** | Orijinal MP4 silinmiyor (posts) | Storage maliyeti | Post-transcode cleanup |
| 13 | **DÜŞÜK** | Position update 500ms interval | Seek/progress bar granülaritesi düşük | 250ms (yüksek, pil etkisi düşük) |
| 14 | **DÜŞÜK** | index.json corruption riski | Crash sırasında partial write | Atomic write (rename pattern) |
| 15 | **DÜŞÜK** | Foreground resume eksik | Background'dan dönüşte video durmuş | Dart tarafında zaten yönetiliyor |

---

# 10) UYGULANABİLİR BACKLOG

## FAZ 0: Acil Düzeltmeler (0-7 gün)

### B-001: automaticallyWaitsToMinimizeStalling = false
- **Dosya:** `ios/Runner/HLSPlayerView.swift:101`
- **Değişiklik:** `true` → `false`
- **Etki:** TTFF -200ms (warm cache)
- **Risk:** Düşük (proxy cache zaten buffer sağlıyor)
- **Maliyet:** 0
- **Done:** TTFF p50 < 600ms (mevcut ~800ms)

### B-002: iOS forward buffer 6s → 3s
- **Dosya:** `HLSPlayerView.swift:96`
- **Değişiklik:** `preferredForwardBufferDuration = 3.0`
- **Etki:** TTFF -100ms, bellek -~1MB per player
- **Risk:** Düşük
- **Maliyet:** 0
- **Done:** İlk frame 3s içinde buffer dolmadan başlıyor

### B-003: ExoPlayer LoadControl optimizasyonu
- **Dosya:** `ExoPlayerView.kt:93-102`
- **Değişiklik:** `minBuffer=2500, maxBuffer=8000, playback=500, rebuffer=1500`
- **Etki:** TTFF -200ms Android, bellek -20MB
- **Risk:** Düşük
- **Maliyet:** 0
- **Done:** Android TTFF p50 < 600ms

### B-004: Video telemetri service oluştur
- **Yeni dosya:** `lib/Core/Services/video_telemetry_service.dart`
- **Değişiklik:** TTFF, rebuffer, session tracking
- **Etki:** Ölçüm altyapısı kurulur
- **Risk:** Yok
- **Maliyet:** 2 gün geliştirme
- **Done:** Firebase'de video_ttff, video_rebuffer, video_session event'leri görünür

### B-005: iOS playDebounce 50ms → 30ms
- **Dosya:** `short_view.dart`
- **Etki:** Scroll autoplay -20ms
- **Risk:** Çok düşük
- **Maliyet:** 0
- **Done:** iOS autoplay start < 280ms

---

## FAZ 1: Mimari İyileştirme (1-4 hafta)

### B-101: HLS segment süresi 6s → 4s
- **Dosya:** `functions/src/hlsTranscode.ts:210`, `adminConfig/hlsSegment`
- **Değişiklik:** `segment2: 6 → 4`
- **Etki:** Daha hızlı ABR geçişi (Faz 2 ile), TTFF -100ms
- **Risk:** Mevcut cache'lenmiş videolar etkilenmez (yeni upload'lar için)
- **Maliyet:** 0
- **Done:** Yeni transcode edilen videolar 4s segment

### B-102: ABR multi-rendition transcode
- **Dosya:** `functions/src/hlsTranscode.ts` (major refactor)
- **Değişiklik:** Tek rendition → 4 rendition (360p/480p/720p/1080p)
- **Etki:** Buffering -%80, TTFF -300ms (360p ilk segment)
- **Risk:** Orta (transcode süresi artışı, Cloud Function timeout)
- **Maliyet:** Cloud Function memory 2GB → 4GB, storage 3x artış
- **Done:** Master playlist 4 variant içeriyor, player otomatik switch yapıyor

### B-103: Thumbnail JPEG → WebP
- **Dosya:** `functions/src/hlsTranscode.ts:339-359`
- **Değişiklik:** `-q:v 2 thumbnail.jpg` → `-f webp -q:v 80 thumbnail.webp`
- **Etki:** Thumbnail boyutu -%40, feed load hızı artışı
- **Risk:** Düşük (CDN URL builder zaten .webp destekliyor)
- **Maliyet:** 0
- **Done:** Yeni thumbnail'lar WebP formatında

### B-104: Android native ExoPlayer cache
- **Dosya:** `ExoPlayerView.kt` (yeni)
- **Değişiklik:** `SimpleCache` + `CacheDataSourceFactory` ekle
- **Etki:** Proxy hop kaldır, segment fetch -50ms
- **Risk:** Orta (Dart proxy ile koordinasyon gerekir)
- **Maliyet:** 3-4 gün geliştirme
- **Done:** Android'de segment cache hit → 0 network latency

### B-105: Cloudflare CDN cache headers
- **Cloudflare dashboard / Worker**
- **Değişiklik:** .ts → 1 year, .m3u8 → 24h, thumbnail → 7d
- **Etki:** CDN cache hit oranı %60 → %90+
- **Risk:** Düşük
- **Maliyet:** 0
- **Done:** Cloudflare analytics'te cache hit ratio > %85

### B-106: iOS GlobalHLSPlayerManager aktive et
- **Dosya:** `ios/Runner/GlobalHLSPlayerManager.swift` (mevcut, kullanılmıyor)
- **Değişiklik:** Tek AVPlayer instance, surface reuse
- **Etki:** TTFF -200ms, bellek -%30-50MB
- **Risk:** Orta (scroll edge case'ler)
- **Maliyet:** 3-5 gün geliştirme
- **Done:** iOS'ta tek player instance, scroll arası geçiş <100ms

---

## FAZ 2: Instagram Seviyesi (1-3 ay)

### B-201: Texture widget (PlatformView yerine)
- **Dosyalar:** Native + Dart player katmanı
- **Değişiklik:** PlatformView → registerTexture + Texture widget
- **Etki:** Frame time -3-5ms per video, 60fps garanti
- **Risk:** Yüksek (büyük refactor)
- **Maliyet:** 2-3 hafta
- **Done:** PlatformView kullanımı sıfır, tüm video Texture widget

### B-202: Signed URL + AES-128 encryption
- **Dosyalar:** Cloud Function + Cloudflare Worker + Native
- **Değişiklik:** Token bazlı erişim + segment encryption
- **Etki:** Güvenlik: hotlink, download engel
- **Risk:** Orta (cache invalidation karmaşıklığı)
- **Maliyet:** 2 hafta
- **Done:** Unsigned URL'lerle erişim 403 döner

### B-203: Sprite thumbnail (seek preview)
- **Dosyalar:** Cloud Function (ffmpeg) + Flutter widget
- **Değişiklik:** 2s aralıklı sprite grid + WebVTT + seek bar overlay
- **Etki:** UX: Instagram tarzı video scrubbing
- **Risk:** Düşük
- **Maliyet:** 1 hafta
- **Done:** Seek bar'da thumbnail preview görünüyor

### B-204: Dropped frame monitoring + alerting
- **Dosyalar:** Native + telemetri service
- **Değişiklik:** AVPlayerItemAccessLog / DecoderCounters → Firebase
- **Etki:** Performans regresyon tespiti
- **Risk:** Düşük
- **Maliyet:** 2-3 gün
- **Done:** P95 dropped frames < 2/video

### B-205: Post-transcode MP4 cleanup
- **Dosya:** `functions/src/hlsTranscode.ts`
- **Değişiklik:** Story gibi post'ta da orijinal MP4 sil
- **Etki:** Storage maliyeti -%40-50
- **Risk:** Düşük (HLS var, MP4'e gerek yok)
- **Maliyet:** 1 saat
- **Done:** Yeni transcode sonrası posts/{docID}/video.mp4 silinmiş

### B-206: Adaptive prefetch (360p first, then upgrade)
- **Dosya:** `prefetch_scheduler.dart`
- **Değişiklik:** Multi-rendition ile: önce 360p segment prefetch, idle'da 720p upgrade
- **Etki:** Prefetch hızı +200%, egress -%40
- **Risk:** Orta (ABR bağımlı)
- **Maliyet:** 3-5 gün
- **Done:** Prefetch'te 360p segment'ler önce, 720p sonra indirilir

### B-207: Real-time quality dashboard
- **Firebase + BigQuery + Looker**
- **Metrikler:** P50/P95 TTFF, rebuffer rate, error rate, cache hit
- **Etki:** Proaktif performans izleme
- **Maliyet:** 1 hafta
- **Done:** Dashboard canlı, alert'ler tanımlı
