# 1. Mevcut Durum Analizi

## Güçlü taraflar
- Flutter tarafında **özel HLS cache altyapısı** hazır: `SegmentCacheManager`, `HLSProxyServer`, `PrefetchScheduler` birlikte çalışıyor.
- Mevcut modelde mobil veride segment fetch’i sınırlayan bir politika var (`CacheNetworkPolicy.canFetchOnDemand`) ve Wi‑Fi öncelikli prefetch davranışı uygulanıyor.
- Kısa video akışında cache quota tercihi (`offline_cache_quota_gb`) kullanıcı ayarı olarak kullanılıyor; uygulama runtime’da `SegmentCacheManager.setUserLimitGB` ile kota uygulayabiliyor.
- Android tarafında Media3 ExoPlayer bağımlılıkları mevcut ve HLS kaynakları `HlsMediaSource` ile oynatılıyor.
- iOS tarafında native AVPlayer entegrasyonu stabil, buffering/ready event zinciri Flutter’a aktarılıyor.
- Firestore için offline persistence + cache-first yardımcıları bulunuyor; profil/veri akışı için local-first geçişine taban sağlıyor.

## Zayıf taraflar
- **Policy Engine ayrışması yok**: ağ modu, disk bütçesi, prefetch skoru ve eviction kararı farklı servislerde dağınık; tek bir orchestration katmanı bulunmuyor.
- Metadata (avatar/bio/profession bio/feed author summary) için **ortak TTL/invalidation şeması** merkezi bir modelde toplanmamış.
- Video cache tek katmanlı: `stream_cache` ve `offline_candidate_cache` gibi policy-semantik ayrım henüz yok.
- Android’de Media3 kullanılmasına rağmen resmi offline hattı (DownloadService/DownloadManager + WorkManager unmetered pipeline) kod tabanında görünmüyor.
- iOS tarafında AVPlayer oynatma güçlü, fakat AVAssetDownloadURLSession ile persistent HLS indirme hattı yok.
- Telemetri var ancak KPI seti (wasted prefetch bytes, resume success, profile local hit ratio, cache thrash rate) tam bir kontrol paneline bağlanmış görünmüyor.

## Kırılgan noktalar
- Mobil veri politikasında cache miss senaryoları “fail-open/fail-closed” dengesinde platforma göre değişebilir; bu bölümde manuel saha testi gerekli.
- Prefetch pencereleri şu an ağırlıklı statik; kullanıcı niyeti (scroll hızı, dwell, ses, fullscreen) ile dinamikleşme sınırlı.
- Disk bütçesi 3/4/5 GB seçimi uygulanıyor ancak reserve/safety-margin/hard-stop/soft-stop çok katmanlı model henüz net değil.
- İleri fazlarda ABR, offline candidate, metadata warming aynı anda açılırsa batarya/IO thrash riski var; rollout kontrollü yapılmalı.

# 2. Hedef Mimarinin Özeti

**Ürün mantığı:**
Uygulama, kullanıcıya “hep hızlı açılan, mobil veride tutumlu, Wi‑Fi’da akıllı şekilde hazırlık yapan” bir deneyim vermeli. İlk ekranda boşluk hissi olmadan içerik açılmalı; kullanıcı davranışı güçlü sinyal verirse sistem prefetch derinliğini artırmalı; düşük ilgi/süratli kaydırmada ise gereksiz indirmeyi kesmeli.

**Teknik mantık:**
Çözüm bir “tek cache” değil, çok katmanlı bir **Playback Intelligence System** olmalı: Flutter domain katmanında policy engine’ler (network resolver, budget manager, prefetch scoring, eviction intelligence, metadata freshness), native katmanlarda platforma uygun yürütme (iOS: AVPlayer + AVAssetDownloadURLSession; Android: Media3 + DownloadService/WorkManager), data katmanında ise cache index + telemetry + local-first metadata depolama.

# 3. Önerilen Sistem Tasarımı

## 3.1 Bootstrap Mode
- Tetik: ilk kurulum, cold start, app relaunch.
- Amaç: ilk 1–2 saniyede canlı deneyim, ilk video hızlı başlangıç.
- Yapılacaklar:
  - App config + feature flags
  - Current user summary (cache-first + silent refresh)
  - İlk feed sayfası + ilk video startup window
  - Continue watching index
  - İlk 30–50 avatarın küçük boyutu
- Yapılmayacaklar:
  - Derin video prefetch
  - Toplu download
  - Düşük olasılıklı profil detayları

## 3.2 WiFi Fill Mode
- Tetik: unmetered ağ, yeterli batarya, düşük cihaz baskısı, kullanıcı data-saver kapalı.
- Hedef: disk bütçesini akıllı doldurmak, tekrar izleme ve “sıradaki içerik” olasılığına göre derinleşmek.
- Aksiyonlar:
  - Hot metadata refresh (TTL yaklaşınca)
  - Resume videoları `resume_ready`
  - Feed’de next N video için startup window
  - Yüksek skorlu adaylarda deep cache
  - Düşük skorlu cache eviction
  - Index compaction + image cache normalization

## 3.3 Cellular Guard Mode
- Tetik: cellular / constrained / low data.
- Hedef: önce local tüketim, minimum ağ çekişi.
- Aksiyonlar:
  - Startup window küçük (1–2 segment)
  - Ahead window davranış tabanlı (devam sinyali yoksa 0–1 segment)
  - Hızlı scroll’da prefetch iptal
  - Bitrate ceiling sertleştirme
  - Yalnızca gerekli metadata diff refresh

# 4. Cache Katmanları

- **P0 Critical Local Cache:** current user summary, session summary, kritik ayarlar.
- **P1 Hot Metadata Cache:** avatar, bio short, profession bio, feed author compact summary.
- **P2 Warm Media Cache:** startup window + resume window + next items seed.
- **P3 Deep Media Cache:** yalnızca Wi‑Fi’da yüksek skorlu içeriklerin geniş penceresi.
- **P4 Disposable Cache:** düşük değerli thumbs/geçici listeler/düşük affinity segmentler.

Eviction sadece LRU değil; önerilen karar formu:
`evict_score = age + low_rewatch_probability + fully_consumed + low_follow_affinity + low_resume_probability`

# 5. Storage Budget Planı

## 3 GB plan
- 2.15 GB media
- 350 MB image
- 180 MB metadata/index
- 120 MB reserve
- 200 MB OS safety margin

## 4 GB plan
- 3.00 GB media
- 420 MB image
- 220 MB metadata/index
- 160 MB reserve
- 200 MB OS safety margin

## 5 GB plan
- 3.95 GB media
- 480 MB image
- 250 MB metadata/index
- 170 MB reserve
- 150 MB OS safety margin

## Hard/soft stop
- `soft_stop`: toplam planın ~%84–88’i; agresif prefetch yavaşlatılır.
- `hard_stop`: toplam planın ~%90’ı; yalnızca kritik startup/resume yazımları.
- `reserve`: fragmentation + index recovery + kritik metadata için korunur.

# 6. Metadata Local-First Planı

Öncelik verilen veri:
- avatar
- bio
- meslek bio
- profile summary
- feed author summary

Strateji:
1. UI her zaman local DB’den anında çizilir.
2. Arka planda freshness kontrolü + diff patch.
3. TTL yaklaşım önerisi:
   - current user summary: 24 saat + app open’da silent refresh
   - author summary: 1–3 gün
   - profession bio: 3–7 gün
   - avatar: etag/version invalidation
4. `usage_count`, `last_accessed_at`, `pinned_score` alanları eviction’a girdi olur.

# 7. Video Prefetch Planı

## Startup window
- Varsayılan 2 segment (network/cihaz baskısına göre 1–2).

## Ahead window
- Devam sinyali oluşmadan 0–1 segment.
- `watch_ratio` veya `continue_threshold` geçilince 2 segmente çıkar.

## Resume-aware prefetch
- Kullanıcı kaldığı zaman çevresinde lokal pencere tutulur (`resume_ready`).

## Scroll intent handling
- Hızlı swipe: prefetch iptal / minimum seed.
- Orta dwell: küçük ahead.
- Fullscreen + ses açık + completion geçmişi yüksek: 3–4 segment.

# 8. iOS Planı

## Mevcut entegrasyona saygılı iyileştirmeler
- AVPlayer event ve lifecycle hattı korunmalı; AppDelegate/plugin kaydı bozulmamalı.
- HLS playback sırasında segment mikroyönetimi zorlanmamalı; policy odak bitrate + persistence yaklaşımı kullanılmalı.

## AVPlayer çevresinde uygulanabilir iyileştirmeler
- `preferredPeakBitRate` ve `preferredPeakBitRateForExpensiveNetworks` (uygun iOS sürümlerinde) policy’den beslensin.
- `NWPath` üzerinden expensive/constrained sinyali domain katmanına taşınsın.
- `low data mode` algısında deep prefetch devre dışı.

## Persistent HLS / offline candidate
- AVAssetDownloadURLSession adapter eklenmeli.
- `offline_candidate` listesindeki yüksek skorlu videolar background görevle indirilmeli.
- Download task registry Flutter domain’e event olarak raporlanmalı.

# 9. Android Planı

## Media3 / ExoPlayer cache stratejisi
- Mevcut ExoPlayer + HLS playback korunur.
- `stream_cache` ve `offline_candidate_cache` ayrımı yapılır.
- `CacheDataSource` katmanında network policy + quota enforcement merkezi hale getirilir.

## DownloadService / WorkManager / quota yönetimi
- Media3 `DownloadService` + `DownloadManager` ile persistent indirme hattı.
- `WorkManager(NetworkType.UNMETERED)` ile Wi‑Fi fill batch işleri.
- Parallel prefetch dedupe + rate limit + hysteresis.

# 10. Önerilen Dosya Yapısı

```text
lib/
  Core/
    Services/
      PlaybackIntelligence/
        playback_policy_engine.dart
        prefetch_scoring_engine.dart
        storage_budget_manager.dart
        network_mode_resolver.dart
        resume_session_manager.dart
        user_data_freshness_manager.dart
      MetadataCache/
        metadata_cache_repository.dart
        metadata_ttl_policy.dart
        models/
          user_summary_cache_model.dart
          feed_author_cache_model.dart
      MediaCache/
        media_cache_repository.dart
        eviction_policy.dart
        cache_state_machine.dart
      Telemetry/
        playback_kpi_service.dart
        cache_kpi_service.dart
        metadata_kpi_service.dart
  Data/
    Local/
      app_cache_db.dart
      tables/
        storage_budget_table.dart
        cached_media_item_table.dart
        media_segment_window_table.dart
        user_summary_cache_table.dart
        image_cache_index_table.dart
        prefetch_queue_table.dart
        playback_session_table.dart

ios/Runner/
  PlaybackIntelligence/
    IOSNetworkPathObserver.swift
    IOSAssetDownloadAdapter.swift
    IOSPlaybackPolicyBridge.swift

android/app/src/main/kotlin/com/turqapp/app/playback/
  AndroidNetworkCostResolver.kt
  AndroidDownloadServiceAdapter.kt
  AndroidOfflineCandidateManager.kt
  AndroidPlaybackPolicyBridge.kt
```

# 11. Veri Tabloları / Modeller

## storage_budget
- plan_gb
- media_quota_bytes
- image_quota_bytes
- metadata_quota_bytes
- reserve_quota_bytes
- soft_stop_bytes
- hard_stop_bytes

## cached_media_item
- media_id
- manifest_url
- estimated_total_bytes
- cached_bytes
- cache_state (`seeded/warm/resume_ready/deep_cached/expired/pinned`)
- last_played_at
- predicted_resume_score
- affinity_score
- expires_at

## media_segment_window
- media_id
- variant_id
- window_start_seq
- window_end_seq
- local_state
- byte_size
- last_verified_at

## user_summary_cache
- user_id
- compact_payload_json
- avatar_local_path
- ttl_expires_at
- usage_count
- last_accessed_at
- pinned_score

## prefetch_queue
- task_id
- entity_type
- entity_id
- priority_score
- policy_reason
- required_network
- required_battery
- status
- created_at

## playback_session
- session_id
- media_id
- start_at
- stop_at
- stop_reason
- watched_seconds
- network_type
- bitrate_estimate
- cache_hit_ratio

# 12. KPI ve Telemetri

## Playback KPI
- startup time
- first frame time
- rebuffer count / duration
- video completion rate
- cache hit ratio
- mobile bytes per playback minute
- resume success rate

## Metadata KPI
- profile card local hit rate
- avatar local hit rate
- stale correction rate
- summary refresh latency

## Storage KPI
- quota fill time
- eviction churn
- deep cache usefulness
- wasted prefetched bytes
- cache thrash rate

# 13. Riskler ve Manuel Kontrol Gerekenler

- **Manuel kontrol gerekli:** iOS AVPlayer ile mevcut Flutter event köprüsünde bitrate policy değişikliği yapıldığında TTFF regresyonu.
- **Manuel kontrol gerekli:** Android’de DownloadService + aktif player aynı içeriğe yarışırken duplicate I/O.
- **Manuel kontrol gerekli:** disk hard-stop altında metadata yazımı engellenmemeli (P0/P1 koruma).
- **Manuel kontrol gerekli:** hızlı scroll senaryolarında prefetch iptal gecikmesi veri kaçağı üretmesin.
- **Manuel kontrol gerekli:** profile summary TTL geçişlerinde UI stale-jump olmasın (diff patch + atomic update).

# 14. Fazlara Bölünmüş Uygulama Planı

## Faz 1 (production-safe temel)
- PlaybackPolicyEngine iskeleti (read-only karar + log)
- 3/4/5 GB budget split + soft/hard stop uygulaması
- Metadata local-first read path + TTL alanları
- Cellular small startup/ahead window standardizasyonu
- Wi‑Fi basic fill queue (yüksek riskli deep cache yok)

## Faz 2 (zeka katmanı)
- PrefetchScoringEngine + resume-aware prefetch
- Smart eviction (`evict_score`)
- Feed next-item prediction
- iOS network cost observer + bitrate policy bridge
- Android WorkManager unmetered orchestration

## Faz 3 (ileri optimizasyon)
- iOS AVAssetDownloadURLSession persistent candidate hattı
- Android DownloadService offline candidate pipeline
- Per-user adaptive quota shaping
- Wasted-byte optimizer + A/B test policy framework
- KPI dashboard ve otomatik policy tuning döngüsü

# 15. Operasyonel Guardrail ve Rollback Planı

## Feature flag grupları
- `pi_policy_engine_enabled`
- `pi_wifi_fill_enabled`
- `pi_cellular_guard_enabled`
- `pi_resume_prefetch_enabled`
- `pi_offline_candidate_enabled_ios`
- `pi_offline_candidate_enabled_android`

## Rollout stratejisi
- Aşamalı açılış: %1 → %5 → %15 → %30 → %50 → %100.
- Her adımda en az 24 saat KPI gözlemi olmadan bir sonraki aşamaya geçilmez.
- Geçişte platformlar ayrı ilerletilir (iOS/Android bağımsız canary).

## Rollback tetikleyicileri
- Startup time p95 > baseline + %15
- Rebuffer duration / session > baseline + %20
- Mobile bytes per playback minute > baseline + %10
- Crash-free session oranı < hedef eşiği

## Rollback aksiyonu
- Önce deep cache ve offline candidate flag’leri kapat.
- Sorun devam ederse policy engine yalnızca telemetry moduna alınır (karar uygulatmaz).
- Son adımda tüm PI flag’leri kapatılarak eski akışa dönülür.

# 16. Test ve Doğrulama Matrisi

## Ağ senaryoları
- Wi‑Fi güçlü sinyal
- Wi‑Fi zayıf sinyal
- Cellular 4G/5G normal
- Cellular + low data mode / constrained
- Ağ değişimi (Wi‑Fi ↔ cellular) oynatma sırasında

## Kullanıcı davranış senaryoları
- Hızlı scroll (düşük dwell)
- Orta dwell + autoplay
- Fullscreen + ses açık + uzun izleme
- Resume (kaldığı yerden devam)
- Uygulama arka plana/alınma geçişleri

## Cihaz durumu senaryoları
- Düşük batarya
- Düşük disk alanı
- Thermal pressure / CPU baskısı
- Uygulama güncelleme sonrası cache migration

## Başarı kriteri
- Tüm kritik senaryolarda playback blokajı olmamalı.
- Cache miss durumunda kullanıcı deneyimi kilitlenmemeli (degrade but safe).
- Hard-stop altında veri bütünlüğü (index + metadata) korunmalı.

# 17. Migration ve Uyumluluk Planı

## Şema versiyonlama
- Local DB için `schema_version` zorunlu.
- Her versiyonda forward-only migration script tanımlanmalı.

## Eski cache’den geçiş
- Mevcut `SegmentCache` index korunur; yeni tablolar yanına eklenir.
- İlk açılışta “lazy backfill” yapılır; büyük bloklayıcı migration yapılmaz.

## Geriye uyumluluk
- Yeni policy alanları yoksa safe default ile çalışır.
- Eski uygulama sürümünden kalan kayıtlar okunurken null-safe parse zorunlu.

# 18. Güvenlik, Gizlilik ve Veri Minimizasyonu

- Telemetry payload’larında PII gönderilmez; user_id hash/pseudonymous id ile raporlanır.
- Prefetch ve playback analitiğinde URL parametrelerinden token/signed query saklanmaz.
- Local metadata cache’de hassas alanlar (telefon, e-posta vb.) tutulmaz; yalnızca UI için gerekli özet tutulur.
- Cache temizleme ekranında “hesap verisini sıfırla” ve “medya cache temizle” ayrı aksiyonlar olmalı.

# 19. Sahiplik (Ownership) ve Çalışma Sözleşmesi

- Flutter Domain (Policy/DB/Telemetry): Mobile Platform Team
- iOS Native adapter (AVPlayer/AssetDownload): iOS Team
- Android Native adapter (Media3/DownloadService/WorkManager): Android Team
- CDN/HLS paketleme politikaları: Backend + Media Infra

Her fazın “Definition of Done” kriteri:
- Kod + telemetry event’leri + dashboard paneli + runbook + rollback adımı birlikte teslim edilir.

# 20. Faz 1 İçin Net Görev Listesi (Uygulamaya Hazır)

1. `PlaybackPolicyEngine` read-only karar katmanı oluştur.
2. `StorageBudgetManager` ile 3/4/5 GB split + soft/hard stop hesaplat.
3. Metadata cache tablosu + TTL alanlarını ekle (read path local-first).
4. `Cellular Guard` için startup/ahead window konfigürasyonunu tek yerden yönet.
5. KPI event şemasını sabitle (`startup`, `ttff`, `rebuffer`, `cache_hit_ratio`, `mobile_bytes_per_min`).
6. Feature flag + rollout + rollback runbook dökümanını tamamla.

Faz 1 çıkış kriteri:
- Runtime regressionsuz prod canary (%5) ve KPI’larda negatif sapma olmadan 7 gün stabil çalışma.
