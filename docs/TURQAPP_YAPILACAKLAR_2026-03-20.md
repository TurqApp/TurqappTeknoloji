# TurqApp Master Plan

Tarih: 20 Mart 2026

## Amac

Bu not, cache-first mimari, user-summary resolver standardizasyonu, feed/short/profile playback-render stabilizasyonu ve kalan son mil tuning isi icin devam noktasi olarak tutulur.

Bu dosya artik otomasyon + manuel dogrulama + bilincli raw alanlar + legacy cleanup dahil tum aciklari toplayan kanonik master plan olarak kullanilsin.

Referans durum:

- Guncel `HEAD`: `ccb53e78` `Expand full automation rollout plan`
- Resolver/cache-first stabilizasyon checkpoint'i: `863b6a98` `Finalize urgent resolver follow-ups`
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
- `DeepLinkService` story owner lookup user-summary gecisi
- `ScholarshipApplicationsContent` tekrarli raw user fetch birlestirme
- `NotificationContent` ve `JobDetails` owner/applicant summary gecisleri

## Son Commit Zinciri

En yeni commitler:

- `863b6a98` `Finalize urgent resolver follow-ups`
- `095c4163` `Resolve deep links and scholarship details through cache layers`
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

### F. Tam otomatik kalite plani

Bu kisim, tek kisi calisan bir ekip icin agir QA orgutu kurmadan maksimum otomasyon hedefiyle yazildi.

1. Faz 1: kritik integration smoke test
   - `Feed` acilis -> route ac -> geri don -> merkez korunuyor mu
   - `Short` refresh -> aktif `docID` korunuyor mu
   - `Profile/SocialProfile` route donusu -> merkez geri geliyor mu
   - `Explore` sekme degisimi -> preview yanlis sekmede aciliyor mu
   - `Notifications` read/delete -> optimistic state ve snapshot state uyumlu mu

2. Faz 2: runtime invariant guard
   - snapshot varsa refresh sonrasi liste `0` item'a dusmemeli
   - aktif `docID` yeni listede varsa merkez ayni item'a donmeli
   - `centeredIndex` gecersiz aralikta kalmamali
   - `Short` tarafinda ayni item icin gereksiz adapter recreate sayisi esik ustune cikmamali
   - route donusu sonrasi `resumeCenteredPost()` cagrisi sonunda aktif item gorunur listede olmali

3. Faz 3: telemetry threshold ve alarm
   - `feedWarmSnapshotHit` ani duserse alarm
   - `shortWarmSnapshotHit` ani duserse alarm
   - `renderDiff` avg/max ani ziplarsa alarm
   - `player recreate rate` esigi gecerse alarm
   - `empty-after-refresh` veya `empty-after-filter` olursa alarm
   - `Notifications` optimistic rollback oranı artarsa alarm

4. Faz 4: release gate
   - release oncesi zorunlu `flutter test`
   - kritik integration smoke testi
   - son runtime KPI ozeti kontrolu
   - zayif ag smoke testi
   - gercek cihazda en az bir Android ve bir iOS hızlı senaryo turu

5. Faz 5: tek kisilik operasyon modeli
   - her yeni kritik bug once test senaryosuna eklenir
   - sonra patch yazilir
   - patch sonrasi smoke test ve KPI karsilastirmasi yapilir
   - checklist guncellenmeden is kapanmis sayilmaz

6. Otomasyon backlog'u
   - `integration_test/feed_resume_test.dart`
   - `integration_test/short_refresh_preserve_test.dart`
   - `integration_test/profile_resume_test.dart`
   - `integration_test/explore_preview_gate_test.dart`
   - `integration_test/notifications_snapshot_mutation_test.dart`
   - debug invariant helper: `lib/Core/Services/runtime_invariant_guard.dart`
   - telemetry threshold config: `lib/Core/Services/PlaybackIntelligence/`

7. Tam otomatik icin eklenecek diger katmanlar
   - screenshot diff smoke:
     `Feed`, `Short`, `Profile`, `SocialProfile`, `Explore`, `Notifications`
   - route replay senaryolari:
     once bug cikan navigation zincirlerini tekrar oynatan regression testleri
   - zayif ag profilleri:
     `offline`, `high latency`, `packet loss` icin ayri smoke test
   - test verisi sabitleme:
     integration testlerde sabit kullanici / sabit feed / sabit short fixture
   - crash artifact toplama:
     fail olan smoke test sonunda otomatik screenshot + son KPI dump + route dump
   - flaky test guard:
     test 1 kez fail, 1 kez pass olursa `unstable` olarak raporlansin
   - release summary raporu:
     tek komut sonunda `pass/fail + screenshot + KPI summary` cikti dosyasi uretsin

8. Tam otomasyon icin tek kisilik pratik sira
   - once runtime invariant guard
   - sonra 5 kritik integration smoke test
   - sonra screenshot diff
   - sonra zayif ag matrix
   - en son telemetry threshold alarm

9. Bu fazin hedefi
   - "bug olunca elle fark et" modelinden cikmak
   - "bug cikinca test/alarm versin" modeline gecmek
   - tek kisi olsan bile release oncesi minimum manuel kontrolle guvenli cikis yapmak

## Master Plan Durum Kontrolu

Durum etiketleri:

- `ACIK`: repo icinde kapanmis gorunmuyor veya saha/cihaz dogrulamasi bekliyor
- `KISMEN`: kod karsiligi var ama tam kapanmis sayilmasi icin ikinci pass veya manuel dogrulama gerekiyor
- `BILINCLI`: bu yuzey bilerek raw/tam belge kullaniyor; hemen zorlanmayacak
- `EKSIK ALTYAPI`: repo icinde dosya/katman olarak henuz yok

### A. En yuksek oncelik: tuning ve dogrulama durum kontrolu

1. `Feed` autoplay ve visibility KPI'larini sahada izle.
   Durum: `KISMEN`
   Not: KPI uretimi var; saha izleme ve threshold/alarm yok.

2. `Short` adapter churn, recreate rate ve first-frame gecikmesini izle.
   Durum: `KISMEN`
   Not: playback window ve video telemetry/TTFF katmani var; recreate threshold/alarm ve saha takibi acik.

3. `media-ready rerank` etkisini gercek kullanicida dogrula.
   Durum: `KISMEN`
   Not: `FeedRenderCoordinator` icinde media-ready rerank kodu var; gercek kullanici etkisi kapanmamis.

4. `promo mixing` sahadaki davranisini kontrol et.
   Durum: `KISMEN`
   Not: feed render katmaninda promo/ad/recommended mix var; saha davranisi ve KPI analizi acik.

5. `Notifications` optimistic state ile server merge arasinda kopma var mi loglardan bak.
   Durum: `KISMEN`
   Not: optimistic read/delete + rollback + merge kodu var; log/cihaz dogrulamasi acik.

6. `cached_user_avatar` davranisini zayif ag ve stale avatar senaryosunda dogrula.
   Durum: `KISMEN`
   Not: summary + raw + current-user fallback zinciri var; zayif ag/stale avatar smoke testi acik.

7. `CurrentUserService` ile warm acilan selector/form ekranlarinda gec acilis regresssion'i var mi bak.
   Durum: `KISMEN`
   Not: `AboutProfile`, `Interests`, `JobSelector`, `AddressSelector` current-user warm/acilis yardimi aliyor; gercek cihaz regression gecisi acik.

### B. Bilincli olarak raw kalan veya ikinci faza birakilan yerler durum kontrolu

- `EditProfile`
  Durum: `BILINCLI`
  Not: current-user cache kullaniyor ama raw fallback halen var.
- `EditorEmail`
  Durum: `BILINCLI`
  Not: account/email dogasi geregi raw belge ihtiyaci suruyor.
- `EditorPhoneNumber`
  Durum: `BILINCLI`
  Not: phone/email alanlari icin raw okuma halen var.
- `EditorNickname`
  Durum: `BILINCLI`
  Not: nickname degisimi ve force refresh akisi nedeniyle raw okuma suruyor.
- `AddressSelector`
  Durum: `BILINCLI`
  Not: current-user warm seed var, raw fallback devam ediyor.
- `JobSelector` raw fallback'i
  Durum: `BILINCLI`
  Not: current-user warm seed var, raw fallback devam ediyor.
- `Interests` raw fallback'i
  Durum: `BILINCLI`
  Not: current-user warm seed var, raw fallback devam ediyor.
- `AboutProfile` `createdDate` icin raw fallback
  Durum: `BILINCLI`
  Not: summary ile avatar/nickname geliyor; `createdDate` icin raw okuma suruyor.
- `SocialProfileController` tam profile alanlari
  Durum: `BILINCLI`
  Not: tam profile/raw bucket alanlari halen kullaniliyor.
- `MyProfileController` tam profile/raw bucket alanlari
  Durum: `BILINCLI`
  Not: tam profil ve birkac raw alan bilincli sekilde tutuluyor.
- `account_center_view`
  Durum: `BILINCLI`
  Not: contact/account bilgileri icin raw fallback var.
- `moderation_settings_view`
  Durum: `BILINCLI`
  Not: admin/moderation akislarinda raw lookup suruyor.
- `education_feed_cta_navigation_service`
  Durum: `BILINCLI`
  Not: navigation kararlari icin raw user doc okunuyor.
- `admin_push_repository`
  Durum: `BILINCLI`
  Not: admin push isleri icin raw kullanimi suruyor.

### C. Kalan kucuk legacy cleanup durum kontrolu

1. Feed-benzeri daha kucuk yuzeylerde route donusleri tekrar taranabilir.
   Durum: `ACIK`
   Not: ana yuzeyler toparlandi; tum kucuk alt yuzeyler icin merkezi kapanis yok.

2. `FloodListing` icin ekstra route-return tuning gerekirse ayri ele alinabilir.
   Durum: `KISMEN`
   Not: `centeredIndex/lastCenteredIndex` akisi var; ama route-return standardizasyonu ana yuzeyler kadar guclu degil.

3. `SavedPosts` yeni davranisi gercek cihazda dogrulanmali.
   Durum: `KISMEN`
   Not: snapshot + silent refresh davranisi kodda var; gercek cihaz smoke testi acik.

4. `Profile` ve `SocialProfile` avatar overlay davranisi gercek cihazda kontrol edilmeli.
   Durum: `KISMEN`
   Not: overlay ac/kapat ve `resumeCenteredPost()` restore akisi var; cihaz dogrulamasi acik.

5. Dirty worktree icindeki eski i18n / UI metin cleanup commit zincirinden ayiklanabilir.
   Durum: `ACIK`
   Not: repo halen cok dirty; bu ayiklama bilincli bir temizlik fazi istiyor.

6. `Explore/SearchedUser` aktif hesap kontrolundeki raw fallback, istenirse second-pass optimize edilebilir.
   Durum: `ACIK`
   Not: aktif hesap kontrolu icin raw fallback halen duruyor.

### D. Dogrulama backlog'u durum kontrolu

1. Android gercek cihaz:
   Durum: `ACIK`
   Not: dokumante edilen senaryolari kapatan otomatik veya kayitli smoke sonucu yok.

2. iOS gercek cihaz:
   Durum: `ACIK`
   Not: `Profile/SocialProfile/avatar overlay/autoplay resume` tarafinda kayitli kapanis izi yok.

3. Zayif ag senaryosu:
   Durum: `ACIK`
   Not: fallback zinciri ve cache-first mantigi var; zayif ag matrix smoke henuz yok.

4. User metadata regression:
   Durum: `ACIK`
   Not: resolver yaygin; ama rozet/nickname/avatar regresyonlari icin ozel smoke ya da alarm yok.

### E. Analytics / KPI kullanimi durum kontrolu

- `cacheFirstLifecycle`
  Durum: `KISMEN`
  Not: event ve summary uretimi var; alarm esigi yok.
- `renderDiff`
  Durum: `KISMEN`
  Not: event ve summary uretimi var; threshold/alarm yok.
- `playbackWindow`
  Durum: `KISMEN`
  Not: event ve summary uretimi var; saha alarmi yok.
- startup `feedWarmSnapshotHit`
  Durum: `KISMEN`
  Not: splash/runtime ozetinde var; alarm yok.
- startup `shortWarmSnapshotHit`
  Durum: `KISMEN`
  Not: splash/runtime ozetinde var; alarm yok.
- render patch avg/max
  Durum: `KISMEN`
  Not: `renderDiff` summary icinde var; otomatik threshold yok.
- active/visible center thrash
  Durum: `ACIK`
  Not: dokumanda hedef metrik olarak var; repo icinde acik threshold/alarm katmani yok.
- player recreate rate
  Durum: `ACIK`
  Not: dogrudan merkezi recreate-rate alarm katmani henuz yok.

### F. Repo icinde henuz eksik olan altyapi

- `integration_test/` kritik smoke test dizini
  Durum: `KISMEN`
  Not: dizin + ortak bootstrap helper + 5 kritik smoke dosyasi acildi. Ilk dilim artik kararlı test key'leri ile `Feed`, `Explore`, `Profile`, `Short`, `Notifications` ekran hedeflerini buluyor; state probe ile `feed/short/profile/socialProfile/notifications/navBar` controller snapshot'i testten okunuyor; deterministic integration test mode ile startup intro/watchdog/periyodik yan etkiler sakinlestirildi; route replay helper'lari ile `Feed -> Explore/Profile/Short/Notifications -> Feed` zinciri ortaklastirildi; replay sonrasi `count zero drop`, `active doc preserve` ve `notifications unread non-negative` assertion'lari eklendi; fixture contract katmani ile `dart-define` uzerinden `minCount/docIds/maxUnread` beklentileri verilebilir hale geldi; `scripts/run_integration_smoke.sh` ve release gate entegrasyonu ile bu kontratlar otomatik kosuya baglandi. Sonraki adim fixture verisini production-benzeri sabit bir JSON ile doldurmak ve CI/device smoke adimina tasimak.
- `lib/Core/Services/runtime_invariant_guard.dart`
  Durum: `KISMEN`
  Not: ilk merkezi guard servisi eklendi; `Feed`, `Short`, `Profile`, `SocialProfile` ve `resume/empty-after-refresh` invariantlari ilk pass baglandi. Sonraki adim `Notifications`, `Short recreate`, `route replay` ve daha genis test coverage.
- telemetry threshold / alert policy katmani
  Durum: `EKSIK ALTYAPI`
- release gate tek komut akisi
  Durum: `EKSIK ALTYAPI`
- artifact toplama: screenshot + KPI dump + route dump
  Durum: `EKSIK ALTYAPI`
- flaky test / unstable raporlama katmani
  Durum: `EKSIK ALTYAPI`

### G. Bundan sonraki master uygulama sirasi

Fazli yuruyus:

1. Faz 0: baseline ve worktree hijyeni
   - dirty worktree siniflandirilir
   - generated / tmp / node_modules gurultusu ayiklanir
   - dar commit disiplini korunur
2. Faz 1: mimari envanter
   - kritik yuzeyler icin kaynak zinciri cikarilir:
     Firestore -> repository -> snapshot/cache -> resolver -> controller -> UI
3. Faz 2: correctness
   - feed/profile/short veri tutarliligi
   - refresh sonrasi kaybolma
   - hybrid feed / publish / filter parity
   - route-return correctness
4. Faz 3: runtime invariant guard
   - ilk pass basladi
   - sonraki alt adim:
     `Notifications`, `Short recreate`, `route replay`, `visible-center thrash`
5. Faz 4: integration smoke
   - `integration_test/` dizini
   - 5 kritik smoke senaryosu
   - deterministic startup/test mode
   - deterministic fixture
6. Faz 5: telemetry threshold + alarm
   - KPI esikleri
   - otomatik uyari / release-blocking kurallari
7. Faz 6: gercek cihaz matrisi
   - Android
   - iPhone
   - iPad/buyuk ekran
   - zayif ag profilleri
8. Faz 7: bilincli raw / legacy cleanup
   - raw kalacaklar
   - second-pass resolver adaylari
9. Faz 8: release gate
   - analyze + test + smoke + KPI summary + artifact export

Aktif faz:

- Su an `Faz 3` ilk dilimi aktif.
- Son tamamlanan kritik urun isi: feed visibility + hybrid feed fallback fix.
- Son tamamlanan kalite isi: `runtime invariant guard` ilk dilimi + `Notifications` invariantlari + `integration_test/` iskeleti.
- Son tamamlanan smoke isi: ana nav ve kritik ekranlar icin kararlı integration test key'leri.
- Son tamamlanan probe isi: kritik controller state'lerini testten okunabilir hale getiren state probe katmani.
- Son tamamlanan smoke derinlestirme isi: state assertion + route-back geri donusu + route replay helper'lari + replay continuity assertion'lari.
- Son tamamlanan deterministic kalite isi: integration startup test mode ile splash intro / watchdog / periyodik nav yan etkilerinin sakinlestirilmesi.
- Son tamamlanan fixture isi: integration fixture contract ile `minCount/docIds/maxUnread` beklentilerinin tanimlanabilmesi.
- Son tamamlanan gate isi: `scripts/run_integration_smoke.sh` + release gate optional smoke adimi.
- Sonraki teknik hedef: smoke testleri production-benzeri sabit fixture JSON + CI/device smoke parametresi + veri seviyesinde state assertion seviyesine tasimak.

1. Repo truth pass:
   dirty worktree ayiklama + bu master planin guncel tutulmasi
2. Manuel kritik dogrulama:
   `Feed`, `Short`, `MyProfile`, `SocialProfile`, `Explore`, `Notifications`, `SavedPosts`, `cached_user_avatar`
3. Bilincli raw alanlar karari:
   hangi ekranlar bilincli raw kalacak, hangileri second-pass optimizasyona alinacak
4. Runtime guard:
   invariant ihlallerini debug/profile modda gorunur hale getirmek
5. Integration smoke:
   5 kritik rota donusu / refresh / optimistic mutation senaryosunu otomatiklestirmek
6. Telemetry threshold + alerting:
   KPI'lari sadece log degil karar ureten release signal haline getirmek
7. Release gate:
   test + smoke + KPI summary + artifact export tek komutta

## Sonraki Oturumda Ilk Yapilacaklar

1. `git status` ile dirty worktree'yi dikkatli incele.
2. Bu notu ve `docs/architecture/cache_first_audit_2026_03_19.md` dosyasini ac.
3. `Master Plan Durum Kontrolu` kismini referans alip aciklari `KISMEN / ACIK / BILINCLI / EKSIK ALTYAPI` diye ayir.
4. Ilk manuel odak:
   `Feed autoplay tuning` + `Short playback churn olcumu`
5. Sonra:
   `Notifications`, `SavedPosts`, `MyProfile`, `SocialProfile`, `cached_user_avatar`, `Explore/SearchedUser` smoke/dogrulama
6. Sonraki teknik odak:
   dirty kalan raw/form ekranlarini tek tek ayirip sadece gerekli olanlari raw belgede birak
7. Sonraki kalite odagi:
   `runtime invariant guard + integration smoke tests + telemetry alarms + release gate`

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

Bu dosya, bundan sonra limit acildiginda dogrudan devam noktasi ve kanonik master plan olarak kullanilsin.
