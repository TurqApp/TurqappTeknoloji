# TurqApp Yapay Zeka Anayasasi

Bu dosya TurqApp icin kalici ajan anayasasidir. Bu repo uzerinde calisan her Codex oturumu, herhangi bir isleme baslamadan once bu dosyayi okumak ve tum gorev boyunca eksiksiz uygulamak zorundadir. Bu zorunluluk `qa baslat` dahil tum komutlarda gecerlidir.

## Temel Davranis Kurallari

1. Varsayim yapma.
   - Eksik bilgi varsa tahmin yurutme.
   - Ne eksik oldugunu acikca belirt.
2. Problemleri yuzeysel degil, kokunden coz.
   - Semptomlari degil, gercek sebebi bul.
   - Gecici fix veya hack uygulama.
3. Gorevleri asla yarim birakma.
   - Cozum calisir ve dogrulanir hale gelmeden isi bitmis sayma.
4. Minimum mudahale prensibi uygula.
   - Sadece gerekli satirlari degistir.
   - Gereksiz refactor yapma.
   - Calisan kodu yeniden yazma.
5. Mevcut sistemi koru.
   - Var olan calisan yapiyi bozma.
   - Yan etki olusturma.
6. Kapsam disina cikma.
   - Istenmeyen hicbir gelistirme yapma.
   - "Bunu da duzeltmisken..." yaklasimi yasak.

## Proje Analizi Zorunlulugu

Her islemden once:

1. Proje yapisini analiz et.
   - Klasor yapisi
   - Bagimliliklar
   - Giris noktalari
   - Veri akisi
   - Ana bilesenler
2. Degisiklik yapilacak kodun su noktalarini tam olarak tespit et.
   - Nereden cagrildigi
   - Neyi etkiledigi
   - Bagimliliklari
   - Yan etkileri
3. Sorunu anlamak icin ilgili dosyalari zincir halinde incele.
   - Gerekirse cagri akislarini cikar.
4. Kok nedeni bulmadan asla kod yazma.

Kok neden net degilse dur ve eksik bilgiyi belirt.

## Kod Degisikligi Kurallari

- Sadece gerekli kodu degistir.
- Yeni bagimlilik ekleme, istenmedikce.
- Isim degistirme yapma.
- Dosya yapisini degistirme.
- Stil degistirme.
- Ekstra log, test veya yorum ekleme.

## Uygulama Sonrasi Zorunluluk

Her degisiklikten sonra:

1. Cozumun problemi tamamen giderdigini dogrula.
2. Baska yerleri bozmadigini kontrol et.
3. Mantiksal tutarliligi kontrol et.
4. Mutlaka calistirma komutu ver.
   - Backend ise terminal komutu ver.
   - Frontend ise run veya build komutu ver.
   - Mobil ise emulator veya cihaz komutu ver.
   - Belirsiz ise nasil test edilecegini acikla.

## Cikti Formati Zorunlulugu

Her zaman su formatta cevap ver:

1. Kok Neden
2. Minimal Cozum
3. Kod Degisikligi
4. Calistirma Komutu
5. Kapsam Notu

## Guvenlik ve Hata Onleme

- Emin degilsen kod yazma.
- Birden fazla ihtimal varsa belirt.
- Risk varsa acikla.
- Eksik context varsa uydurma.
- Runtime, playback ve cihaz uzerinde yeniden uretilebilen hatalarda tahminle
  ilerleme.
- Bu tip hatalarda once canli log, telemetry, native event ve mevcut kod akisi
  okunacak; kanit yoksa kok neden iddiasi kurulmayacak.
- "Muhtemelen", "buyuk ihtimalle" gibi ifadelerle gecici hikaye kurup patch
  yazmak yasak; once kanit, sonra mudahale.

## Genel Prensip

"Sadece isteneni yap. Minimum degistir. Tam coz. Asla varsayim yapma."

## Context-Aware Davranis Eki

- Her gorevde once proje baglamini cikar.
- Once anlamadan asla degistirme.
- Kodun sistem icindeki rolunu anlamadan mudahale etme.
- Buyuk projelerde lokal degil sistemsel dusun.

Bu kurallar her gorevde otomatik uygulanir. Tekrar hatirlatilmasina gerek yoktur.

## 2026-03-29 Sistem Koruma Maddeleri

Bu baslik altindaki maddeler, `P1 hardening + P2 smoke/regression` lane'inde
kalici hale getirilen davranislardir. Baska bir Codex oturumu bu maddeleri
bilmeden feed, startup, playback, smoke veya telemetry tarafina mudahale
etmemelidir.

### Bu Lane'de Kalici Hale Gelenler

- Startup/session akisinda ayrik roller korunacak:
  - `SplashStartupOrchestrator`
  - `SessionBootstrap`
  - `DependencyRegistrar`
  - `PostLoginWarmup`
- Startup route/nav restore davranisi manifest ve navbar uzerinden
  korunacak; restore state ham index set'i ile degil gercek controller
  akisiyla uygulanacak.
- `integration_test/core/bootstrap/test_app_bootstrap.dart` icindeki
  `launchTurqApp()` sirasi korunacak:
  - app main
  - startup pump
  - auth hazirlama
  - account center sync
  - notification/feed/market prime
  - route/nav restore
- Process-death verify lane'inde feed zorla acilmayacak; restore edilecek
  tab `restoredNavIndex` ile gercek akis uzerinden geri gelecek.
- Replay testlerinde bootstrap contract ile replay contract ayri
  yorumlanacak:
  - bootstrap lane'lerinde `requiredDocIds` zorunlu
  - `route_replay` sonrasi feed kontrolunde `requiredDocIds` zorunlu degil
- `scripts/run_integration_smoke.sh` her suite'i ayri manifest ve ayri
  artifact klasoru ile kosacak; host-side `host_stub` failure gorurse
  suite bir kez retry edilecek.
- `scripts/run_turqapp_test_smoke.sh` bozuk JSON artifact kopyalamayacak.
- `tool/integration_smoke_report.dart` malformed artifact gorurse raporu
  dusurmek yerine skip edecek.
- Feed ordering ana `PostsModel` uzerinden korunacak; backing post olmadan
  gelen bare reshare event'i ana listeye tek basina girmeyecek.
- Feed sync sonrasi playback anchor korunacak:
  - `capturePlaybackAnchor(...)`
  - `_pendingCenteredDocId`
  - `resumeFeedPlayback()`
- `FeedRenderCoordinator.buildMergedEntries` icin su davranislar korunacak:
  - gercek feed post varsa reshare event onu ezmez
  - backing post yoksa reshare-only row render listesine girmez
- Telemetry tarafinda kucuk smoke ornekleri false-positive uretmeyecek:
  - `feed` icin `local_hit_ratio_low` minimum cache event esigi `4`
- Tam smoke kapisi bu lane icin su cikti ile kapanmis kabul edilir:
  - `scenarios=5`
  - `blocking=0`
  - `failures=0`

### Kod Bazli Son Kontrol Zinciri

Bu alanlara dokunulursa minimum su dogrulama zinciri tekrar kosulacak:

- `flutter test test/unit/core/services/feed_render_coordinator_build_test.dart`
- `flutter test test/unit/services/telemetry_threshold_policy_test.dart`
- `bash scripts/run_auth_session_feed_regression.sh`
- `bash scripts/run_process_death_restore_suite.sh`
- `bash scripts/run_integration_smoke.sh`
- `bash scripts/export_integration_smoke_report.sh`

Beklenen kapanis:

- `artifacts/integration_smoke_report_latest.json` uretilecek
- `scenarios=5`
- `blocking=0`
- `failures=0`

### Bu Sistemi Bozmamak Icin Yasaklar

- Feed replay testlerini yeniden bootstrap contract gibi yorumlama.
- `requiredDocIds` zorunlulugunu replay lane'lerine geri tasima.
- `run_integration_smoke.sh` icini tekrar tek manifestli kirilgan loop'a
  dondurme.
- Smoke artifact eksikliginde raw stderr veya host stub metnini gercek JSON
  artifact gibi kabul etme.
- Feed merge akisina backing post olmadan reshare row'u geri sokma.
- Sync head sonrasi playback anchor'i temizleyip autoplay'i sifirdan secmeye
  zorlama.
- Tiny-sample telemetry warning'lerini tekrar `3` event civarina cekme.
- Sadece threshold ile warning bastirip kok nedeni kapandi varsayma.

### Merkezi Budget ve Cache Ownership Kurali

- Kullaniciya gorunen surface/list startup-read-warm budget'lari tek yerden
  yonetilecek:
  - `lib/Core/Services/read_budget_registry.dart`
- Yeni bir surface icin `limit`, `pageLimit`, `warmCount`, `startupShard`
  veya `take(...)` tipi bir sayisal karar eklenecekse once registry'ye
  girilecek, sonra call-site oraya baglanacak.
- Su alanlarda sabit sayi hardcode etmek yasak:
  - splash/startup warmup
  - snapshot repo default limit'leri
  - story/recommended/profile/job/market startup shard boyutlari
  - explore/feed/listing page budget'lari
  - navbar arka plan warm loop'u
- `ContentPolicy` sadece ag/davranis karari verir; sayisal budget uretmez.
- `CacheFirstPolicyRegistry` TTL/stale/sync politikasi icin kalir; sayisal
  budget kararlari `read_budget_registry.dart` icinde tutulur.
- Kullaniciya gorunen listing/owner/search/answered/favorites/type/shared
  surface'leri icin tek cache omurgasi sudur:
  - `CacheFirstCoordinator`
  - `CacheFirstQueryPipeline`
  - `SharedPrefsScopedSnapshotStore`
  - ilgili `*_snapshot_repository.dart`
- Bir domain icin `*_snapshot_repository.dart` varsa controller ve view
  katmani artik repo-local listing cache/query yoluna donmeyecek.
- Surface ownership artik su backbone uzerindedir:
  - `profile_posts_snapshot`
  - `market_home/search/owner`
  - `jobs_home/search/owner`
  - `scholarship_home/search`
  - `tutoring_home/search/owner`
  - `practice_exam_home/search/owner/type/answered`
  - `test_home/type/owner/answered/favorites/shared`
  - `answer_key_home/search/owner/type`
  - `optical_form_owner/answered`
  - `past_question_home`
- Ayni surface icin ikinci bir repo-local listing cache API'si tutmak yasak.
- Su sayilar merkezi surface policy omurgasina dahildir ve lokal
  hardcode edilemez:
  - home/search/owner/type/answered/favorites/saved/applied/shared limitleri
  - related/similar surface fetch ve visible limitleri
  - personalized/vitrin/bootstrap/home seed limitleri
  - feed/short/explore prefetch ve candidate havuz limitleri
- Su sayilar surface policy omurgasina dahil degildir; ancak sadece kendi
  dar rolunde lokal kalabilir:
  - diagnostic sample sayilari
  - QA/export truncation sayilari
  - user summary batch chunk sayilari
  - detail ekraninda "daha fazla goster" oncesi preview satir/adet siniri
- Bir lokal sayi startup, cache ownership, paging, warmup, prefetch veya
  kullaniciya gorunen ana liste uzunlugunu etkiliyorsa anayasa geregi
  `SurfacePolicyRegistry` veya `ReadBudgetRegistry` altina tasinmak zorundadir.
  Su legacy pattern'ler geri getirilmeyecek:
  - `fetchAnsweredByUser`
  - `fetchFavorites`
  - `fetchByOwner`
  - `fetchAll`
  - `fetchByType`
  - `fetchByExamType`
  - `fetchSharedPage`
  - `fetchLatestRaw`
  - `fetchByOwnerAndEnded`
- Repo-local cache sadece su alanlarda kabul edilir:
  - detail/doc cache
  - kucuk metadata cache
  - preference/runtime state
- Ayni surface icin ikinci bir lokal budget kaynagi olusturma:
  - controller field icinde sabit
  - repo icinde ayri sabit
  - splash icinde farkli sabit
  yaklasimlari yasak.

### Acik Sonraki Plan

Cache/backbone ana plan kapanmistir. Aktif blocker yoktur. Bundan sonraki
lane'ler cache ownership ile karistirilmayacak; ozellikle `Agenda/Short/iOS
playback` gibi lifecycle ve native playback diff'leri ayri lane olarak
yurutulecek.

Bir sonraki lane'e gecmeden once beklenen kapanis:

- full smoke yesil kalacak
- `blocking=0`
- `failures=0`

## 2026-03-30 Surface Policy ve Ayar Verme Modu

Cache ownership omurgasi tamamlandiktan sonra surface davranisini etkileyen
tum ayarlar tek merkez mantigi ile yonetilecektir. Bu baslik altindaki
kurallar, "ayar verme modu"nda alinacak her karar icin baglayicidir.

### Tek Merkez Ayar Sahipligi

- Kullaniciya gorunen her surface icin su kararlar tek sahiplik altinda
  tutulacak:
  - `initialLimit`
  - `pageLimit`
  - `startupShardLimit`
  - `readyForNavCount`
  - `warmCount`
  - `prefetchDocLimit`
  - `bootstrapNetwork` davranisi
  - `backgroundRefresh` davranisi
  - `snapshotTtl`
  - `minLiveSyncInterval`
  - `preservePreviousOnEmptyLive`
  - `treatWarmLaunchAsStale`
- "Bir yerde 30, diger yerde 200" turu ayri ayar sahipligi anayasa ihlalidir.
- Controller, repo, splash, warmup, navbar ve widget katmani surface'e ait
  sayisal karar uretmeyecek; sadece merkezi policy kaydini tuketecek.

### Merkezi Policy Omurgasi

- Birincil sahiplik artik su dosyadadir:
  - `lib/Core/Services/AppPolicy/surface_policy_registry.dart`
- `read_budget_registry.dart` artik bagimsiz karar sahibi degil;
  `SurfacePolicyRegistry` uzerine kurulu uyumluluk/adaptor katmanidir.
- `cache_first_policy_registry.dart` artik bagimsiz karar sahibi degil;
  schema ve snapshot policy bilgisini `SurfacePolicyRegistry` uzerinden okur.
- `content_policy.dart` artik sayi sahibi degil;
  yalniz runtime yorumlayici olarak `SurfacePolicyRegistry` kararlarini uygular.
- Bundan sonra:
  - yeni lokal sabit eklemek yasak
  - mevcut lokal sabit gorulurse registry'ye tasimadan birakmak yasak
  - ayni ayarin iki farkli dosyada yasamasi yasak

### Ayar Verme Modu Kurali

- Bu modda yapilan her degisiklik yeni ozellik degil, politika ayari
  degisikligi olarak ele alinacak.
- Ayar degisikligi su kategorilerden birine baglanmadan yapilmayacak:
  - startup/splash hazirlik boyutu
  - initial read/pool boyutu
  - network bootstrap davranisi
  - paging limiti
  - warmup/prefetch boyutu
  - stale/ttl/sync davranisi
  - background refresh izni
- Ayar degisikligi yapilirken "etki alani" mutlaka belirtilecek:
  - feed
  - short
  - explore
  - story
  - profile
  - market
  - job
  - scholarship
  - practice exam
  - test
  - answer key
  - optical form
  - past questions

### Yasaklar

- Controller icinde `_pageSize = 30` tipi yeni sabit ekleme.
- Repo icinde surface'e ozel `take`, `limit`, `page` sabitini yeniden
  uretme.
- Splash ve warmup tarafinda registry disi farkli hedef sayi tanimlama.
- `ContentPolicy` icine yeni sayisal budget gommek.
- Smoke yesil diye ayar daginikligini gormezden gelmek.

### Ayar Degisikligi Sonrasi Zorunlu Dogrulama

- `dart analyze`
- etkilenen surface icin hedefli test veya smoke
- `bash scripts/run_integration_smoke.sh`
- `bash scripts/export_integration_smoke_report.sh`

Beklenen kapanis:

- `scenarios=5`
- `blocking=0`
- `failures=0`

### Manuel Ayar Menusu Kurali

- Uygulama ici manuel surface tuning menusu yerel cihaz ayari olarak
  calisacak; remote config veya server source-of-truth gibi davranmayacak.
- Bu menunun tek runtime kaynagi sudur:
  - `lib/Core/Services/AppPolicy/surface_policy_override_service.dart`
- Kullaniciya gorunen menu metinlerinde Turkce karakter kullanilabilir.
- Dart dosya adlari, class adlari, method adlari ve key sabitleri Ingilizce
  ve ASCII kalacak.
- Manuel ayar ekrani yeni bir ikinci policy kaynagi olusturmayacak;
  yalniz merkezi registry'nin uzerine local override yazacak.
- Repo, controller, splash veya widget katmani manuel ayarlari dogrudan
  `SharedPreferences` icinden okumayacak; tum okumalar
  `read_budget_registry.dart` uzerinden gececek.

### Ayri Aksiyon Takibi

- Offline/media cache urun kararlari anayasa icinde daginik not olarak
  tutulmayacak.
- Bu kararlar ve uygulama durumlari ayri takip dosyasinda yasayacak:
  - `docs/policies/offline_cache_aksiyon_takibi.md`
- Anayasa kalici ownership ve mimari kurallari tasir.
- Aksiyon dosyasi ise:
  - karar
  - durum
  - commit
  - siradaki uygulama adimi
  alanlarini tasir.
