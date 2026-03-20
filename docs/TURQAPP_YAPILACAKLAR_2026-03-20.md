# TurqApp Yapilacaklar

Tarih: 20 Mart 2026

## Amac

Bu not, cache-first mimari, user-summary resolver standardizasyonu, feed/short/profile playback-render stabilizasyonu ve kalan son mil tuning isi icin devam noktasi olarak tutulur.

Son guvenli durum:

- `HEAD`: `da5083ba` `Resolve cached avatars through summary cache`
- Ana mimari safhasi bitti.
- Resolver / cache-first yayginlastirma buyuk olcude bitti.
- Kalan isler buyuk refactor degil; tuning, gercek cihaz dogrulama ve az sayida dirty legacy cleanup.

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
- BlockedUsers
- Comments
- Share grid
- Story
- Job
- Tutoring
- Explore user cards
- Like / reshare user listeleri
- Reshare attribution
- Rozet / avatar ortak widget ve helper katmani
- Chat message / create chat user kartlari
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

### 8. Bu not yazildiktan sonra ek tamamlananlar

Son continuation dosyasi olusturulduktan sonra su isler de tamamlandi:

- `AgendaContent` kullanan lokal feed baglamlari icin ortak restore:
  - `FloodListing`
  - `MyProfile`
  - `SocialProfile`
  - `Archives`
  - `LikedPosts`
  - `TopTags`
  - `TagPosts`
- `LikedPosts`, `TopTags`, `SocialProfile.refreshAll()` icin refresh sirasinda listeyi gereksiz bosaltmama
- `BlockedUsers` ve `FollowingFollowers` user-summary resolver cizgisine gecis
- `PostLikeListing`, `PostReshareListing`, `PostLikeContent` summary cache gecisi
- `StoryCommentUser`, `StoryContentProfile`, `PostCommentContent` summary cache gecisi
- `PhotoShorts` user profile fetch gecisi
- `AboutProfile` ve `Interests` warm current-user / summary seed
- `JobSelector` ve `AddressSelector` current-user warm seed
- `ReshareHelper`, `RozetContent`, `rozet_permissions`, `cached_user_avatar` ortak helper/widget gecisleri
- `AccountCenterService`, `CreateChatContent`, `MessageContent`, `DenemeGrid`, `TestsGrid`, `AnswerKeyContent` user-summary gecisleri

## Son Commit Zinciri

En yeni commitler:

- `da5083ba` `Resolve cached avatars through summary cache`
- `6602f1da` `Resolve chat message users through summary cache`
- `70f70189` `Resolve rozet permissions through summary cache`
- `64259f73` `Resolve education cards through summary cache`
- `1e873d90` `Resolve account and content cards through summary cache`
- `956d5076` `Resolve shared user helpers through summary cache`
- `421403f5` `Warm profile details from summary and current cache`
- `cfea84c1` `Warm profile selectors from current user cache`
- `638a0739` `Resolve photo shorts profiles through summary cache`
- `2ab443e6` `Resolve story and comment profiles through summary cache`
- `3da56338` `Resolve reshare attribution through summary cache`
- `fe7ed644` `Resolve agenda user lists through summary cache`
- `65ba1597` `Unify profile relation list resolvers`
- `8a8b9c03` `Preserve profile and tag lists during refresh`
- `59052c32` `Restore embedded feed contexts after content routes`
- `1701a490` `Add TurqApp continuation todo list`
- `130d2e80` `Restore profile center after avatar overlays`
- `2eaf48f2` `Stabilize saved posts snapshot rendering`
- `3c887cd2` `Resume social profile grids after media routes`
- `62c44695` `Restore feed center after flood and comment routes`

## Kalan Isler

### A. En yuksek oncelik: tuning ve dogrulama

1. `Feed` autoplay ve visibility KPI'larini sahada izle.
2. `Short` adapter churn, recreate rate ve first-frame gecikmesini izle.
3. `media-ready rerank` etkisini gercek kullanicida dogrula.
4. `promo mixing` sahadaki davranisini kontrol et.
5. `Notifications` optimistic state ile server merge arasinda kopma var mi loglardan bak.
6. `cached_user_avatar` davranisini zayif ag ve stale avatar senaryosunda dogrula.
7. `CurrentUserService` ile warm acilan selector/form ekranlarinda gec acilis regresssion'i var mi bak.

### B. Bilincli olarak raw kalan veya ikinci faza birakilan yerler

Buralar halen `getUserRaw` veya tam profile/raw belge kullaniyor; bu durum bilincli:

- `EditProfile`
- `EditorEmail`
- `EditorPhoneNumber`
- `EditorNickname`
- `AddressSelector`
- `JobSelector` raw fallback'i
- `Interests` raw fallback'i
- `AboutProfile` `createdDate` icin raw fallback
- `SocialProfileController` tam profile alanlari
- `MyProfileController` tam profile/raw bucket alanlari
- `account_center_view`
- `moderation_settings_view`
- `deep_link_service`
- `education_feed_cta_navigation_service`
- `admin_push_repository`

Bu ekranlar/formlar tam belge veya raw alan ihtiyaci tasidigi icin tamamen resolver'a zorlanmadi.

### C. Kalan kucuk legacy cleanup

1. Feed-benzeri daha kucuk yuzeylerde route donusleri tekrar taranabilir.
2. `FloodListing` icin ekstra route-return tuning gerekirse ayri ele alinabilir.
3. `SavedPosts` yeni davranisi gercek cihazda dogrulanmali.
4. `Profile` ve `SocialProfile` avatar overlay davranisi gercek cihazda kontrol edilmeli.
5. Dirty worktree icindeki eski i18n / UI metin cleanup commit zincirinden ayiklanabilir.
6. `Explore/SearchedUser` aktif hesap kontrolundeki raw fallback, istenirse second-pass optimize edilebilir.

### D. Dogrulama backlog'u

1. Android gercek cihaz:
   - Feed acilis
   - Feed -> PostCreator / Story / Comments / Quote / Report donusu
   - Short refresh sonrasi aktif video korunumu
   - Explore preview sekme degisimi
   - Like / reshare / comments user card acilislari
   - cached avatar yenileme davranisi
2. iOS gercek cihaz:
   - Profile / SocialProfile route donusleri
   - avatar overlay ac/kapat
   - autoplay resume davranisi
   - Account center / selector ekranlarinda warm acilis
3. Zayif ag senaryosu:
   - snapshot hit
   - liste korunumu
   - bos state'e dusmeme
   - stale avatar / stale nickname fallback
4. User metadata regression:
   - rozet rengi
   - reshare attribution nickname'i
   - blocked/followers listeleri
   - story comment / story profile avatarlari

### E. Analytics / KPI kullanimi

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
   `SavedPosts`, `MyProfile`, `SocialProfile`, `cached_user_avatar` smoke test
6. Sonraki teknik odak:
   dirty kalan raw/form ekranlarini tek tek ayirip, sadece gerekli olanlari raw belgede birak

## Teknik Notlar

- Repo cok dirty; alakasiz degisiklikleri geri alma.
- `functions/node_modules`, `.idea`, tmp image dosyalari ve diger daginik degisiklikler bu isin parcasi degil.
- Dar commit mantigiyla devam et.
- Yeni buyuk mimari dosya yazmaktan cok mevcut KPI'a gore tuning yap.
- `UserRepository.ensure().getUser(...)` kullanan temiz gorunur yuzeylerin tamami kapatildi.
- Bundan sonraki resolver isleri daha cok dirty dosyalarda veya bilincli raw ekranlarda kaldi.

## Kisa Durum Ozeti

Bugun:

- Ana cache-first / snapshot-first iskelet kuruldu.
- Feed / Short / Profile / SocialProfile playback-restore davranisi buyuk olcude toparlandi.
- User-summary resolver hatlari gorunur UI yuzeylerinde buyuk olcude tekillesti.
- Kalan isler artik refactor degil, kalite, gercek cihaz dogrulama ve tuning.

Pratik kalan oran:

- `%2-4`

Bu not, limit acildiginda dogrudan devam noktasi olarak kullanilsin.
