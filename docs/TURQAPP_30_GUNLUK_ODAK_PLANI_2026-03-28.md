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

## KPI Olcum Matrisi

| KPI | Bagli isler | Baseline | Hedef | Olcum kaynagi | Olcum zamani |
| --- | --- | --- | --- | --- | --- |
| KPI-01 | T-004 - T-007 | mevcut rules/authz aciklari ve daginik test durumu | ilgili rules ve authz testleri yesil | `functions/tests`, `npm run test:rules` | her ilgili is kapanisinda |
| KPI-02 | T-008 | cihazda parola saklayan aktif akisin varligi | parola saklayan aktif yol `0` | sign-in/account davranis testi + manuel cihaz kontrolu | T-008 kapanisinda |
| KPI-03 | T-009 | guard yok, yeni erozyon sessiz ilerleyebilir | yeni `Core/Services/Models` feature dosyasi ve yeni part-sprawl ihlali CI'da fail | `architecture-guards` job ciktilari | T-009 kapanisinda ve sonraki her PR'da |
| KPI-04 | T-010 - T-011 | startup rolleri tek akis icinde toplu | en az 4 ayri startup rolu gorunur | startup akisi kod haritasi + davranis testi | T-011 kapanisinda |
| KPI-05 | T-015 - T-016 | feed fallback zinciri daginik | `1` birincil yol + en fazla `1` acil fallback | feed contract notu + feed source testi | T-016 kapanisinda |
| KPI-06 | T-022 | startup/session/feed davranis kapsami eksik | startup, session, account switching ve feed source testleri yesil | test raporu | T-022 kapanisinda |
| KPI-07 | T-024 | coverage gate sahte yesil uretebilir | esik, istisna ve fail kosullari yazili ve isliyor | coverage policy dosyalari + script ciktilari | T-024 kapanisinda |
| KPI-08 | T-026 | dokuman yigini guard ile korunmuyor | tarihli plan/doc ihlali guard ile gorunur | repo guard ciktilari | T-026 kapanisinda |
| KPI-09 | T-029 | playback/runtime bozulmalari sayisal izlenmiyor | watchdog/freeze sinyalleri acik kayitli ve kapanis testinde degerlendiriliyor | Android/iOS smoke loglari + runtime testleri | T-029 kapanisinda |

## Yurutme Anayasasi

Bu plan yalnizca bir niyet listesi degil, sirali uygulama protokoludur.

Baglayici kurallar:

- Plan disina cikilmaz
- Ayni anda yalnizca `1` is aktif olabilir
- Is sirasi onaysiz degistirilemez
- Aktif is bitmeden yeni bulguya gecilemez
- Yeni bulgular kayda girer ama aktif isi bolmez
- Belirsizlik varsa durum acikca `eksik bilgi` diye yazilir
- Varsayim ile is kapanisi yapilmaz
- Her is icin kabul kriteri ve teknik dogrulama zorunludur
- Kabul kriteri veya teknik dogrulamasi tanimli olmayan is baslatilmaz
- Her is icin yan etki kontrolu zorunludur
- Her is icin planla uyum kontrolu zorunludur
- Her is sonunda kullanici kontrol checklist'i verilir
- Kullanici onayi olmadan bir sonraki resmi ise gecilmez
- "Bunu da duzeltmisken" yaklasimi yasaktir
- Plansiz refactor yasaktir
- Yeni feature kodu icin yatay koklere donus yasaktir
- Hiz, dogrulama ve sira disiplininin yerine gecemez
- Konu disi mimari degisiklik yasaktir
- Ben istenmeden yeni hedef uretilmez

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

## Is Baslangic Protokolu

Her yeni is baslamadan once asagidaki 4 satir zorunludur:

- aktif is no
- isin amaci
- bagimliliklar tamam mi
- basari olcutu

Kural:

- bu ozet yazilmadan yeni is teknik olarak baslamis sayilmaz
- aktif is bilgisi, resmi yurutme sirasindaki is numarasi ile birebir ayni olmali

## Is Sirasi Davranis Kurallari

- aktif is sirasinda yalnizca o isin kapsaminda kalinir
- aktif is sirasinda gorulen baska problemler `Yeni bulunan ama plana alinmamis konular` altinda loglanir
- loglanan yeni kayitlar aktif isi durdurmaz
- `BLOCK-###` disindaki hicbir kayit aktif isi kendiliginden yon degistirme sebebi olamaz

## Eksik Bilgi ve Blokaj Kurali

- kritik karar icin veri yoksa durum `eksik bilgi` olarak yazilir
- `eksik bilgi` aktif isin kabul kriterini etkiliyorsa `BLOCK-###` kaydi acilir
- blokaj yoksa makul yorumla degil, gozlenen veriyle ilerlenir
- blokaj varsa plan revizyonu istemeden once aktif isin neden durdugu acik yazilir

## Ilerleme ve Puanlama Modeli

Plan ilerlemesi gorev sayisina gore degil, efor puanina gore izlenir.

Puanlar:

- `S = 1`
- `M = 2`
- `L = 3`
- `XL = 5`

Hesap:

- toplam ilerleme `% = tamamlanan puan / toplam puan x 100`
- toplam plan puani: `76`
- toplam numarali is sayisi: `33`

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
- ilgili artifact/kanit kaydi eklenmis olacak
- reviewer sonucu yazilmis olacak
- final approval durumu kaydedilmis olacak
- kullanici kontrol adimlari verilmis olacak
- ilerleme ve kalan is raporu guncellenmis olacak

Bu liste, minimum zorunlu 7 kosulu da kapsar:

- hedef
- kabul kriteri
- teknik dogrulama
- yan etki kontrolu
- dosya listesi
- kullanici kontrol adimlari
- ilerleme raporu

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

Kapsam degisikligi gerekiyorsa bu durum acikca `Plan Revizyon Talebi` basligi ile sunulur.

## Davranis Sinirlari ve Hiz Kurali

Davranis sinirlari:

- gereksiz iyimserlik yapilmaz
- gercek disi hiz vaadi verilmez
- "AI oldugum icin yetisir" varsayimi ile dogrulama azaltılmaz
- paralel is acilmaz
- is gereksiz buyutulmez
- kullanici istemeden yeni hedef uretilmez

Hiz kurali:

- hiz sadece daha hizli analiz, daha hizli uygulama ve daha hizli dogrulama icin kullanilir
- sira, kontrol ve disiplin bozulmaz
- hiz kazanmak icin test, guard veya yan etki kontrolu atlanmaz

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

## Uygulama Butunu Sistem Haritasi

Bu plan tek bir modulu degil, uygulamanin tamamini kapsar. Yurutme ve refactor kararlari asagidaki sistem eksenlerine gore okunur:

- `App Shell`
  - `main`, `Splash`, `NavBar`, deep link, unread badge, tab gecisleri, acilis ve ilk route karari

- `Session / Identity`
  - `SignIn`, `CurrentUserService`, account switching, user cache, account center, auth/session dogrulama

- `Social Yuzeyler`
  - `Agenda`, `Story`, `Short`, `Chat`
  - feed, playback, overlay, visibility, notification ve lifecycle koordinasyonu

- `Pasaj Shell`
  - `EducationView` ve `EducationController`
  - ortak arama, sekme gorunurlugu, tab/page koordinasyonu, floating action menu, aktif yuzey reset ve child controller baglari

- `Pasaj Alt Alanlari`
  - `Market`
  - `JobFinder`
  - `Scholarships`
  - `QuestionBank / Antreman`
  - `PracticeExams`
  - `OnlineExam`
  - `AnswerKey`
  - `Tutoring`

- `Profile / Settings`
  - profil akislari, saved surfaces, follow/follower, profile render, settings ve kullanici tercihi temelli davranislar

- `Shared Runtime / Infra`
  - media playback, upload queue, cache, notification, network awareness, telemetry, deep link, secure storage, repository ve datasource sinirlari

Kural:

- hicbir pilot alan, planin merkezi gibi yorumlanmaz
- pilotlar yalnizca kalip dogrulamak icindir
- ana hedef uygulamanin tum yuzeylerinde ayni katman ve sahiplik disiplinini kurmaktir

## Uygulama Butunu Eksik Alanlar Matrisi

Bu matris, uygulamayi tek tek moduller degil sistem olarak okuyup eksik kalan taraflari sabitler.

| Sistem Alani | Onaylanmis eksik | Kod bazli belirti | Neden onemli | Hangi islerle kapanacak |
| --- | --- | --- | --- | --- |
| App Shell | Tek sahipli orchestration katmani yok | `main`, `Splash`, `NavBar` ve overlay/lifecycle kodu farkli yerlerde ayni sorumluluklari tasiyor | Acilis, tab gecisi, resume/pause ve surface reset davranislarinda regression riski yuksek | `T-010`, `T-011`, `T-027` |
| Session / Identity | Auth, cache, sync ve account switching tek merkezde yigiliyor | `CurrentUserService` hem veri erisimi hem lifecycle hem session sahibi gibi davraniyor | Session bug'lari tum uygulamayi etkiliyor; guvenli refactor zorlasiyor | `T-008`, `T-012`, `T-013`, `T-028` |
| Social Yuzeyler | Feed/story/short/chat icin ortak orchestrator ve yuzey kontrati yok | playback, overlay, visibility ve notification davranisleri controller ve runtime arasinda daginik | Story/short/feed/chat birlikte calistiginda yan etki yonetimi zorlasiyor | `T-015`, `T-016`, `T-017`, `T-018`, `T-023C`, `T-029` |
| Pasaj Shell | Sekmeler icin public shell contract yok | `EducationController` ve `EducationView` child controller API'lerine dogrudan baglaniyor | Ortak arama, tab reset, menu ve scroll davranislari kirilgan hale geliyor | `T-023A`, `T-023B`, `T-027` |
| Pasaj Alt Alanlari | Market/job disindaki sekmeler icin katman disiplini ve ortak davranis matrisi zayif | scholarships, question bank, practice exams, online exam, answer key, tutoring taraflari shell icine dogrudan bagli | Pasaj bir butun olarak buyuyor ama alt alanlar ortak contract ile korunmuyor | `T-023A`, `T-023B`, sonraki dalga isleri |
| Profile / Settings | Kismi no-op ayarlar ve schema drift var | Pasaj reorder hareketleri gercekte default siraya donuyor; profil counter alanlari coklu isimle okunuyor | Kullanici ayari guvenilmez olur; veri kontrati bulanir | `T-005`, `T-012`, `T-026`, ek profile/settings dalgasi |
| Runtime / Media / Cache | Runtime servisleri icin acik sahiplik ve erisim siniri yok | upload, playback, cache, network, device-session servislerine birden fazla yuzey dogrudan dokunuyor | Arka plan akislarinda sessiz regression ve lifecycle bozulmasi uretir | `T-027`, `T-028`, `T-029` |
| Yapisal Hijyen / Part Sprawl | Mikro `facade/fields/class part` parcaciklari ve sahte modulerlik birikmis | okuma yolu gereksiz uzuyor; degisiklik icin fazla dosya aciliyor; parcalar tek sorumluluk uretmiyor | Gelistirme hizi dusuyor, refactor guveni azaliyor, yeni gelen gelistirici icin sistem daha karisik gorunuyor | `T-009`, `T-026`, `T-030` |
| Repo Yuzeyi / Dosya Sişkinligi | Repo genelinde dosya yuzeyi cok buyuk; sicak akislar cok sayida dosyaya dagilmis | repo genelinde `2888` adet `.dart` dosyasi var; kritik akislarin takibi birden fazla klasor ve part kumesine yayiliyor | Kod takibi, onboarding, review ve degisiklik guveni dusuyor; her dokunus daha fazla dosya acmayi gerektiriyor | `T-030`, `T-031` |
| Testing / Reliability | Test dagilimi urunun agirlik merkeziyle uyumlu degil | startup/session/Pasaj/runtime alanlari sosyal tarafa gore daha zayif korunuyor; bazi testler gercek urun yuzeyi degil | Mimari degisiklikler guvenle yapilamaz; sahte guven olusur | `T-021`, `T-022`, `T-024`, `T-025`, `T-029` |

Kurallar:

- bu matris yeni scope acmak icin degil, eksigi isimlendirmek icin tutulur
- bir eksik ancak ilgili is ve test/guard ile kapatilmis sayilir
- matriste yer alan alanlar plan sagligi gozden gecirmelerinde tek tek kontrol edilir

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

| Is No | Baslik | Hafta | Primary Owner | Reviewer | Final Approval | Efor | Puan | Bagimlilik |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-001 | Baseline envanteri, risk kaydi ve checkpoint matrisi | Hazirlik | Flutter/Fullstack | QA/Platform | User | M | 2 | - |
| T-002 | Yurutme anayasasi, DoD ve rapor standardini plana bagla | Hazirlik | Flutter/Fullstack | QA/Platform | User | S | 1 | T-001 |
| T-003 | Import graph, GetX locator ve god-object envanteri cikar | 1 | QA/Platform | Flutter/Fullstack | User | M | 2 | T-001 |
| T-004 | `reviewReportedTarget` auth fallback yolunu kapat | 1 | Backend | QA/Platform | User | M | 2 | T-001 |
| T-005 | `firestore.rules` icinde `/users/{uid}` okuma yuzeyini daralt | 1 | Backend | QA/Platform | User | M | 2 | T-004 |
| T-006 | `marketStore` client counter update yetkisini kapat | 1 | Backend | QA/Platform | User | M | 2 | T-004 |
| T-007 | `storage.rules` bypass UID yolunu kaldir veya kontrollu hale getir | 1 | Backend | QA/Platform | User | M | 2 | T-004 |
| T-008 | Parola saklama davranisini sonlandir ve re-auth kararini netlestir | 1 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-004 |
| T-009 | `architecture-guards` altyapisini ve CI fail-fast zincirini kur | 1 | QA/Platform | Flutter/Fullstack | User | M | 2 | T-003 |
| T-010 | Splash startup orkestrasyonunu ayir | 2 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-008, T-009 |
| T-011 | `StartupBootstrap`, `SessionBootstrap`, `PostLoginWarmup`, `DependencyRegistrar` ayrimini kur | 2 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-010 |
| T-012 | `CurrentUserService` sorumluluklarini auth/cache/sync/account-center olarak ayir | 2 | Flutter/Fullstack | QA/Platform | User | XL | 5 | T-008, T-010 |
| T-013 | Sign-in ve stored-account akislarini UseCase/Application Service katmanina tasimaya basla | 2 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-011, T-012 |
| T-014 | Startup/session tarafindaki genis `catch (_) {}` bloklarini siniflandirilmis failure modeline cevir | 2 | Flutter/Fullstack | QA/Platform | User | M | 2 | T-010 |
| T-015 | Feed icin tek birincil akis ve istemci contract tanimini yaz | 3 | Flutter/Fullstack | Backend | User | M | 2 | T-003, T-009 |
| T-016 | `hybridFeed.ts` ile istemci feed contract'ini hizala | 3 | Backend | Flutter/Fullstack | User | L | 3 | T-015 |
| T-017 | `AgendaController` orchestration adimlarini UseCase'e cek | 4 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-015, T-016, T-023A |
| T-018 | `ShortController` ve `StoryRowController` orchestration adimlarini UseCase'e cek | 4 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-015, T-016, T-017 |
| T-019 | Yuksek riskli direct Firebase erisim envanterini cikar | 3 | QA/Platform | Flutter/Fullstack | User | M | 2 | T-003 |
| T-020 | Ilk direct Firebase akislarini repository/usecase arkasina al | 3 | Flutter/Fullstack | QA/Platform | User | L | 3 | T-019 |
| T-021 | `functions/tests` altina reports/moderation/security regression testleri ekle | 4 | Backend | QA/Platform | User | L | 3 | T-004, T-005, T-006, T-007 |
| T-022 | Auth/session/feed davranis testlerini genislet | 4 | QA/Platform | Flutter/Fullstack | User | L | 3 | T-013, T-015, T-016, T-017, T-018 |
| T-023A | Market/job icin ilk bounded-context UseCase pilotunu uygula | 3 | Flutter/Fullstack | QA/Platform | User | M | 2 | T-009, T-012, T-020 |
| T-023B | Ads center icin ikinci kucuk UseCase pilotunu uygula | 4 | Flutter/Fullstack | QA/Platform | User | S | 1 | T-009, T-012, T-023A |
| T-023C | Chat icin ilk UseCase cikarimini baslat | 4 | Flutter/Fullstack | QA/Platform | User | M | 2 | T-009, T-012, T-023A |
| T-027 | Runtime servis sahiplik haritasi ve erisim envanterini cikar | 3 | Flutter/Platform | QA/Platform | User | M | 2 | T-003, T-009, T-012 |
| T-028 | Upload, network ve device-session akislarini runtime boundary icine al | 4 | Flutter/Fullstack | QA/Platform | User | M | 2 | T-012, T-020, T-027 |
| T-029 | `VideoStateManager` ve `SegmentCacheManager` kullanim sinirlarini netlestir; lifecycle testlerini ekle | 4 | Flutter/Platform | QA/Platform | User | L | 3 | T-017, T-018, T-027 |
| T-030 | Part-sprawl envanteri cikar ve sicak alanlarda secici sadeleştirme uygula | 4 | Flutter/Fullstack | QA/Platform | User | M | 2 | T-009, T-012, T-023A |
| T-031 | Repo surface area envanteri cikar; sicak yol dosya kumeleri icin sadeleştirme butcesi ve hedef listesi olustur | 4 | Flutter/Fullstack | QA/Platform | User | M | 2 | T-030 |
| T-024 | Coverage gate'i gercek risk gosterecek seviyeye cek | 4 | QA/Platform | Flutter/Fullstack | User | S | 1 | T-021, T-022 |
| T-025 | Yaniltici widget testlerini gercek ekran davranisina bagla | 4 | QA/Platform | Flutter/Fullstack | User | M | 2 | T-022 |
| T-026 | Dokuman tek-kaynak kuralini ve tarihli plan yigilmama guard'ini koy | 4 | QA/Platform | Flutter/Fullstack | User | S | 1 | T-009 |

Kurallar:

- `Primary Owner` isi surer
- `Reviewer` teknik kapanis kalitesini dogrular
- `Final Approval` bir sonraki resmi ise gecis iznini verir
- reviewer sonucu olmadan is `Tamamlandi` sayilmaz

## Resmi Yurutme Sirasi

Bu zincir planin risk-kontrollu resmi uygulama sirasidir.
Bu liste operasyonel disiplin icin hangi sirayla ilerleyecegimizi sabitler.

- `T-001 -> T-002 -> T-003 -> T-004 -> T-005 -> T-006 -> T-007 -> T-008 -> T-009 -> T-010 -> T-011 -> T-012 -> T-013 -> T-027 -> T-015 -> T-016 -> T-019 -> T-020 -> T-023A -> T-017 -> T-018 -> T-029 -> T-021 -> T-022 -> T-024 -> T-026`

## Bagimlilik Bazli En Uzun Zincir

Bagimlilik tablosuna gore bugun hesaplanan en uzun zincir su hattir:

- `T-001 -> T-004 -> T-008 -> T-010 -> T-012 -> T-023A -> T-017 -> T-018 -> T-022 -> T-024`

Kural:

- resmi yurutme sirasi bozulmaz
- bagimlilik bazli en uzun zincir plan sagligi ve gecikme riskini okumak icin tutulur

Destekleyici ama resmi siralama disi isler:

- `T-014`
- `T-023B`
- `T-023C`
- `T-028`
- `T-030`
- `T-031`
- `T-025`

Kural:

- bu isler planda kayitli olsa da kullanici onayi olmadan resmi siraya alinamaz
- ayni anda ikinci aktif is acilamaz

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
| CP-001 | T-001 oncesi | `codex/final-perf-firebase-baseline @ 35f3b0a9` | worktree temiz; kanonik plan commit'i alinmis durumda | bu commit'ten gecici branch ac veya gerekirse sonraki asamada revert/cherry-pick ile don | Kaydedildi |
| CP-002 | T-004 oncesi | doldurulacak | callable/rules fallback davranisi | functions/rules rollback plani | Acik |
| CP-003 | T-008 oncesi | doldurulacak | account/session davranisi | sign-in/session rollback plani | Acik |
| CP-004 | T-010 oncesi | doldurulacak | startup route ve splash davranisi | startup rollback plani | Acik |
| CP-005 | T-015 oncesi | doldurulacak | feed source davranisi | feed contract rollback plani | Acik |
| CP-006 | T-023A oncesi | doldurulacak | pilot modul davranisi | pilot modul rollback plani | Acik |
| CP-007 | T-028 / T-029 oncesi | doldurulacak | runtime/playback/cache/session davranisi | runtime boundary rollback plani | Acik |

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
- Runtime/media/cache degisikligi:
  - lifecycle ve davranis testleri
  - upload persistence/retry dogrulamasi
  - playback exclusivity ve cache davranisi kontrolu
  - gerekiyorsa ayar/diagnostic ekranindan manuel saglik kontrolu

Zorunlu minimum:

- Her is en az 1 teknik dogrulama adimi ile kapanir
- Kurali degistiren her is en az 1 guard/test ile kapanir
- Auth, rules, feed ve session isleri yalnizca kod okumasiyla kapanmaz

## Kanit / Artifact Register

Her tamamlanan is en az bir kanit kaydi uretir.

| Artifact ID | Is No | Kanit tipi | Dosya / cikti | Uretim komutu | Reviewed by | Durum |
| --- | --- | --- | --- | --- | --- | --- |
| ART-001 | T-001 | baseline envanteri | `docs/architecture/T-001_BASELINE_ENVANTERI_2026-03-28.md` | `git status` + `git rev-parse` + `find/rg` bazli envanter komutlari | Codex local review | Hazir |
| ART-010 | T-002 | yurutme anayasasi ve rapor standardi diff'i | `docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md` | `git diff -- docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md` | Codex local review | Hazir |
| ART-002 | T-003 | import graph + locator raporu | `docs/architecture/T-003_IMPORT_GRAPH_GETX_GOD_OBJECT_ENVANTERI_2026-03-28.md` | `rg/find/wc/awk` bazli import + locator + buyuk kume envanteri | Codex local review | Hazir |
| ART-011 | T-004 | review auth fallback regression testi | `functions/tests/unit/reportsAuth.test.js` | `npm run build` + `node --test tests/unit/reportsAuth.test.js` | Codex local review | Hazir |
| ART-012 | T-005 | users root read-surface daraltma notu ve rules regression'i | `docs/architecture/T-005_USERS_READ_SURFACE_DARALTMA_2026-03-28.md` + `functions/tests/rules/firestore.rules.test.js` | `npm run build` + `npm run test:rules` | Codex local review | Hazir |
| ART-013 | T-006 | market client counter path kapatma notu ve rules regression'i | `docs/architecture/T-006_MARKET_COUNTER_CLIENT_PATH_KAPATMA_2026-03-28.md` + `functions/tests/rules/firestore.rules.test.js` | `npm run test:rules` + `dart analyze --no-fatal-warnings --no-fatal-infos ...` | Codex local review | Hazir |
| ART-014 | T-007 | storage bypass kapatma notu ve storage rules regression'i | `docs/architecture/T-007_STORAGE_BYPASS_KAPATMA_2026-03-28.md` + `functions/tests/rules/storage.rules.test.js` | `npm run test:rules` | Codex local review | Hazir |
| ART-015 | T-008 | re-auth politikasi, vault scrub notu ve hedefli testler | `docs/architecture/T-008_REAUTH_VE_SIFRE_SAKLAMA_DONUSUMU_2026-03-28.md` + `test/unit/services/account_session_vault_test.dart` + `test/unit/utils/stored_account_reauth_policy_test.dart` | `dart analyze --no-fatal-warnings ...` + `flutter test ...` | Codex local review | Hazir |
| ART-003 | T-009 | architecture guard script'i, CI baglantisi ve guard artifact'lari | `scripts/check_architecture_guards.sh` + `.github/workflows/ci.yml` + `artifacts/architecture/*` + `docs/architecture/T-009_ARCHITECTURE_GUARDS_2026-03-28.md` | `bash scripts/check_architecture_guards.sh --against HEAD --files scripts/check_architecture_guards.sh,.github/workflows/ci.yml,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md,docs/architecture/T-009_ARCHITECTURE_GUARDS_2026-03-28.md` | Codex local review | Hazir |
| ART-016 | T-010 | splash startup orkestrasyon ayrimi notu ve hedefli startup dogrulamasi | `docs/architecture/T-010_SPLASH_STARTUP_ORKASTRASYON_AYIRMA_2026-03-28.md` + `lib/Modules/Splash/splash_startup_orchestrator.dart` | `dart analyze --no-fatal-warnings lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_startup_orchestrator.dart` + `flutter test test/unit/utils/integration_key_contract_test.dart` | Codex local review | Hazir |
| ART-017 | T-011 | startup rol ayrimi notu ve birim testleri | `docs/architecture/T-011_STARTUP_ROLLERI_AYIRMA_2026-03-28.md` + `test/unit/modules/splash/splash_bootstrap_roles_test.dart` | `dart analyze --no-fatal-warnings lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_startup_orchestrator.dart lib/Modules/Splash/splash_startup_bootstrap.dart lib/Modules/Splash/splash_session_bootstrap.dart lib/Modules/Splash/splash_post_login_warmup.dart lib/Modules/Splash/splash_dependency_registrar.dart test/unit/modules/splash/splash_bootstrap_roles_test.dart` + `flutter test test/unit/modules/splash/splash_bootstrap_roles_test.dart` | Codex local review | Hazir |
| ART-018 | T-012 | current user service role split notu ve hedefli servis testleri | `docs/architecture/T-012_CURRENT_USER_SERVICE_ROLE_SPLIT_2026-03-28.md` + `test/unit/services/current_user_service_role_split_test.dart` | `dart analyze --no-fatal-warnings lib/Services/current_user_service.dart lib/Services/current_user_service_auth_part.dart lib/Services/current_user_service_cache_part.dart lib/Services/current_user_service_sync_part.dart lib/Services/current_user_service_lifecycle_part.dart lib/Services/current_user_service_auth_role_part.dart lib/Services/current_user_service_cache_role_part.dart lib/Services/current_user_service_sync_role_part.dart lib/Services/current_user_service_account_center_role_part.dart test/unit/services/current_user_service_role_split_test.dart` + `flutter test test/unit/services/current_user_service_role_split_test.dart` | Codex local review | Hazir |
| ART-019 | T-013 | sign-in application service notu ve hedefli delegasyon testleri | `docs/architecture/T-013_SIGNIN_APPLICATION_SERVICE_2026-03-28.md` + `test/unit/modules/sign_in/sign_in_application_service_test.dart` | `dart analyze --no-fatal-warnings lib/Modules/SignIn/sign_in_controller.dart lib/Modules/SignIn/sign_in_controller_auth_part.dart lib/Modules/SignIn/sign_in_controller_account_part.dart lib/Modules/SignIn/sign_in_controller_support_part.dart lib/Modules/SignIn/sign_in_application_service.dart test/unit/modules/sign_in/sign_in_application_service_test.dart` + `flutter test test/unit/modules/sign_in/sign_in_application_service_test.dart` | Codex local review | Hazir |
| ART-020 | T-027 | runtime servis sahiplik envanteri ve erisim haritasi | `docs/architecture/T-027_RUNTIME_SERVICE_SAHIPLIK_ENVANTERI_2026-03-28.md` | `sed` + `rg` + `python3` bazli runtime servis referans envanteri | Codex local review | Hazir |
| ART-021 | T-015 | feed primary contract notu ve hedefli contract testi | `docs/architecture/T-015_FEED_PRIMARY_CONTRACT_2026-03-28.md` + `test/unit/repositories/feed_home_contract_test.dart` | `dart analyze --no-fatal-warnings lib/Core/Repositories/feed_home_contract.dart lib/Core/Repositories/feed_snapshot_repository.dart lib/Core/Repositories/feed_snapshot_repository_class_part.dart lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart test/unit/repositories/feed_home_contract_test.dart` + `flutter test test/unit/repositories/feed_home_contract_test.dart` | Codex local review | Hazir |
| ART-022 | T-016 | backend-client feed contract hizalama notu ve hedefli Dart/Functions testleri | `docs/architecture/T-016_FEED_BACKEND_CLIENT_ALIGNMENT_2026-03-28.md` + `test/unit/repositories/feed_home_contract_test.dart` + `functions/tests/unit/hybridFeedContract.test.js` | `dart analyze --no-fatal-warnings lib/Core/Repositories/feed_home_contract.dart test/unit/repositories/feed_home_contract_test.dart` + `flutter test test/unit/repositories/feed_home_contract_test.dart` + `npm run build` + `node --test tests/unit/hybridFeedContract.test.js` | Codex local review | Hazir |
| ART-026 | T-017 | agenda feed application service notu ve hedefli delegasyon testleri | `docs/architecture/T-017_AGENDA_FEED_APPLICATION_SERVICE_2026-03-28.md` + `test/unit/modules/agenda/agenda_feed_application_service_test.dart` | `dart analyze --no-fatal-warnings lib/Modules/Agenda/agenda_feed_application_service.dart lib/Modules/Agenda/agenda_controller.dart lib/Modules/Agenda/agenda_controller_fields_part.dart lib/Modules/Agenda/agenda_controller_feed_part.dart lib/Modules/Agenda/agenda_controller_loading_part.dart test/unit/modules/agenda/agenda_feed_application_service_test.dart` + `flutter test test/unit/modules/agenda/agenda_feed_application_service_test.dart` + `bash scripts/check_architecture_guards.sh --against HEAD --files ...` | Codex local review | Hazir |
| ART-027 | T-018 | short/story application service ayrimi notu ve hedefli delegasyon testleri | `docs/architecture/T-018_SHORT_STORY_APPLICATION_SERVICES_2026-03-28.md` + `test/unit/modules/short/short_feed_application_service_test.dart` + `test/unit/modules/story/story_row_application_service_test.dart` | `dart analyze --no-fatal-warnings lib/Modules/Short/short_feed_application_service.dart lib/Modules/Short/short_controller.dart lib/Modules/Short/short_controller_fields_part.dart lib/Modules/Short/short_controller_loading_part.dart lib/Modules/Story/StoryRow/story_row_application_service.dart lib/Modules/Story/StoryRow/story_row_controller.dart lib/Modules/Story/StoryRow/story_row_controller_fields_part.dart lib/Modules/Story/StoryRow/story_row_controller_load_part.dart test/unit/modules/short/short_feed_application_service_test.dart test/unit/modules/story/story_row_application_service_test.dart` + `flutter test test/unit/modules/short/short_feed_application_service_test.dart test/unit/modules/story/story_row_application_service_test.dart` + `bash scripts/check_architecture_guards.sh --against HEAD --files ...` | Codex local review | Hazir |
| ART-004 | T-021 | backend/rules regression test raporu | doldurulacak | doldurulacak | doldurulacak | Acik |
| ART-005 | T-022 | startup/session/feed davranis test raporu | doldurulacak | doldurulacak | doldurulacak | Acik |
| ART-006 | T-024 | coverage gate policy ve cikti | doldurulacak | doldurulacak | doldurulacak | Acik |
| ART-007 | T-029 | runtime/playback lifecycle smoke ve log notu | doldurulacak | doldurulacak | doldurulacak | Acik |
| ART-008 | T-030 | part-sprawl envanteri ve secili sadeleştirme diff'i | doldurulacak | doldurulacak | doldurulacak | Acik |
| ART-009 | T-031 | repo surface area envanteri ve sicak yol sadeleştirme hedef listesi | doldurulacak | doldurulacak | doldurulacak | Acik |

Kurallar:

- artifact kaydi olmayan is kapanmaz
- artifact path veya cikti adi gorev raporunda acik yazilir
- reviewer artifact'i gormeden kapanis veremez

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
| T-027 | runtime servis sahiplik haritasi ve erisim envanteri cikmis olacak | runtime envanter raporu + import/lookup kontrolu | Upload/cache/playback/session sahibi net gorunuyor mu |
| T-028 | upload, network ve device-session akislarinda runtime boundary netlesmis olacak | davranis testi + lifecycle kontrolu | Bu servisler artik gelisiguzel feature icinden cagriliyor mu |
| T-029 | video/cache lifecycle sinirlari netlesmis ve testlenmis olacak | lifecycle testi + manuel dogrulama | Story/short/feed gecislerinde playback ve cache davranisi stabil mi |
| T-030 | yapay part-sprawl envanteri cikmis olacak; dokunulan sicak alanlarda secili sadeleştirme davranis bozmadan uygulanmis olacak | guard calistirma + odak testleri + diff kontrolu | Daha az dosya ile ayni akis okunabiliyor mu; gereksiz mikro parcalar azaldi mi |
| T-031 | repo genel dosya yuzeyi envanteri cikmis olacak; sicak yol kume bazli sadeleştirme hedefleri ve butcesi belirlenmis olacak | envanter raporu + hedef liste diff'i | En pahali dosya kumeleri net mi; hangi alanlarda dosya yuzeyi azaltilacak gorunuyor mu |
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
| upload queue persistence/retry testi | T-028 |
| device session claim/auth boundary testi | T-028 |
| network awareness policy testi | T-028 |
| video playback exclusivity/lifecycle testi | T-029 |
| segment cache quota/eviction/hls proxy testi | T-029 |
| part-sprawl inventory ve hot-path sadeleştirme diff kontrolu | T-030 |
| repo surface area inventory ve hot-cluster hedef listesi | T-031 |
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
| RISK-005 | Risk | Yuksek | T-028, T-029 | Acik | Upload/playback/cache boundary degisiklikleri arka plan akislarinda gorunmeyen regresyon uretebilir |
| RISK-006 | Risk | Orta | T-006, T-021 | Acik | Market root sayaçlari icin server-side aggregation olmadigindan, client yolu kapaninca `viewCount/favoriteCount/offerCount/reviewCount` stale kalabilir |
| DEBT-001 | Debt | Orta | T-030 | Acik | Mikro `facade/fields/class part` dagilimi okuma maliyeti ve sahte modulerlik uretiyor; secici sadeleştirme gerekiyor |
| DEBT-002 | Debt | Orta | T-031 | Acik | Repo genelinde dosya yuzeyi cok buyuk; kritik akislar fazla dosyaya dagiliyor ve takip maliyeti yukseliyor |
| GAP-001 | Gap | Orta | T-001 | Kapandi | Rollback/checkpoint standardi plan icine eklendi; T-001'de canli kayit doldurulacak |
| GAP-002 | Gap | Orta | T-021, T-022 | Kapandi | Fixture/seed checklist planda tanimlandi; uygulamada test bazli doldurulacak |

## Plan Sonrasi Tavsiye Backlogu

Bu bolum, aktif resmi sirayi bozmadan kayda alinacak ama 30 gunluk ana plan bittikten sonra ele alinacak tavsiyeleri tutar.

Kurallar:

- burada tutulan maddeler aktif resmi isi bozmaz
- resmi sira disina alinmaz
- plan boyunca cikan benzer tavsiyeler bu backlog'a eklenir
- ana plan bitince etki/efor sirasina gore ayrica ele alinir

| Tavsiye No | Kaynak | Durum | Neden simdi degil | Plan bitince onerilen ilk adim |
| --- | --- | --- | --- | --- |
| ADV-001 | `RISK-006`, `T-006` | Acik | `T-006` guvenlik yolunu kapatti; ama server-side aggregation ayri tasarim ve uygulama isi gerektiriyor, bu yuzden resmi sirayi bozmuyoruz | market root sayaclari icin server-side aggregation / backfill tasarimi cikar; `viewCount`, `favoriteCount`, `offerCount`, `reviewCount` alanlarini server ownership modeline tasi |


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
| Runtime / Media / Cache | runtime coordinator / policy layer | runtime services + approved adapters | `SegmentCacheManager`, upload queue persistence, device/session state | runtime policy / coordinator | UI diagnostics + caller surface |

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

Runtime / Media / Cache:

- `lib/Core/Services/upload_queue_service.dart`
- `lib/Core/Services/video_state_manager.dart`
- `lib/Core/Services/network_awareness_service.dart`
- `lib/Core/Services/SegmentCache/cache_manager.dart`
- `lib/Services/device_session_service.dart`
- `lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart`
- `lib/Modules/Splash/splash_view_startup_part.dart`
- `lib/main.dart`

Part Sprawl / Yapisal Hijyen:

- `lib/Modules/Education/education_controller.dart`
- `lib/Modules/Profile/Settings/settings_controller.dart`
- `lib/Modules/JobFinder/job_finder_controller.dart`
- `lib/Modules/Chat/chat_controller.dart`
- `lib/Services/current_user_service.dart`

Repo Surface Area / Dosya Sişkinligi:

- `lib/Modules/Education/**`
- `lib/Modules/Chat/**`
- `lib/Modules/Story/**`
- `lib/Modules/Short/**`
- `lib/Modules/Profile/**`
- `lib/Services/**`
- `lib/Core/Repositories/**`

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
  - `PersistSessionHandleUseCase`

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

## Runtime / Media / Cache Stabilizasyonu

Bu eksen planin disinda degil; tum uygulama genelinde zorunlu capraz eksendir.

Kapsam:

- `UploadQueueService`
- `VideoStateManager`
- `SegmentCacheManager`
- `NetworkAwarenessService`
- `DeviceSessionService`

Kurallar:

- feature widget ve view'lar runtime servis yasam dongusunu dogrudan yonetmez
- upload tetikleme feature tarafindan yapilabilir; queue policy, persistence ve retry runtime servisinde kalir
- playback exclusivity, pause/resume ve overlay davranisi yalnizca onayli playback coordinator / runtime katmani uzerinden gider
- segment cache feature icinden gelisiguzel okunmaz veya yazilmaz; yalnizca onayli adapter ve coordinator uzerinden kullanilir
- `DeviceSessionService` yalnizca auth/session akislarinda ve ilgili usecase/application service tarafinda kullanilir
- `NetworkAwarenessService` UI dallanma mantiginin rastgele parcasi olmaz; policy/coordinator veya approved helper uzerinden kullanilir
- settings/diagnostics yuzeyi runtime servislerini gozetleyebilir; ama feature business flow sahibi olamaz

Beklenen ciktılar:

- runtime servis sahibi ve cagri haritasi
- hangi yuzeyin hangi runtime servise bakabildigi listesi
- upload/playback/cache/session icin lifecycle kontratlari
- testle dogrulanan minimum stabilizasyon paketi

## Part Sprawl / Yapisal Hijyen Kontrolu

Bu eksen dosya sayisini azaltma hedefi degil, yapay parcacik birikimini kontrol etme eksenidir.

Kapsam:

- yeni `*_facade_part.dart`, `*_fields_part.dart`, `*_class_part.dart` turevlerinin buyumesini durdurmak
- sicak alanlarda okumayi zorlastiran mikro parcaciklari envanterlemek
- yalnizca dokunulan akislarda secici sadeleştirme yapmak

Kurallar:

- tum repoda toplu dosya birlestirme turu yapilmaz
- sadece aktif is kapsaminda dokunulan sicak alanlarda sadeleştirme yapilir
- davranis degismeden yapisal sadeleştirme hedeflenir
- yeni part-sprawl uretimi guard ile engellenir; eski birikim secili dalgalarla azaltilir

Beklenen ciktılar:

- part-sprawl envanter raporu
- secilen sicak alanlar icin once/sonra diff'i
- davranis bozmadan kapanmis secili sadeleştirmeler

## Repo Surface Area / Dosya Sişkinligi Kontrolu

Bu eksen toplam dosya sayisini sayisal takinti haline getirmek icin degil, kritik akislarin asiri genis dosya yuzeyine dagilmasini kontrol etmek icindir.

Kapsam:

- repo genelindeki buyuk dosya/kume envanterini cikarmak
- sicak akislar icin "bir degisiklikte kac dosya aciliyor" maliyetini gorunur hale getirmek
- en pahali kume ve klasorler icin sadeleştirme butcesi belirlemek
- yalnizca aktif refactor alanlarinda secili dosya birleştirme veya dosya azaltma uygulamak

Kurallar:

- tum repoda toplu dosya birleştirme turu yapilmaz
- dosya sayisini dusurmek tek basina hedef degildir; okuma ve degisim maliyetini azaltmak hedeftir
- sadece sicak yol ve aktif is kapsamindaki kumelerde secili sadeleştirme yapilir
- yeni dosya eklemek yasak degildir; ama yeni dosya gercek sorumluluk ayrimi uretmiyorsa kabul edilmez

Beklenen ciktılar:

- repo surface area envanteri
- sicak yol dosya kumeleri listesi
- sadeleştirme butcesi ve hedef alan listesi
- secili kumelerde once/sonra diff'i

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
- `UploadQueueService`, `VideoStateManager`, `SegmentCacheManager`, `NetworkAwarenessService` ve `DeviceSessionService` icin runtime sahiplik ve cagri haritasini cikar
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
- Runtime servis sahiplik ve erisim haritasi

Cikis Kriteri:

- Feed icin birincil yol tanimli olacak
- Yeni direct Firebase erisimi eklenmeyecek
- Daha kucuk bir pilot modulde katman kurali sahada kanitlanmis olacak
- Runtime/media/cache akislarinin sahibi ve sinirlari acikca gorunur olacak
- `T-015`, `T-016`, `T-019`, `T-020`, `T-023A` ve `T-027` tamamlanmis olacak

## 4. Hafta: Sosyal Orkestrasyon, Test, CI ve Kalici Dokuman Seti

Hedef:

- Kalite sinyalini gerceklestirmek
- Pilotta kanitlanan kalibi daha riskli sosyal akislar icin uygulamak
- Yeniden dokuman kalabaligi olusmasini engellemek

Isler:

- `AgendaController`, `ShortController`, `StoryRowController` icindeki orchestration adimlarini UseCase'e cek
- Ads center icin ikinci kucuk UseCase pilotunu cikar
- Chat akislarinda ilk UseCase cikarimlarini baslat
- Upload, network ve device-session akislarinda runtime boundary'leri netlestir
- `VideoStateManager` ve `SegmentCacheManager` icin kullanim sinirlarini ve lifecycle kontratlarini testle sabitle
- `functions/tests` altina reports/moderation/security regression testleri ekle
- Auth/session/feed kritik akislari icin davranis testlerini genislet
- `scripts/check_flutter_coverage.sh` ve `config/quality/flutter_coverage_policy.env` icindeki zayif coverage gate'i gercekci seviyeye cek
- `test/widget/screens/sign_in_test.dart` benzeri yaniltici testleri gercek ekran davranisina bagla
- `docs/README.md` disinda tarihli yeni plan/analiz birikmesini durduracak repo kurali koy

Teslimatlar:

- Kritik backend test paketi
- Guclendirilmis coverage gate
- Temiz ve tek kaynakli dokuman girisi
- Runtime/media/cache stabilizasyon paketi

Cikis Kriteri:

- CI mevcut durumu gizleyen degil, gercek risk gosteren sinyaller uretecek
- Sosyal controller refactor'u pilotta dogrulanan kalipla ilerlemis olacak
- Upload, playback, cache ve session runtime servisleri icin minimum sinirlar testle gorunur olacak
- Dokuman seti yeniden dagilmayacak sekilde sade kalacak
- `T-017`, `T-018`, `T-021`, `T-022`, `T-023B`, `T-023C`, `T-024`, `T-025`, `T-026`, `T-028`, `T-029` tamamlanmis olacak

## Hafta Gecis Kapilari

Hafta gecisi sadece takvimle degil, cikis kapisi ile olur.

- `Week-1 -> Week-2 Gate`
  - `T-004` - `T-009` tamamlanmis olacak
  - ilgili rules/authz testleri yesil olacak
  - en az `CP-002` ve `CP-003` doldurulmus olacak

- `Week-2 -> Week-3 Gate`
  - `T-010` - `T-014` tamamlanmis olacak
  - startup/session davranis testleri yesil olacak
  - `CurrentUserService` parcasi reviewer tarafindan dogrulanmis olacak

- `Week-3 -> Week-4 Gate`
  - `T-015`, `T-016`, `T-019`, `T-020`, `T-023A`, `T-027` tamamlanmis olacak
  - feed contract ve runtime sahiplik artefact'lari kayda gecmis olacak
  - direct Firebase ve feed fallback riskleri plan sagligi kontrolunden gecmis olacak

Kurallar:

- gate fail ise sonraki haftanin resmi isleri acilmaz
- gate fail durumu plan revizyon protokolune girer
- yan isler gate'i dolanmak icin kullanilmaz

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
- upload queue persistence/retry testi
- device session claim/auth boundary testi
- video playback exclusivity/lifecycle testi
- segment cache quota/eviction/hls proxy testi

Static guard testleri:

- feature ic import ihlali testi
- presentation -> infra erisim ihlali testi
- locator kullanim siniri testi
- legacy folder freeze testi
- yeni part-sprawl kaliplari testi

## Zincir Sagligi Kontrolu

Her is kapanisinda sadece ilgili degisiklik degil, bagli akis zincirleri de kontrol edilir.
Amaç, tekil gorev tamamlaniyor gorunurken baska bir kritik akis veya bagimlilik zincirinin sessizce kirilmasini engellemektir.

Her is sonunda asagidaki alanlar zorunlu degerlendirilir:

- Etkilenen zincirler
- Kontrol edilen bagli akislar
- Kirilma var mi: `Evet / Hayir`
- Regresyon var mi: `Evet / Hayir`
- Zincir durumu: `Temiz / Riskli / Kirik`
- Bozulan akislar varsa acik kaydi

Standart minimum zincir listesi:

- `Startup Zinciri`
  splash -> auth bootstrap -> session restore -> initial route
- `Session Zinciri`
  sign-in -> current user load -> account switch -> sign-out
- `Social Zinciri`
  feed -> story row -> story viewer -> short -> playback ownership
- `Data/Authz Zinciri`
  firestore rules -> storage rules -> callable auth -> client write path
- `CI Zinciri`
  architecture guards -> analyze/test -> smoke -> coverage/reporting

Her gorev icin bu listenin tamami degil, etkilenme ihtimali olan zincirler secilir ve raporda acikca yazilir.
Zincir kontrolu yapilmadan hicbir is `Tamamlandi` durumuna gecemez.

## Is Tipine Gore Zincir Kontrol Matrisi

| Is ailesi | Zorunlu zincirler | Minimum kontrol |
| --- | --- | --- |
| Rules / Authz / Backend | `Data/Authz`, `Session` | profile read, upload, admin callable, save/apply akislari |
| Startup / Session | `Startup`, `Session`, `CI` | app acilisi, session restore, sign-in, sign-out, initial route |
| Feed / Social | `Social`, `Startup`, `CI` | feed render, story row, story viewer, short, playback sahipligi |
| Runtime / Media / Cache | `Social`, `Session`, `CI` | upload queue, playback exclusivity, cache davranisi, device session |
| Guard / CI / Policy | `CI` + etkilenen feature zinciri | guard fail/pass, analyze, test, smoke, coverage |
| Docs / Repo Guard | `CI` | dokuman guard'i, tek-kaynak kurali, policy ihlali gorunurlugu |

## Her Is Sonu Zorunlu Rapor Formati

Her is bitiminde asagidaki format ve sira zorunludur:

- `Is No`
- `Baslik`
- `Durum: Tamamlandi / Kismi / Bloklu`
- `Bu iste yapilanlar`
- `Somut kazanımlar`
- `Etkilenen dosyalar`
- `Artifact / kanit kayitlari`
- `Teknik dogrulama`
- `Bagli zincir kontrolu`
- `Benim kontrol etmem gerekenler`
- `Risk veya dikkat notu`
- `Toplam ilerleme`
- `Tamamlanan puan`
- `Kalan puan`
- `Tamamlanan is sayisi`
- `Kalan is sayisi`
- `Siradaki onerilen is`
- `Yeni bulunan ama plana alinmamis konular`

Ek zorunlu notlar:

- `Benim kontrol etmem gerekenler` alani kisa ve maddeli yazilir
- teknik dogrulama icinde yan etki kontrolu ve planla uyum kontrolu yazilir
- gerekirse `Bagli zincir kontrolu` altinda kirilma/regresyon notu verilir
- kullanici onayi gelmeden bir sonraki resmi ise gecilmez

## Plan Sagligi Gozden Gecirme Dongusu

Plan, tamamlanan is sayisi `5`'in katina her ulastiginda yeniden gozden gecirilir.

Tetikleme noktaları:

- `5`
- `10`
- `15`
- `20`
- `25`
- `30`

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

Kural:

- bu gozden gecirme, aktif isi birakip yeni ise atlamak icin kullanilmaz
- yeni sorunlar bulunursa yalnizca `RISK/GAP/DEBT/BLOCK` kaydina donusturulur
- resmi sira yalnizca plan revizyon protokolu ile degisebilir

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
