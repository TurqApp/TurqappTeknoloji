# TurqApp Yapilacaklar

Tarih: 20 Mart 2026

## Amac

Bu not, cache-first mimari, feed/short/profile playback-render stabilizasyonu ve kalan son mil tuning isi icin devam noktasi olarak tutulur.

Son guvenli durum:

- `HEAD`: `130d2e80` `Restore profile center after avatar overlays`
- Ana mimari safhasi bitti.
- Kalan isler buyuk refactor degil; tuning, dogrulama ve az sayida legacy cleanup.

## Bu Fazda Yapilan Ana Isler

### 1. Cache-first cekirdek ve ortak kontratlar

- `CachedResource<T>`
- `ScopedSnapshotStore`
- `WarmLaunchPool`
- `CacheFirstCoordinator`
- `CacheFirstQueryPipeline`
- `Typesense cache-first adapterlari`
- `UserSummaryResolver`
- `TypesenseUserCardCacheService`

Ana dosyalar:

- `lib/Core/Services/CacheFirst/`
- `lib/Core/Services/user_summary_resolver.dart`
- `lib/Core/Services/typesense_user_card_cache_service.dart`

### 2. Typesense ve Pasaj/Egitim ailesi

Su yuzeyler snapshot-first + silent sync omurgasina baglandi:

- `Job`
- `Tutoring`
- `PracticeExams`
- `AnswerKey`
- `CikmisSorular`
- `Scholarships`
- `QuestionBank / Antreman`
- `Market`

Ana repo kopruleri:

- `job_home_snapshot_repository.dart`
- `tutoring_snapshot_repository.dart`
- `practice_exam_snapshot_repository.dart`
- `answer_key_snapshot_repository.dart`
- `cikmis_sorular_snapshot_repository.dart`
- `scholarship_snapshot_repository.dart`
- `question_bank_snapshot_repository.dart`
- `market_snapshot_repository.dart`

### 3. Feed ve Short veri omurgasi

- `FeedSnapshotRepository`
- `ShortSnapshotRepository`
- `ShortPlaybackCoordinator`
- `FeedRenderCoordinator`
- `ShortRenderCoordinator`

Elde edilenler:

- snapshot-first acilis
- warm snapshot / scoped snapshot persist
- live source assembly ayristirma
- render diff mantigi
- short playback window ayristirma
- splash warm snapshot KPI olcumu

### 4. Notifications

- `NotificationsSnapshotRepository`
- optimistic read/delete ile snapshot state uyumu
- bootstrap + merge standardizasyonu

### 5. Runtime telemetry ve saglik ozetleri

- cache-first lifecycle telemetry
- render diff telemetry
- playback window telemetry
- startup/runtime summary export
- debug dashboard ozetleri

### 6. Kullanici / resolve standardizasyonu

Liste, kart ve header yuzeylerinin buyuk kismi `UserSummaryResolver` cizgisine cekildi:

- Feed
- Short
- Profile
- SocialProfile
- Followers
- Comments
- Share grid
- Story
- Job
- Tutoring
- Egitim detail/review aileleri

### 7. Feed/Short/Profile route-return stabilizasyonu

Asagidaki yuzeylerde merkez/oynatim geri donus mantigi buyuk oranda standardize edildi:

- `Feed`
- `ClassicFeed`
- `Short`
- `MyProfile`
- `SocialProfile`
- `Archives`
- `LikedPosts`
- `TopTags`
- `TagPosts`
- `Explore` preview
- `SavedPosts`

Ana etkiler:

- route acilip donunce yanlis item aktif kalma azaldi
- `centeredIndex = 0` tipi sert resetler azaldi
- modal/bottom sheet donuslerinde restore mantigi toplandi
- profile avatar overlay ve sosyal profil avatar overlay kapanisinda merkez geri kuruluyor

## Son Commit Zinciri

En yeni commitler:

- `130d2e80` `Restore profile center after avatar overlays`
- `2eaf48f2` `Stabilize saved posts snapshot rendering`
- `3c887cd2` `Resume social profile grids after media routes`
- `62c44695` `Restore feed center after flood and comment routes`
- `f9ae0877` `Suspend explore previews during profile routes`
- `4b3fc2cc` `Restore feed center after quote routes`
- `b0c4996c` `Restore feed center after modal actions`
- `37c72d5f` `Restore feed center after menu routes`
- `900303ab` `Gate explore previews by active tab`
- `4fc7f679` `Resume explore previews after media routes`
- `00653546` `Restore feed center after content routes`
- `cb8a5b0c` `Stabilize top tag feed playback`
- `798c1612` `Resume liked posts after media routes`
- `3b2447c8` `Preserve archive centered post across refresh`
- `3c72aa52` `Resume profile playback after market details`
- `d408782e` `Resume social profile playback after following routes`
- `9c078c72` `Resume profile playback after story viewer`
- `d337d026` `Resume profile playback after detail routes`
- `c2bed955` `Resume my profile feed after content routes`
- `0d2262c9` `Resume my profile playback after returns`
- `29639504` `Preserve centered feed post across refresh`
- `ac8dd656` `Preserve centered profile post across returns`
- `ae0c5e1b` `Resume feed playback after story routes`
- `f20176e6` `Resume feed playback after route returns`
- `7e607684` `Refine profile merged feed rendering`
- `aa677256` `Stabilize notifications snapshot mutations`
- `a493c907` `Add profile posts snapshot bootstrap`
- `3d5a1c8e` `Keep active short ready after refresh`
- `3031182d` `Deduplicate short telemetry listeners`
- `9e1f8ee2` `Preserve short adapters across refresh`
- `d56daacf` `Export runtime health summaries on startup`
- `b5961866` `Add feed and short runtime health summaries`
- `89395983` `Add notifications snapshot bootstrap`
- `a1a07b2a` `Show cache-first telemetry in health dashboard`
- `aac56ced` `Add cache-first lifecycle telemetry`
- `57987e58` `Stabilize short warm start and splash metrics`
- `8e954729` `Refine feed render mixing`
- `dd12ebb7` `Reduce short render churn`
- `d322f700` `Feed and short cache-first runtime skeleton`

## Kalan Isler

### A. En yuksek oncelik: tuning ve dogrulama

1. `Feed` autoplay ve visibility KPI'larini sahada izle.
2. `Short` adapter churn, recreate rate ve first-frame gecikmesini izle.
3. `media-ready rerank` etkisini gercek kullanicida dogrula.
4. `promo mixing` sahadaki davranisini kontrol et.
5. `Notifications` optimistic state ile server merge arasinda kopma var mi loglardan bak.

### B. Kalan kucuk legacy cleanup

1. Feed-benzeri daha kucuk yuzeylerde route donusleri tekrar taranabilir.
2. `FloodListing` icin ekstra route-return tuning gerekirse ayri ele alinabilir.
3. `SavedPosts` yeni davranisi gercek cihazda dogrulanmali.
4. `Profile` ve `SocialProfile` avatar overlay davranisi gercek cihazda kontrol edilmeli.

### C. Dogrulama backlog'u

1. Android gercek cihaz:
   - Feed acilis
   - Feed -> PostCreator / Story / Comments / Quote / Report donusu
   - Short refresh sonrasi aktif video korunumu
   - Explore preview sekme degisimi
2. iOS gercek cihaz:
   - Profile / SocialProfile route donusleri
   - avatar overlay ac/kapat
   - autoplay resume davranisi
3. Zayif ag senaryosu:
   - snapshot hit
   - liste korunumu
   - bos state'e dusmeme

### D. Analytics / KPI kullanimi

Bakilacak metrikler:

- `cacheFirstLifecycle`
- `renderDiff`
- `playbackWindow`
- startup `feedWarmSnapshotHit`
- startup `shortWarmSnapshotHit`
- render patch avg/max
- active/visible center thrash
- player recreate rate

## Sonraki Oturumda Ilk Yapilacaklar

1. `git status` ile dirty worktree'yi dikkatli incele.
2. Bu notu ve `docs/architecture/cache_first_audit_2026_03_19.md` dosyasini ac.
3. Runtime KPI / log ureten son commitlerden sonra gercek cihaz dogrulamasina gir.
4. Ilk odak:
   `Feed autoplay tuning` + `Short playback churn olcumu`
5. Sonra:
   `SavedPosts`, `MyProfile`, `SocialProfile` gercek cihaz smoke test

## Teknik Notlar

- Repo cok dirty; alakasiz degisiklikleri geri alma.
- `functions/node_modules`, `.idea`, tmp image dosyalari ve diger daginik degisiklikler bu isin parcasi degil.
- Dar commit mantigiyla devam et.
- Yeni buyuk mimari dosya yazmaktan cok mevcut KPI'a gore tuning yap.

## Kisa Durum Ozeti

Bugun:

- Ana cache-first / snapshot-first iskelet kuruldu.
- Feed / Short / Profile / SocialProfile playback-restore davranisi buyuk olcude toparlandi.
- Kalan isler artik refactor degil, kalite ve tuning.

Pratik kalan oran:

- `%3-5`

Bu not, limit acildiginda dogrudan devam noktasi olarak kullanilsin.
