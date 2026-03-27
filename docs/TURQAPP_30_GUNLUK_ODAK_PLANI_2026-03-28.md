# TurqApp 30 Gunluk Mimari Donusum ve Stabilizasyon Plani

Bu plan mevcut kod tabani temel alinarak hazirlandi.

Amac:

- Guvenlik ve veri siniri aciklarini kapatmak
- Startup ve session karmasini azaltmak
- Feed akisindaki mimari riski kontrol altina almak
- Test ve CI sinyallerini gercek koruma seviyesine cikarmak

Bu 30 gunde yapilmayacaklar:

- GetX -> Riverpod big-bang gecisi
- Tum klasor yapisini yeniden kurma
- Tam schema rewrite
- Genis capli kozmetik refactor
- Yuzde 100 coverage hedefi

## Basari Kriterleri

- Kritik auth ve veri yetkisi aciklari kapatilmis olacak
- Startup akisinda sorumluluklar ayrismis olacak
- Session yonetimi tek mega servis olmaktan cikmaya baslayacak
- Feed icin tek birincil akis tanimlanmis olacak
- CI daha gercekci kalite kapilari ile calisacak

## Yurutme Anayasasi

Bu plan yalnizca bir niyet listesi degil, sirali uygulama protokoludur.

Baglayici kurallar:

- Ayni anda yalnizca 1 is aktif olabilir
- Is sirasi onaysiz degistirilemez
- Aktif is bitmeden yeni bulguya gecilemez
- Yeni bulgular kayda girer ama aktif isi bolmez
- Her is icin kabul kriteri ve teknik dogrulama zorunludur
- Her is sonunda kullanici kontrol checklist'i verilir
- "Bunu da duzeltmisken" yaklasimi yasaktir
- Plansiz refactor yasaktir
- Yeni feature kodu icin yatay koklere donus yasaktir
- Hiz, dogrulama ve sira disiplininin yerine gecemez

Zorunlu kayit tipleri:

- `RISK-###`
  - aktif veya yaklasan risk
- `GAP-###`
  - planda eksik kalan ama eklenmesi gereken is
- `DEBT-###`
  - teknik borc kaydi
- `BLOCK-###`
  - aktif isi durduran engel

Kurallar:

- `RISK/GAP/DEBT/BLOCK` kayitlari aktif isten bagimsiz loglanir
- aktif is tamamlanmadan uygulanmaz
- yalnizca kritik blokaj, guvenlik acigi, veri kaybi riski veya uretim cokus riski varsa plan revizyonu istenir

## Ilerleme ve Puanlama Modeli

Plan ilerlemesi gorev sayisina gore degil, efor puanina gore izlenir.

Puanlar:

- `S = 1`
- `M = 2`
- `L = 3`
- `XL = 5`

Hesap:

- toplam ilerleme `% = tamamlanan puan / toplam puan x 100`
- toplam plan puani: `63`
- toplam numarali is sayisi: `26`

Rapor zorunlulugu:

- tamamlanan puan
- kalan puan
- tamamlanan is sayisi
- kalan is sayisi
- toplam ilerleme yuzdesi

## Is Tamamlandi Tanimi

Bir is ancak asagidaki sartlarin tamami saglandiginda bitmis sayilir:

- hedef karsilanmis olacak
- kabul kriteri saglanmis olacak
- teknik dogrulama yapilmis olacak
- yan etki kontrolu yapilmis olacak
- etkilenen dosyalar acikca listelenmis olacak
- kullanici kontrol adimlari verilmis olacak
- ilerleme ve kalan is raporu guncellenmis olacak

## Plan Revizyon Protokolu

Plan yalnizca asagidaki durumlarda revize edilir:

- kritik blokaj
- guvenlik acigi
- veri kaybi riski
- uretim cokus riski
- onceki is tamamlanmadan sonraki isin anlamsiz hale gelmesi

Revizyon formati:

- revizyon nedeni
- etkilenen isler
- eski sira
- yeni sira
- risk
- kazanım
- onay gerekiyor / gerekmiyor

## Hedef Katman Modeli

Bu repo icin hedef akış:

- View -> Controller -> UseCase/Application Service -> Repository -> DataSource

Ayri tutulacak runtime servisleri:

- `NotificationService`
- `VideoStateManager`
- `NetworkAwarenessService`
- `UploadQueueService`
- `SegmentCacheManager`
- `DeviceSessionService`

## Repo Guardrail'leri

Bu kurallar 30 gunluk planin disinda degil, planin baslangic kosuludur:

- UI/controller/widget katmani dogrudan `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseFunctions`, `Typesense`, `secure storage` ve lokal cache adapter'lari cagirmaz
- Splash icine yeni is eklenmez
- `CurrentUserService` icine yeni sorumluluk eklenmez
- Sessiz `catch (_) {}` yeni kodda yasaktir
- Her `catch` ya siniflandirilmis log uretecek ya da typed failure donecektir
- `Controller -> Service -> Service -> Service -> Repository` zinciri kurulmaz
- Basit CRUD yuzeyinde `Controller -> Repository` istisnasi kabul edilebilir
- Orchestration, capraz concern veya birden fazla repository/datasource kullanan akislar `UseCase/Application Service` katmanina cikarilir
- `lib/Core`, `lib/Services` ve `lib/Models` yatay kokleri yeni feature kodu icin dondurulur
- Yeni `*_facade_part.dart`, `*_fields_part.dart`, `*_class_part.dart` turevi dosya eklenmez
- Bir feature baska bir feature'in ic dosyasina import ile baglanmaz
- `Get.find<OtherFeatureController>()`, `Get.put(OtherFeatureController)` ve benzeri cross-feature locator baglari yeni kodda yasaktir

Kurallar:

- Controller yalnizca ekran state'i, loading/error ve kullanici aksiyonunu tutar
- Orchestration gerektiren her akis UseCase/Application Service'e tasinir
- Repository veri kaynagi secimini yapar ama ranking, visibility, fallback labirenti tasimaz
- DataSource yalnizca Firestore, Functions, Storage, Typesense, secure storage ve local cache ile konusur
- `Get.find<OtherFeatureController>()` ile feature baglama yeni kodda yasaklanir

## Mimari Guard ve Envanter

Bu plan yalnizca kural yazmakla yetinmez; kurallar CI ve rapor ile korunur.

Olusturulacaklar:

- `tool/check_architecture.dart` veya `scripts/check_architecture_guards.sh`
- import graph raporu
- GetX locator envanteri
- god-object envanteri
- yasak import ve yasak dosya isimleri denetimi

Ilk zorunlu guard kurallari:

- `presentation_cannot_touch_infra`
  - controller/view/widget katmani repository alti datasource veya Firebase/Storage/Functions paketlerine dokunamaz

- `no_cross_feature_internal_imports`
  - feature A, feature B'nin ic dosyasina import ile baglanamaz

- `no_service_locator_outside_root`
  - composition root disinda yeni global locator kullanimlari yasaktir

- `legacy_folder_freeze`
  - `lib/Core`, `lib/Services`, `lib/Models` altina yeni feature kodu acilmaz

- `no_new_part_sprawl`
  - yeni `facade/fields/class part` dosya kaliplari uretilemez

CI kurali:

- `architecture-guards` isi `flutter-quality` oncesi kosar
- kural ihlali olursa testler calismadan fail eder
- import graph ve locator envanteri artifact olarak saklanir

## Numaralandirilmis Master Yurutme Listesi

Bu liste planin resmi uygulama sirasidir.

| Is No | Baslik | Hafta | Efor | Puan | Bagimlilik |
| --- | --- | --- | --- | --- | --- |
| T-001 | Baseline envanteri, risk kaydi ve checkpoint matrisi | Hazirlik | M | 2 | - |
| T-002 | Yurutme anayasasi, DoD ve rapor standardini plana bagla | Hazirlik | S | 1 | T-001 |
| T-003 | Import graph, GetX locator ve god-object envanteri cikar | 1 | M | 2 | T-001 |
| T-004 | `reviewReportedTarget` auth fallback yolunu kapat | 1 | M | 2 | T-001 |
| T-005 | `firestore.rules` icinde `/users/{uid}` okuma yuzeyini daralt | 1 | M | 2 | T-004 |
| T-006 | `marketStore` client counter update yetkisini kapat | 1 | M | 2 | T-004 |
| T-007 | `storage.rules` bypass UID yolunu kaldir veya kontrollu hale getir | 1 | M | 2 | T-004 |
| T-008 | Parola saklama davranisini sonlandir ve re-auth kararini netlestir | 1 | L | 3 | T-004 |
| T-009 | `architecture-guards` altyapisini ve CI fail-fast zincirini kur | 1 | M | 2 | T-003 |
| T-010 | Splash startup orkestrasyonunu ayir | 2 | L | 3 | T-008, T-009 |
| T-011 | `StartupBootstrap`, `SessionBootstrap`, `PostLoginWarmup`, `DependencyRegistrar` ayrimini kur | 2 | L | 3 | T-010 |
| T-012 | `CurrentUserService` sorumluluklarini auth/cache/sync/account-center olarak ayir | 2 | XL | 5 | T-008, T-010 |
| T-013 | Sign-in ve stored-account akislarini UseCase/Application Service katmanina tasimaya basla | 2 | L | 3 | T-011, T-012 |
| T-014 | Startup/session tarafindaki genis `catch (_) {}` bloklarini siniflandirilmis failure modeline cevir | 2 | M | 2 | T-010 |
| T-015 | Feed icin tek birincil akis ve istemci contract tanimini yaz | 3 | M | 2 | T-003, T-009 |
| T-016 | `hybridFeed.ts` ile istemci feed contract'ini hizala | 3 | L | 3 | T-015 |
| T-017 | `AgendaController` orchestration adimlarini UseCase'e cek | 3 | L | 3 | T-015 |
| T-018 | `ShortController` ve `StoryRowController` orchestration adimlarini UseCase'e cek | 3 | L | 3 | T-015 |
| T-019 | Yuksek riskli direct Firebase erisim envanterini cikar | 3 | M | 2 | T-003 |
| T-020 | Ilk direct Firebase akislarini repository/usecase arkasina al | 3 | L | 3 | T-019 |
| T-021 | `functions/tests` altina reports/moderation/security regression testleri ekle | 4 | L | 3 | T-004, T-005, T-006, T-007 |
| T-022 | Auth/session/feed davranis testlerini genislet | 4 | L | 3 | T-013, T-015, T-016, T-017, T-018 |
| T-023 | Chat, market/job ve ads center icin ilk UseCase cikarimlarini baslat | 4 | L | 3 | T-009, T-012 |
| T-024 | Coverage gate'i gercek risk gosterecek seviyeye cek | 4 | S | 1 | T-021, T-022 |
| T-025 | Yaniltici widget testlerini gercek ekran davranisina bagla | 4 | M | 2 | T-022 |
| T-026 | Dokuman tek-kaynak kuralini ve tarihli plan yigilmama guard'ini koy | 4 | S | 1 | T-009 |

## Kritik Yol

Bu zincir planin resmi kritik yoludur:

- `T-001 -> T-002 -> T-003 -> T-004 -> T-005 -> T-006 -> T-007 -> T-008 -> T-009 -> T-010 -> T-011 -> T-012 -> T-013 -> T-015 -> T-016 -> T-017 -> T-018 -> T-020 -> T-021 -> T-022 -> T-024 -> T-026`

Destekleyici ama kritik yol disi isler:

- `T-014`
- `T-019`
- `T-023`
- `T-025`

## Feature Sahiplik Matrisi

Bu tablo "bu feature'i kim sahipleniyor" sorusunu kod bazli olarak tek cevaba indirir:

| Feature | Application owner | Read owner | Cache owner | Validation owner | Error translation |
| --- | --- | --- | --- | --- | --- |
| Startup/Auth | `Bootstrap*UseCase`, `SignIn*UseCase` | `UserRepository`, auth repository | `UserCacheService` | UseCase | Controller/UI |
| Session/Account switching | `SwitchStoredAccountUseCase` | account repository + user repository | `UserCacheService` + account cache | UseCase | Controller/UI |
| Feed | `LoadHomeFeedUseCase` | `FeedSnapshotRepository`, `PostRepository` | feed snapshot cache | UseCase | Controller/UI |
| Story/Short | `OpenStoryUseCase`, `LoadShortFeedUseCase` | story/short repositories | playback/cache runtime services | UseCase | Controller/UI |
| Chat | `SendChatMessageUseCase`, `MarkConversationReadUseCase` | conversation/message repository | chat local cache | UseCase | Controller/UI |
| Market | `SaveMarketItemUseCase`, `SubmitMarketOfferUseCase`, `SubmitMarketReviewUseCase` | `MarketRepository` | market cache | UseCase | Controller/UI |
| Job | `ApplyJobUseCase`, `SaveJobUseCase`, `SubmitJobReviewUseCase` | `JobRepository` | job cache | UseCase | Controller/UI |
| Ads Center | `LoadAdsDashboardUseCase`, `SaveAdCampaignUseCase` | ads repository | ads runtime/config cache | UseCase | Controller/UI |

## Dosya Bazli Odak Alanlari

Startup/Auth:

- `lib/Modules/Splash/splash_view_startup_part.dart`
- `lib/Modules/SignIn/sign_in_controller_auth_part.dart`
- `lib/Modules/SignIn/sign_in_controller_account_part.dart`
- `lib/Services/current_user_service.dart`
- `functions/src/24_reports.ts`

Feed/Story/Short:

- `lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart`
- `lib/Core/Repositories/post_repository_query_part.dart`
- `functions/src/hybridFeed.ts`
- `lib/Modules/Agenda/agenda_controller.dart`
- `lib/Modules/Short/short_controller.dart`
- `lib/Modules/Short/short_content_controller.dart`
- `lib/Modules/Story/StoryRow/story_row_controller.dart`
- `lib/Modules/Story/StoryViewer/story_viewer_controller.dart`

Chat:

- `lib/Modules/Chat/chat_controller_send_part.dart`
- `lib/Modules/Chat/chat_controller_conversation.dart`
- `lib/Modules/Chat/chat_controller_media_part.dart`
- `lib/Modules/Chat/chat_realtime_sync_policy.dart`

Market/Job:

- `lib/Modules/Market/market_controller.dart`
- `lib/Modules/Market/market_create_controller.dart`
- `lib/Core/Repositories/market_repository_action_part.dart`
- `lib/Core/Repositories/market_repository_query_part.dart`
- `lib/Modules/JobFinder/job_finder_controller.dart`
- `lib/Modules/JobFinder/JobDetails/job_details_controller.dart`
- `lib/Modules/JobFinder/FindingJobApply/finding_job_apply_controller.dart`
- `lib/Core/Repositories/job_repository_query_part.dart`

Ads Center:

- `lib/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart`
- `lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_actions_part.dart`
- `lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_runtime_part.dart`
- `lib/Core/Services/Ads/ads_repository_service.dart`
- `lib/Core/Services/Ads/ads_delivery_service.dart`

## Controller -> UseCase Cikarim Listesi

Ilk 30 gunde cikarilacak UseCase/Application Service adaylari:

- `Splash`
  - `BootstrapStartupUseCase`
  - `BootstrapSessionUseCase`
  - `PreparePostLoginWarmupUseCase`
  - `ResolveInitialRouteUseCase`

- `SignInController`
  - `SignInWithPasswordUseCase`
  - `SwitchStoredAccountUseCase`
  - `ResetPasswordUseCase`
  - `PersistSessionCredentialUseCase`

- `AgendaController`
  - `LoadHomeFeedUseCase`
  - `RefreshHomeFeedUseCase`

- `ShortController` / `ShortContentController`
  - `LoadShortFeedUseCase`
  - `PrepareShortPlaybackUseCase`
  - `ApplyShortInteractionUseCase`

- `StoryRowController` / `StoryViewerController`
  - `LoadStoryRowUseCase`
  - `OpenStoryUseCase`
  - `CloseStoryUseCase`
  - `SyncStoryPlaybackUseCase`

- `ChatController`
  - `SendChatMessageUseCase`
  - `UploadChatMediaUseCase`
  - `MarkConversationReadUseCase`
  - `ApplyChatNotificationPolicyUseCase`

- `Market`
  - `SaveMarketItemUseCase`
  - `SubmitMarketOfferUseCase`
  - `SubmitMarketReviewUseCase`
  - `ToggleSavedMarketItemUseCase`

- `JobFinder`
  - `ApplyJobUseCase`
  - `SaveJobUseCase`
  - `SubmitJobReviewUseCase`

- `AdsCenter`
  - `LoadAdsDashboardUseCase`
  - `SaveAdCampaignUseCase`
  - `PreviewAdDeliveryUseCase`
  - `ReviewCreativeUseCase`

## Runtime Servis Olarak Kalacaklar

Asagidaki tipler UseCase olmayacak; bunlar runtime altyapi servisleri olarak kalacak:

- bildirim gosterme / kaydetme
- video ve audio playback state koordinasyonu
- cache kotasi ve segment cache yonetimi
- upload queue ve background retry
- cihaz/session claim mekanigi
- network farkindaligi

## Kritik Parcalama Hedefleri

Bu 30 gunde en once parcali hale getirilecek merkezler:

- `lib/Modules/Splash/splash_view_startup_part.dart`
  - `StartupBootstrap`
  - `SessionBootstrap`
  - `PostLoginWarmup`
  - `DependencyRegistrar`

- `lib/Services/current_user_service.dart`
  - `AuthSessionService`
  - `UserProfileStore`
  - `UserCacheService`
  - `AccountCenterSyncService`
  - `UserLifecycleGuard`

- `lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart`
  - `PrimaryFeedSource`
  - `FallbackFeedSource`
  - `FeedMergePolicy`
  - `FeedVisibilityPolicy`

## Sadelestirilecek Repository Alanlari

- `FeedSnapshotRepository`
  - fallback, visibility ve source secim labirenti UseCase katmanina cekilecek

- `MarketRepository`
  - save/offer/review orchestration'i repository disina alinacak

- `JobRepository`
  - apply/save/review policy'si repository disina alinacak

- Chat repository/conversation repository
  - notification policy ve read-side effect'leri UseCase'e cekilecek

- Ads repository/service yuzeyi
  - dashboard, campaign save ve delivery preview orchestration'i UseCase'e cekilecek

## Fallback Politikasi

Bu repo icin fallback kurali acik olacak:

- Her kritik akis bir tane birincil yola sahip olacak
- Her kritik akis en fazla bir tane acil durum fallback'i tasiyacak
- `legacy fallback` kalici durum olmayacak
- Yeni fallback ekleniyorsa:
  - sebebi yazilacak
  - cikis kriteri yazilacak
  - kaldirilma tarihi belirlenecek

Bu kural ilk olarak feed tarafinda uygulanacak.

## 1. Hafta: Guvenlik ve Sinirlar

Hedef:

- Dogrudan risk tasiyan aciklari kapatmak
- Veri ve authz sinirlarini sertlestirmek
- Yeni mimari erozyonu hemen durdurmak

Isler:

- `functions/src/24_reports.ts` icindeki `reviewReportedTarget` auth fallback yolunu kaldir
- `firestore.rules` icinde `/users/{uid}` okuma yuzeyini daralt
- `firestore.rules` icinde `marketStore` client counter update yetkisini kapat
- `storage.rules` icindeki hardcoded bypass UID kullanimini config temelli hale getir veya kaldir
- `lib/Services/account_session_vault.dart` ve sign-in akisinda parola saklama davranisini sonlandir
- Yeni katman kurali ekle:
  - orchestration controller'da kalmaz
  - yeni feature kodu `Controller -> UseCase/Application Service -> Repository -> DataSource` cizgisini izler
- `tool/check_architecture.dart` veya `scripts/check_architecture_guards.sh` olustur
- import graph ve GetX locator envanteri cikar
- `architecture-guards` CI isi ekle
- `legacy_folder_freeze`, `no_cross_feature_internal_imports`, `no_new_part_sprawl` kurallarini fail-fast hale getir

Teslimatlar:

- Guvenlik aciklari icin testler
- Kurallarda daraltilmis erisim modeli
- Multi-account akisinda parolasiz gecis veya kontrollu re-auth karari
- import graph raporu
- GetX locator raporu
- calisan architecture-guards CI isi

Cikis Kriteri:

- Kritik admin callable auth bypass kapanmis olacak
- Client tarafindan veri butunlugunu bozabilen update yollarinin ana kismi kapanmis olacak
- Yeni mimari erozyon CI tarafinda gorunur hale gelmis olacak
- `T-004` - `T-009` arasi isler tamamlanmis olacak

## 2. Hafta: Startup ve Session Toparlama

Hedef:

- Uygulama acilis yolunu sadeleştirmek
- Session yonetimini parcali hale getirmek

Isler:

- `lib/Modules/Splash/splash_view_startup_part.dart` icinden startup orkestrasyonunu ayir
- Ayri sorumluluklar olustur:
  - `StartupBootstrap`
  - `SessionBootstrap`
  - `PostLoginWarmup`
  - `DependencyRegistrar`
- `lib/Services/current_user_service.dart` icinde auth, cache, sync ve account-center baglarini ayikla
- `lib/Modules/SignIn/sign_in_controller_auth_part.dart` icindeki sign-in ve stored-account gecis akislarini UseCase/Application Service'e tasimaya basla
- Genis `catch (_) {}` bloklarini siniflandirilmis log + kontrollu fallback modeline cevir

Teslimatlar:

- Ayrismis startup akis cizgisi
- `CurrentUserService` icin sorumluluk parcasi cikarimi
- Startup ve session icin ilk davranis testleri

Cikis Kriteri:

- Splash artik her seyin merkezi olmayacak
- Session davranisinda en az birincil sorumluluklar ayrilmis olacak
- `T-010` - `T-014` arasi isler tamamlanmis olacak

## 3. Hafta: Feed ve Veri Erisimi Disiplini

Hedef:

- Feed akisindaki asiri fallback zincirini kontrol altina almak
- Veri erisimine tek giris kapisi koymak

Isler:

- `lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart` icin birincil feed yolunu netlestir
- `functions/src/hybridFeed.ts` ile istemci feed contract'ini uyumlu hale getir
- `AgendaController`, `ShortController`, `StoryRowController` icindeki orchestration adimlarini UseCase'e cek
- `lib/Modules`, `lib/Services`, `lib/Core` altinda dogrudan Firebase kullanan yuksek riskli akislari envanterle
- Yeni kural koy:
  - Controller/widget dogrudan Firebase'e gitmez
  - Service/use-case ve repository uzerinden gider
- Ilk etapta auth, post delete, phone limiter, short post, offline mode gibi yuksek riskli akislari repository arkasina cek

Teslimatlar:

- Feed contract notu
- Doğrudan Firebase cagri envanteri
- Ilk tasinmis yuksek riskli akislar

Cikis Kriteri:

- Feed icin birincil yol tanimli olacak
- Yeni direct Firebase erisimi eklenmeyecek
- `T-015` - `T-020` arasi isler tamamlanmis olacak

## 4. Hafta: Test, CI ve Kalici Dokuman Seti

Hedef:

- Kalite sinyalini gerceklestirmek
- Yeniden dokuman kalabaligi olusmasini engellemek

Isler:

- `functions/tests` altina reports/moderation/security regression testleri ekle
- Auth/session/feed kritik akislari icin davranis testlerini genislet
- Chat, market/job ve ads center akislarinda ilk UseCase cikarimlarini baslat
- `scripts/check_flutter_coverage.sh` ve `config/quality/flutter_coverage_policy.env` icindeki zayif coverage gate'i gercekci seviyeye cek
- `test/widget/screens/sign_in_test.dart` benzeri yaniltici testleri gercek ekran davranisina bagla
- `docs/README.md` disinda tarihli yeni plan/analiz birikmesini durduracak repo kurali koy

Teslimatlar:

- Kritik backend test paketi
- Guclendirilmis coverage gate
- Temiz ve tek kaynakli dokuman girisi

Cikis Kriteri:

- CI mevcut durumu gizleyen degil, gercek risk gosteren sinyaller uretecek
- Dokuman seti yeniden dagilmayacak sekilde sade kalacak
- `T-021` - `T-026` arasi isler tamamlanmis olacak

## Mimari Kontrat Testleri

Refactor sonrasi su davranis testleri olmadan is tamamlanmis sayilmaz:

- startup akis testi
- session restore ve sign-out testi
- account switching testi
- feed source secimi testi
- admin callable auth siniri testi
- visibility/filter policy testi
- chat send/read policy testi
- market/job apply-save-review policy testi

Static guard testleri:

- feature ic import ihlali testi
- presentation -> infra erisim ihlali testi
- locator kullanim siniri testi
- legacy folder freeze testi
- yeni part-sprawl kaliplari testi

## Her Is Sonu Zorunlu Rapor Formati

Her is bitiminde asagidaki format zorunludur:

- Is No
- Baslik
- Durum: `Tamamlandi / Kismi / Bloklu`
- Bu iste yapilanlar
- Somut kazanımlar
- Etkilenen dosyalar
- Teknik dogrulama
- Benim kontrol etmem gerekenler
- Risk veya dikkat notu
- Toplam ilerleme
- Tamamlanan puan
- Kalan puan
- Tamamlanan is sayisi
- Kalan is sayisi
- Siradaki onerilen is
- Yeni bulunan ama plana alinmamis konular

`Benim kontrol etmem gerekenler` alani zorunludur ve kisa maddeler halinde yazilir.

## Her 5 Iste Bir Plan Sagligi Gozden Gecirmesi

Asagidaki islerden sonra plan yeniden gozden gecirilir:

- `T-005`
- `T-010`
- `T-015`
- `T-020`
- `T-025`

Zorunlu kontrol basliklari:

- basta dusunulmeyen eksik var mi
- plan sirasi hala dogru mu
- yeni bagimlilik cikti mi
- onceki karar yanlislandi mi
- teknik borc buyuyor mu
- kapsam kaymasi basladi mi

Cikti formati:

- plan sagligi: `iyi / riskli / revizyon gerekli`
- yeni eksikler
- kapatilan riskler
- kalan ana riskler

## Gunlere Gore Onerilen Sira

1-3. gun:

- Kritik auth ve rules aciklari

4-7. gun:

- Parola saklama ve session yuzeyi

8-14. gun:

- Splash ve CurrentUserService parcalama

15-21. gun:

- Feed contract ve repository boundary

22-30. gun:

- Test, CI ve kalan kritik temizlik

## Roller

- Backend:
  - Functions authz
  - Firestore/Storage rules
  - Feed contract

- Flutter/Fullstack:
  - Splash
  - CurrentUserService
  - Sign-in/account center
  - Repository boundary

- QA/Platform:
  - Test kapsami
  - Coverage gate
  - CI sinyal kalitesi

## Sonuc Beklentisi

30 gun sonunda hedef, projeyi "temiz mimariye gecmis" hale getirmek degil; en yuksek riskli kaosu durdurmus, sinirlari sertlestirmis ve sonraki 60-90 gunluk refactor'u guvenli hale getirmis olmak.
