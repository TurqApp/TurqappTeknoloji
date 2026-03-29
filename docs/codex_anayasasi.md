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

### Acik Sonraki Plan

Ana plan kapanmistir. Aktif blocker yoktur. Siradaki tek non-blocking mini
lane sudur:

- `render_diff_high` warning'inin kok nedenini dusurmek

Bu lane icin sira:

- `merged_feed_rebuild`
- `filtered_feed_rebuild`
- `render_feed_rebuild`

zincirinde patch hacmini dusuren gereksiz rebuild/update noktalarini bul.

Bu lane'in Definition of Done'u:

- full smoke yesil kalacak
- `blocking=0`
- `failures=0`
- mumkunse `render_diff_high` warning'i artifact'lardan kalkacak
