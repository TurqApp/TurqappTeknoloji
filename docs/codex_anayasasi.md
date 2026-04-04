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
   - Yan etki kesinlikle kabul edilemez.
   - Bir degisiklik, hedef problemi cozse bile baska bir akis, ekran, trigger,
     feed, playback, cache veya veri davranisinda bozulma olusturuyorsa kabul
     edilmez.
   - "Kucuk yan etki", "tolere edilebilir yan etki" veya "sonra temizleriz"
     yaklasimi yasaktir.
6. Kapsam disina cikma.
   - Istenmeyen hicbir gelistirme yapma.
   - "Bunu da duzeltmisken..." yaklasimi yasak.
7. Basarisiz patch birakma.
   - Istenen sonucu vermeyen veya yan etki ureten patch'ler temizlenmeden yeni
     patch yazma.
   - Duzeltmeyi temiz bir diff uzerinden tamamla.

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
- Her patch yan etki olusturmama hedefiyle tasarlanacak.
- Degisiklikten etkilenen yakin akislar ve bagli yuzeyler dogrulanmadan cozum
  tamamlanmis sayilmayacak.

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
5. Kullanici `commit` istediyse commit alma istegi unutulmayacak.
   - Dogrulama zinciri tamamlanir tamamlanmaz uygun commit alinacak.
   - Commit alinmadiysa nedeni final cevapta acikca yazilacak.
6. Kullanici yalnizca `run` dediginde varsayilan kosu profili sunlardir:
   - Android tarafinda Wi-Fi bagli cihaz kullanilir.
   - iOS tarafinda release run kullanilir.
   - Kullanici ayrica platform, cihaz veya build modu belirtirse bu varsayilan
     gecersiz olur ve acik talimat uygulanir.

## Cikti Formati Zorunlulugu

Varsayilan cevap formati, kod yazma/duzeltme turu gorevlerde sudur:

1. Kok Neden
2. Minimal Cozum
3. Kod Degisikligi
4. Calistirma Komutu
5. Kapsam Notu

Her is kapanisinda, yukaridaki 5 ana basliga ek olarak kisa bir review ozeti
de verilir. Bu ozet yalnizca yapilan ise odaklanir ve su sabit formatla
yazilir:

- Sonuc: Dogru / Kismen / Hatali
- Bulunan sorunlar
- Firebase maliyet etkisi
- Merge oncesi duzeltilmesi gerekenler

- Kullanici review/denetim talep ettiyse bu varsayilan 5 baslikli format yerine
  asagidaki `Denetim ve Review Modu` formati kullanilir.

## Denetim ve Review Modu Zorunlulugu

- Kullanici "kontrol et", "review et", "denetle", "az once yapilan isi kontrol
  et" veya benzeri bir talep verdiginde varsayilan calisma modu kod review'dur.
- Bu modda:
  - yeni ozellik yazilmaz
  - kapsam buyutulmaz
  - gereksiz refactor yapilmaz
  - sadece yapilan gorevin dogrulugu, temizligi, guvenligi ve yakin etkileri
    denetlenir
- Review su 4 eksende zorunlu olarak yapilir:
  - istenen gorev tam yapilmis mi
  - Flutter tarafi
  - Firebase tarafi
  - kod kalitesi ve regresyon riski
- Istenen gorev kontrolunde su sorular zorunludur:
  - degisiklik gercekten talep edilen isi karsiliyor mu
  - eksik senaryo kalmis mi
  - sadece gerekli dosya ve satirlara mi dokunulmus
  - gereksiz yerlere mudahale edilmis mi
- Flutter kontrolunde su basliklar zorunludur:
  - mevcut mimari bozulmus mu
  - widget/state/async/lifecycle tarafinda bariz hata var mi
  - null safety ve context kullanimi dogru mu
  - controller/dispose yonetimi dogru mu
  - stream/subscription yonetimi dogru mu
  - gereksiz rebuild veya gereksiz karmasiklik var mi
- Firebase kontrolunde su basliklar zorunludur:
  - Firebase/Firestore kullanimi dogru mu
  - gereksiz read/write ureten akis var mi
  - gereksiz veya yanlis listener var mi
  - tek seferlik islem icin stream acilmis mi
  - cache ile cozulebilecek yerde tekrar sorgu var mi
  - guvenlik riski olusturan kullanim var mi
  - veri modeli veya sorgu tarafinda bariz hata var mi
- Kod kalitesi kontrolunde su basliklar zorunludur:
  - isimlendirmeler anlasilir mi
  - kod okunabilir mi
  - hata yonetimi yeterli mi
  - edge case eksigi var mi
  - mevcut akislari bozma riski var mi
- Emin olunmayan noktalarda varsayim yapilmaz; acikca `muhtemel risk`
  denilerek belirtilir.
- Mumkun oldugunca dosya, sinif ve fonksiyon bazli konusulur.

Review cikti formati zorunlu olarak su sekilde yazilir:

1. SONUC
- Gorev dogru tamamlanmis mi? (Evet / Kismen / Hayir)
- Kisa ozet

2. BULGULAR
- Her bulgu icin:
- Seviye: Kritik / Orta / Dusuk
- Konum: dosya / sinif / fonksiyon
- Sorun
- Neden sorun
- Nasil duzeltilir

3. FIREBASE ETKISI
- Ek maliyet riski var mi?
- Gereksiz read/write/listener var mi?
- Varsa nasil azaltilir?

4. SON KARAR
- Bu haliyle kabul edilir mi?
- Merge oncesi duzeltilmesi gerekenler neler?

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

Bu bolum yeni kural getirmez; ustteki temel maddelerin kisa ozetidir:
"Sadece isteneni yap. Minimum degistir. Tam coz. Asla varsayim yapma."

## Context-Aware Davranis Eki

Bu bolum, `Proje Analizi Zorunlulugu` basliginin kisa uygulama notudur.
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

- Bu bolumdeki budget/cache guard'larinin kalici tek sahipligi
  `SurfacePolicyRegistry`'dedir.
- `lib/Core/Services/read_budget_registry.dart` bagimsiz karar sahibi degil;
  runtime/uyumluluk giris noktasi olarak kalabilir.
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
  budget kararlari bagimsiz lokal kaynaklarda tutulmaz.
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
  `SurfacePolicyRegistry`'ye tanimlanmak, gerekirse `ReadBudgetRegistry`
  uzerinden tuketilmek zorundadir.
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
kurallar, "ayar verme modu"nda alinacak her karar icin baglayicidir. 2026-03-29
bolumundeki budget/cache guard'larinin kanonik sahiplik yorumu bu bolumle
birlikte okunur.

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

## 2026-03-30 Merkezi Purge ve Invalidation Omurgasi

Kullanici aksiyonu ile silinen, geri alinan, gizlenen, yayindan kaldirilan
veya gorunurlugu degisen icerikler cache'de yasamayacak. Bu baslik altindaki
kurallar, cache omurgasinin tamamlayici "anlik purge" sozlesmesidir.

### Tek Merkez Mutation Sahipligi

- Kullaniciya gorunen bir icerigi etkileyen `delete`, `unsend`, `remove`,
  `withdraw`, `unpublish`, `hide`, `block`, `private/public` mutasyonlari
  controller veya view katmaninda dogrudan Firestore/Storage silme mantigi
  tasimayacak.
- Bu mutasyonlar yalniz alan sahibi repository veya alan sahibi service
  uzerinden yurutulecek.
- UI katmani sadece:
  - intent baslatir
  - optimistik local state uygular
  - repository/service sonucunu tuketir
- Firestore alt koleksiyon, snapshot surface, doc cache, media cache ve local
  liste temizligi ayni ownership hattinda kapanacak.

### Zorunlu Purge Davranisi

- Bir icerik silinirse:
  - ekrandan aninda dusecek
  - ilgili snapshot/local liste cache'inden aninda dusecek
  - app restart sonrasi geri gelmeyecek
  - offline acilista geri gelmeyecek
- Medya veya dosya baglantili bir icerikse:
  - disk/cache temizligi de ayni mutation zincirinin parcasi olacak
- Visibility degisimi ise:
  - UI filtresi tek basina yeterli sayilmayacak
  - ilgili surface invalidation'i da zorunlu olacak

### Kabul Edilen Dogrudan Delete Istisnalari

Asagidaki kategoriler mimari ihlal sayilmaz; bunlar bilincli cekirdek
temizliklerdir:

- canonical cekirdek servis transaction silmeleri
  - `post_delete_service.dart`
  - `post_interaction_service.dart`
  - `offline_mode_service_action_part.dart`
  - `user_post_link_service.dart`
- temp veya lokal dosya temizligi
  - ses kaydi gecici dosyasi
  - avatar eski dosyalari
  - upload temp klasorleri
- secure storage / session / account vault temizligi
- auth hesabini silme veya account lifecycle temizligi
- repository'nin kendi icinde yaptigi alt koleksiyon batch purge'leri

Bu alanlar disinda view/controller katmaninda dogrudan `.delete()` kullanimi
anayasa ihlalidir.

### User-Content Domain Kurali

- Post, yorum, alt yorum, reshare, saved, liked, hidden, story, market, job,
  tutoring, scholarship, test, practice exam, answer key ve optical form
  mutasyonlari repository/service omurgasi disina cikmayacak.
- Bildirim inbox, sohbet mesaji, sohbet preview ve bagli medya temizligi
  lokal snapshot ile birlikte yurutulecek.
- Admin ekranlari dahil olmak uzere kullaniciya gorunen veri degistiren
  silme akislari once service/repository'ye alinacak, sonra UI'dan
  cagrilacak.

### Kapanis Kriteri

- Residual taramada kalan `delete` cagrilari su siniflara dusuyorsa lane
  kapanmis sayilir:
  - canonical cekirdek servis
  - temp/local file cleanup
  - secure storage/session cleanup
  - auth/account cleanup
- Bunlar disinda yeni bir dogrudan delete gorulurse:
  - once ownership hatti acilacak
  - sonra mutation repository/service'e tasinacak
  - en son UI call-site sadeleştirilecek
