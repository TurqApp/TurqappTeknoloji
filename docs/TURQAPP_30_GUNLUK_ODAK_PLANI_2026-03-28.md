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

## Basari KPI'lari

Bu plan yalnizca nitel degil, olculebilir sinyallerle takip edilir.

- `KPI-01`
  - `T-004` - `T-007` kapsamindaki authz/rules degisiklikleri icin ilgili testler yesil olacak
- `KPI-02`
  - `T-008` tamamlandiginda cihazda parola saklayan aktif uygulama yolu kalmayacak
- `KPI-03`
  - `T-009` tamamlandiginda yeni `Core/Services/Models` feature dosyasi ekleme ve yeni part-sprawl ihlalleri CI'da fail edecek
- `KPI-04`
  - `T-011` tamamlandiginda startup akisinin sorumluluklari en az 4 acik role ayrilmis olacak
- `KPI-05`
  - `T-015` - `T-016` tamamlandiginda feed icin `1` birincil yol ve en fazla `1` acil durum fallback tanimli olacak
- `KPI-06`
  - `T-022` tamamlandiginda startup, session, account switching ve feed source secimi davranis testleri yesil olacak
- `KPI-07`
  - `T-024` tamamlandiginda coverage gate sahte yesil vermeyecek; esik ve istisnalar yazili olacak
- `KPI-08`
  - `T-026` tamamlandiginda tarihli yeni plan/doc yigini olusturan ihlal en az bir guard ile gorunur olacak

## Yurutme Anayasasi

Bu plan yalnizca bir niyet listesi degil, sirali uygulama protokoludur.

Baglayici kurallar:

- Ayni anda yalnizca 1 kritik-yol isi aktif olabilir
- Kritik yola dokunmayan en fazla 1 yan is, cakismayan dosya ve alanlarda paralel ilerleyebilir
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
- yan is, kritik-yol isinin onune gecemez ve aktif kritik-yol isini bloke edemez
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
- toplam plan puani: `65`
- toplam numarali is sayisi: `28`

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

## Guard Istisna Protokolu

Architecture guard'lar icin kalici sessiz istisna modeli yoktur.

Gecici istisna gerekiyorsa zorunlu alanlar:

- kural adi
- ihlal eden dosya veya path
- neden gerekli oldugu
- owner
- acilis tarihi
- bitis / kaldirma tarihi
- kaldiracak is numarasi

Kurallar:

- istisna olmadan guard atlatilmaz
- suresiz istisna yasaktir
- bitis tarihi gecen istisna CI'da warning degil fail uretir
- bir istisna ikinci kez uzatilacaksa plan revizyonu gerekir

## Numaralandirilmis Master Yurutme Listesi

Bu liste planin resmi uygulama sirasidir.

| Is No | Baslik | Hafta | Owner | Efor | Puan | Bagimlilik |
| --- | --- | --- | --- | --- | --- | --- |
| T-001 | Baseline envanteri, risk kaydi ve checkpoint matrisi | Hazirlik | Flutter/Fullstack | M | 2 | - |
| T-002 | Yurutme anayasasi, DoD ve rapor standardini plana bagla | Hazirlik | Flutter/Fullstack | S | 1 | T-001 |
| T-003 | Import graph, GetX locator ve god-object envanteri cikar | 1 | QA/Platform | M | 2 | T-001 |
| T-004 | `reviewReportedTarget` auth fallback yolunu kapat | 1 | Backend | M | 2 | T-001 |
| T-005 | `firestore.rules` icinde `/users/{uid}` okuma yuzeyini daralt | 1 | Backend | M | 2 | T-004 |
| T-006 | `marketStore` client counter update yetkisini kapat | 1 | Backend | M | 2 | T-004 |
| T-007 | `storage.rules` bypass UID yolunu kaldir veya kontrollu hale getir | 1 | Backend | M | 2 | T-004 |
| T-008 | Parola saklama davranisini sonlandir ve re-auth kararini netlestir | 1 | Flutter/Fullstack | L | 3 | T-004 |
| T-009 | `architecture-guards` altyapisini ve CI fail-fast zincirini kur | 1 | QA/Platform | M | 2 | T-003 |
| T-010 | Splash startup orkestrasyonunu ayir | 2 | Flutter/Fullstack | L | 3 | T-008, T-009 |
| T-011 | `StartupBootstrap`, `SessionBootstrap`, `PostLoginWarmup`, `DependencyRegistrar` ayrimini kur | 2 | Flutter/Fullstack | L | 3 | T-010 |
| T-012 | `CurrentUserService` sorumluluklarini auth/cache/sync/account-center olarak ayir | 2 | Flutter/Fullstack | XL | 5 | T-008, T-010 |
| T-013 | Sign-in ve stored-account akislarini UseCase/Application Service katmanina tasimaya basla | 2 | Flutter/Fullstack | L | 3 | T-011, T-012 |
| T-014 | Startup/session tarafindaki genis `catch (_) {}` bloklarini siniflandirilmis failure modeline cevir | 2 | Flutter/Fullstack | M | 2 | T-010 |
| T-015 | Feed icin tek birincil akis ve istemci contract tanimini yaz | 3 | Flutter/Fullstack | M | 2 | T-003, T-009 |
| T-016 | `hybridFeed.ts` ile istemci feed contract'ini hizala | 3 | Backend | L | 3 | T-015 |
| T-017 | `AgendaController` orchestration adimlarini UseCase'e cek | 4 | Flutter/Fullstack | L | 3 | T-015, T-016, T-023A |
| T-018 | `ShortController` ve `StoryRowController` orchestration adimlarini UseCase'e cek | 4 | Flutter/Fullstack | L | 3 | T-015, T-016, T-017 |
| T-019 | Yuksek riskli direct Firebase erisim envanterini cikar | 3 | QA/Platform | M | 2 | T-003 |
| T-020 | Ilk direct Firebase akislarini repository/usecase arkasina al | 3 | Flutter/Fullstack | L | 3 | T-019 |
| T-021 | `functions/tests` altina reports/moderation/security regression testleri ekle | 4 | Backend | L | 3 | T-004, T-005, T-006, T-007 |
| T-022 | Auth/session/feed davranis testlerini genislet | 4 | QA/Platform | L | 3 | T-013, T-015, T-016, T-017, T-018 |
| T-023A | Market/job icin ilk bounded-context UseCase pilotunu uygula | 3 | Flutter/Fullstack | M | 2 | T-009, T-012, T-020 |
| T-023B | Ads center icin ikinci kucuk UseCase pilotunu uygula | 4 | Flutter/Fullstack | S | 1 | T-009, T-012, T-023A |
| T-023C | Chat icin ilk UseCase cikarimini baslat | 4 | Flutter/Fullstack | M | 2 | T-009, T-012, T-023A |
| T-024 | Coverage gate'i gercek risk gosterecek seviyeye cek | 4 | QA/Platform | S | 1 | T-021, T-022 |
| T-025 | Yaniltici widget testlerini gercek ekran davranisina bagla | 4 | QA/Platform | M | 2 | T-022 |
| T-026 | Dokuman tek-kaynak kuralini ve tarihli plan yigilmama guard'ini koy | 4 | QA/Platform | S | 1 | T-009 |

## Kritik Yol

Bu zincir planin resmi kritik yoludur:

- `T-001 -> T-002 -> T-003 -> T-004 -> T-005 -> T-006 -> T-007 -> T-008 -> T-009 -> T-010 -> T-011 -> T-012 -> T-013 -> T-015 -> T-016 -> T-019 -> T-020 -> T-023A -> T-017 -> T-018 -> T-021 -> T-022 -> T-024 -> T-026`

Destekleyici ama kritik yol disi isler:

- `T-014`
- `T-023B`
- `T-023C`
- `T-025`

## Cevresel Onkosullar ve Blokaj Kontrolu

Bu plan calismaya baslamadan once asagidaki onkosullar dogrulanir:

- Flutter SDK, Android toolchain ve iOS toolchain calisir durumda olacak
- Firebase Emulator Suite lokal olarak ayaga kalkabiliyor olacak
- `functions` bagimliliklari kurulabiliyor olacak
- test kullanicilari ve fixture/seed akislarina erisim olacak
- Android fiziksel cihaz veya emulator, iOS simulator veya fiziksel cihaz hazir olacak
- CI tarafinda gerekli secret'lar tanimli olacak:
  - `INTEGRATION_LOGIN_EMAIL`
  - `INTEGRATION_LOGIN_PASSWORD`
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
- Kritik degisikliklerden once geri donus icin commit/checkpoint alinmis olacak

Bir is baslamadan once blokaj sorulari:

- Bu is icin gerekli emulator/cihaz hazir mi
- Bu is icin gerekli secret veya fixture var mi
- Rules veya backend degisikligi lokal test edilebilir mi
- Rollback noktasi alinmis mi

## Rollback / Checkpoint Tablosu

Kritik islerden once ve sonra bu tablo doldurulur.

| Checkpoint | Ilgili is | Onceki commit/branch | Dogrulama notu | Geri donus yontemi | Durum |
| --- | --- | --- | --- | --- | --- |
| CP-001 | T-001 oncesi | doldurulacak | baseline dogrulamasi | branch veya commit reset/cherry-pick plani | Acik |
| CP-002 | T-004 oncesi | doldurulacak | callable/rules fallback davranisi | functions/rules rollback plani | Acik |
| CP-003 | T-008 oncesi | doldurulacak | account/session davranisi | sign-in/session rollback plani | Acik |
| CP-004 | T-010 oncesi | doldurulacak | startup route ve splash davranisi | startup rollback plani | Acik |
| CP-005 | T-015 oncesi | doldurulacak | feed source davranisi | feed contract rollback plani | Acik |
| CP-006 | T-023A oncesi | doldurulacak | pilot modul davranisi | pilot modul rollback plani | Acik |

Kurallar:

- checkpoint alinmadan kritik is acilmaz
- her checkpoint bir dogrulama notu ile kaydedilir
- geri donus yontemi "gerekirse bakariz" seviyesinde birakilamaz

## Fixture / Seed Checklist

Bu checklist ozellikle rules, backend ve davranis testleri icin canli tutulur.

- auth test kullanicisi mevcut mu
- admin callable test fixture'i mevcut mu
- market counter fixture'i mevcut mi
- storage upload fixture'i mevcut mu
- feed/hybrid feed fixture'i mevcut mu
- account switching test cift-hesap fixture'i mevcut mu
- chat conversation fixture'i mevcut mu
- ads dashboard/campaign fixture'i mevcut mu
- lokal env ve secret ihtiyaclari yazili mi
- ilgili test hangi fixture'a bagimli acikca not edilmis mi

Kurallar:

- fixture olmadan davranis testi yazildi sayilmaz
- test hangi fixture'a bagimli ise gorev raporunda yazilir
- yeni fixture ihtiyaci bulunursa `GAP-###` olarak kayda girer

## Standart Dogrulama Paketi

Her iste tum paket kosulmaz; ama is tipine gore asagidaki standart setten secim yapilir:

- Mimari/disiplin isleri:
  - `architecture-guards`
  - import graph raporu
  - locator envanteri diff'i
- Flutter davranis degisikligi:
  - ilgili unit/widget testleri
  - gerekiyorsa `flutter analyze --no-fatal-infos`
  - ilgili smoke veya manuel cihaz dogrulamasi
- Backend/rules degisikligi:
  - ilgili `functions/tests`
  - `npm run test:rules`
  - callable veya rule davranisinin fixture ile dogrulanmasi
- CI/policy degisikligi:
  - ilgili script dry-run veya local invocation
  - workflow mantiginin satir bazli kontrolu

Zorunlu minimum:

- Her is en az 1 teknik dogrulama adimi ile kapanir
- Kurali degistiren her is en az 1 guard/test ile kapanir
- Auth, rules, feed ve session isleri yalnizca kod okumasiyla kapanmaz

## Gorev Karti Matrisi

Bu matris her `T-###` isinin kapanis olcutunu resmi hale getirir.

| Is No | Kabul kriteri | Teknik dogrulama | Benim kontrol etmem gerekenler |
| --- | --- | --- | --- |
| T-001 | Baseline risk/checkpoint kaydi ve mevcut durum tablosu cikmis olacak | git/status + envanter raporu | Risk listesi ve checkpoint mantikli mi |
| T-002 | Yurutme kurallari plana baglanmis olacak | plan diff kontrolu | Is sirasi ve rapor formati net mi |
| T-003 | import graph, locator ve god-object raporu uretilmis olacak | guard script veya rapor dosyasi | En sorunlu moduller gercekten gorunuyor mu |
| T-004 | auth fallback yolu tamamen kapanmis olacak | functions unit testi + callable kontrolu | Yetkisiz kullanici artik review path'ine giremiyor mu |
| T-005 | `/users/{uid}` okuma yuzeyi daralmis olacak | rules testi | Profil akislari gerektigi kadar calisiyor mu |
| T-006 | `marketStore` client counter update yolu kapanmis olacak | rules testi | Kaydetme/sayac davranisi bozuldu mu |
| T-007 | storage bypass UID yolu kalkmis veya kontrollu hale gelmis olacak | storage rules testi | Upload akislarinda gizli bypass kaldi mi |
| T-008 | parola cihazda tutulmayacak; re-auth yolu net olacak | sign-in/account testleri | Hesap gecisi ve yeniden giris davranisi dogru mu |
| T-009 | architecture guards CI oncesi fail-fast kosacak | local guard run + workflow kontrolu | Yeni ihlal oldugunda CI duruyor mu |
| T-010 | splash artik merkezi orkestrasyon yigini olmayacak | ilgili startup testleri | Acilis akisinda ekran sapmasi var mi |
| T-011 | startup rolleri ayrismis olacak | birim test + satir bazli akis kontrolu | Session/bootstrap rolleri ayrik mi |
| T-012 | `CurrentUserService` auth/cache/sync/account-center olarak parcali hale gelmis olacak | service testleri + import kontrolu | Tek mega servis davranisi gercekten azaldi mi |
| T-013 | sign-in ve stored-account akislarinin ana orkestrasyonu usecase'e alinmis olacak | davranis testleri | Giris ve hesap gecisi akisi stabil mi |
| T-014 | genis sessiz catch bloklari siniflandirilmis olacak | ilgili test + log kontrolu | Hata oldugunda artik nedeni gorunuyor mu |
| T-015 | tek birincil feed yolu ve contract notu olacak | contract testi + dokuman kontrolu | Feed'in resmi birincil yolu net mi |
| T-016 | istemci feed contract'i backend ile uyumlu olacak | unit/integration dogrulamasi | Feed bos/yanlis fallback'e dusuyor mu |
| T-017 | `AgendaController` orchestration'i usecase'e alinmis olacak | unit test + import kontrolu | Feed controller daha sade mi |
| T-018 | short/story orchestration'i usecase'e alinmis olacak | ilgili testler | Story/short lifecycle bozuldu mu |
| T-019 | direct Firebase erisim envanteri cikarilmis olacak | kod tarama raporu | En riskli dogrudan erisimler gorunuyor mu |
| T-020 | ilk yuksek riskli direct Firebase akislar repository/usecase arkasina alinmis olacak | ilgili testler + guard | Artik widget/controller dogrudan Firebase'e gidiyor mu |
| T-021 | reports/moderation/security regression test paketi eklenmis olacak | functions test run | Kritik backend korumalari testle gorunuyor mu |
| T-022 | auth/session/feed davranis testleri genislemis olacak | test run | En kritik akislarda regression kapsaniyor mu |
| T-023A | market/job bounded-context usecase pilotu calisiyor olacak | ilgili davranis testleri + guard | Pilot model diger alanlara tasinabilir kadar net mi |
| T-023B | ads center icin ikinci kucuk usecase pilotu calisiyor olacak | ilgili test/guard | Kucuk ikinci pilotta katman kurali korunuyor mu |
| T-023C | chat usecase cikarimi baslamis olacak | ilgili test/guard | Sohbet akisinda controller orkestrasyonu azaldi mi |
| T-024 | coverage gate gercek risk gosterecek seviyeye gelmis olacak | script calistirma + policy kontrolu | Gate sahte yesil uretmiyor mu |
| T-025 | yaniltici widget testleri ekran davranisina baglanmis olacak | widget test run | Test gercek davranisi olcuyor mu |
| T-026 | dokuman tek-kaynak guard'i aktif olacak | repo guard + policy kontrolu | Yeni tarihli plan yigini tekrar olusuyor mu |

## Buyuk Islerin Alt Kirilimi

Asagidaki isler tek parca ilerlemeye uygun degil; resmi is numarasi korunur ama ic icra sirasinda alt kirilim kullanilir.

`T-012` alt kirilim:

- `T-012A` `AuthSessionService`
- `T-012B` `UserCacheService`
- `T-012C` `UserProfileStore`
- `T-012D` `AccountCenterSyncService`
- `T-012E` `UserLifecycleGuard`

`T-020` alt kirilim:

- `T-020A` auth ve session kaynakli direct Firebase akislar
- `T-020B` post delete / phone limiter / moderation benzeri yuksek riskli akislar
- `T-020C` short post / offline mode / upload siniri benzeri akislar

`T-023A`, `T-023B` ve `T-023C` artik ayri birer resmi is kartidir; parent alt kirilim olarak degil, dogrudan plan ilerlemesine sayilir.

## Mimari Kontrat Testi Esleme Matrisi

Bu esleme, hangi testin hangi isi kapattigini netlestirir.

| Test/Kontrat | Bagli isler |
| --- | --- |
| startup akis testi | T-010, T-011, T-014 |
| session restore ve sign-out testi | T-008, T-012, T-013 |
| account switching testi | T-008, T-013 |
| feed source secimi testi | T-015, T-016, T-017, T-018 |
| admin callable auth siniri testi | T-004 |
| visibility/filter policy testi | T-015, T-016 |
| chat send/read policy testi | T-023C |
| market/job apply-save-review policy testi | T-023A |
| ads center dashboard/campaign policy testi | T-023B |
| feature ic import ihlali testi | T-009, T-026 |
| presentation -> infra erisim ihlali testi | T-009, T-020 |
| locator kullanim siniri testi | T-009, T-017, T-018, T-023A, T-023B, T-023C |
| legacy folder freeze testi | T-009, T-026 |
| yeni part-sprawl kaliplari testi | T-009, T-026 |

## Aktif Risk Register

Bu tablo canli tutulur; her is sonu guncellenir.

| Kayit | Tip | Siddet | Ilgili is | Durum | Aciklama |
| --- | --- | --- | --- | --- | --- |
| RISK-001 | Risk | Yuksek | T-005, T-007 | Acik | Rules daraltilirken profil okuma ve upload akislarinin kirilma riski var |
| RISK-002 | Risk | Yuksek | T-008, T-013 | Acik | Parola saklama kalkarken mevcut hesap gecisi davranisi bozulabilir |
| RISK-003 | Risk | Orta | T-009 | Acik | Architecture guard false-positive uretip CI'yi gereksiz kilitleyebilir |
| RISK-004 | Risk | Yuksek | T-015, T-016 | Acik | Feed contract yanlis sabitlenirse legacy fallback'e bagimli akislar bozulabilir |
| GAP-001 | Gap | Orta | T-001 | Kapandi | Rollback/checkpoint standardi plan icine eklendi; T-001'de canli kayit doldurulacak |
| GAP-002 | Gap | Orta | T-021, T-022 | Kapandi | Fixture/seed checklist planda tanimlandi; uygulamada test bazli doldurulacak |


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

## 3. Hafta: Veri Erisimi Disiplini ve Ilk Pilot

Hedef:

- Veri erisimine tek giris kapisi koymak
- Feed akisindaki asiri fallback zincirini kontrol altina almak
- Sosyal refactor'a girmeden once daha dar bir bounded-context pilotu kanitlamak

Pilot sirasi:

- `Market/Job -> Ads Center -> Chat -> Social controller refactor`

Isler:

- `lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart` icin birincil feed yolunu netlestir
- `functions/src/hybridFeed.ts` ile istemci feed contract'ini uyumlu hale getir
- `lib/Modules`, `lib/Services`, `lib/Core` altinda dogrudan Firebase kullanan yuksek riskli akislari envanterle
- Yeni kural koy:
  - Controller/widget dogrudan Firebase'e gitmez
  - Service/use-case ve repository uzerinden gider
- Ilk etapta auth, post delete, phone limiter, short post, offline mode gibi yuksek riskli akislari repository arkasina cek
- `Market` / `Job` akislarinda ilk bounded-context UseCase pilotunu cikar

Teslimatlar:

- Feed contract notu
- Dogrudan Firebase cagri envanteri
- Ilk tasinmis yuksek riskli akislar
- Calisan ilk pilot modul kalibi

Cikis Kriteri:

- Feed icin birincil yol tanimli olacak
- Yeni direct Firebase erisimi eklenmeyecek
- Daha kucuk bir pilot modulde katman kurali sahada kanitlanmis olacak
- `T-015`, `T-016`, `T-019`, `T-020` ve `T-023A` tamamlanmis olacak

## 4. Hafta: Sosyal Orkestrasyon, Test, CI ve Kalici Dokuman Seti

Hedef:

- Kalite sinyalini gerceklestirmek
- Pilotta kanitlanan kalibi daha riskli sosyal akislar icin uygulamak
- Yeniden dokuman kalabaligi olusmasini engellemek

Isler:

- `AgendaController`, `ShortController`, `StoryRowController` icindeki orchestration adimlarini UseCase'e cek
- Ads center icin ikinci kucuk UseCase pilotunu cikar
- Chat akislarinda ilk UseCase cikarimlarini baslat
- `functions/tests` altina reports/moderation/security regression testleri ekle
- Auth/session/feed kritik akislari icin davranis testlerini genislet
- `scripts/check_flutter_coverage.sh` ve `config/quality/flutter_coverage_policy.env` icindeki zayif coverage gate'i gercekci seviyeye cek
- `test/widget/screens/sign_in_test.dart` benzeri yaniltici testleri gercek ekran davranisina bagla
- `docs/README.md` disinda tarihli yeni plan/analiz birikmesini durduracak repo kurali koy

Teslimatlar:

- Kritik backend test paketi
- Guclendirilmis coverage gate
- Temiz ve tek kaynakli dokuman girisi

Cikis Kriteri:

- CI mevcut durumu gizleyen degil, gercek risk gosteren sinyaller uretecek
- Sosyal controller refactor'u pilotta dogrulanan kalipla ilerlemis olacak
- Dokuman seti yeniden dagilmayacak sekilde sade kalacak
- `T-017`, `T-018`, `T-021`, `T-022`, `T-023B`, `T-023C`, `T-024`, `T-025`, `T-026` tamamlanmis olacak

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
