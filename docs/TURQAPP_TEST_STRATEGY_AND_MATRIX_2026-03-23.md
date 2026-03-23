# TurqApp Test Strategy And Matrix

Tarih: 2026-03-23

Bu dokuman TurqApp icin kanonik test stratejisi, uygulama matrisi ve test sertlestirme planidir.
Amaç:

- testleri implementasyon detayindan urun kontratina cekmek
- flaky smoke hatalarini sistematik sekilde azaltmak
- hangi testin hangi ortamda neyi dogruladigini tek yerde sabitlemek
- fixture, helper, CI ve release gate iliskisini netlestirmek
- gelistirme ekibine dosya bazli uygulanabilir is listesi vermek

## 1. Temel Ilkeler

1. Testler widget veya native implementasyon detayini degil urun kontratini dogrulayacak.
2. Her async yuzey poll + timeout + son snapshot mantigiyla okunacak.
3. Gecici backend veya player jitter hatalari fatal sinifa alinmayacak.
4. Feed, profile, chat ve auth testleri birbirinden bagimsiz deterministic fixture kullanacak.
5. Buyuk smoke testleri ilk tespit noktasi degil son guvenlik agi olacak.
6. Her basarili sertlestirme adimi bagimsiz commit ile alinacak.

## 2. Mevcut Test Envanteri

### Unit + Widget

- `test/` altinda `38` dosya
- Komut: `flutter test`
- Rol:
  - service/state mantigi
  - widget davranisi
  - integration harness contractlari

### Integration

- `integration_test/` altinda `42` dosya
- Ana scriptler:
  - `scripts/run_turqapp_test_smoke.sh`
  - `scripts/run_integration_smoke.sh`
  - `scripts/run_turqapp_master_e2e.sh`
  - `scripts/run_extended_e2e_suite.sh`
  - `scripts/run_long_session_suite.sh`
  - `scripts/run_process_death_restore_suite.sh`
  - `scripts/run_permission_os_matrix_suite.sh`
  - `scripts/run_product_depth_e2e.sh`
  - `scripts/run_release_gate_checks.sh`

### Suite Manifestleri

- `config/test_suites/turqapp_test_smoke.txt`
- `config/test_suites/extended_smoke.txt`
- `config/test_suites/long_session_e2e.txt`
- `config/test_suites/permission_os_matrix_e2e.txt`
- `config/test_suites/process_death_e2e.txt`
- `config/test_suites/product_depth_e2e.txt`
- `config/test_suites/release_gate_e2e.txt`
- `config/test_suites/integration_smoke.tsv`

## 3. Hedeflenen Test Katmanlari

### Katman 1: Boot/Auth Contract

Amaç:

- uygulama boot ediyor mu
- login deterministic mi
- sign-out auth state'i temizliyor mu
- reauth oturumu dogru geri getiriyor mu

Kapsam:

- `integration_test/auth/login_flow_test.dart`
- `integration_test/auth/auth_session_churn_e2e_test.dart`

Hedeflenen yeni testler:

- `integration_test/auth/auth_signout_state_test.dart`
- `integration_test/auth/auth_reauth_restore_test.dart`

### Katman 2: Feed Playback Contract

Amaç:

- ilk gorunur video bulunuyor mu
- adapter olusuyor mu
- first frame geliyor mu
- playback ilerliyor mu
- mute toggle kontrati calisiyor mu

Kapsam:

- `integration_test/feed/feed_production_smoke_suite_test.dart`
- `integration_test/feed/feed_first_video_autoplay_test.dart`
- `integration_test/feed/feed_first_video_playback_test.dart`
- `integration_test/feed/feed_network_resilience_smoke_test.dart`
- `integration_test/feed/feed_resume_test.dart`
- `integration_test/feed/hls_data_usage_suite_test.dart`

Hedeflenen yeni testler:

- `integration_test/feed/feed_boot_visible_video_test.dart`
- `integration_test/feed/feed_first_video_playback_contract_test.dart`
- `integration_test/feed/feed_audio_toggle_contract_test.dart`

### Katman 3: Profile Playback Contract

Amaç:

- profile ekraninda merkezlenen video gorunur mu
- adapter gec olussa bile recover ediyor mu
- profile playback feed ile ayni kontratla okunuyor mu

Kapsam:

- `integration_test/profile/profile_resume_test.dart`
- `integration_test/profile/profile_feed_video_smoke_test.dart`

Hedeflenen yeni testler:

- `integration_test/profile/profile_visible_video_contract_test.dart`
- `integration_test/profile/profile_first_video_playback_test.dart`

### Katman 4: Network Resilience Contract

Amaç:

- Firestore `unavailable`
- transient `503`
- kisa player reset
- feed/profile/auth bootstrap gecikmesi

gibi durumlarin false negative uretmemesi

Kapsam:

- `integration_test/feed/feed_network_resilience_smoke_test.dart`
- `integration_test/feed/hls_data_usage_suite_test.dart`
- `integration_test/core/bootstrap/test_app_bootstrap.dart`

### Katman 5: Full Smoke Suite

Amaç:

- alt kontratlar gectikten sonra orchestrated confidence saglamak
- release-oncesi buyuk regresyonlari yakalamak

Kapsam:

- `integration_test/feed/feed_production_smoke_suite_test.dart`
- `integration_test/turqapp_complete_e2e_test.dart`
- `config/test_suites/release_gate_e2e.txt`

## 4. Urun Kontrati Seviyesinde Assertion Standardi

### Video kontrati

Her video testinde ayni sira izlenecek:

1. `exists`
2. `initialized`
3. `firstFrame`
4. `position advanced`

Video testleri tek adimda "playable" demeyecek. Her durum ayri okunacak.

### Audio kontrati

Audio toggle testleri su sirayla calisacak:

1. ilk state okunur
2. command verilir
3. kisa poll penceresinde state degisimi aranir
4. gerekirse `isMuted` ve `volume` birlikte okunur

### Auth kontrati

Auth churn testleri su ana durumu dogrular:

1. signed-in
2. signed-out
3. current uid temizlendi
4. reauth sonrasi uid geri geldi

`account center`, `notifications`, `reshare`, `comments membership` gibi akislari ikincil sinyal kabul eder.

## 5. Transient Hata Siniflandirmasi

### Toleransli sinif

- `cloud_firestore/unavailable`
- `Invalid statusCode: 503`
- kisa sureli player adapter reset
- ilk acilista gec gelen feed/profile snapshot

### Fatal sinif

- `permission-denied`
- fixture'ta zorunlu dokuman eksigi
- invalid auth state transition
- player hic olusmuyor ve timeout asiyor
- route hedefi acilmiyor

### Uygulama

Bu politika ortak helper seviyesinde toplanacak:

- `integration_test/core/helpers/transient_error_policy.dart`
- `integration_test/core/helpers/contract_waiters.dart`

## 6. Deterministic Fixture Stratejisi

Mevcut durum:

- tek veya asiri genis seed birden fazla yuzeyi ayni anda besliyor
- bu da feed/profile/chat testlerini birbirine bagimli hale getiriyor

Hedef:

- yuzey bazli seed ayrimi

Olusturulacak dosyalar:

- `integration_test/core/fixtures/smoke_seed.auth.json`
- `integration_test/core/fixtures/smoke_seed.feed.json`
- `integration_test/core/fixtures/smoke_seed.profile.json`
- `integration_test/core/fixtures/smoke_seed.chat.json`
- `integration_test/core/fixtures/smoke_seed.notifications.json`

Degisecek dosyalar:

- `scripts/run_turqapp_test_smoke.sh`
- `lib/Core/Services/integration_test_fixture_contract.dart`
- `config/test_suites/*.txt`

Fixture kontrati:

- auth:
  - sign-in icin hazir hesap
  - Firestore profile kaydi
  - session restore sinyali
- feed:
  - autoplay video post
  - feed ref zinciri
  - mute toggle uygun media
- profile:
  - owner'a ait en az 1 playable video
  - profile liste gorunurlugu
- chat:
  - en az 1 thread
  - son mesaj
  - media fail/success varyanti
- notifications:
  - route acan bildirim
  - unread snapshot mutasyonu

## 7. Test Matrisi

| Katman | Yuzey | Kontrat | Ortam | Komut/Suite | Gate |
| --- | --- | --- | --- | --- | --- |
| Static | tum kod | analyze + compile | lokal + CI | `flutter analyze --no-fatal-infos`, `./gradlew :app:compileDebugKotlin :app:compileDebugAndroidTestKotlin` | hard |
| Unit/Widget | service, state, widget | business logic | lokal + CI | `flutter test` | hard |
| Boot/Auth | auth | login/signout/reauth | Android emulator, iPhone 11 sim, CI | auth testleri | hard |
| Feed Playback | agenda/feed | autoplay, adapter, first frame, advance | Android emulator, iPhone 11 sim, gerektiğinde gercek cihaz | feed contract testleri | hard |
| Profile Playback | my profile | visible video + playback | iPhone 11 sim, Android emulator | profile contract testleri | medium -> hard |
| Network | firestore/hls | transient retry/recovery | CI, emulator, sim | network resilience suite | hard |
| Chat | chat | thread visible, send, media failure | Android emulator, iPhone 11 sim | chat suite | medium |
| Notifications | notification | deeplink, unread mutasyon | Android emulator, iPhone 11 sim | notifications suite | medium |
| Full Smoke | coklu yuzey | orchestration regression | CI + nightly | `turqapp_test_smoke.txt`, `release_gate_e2e.txt` | hard |
| Long Session | dayaniklilik | churn, replay, memory trend | nightly, secili gercek cihaz | `long_session_e2e.txt` | nightly |
| Process Death | restore | state restore | Android once, sonra iOS | `process_death_e2e.txt` | nightly/release |
| Permission Matrix | system | allow/deny state | Android/iOS | `permission_os_matrix_e2e.txt` | nightly/release |

## 8. Dosya Bazli Uygulanacak Ilk 5 Is

### Is 1: Feed smoke'u kucuk contract testlerine bol

Degisecek dosyalar:

- `integration_test/feed/feed_production_smoke_suite_test.dart`
- `integration_test/core/helpers/player_contract_helpers.dart` (yeni)
- `integration_test/core/helpers/contract_waiters.dart` (yeni)

Olusturulacak dosyalar:

- `integration_test/feed/feed_boot_visible_video_test.dart`
- `integration_test/feed/feed_first_video_playback_contract_test.dart`
- `integration_test/feed/feed_audio_toggle_contract_test.dart`

Beklenen kazanim:

- feed fail ettiginde hangi adim kirildi net okunur
- mute toggle ile adapter existence ayni testte karismaz

### Is 2: Profile adapter wait'i toleransli yap

Degisecek dosyalar:

- `integration_test/profile/profile_feed_video_smoke_test.dart`
- `integration_test/core/helpers/player_contract_helpers.dart`

Degisiklik:

- doc bulundu -> adapter reacquire -> firstFrame -> advance
- profile cache key / centered post ayrismasi testten saklanir

Beklenen kazanim:

- iPhone 11 sim ve CI profile playback false negative'leri azalir

### Is 3: Auth churn'u auth-state odakli hale getir

Degisecek dosyalar:

- `integration_test/auth/auth_session_churn_e2e_test.dart`
- `integration_test/core/bootstrap/test_app_bootstrap.dart`
- `integration_test/core/helpers/test_state_probe.dart`

Olusturulacak dosyalar:

- `integration_test/auth/auth_signout_state_test.dart`
- `integration_test/auth/auth_reauth_restore_test.dart`

Beklenen kazanim:

- logout sonrasi yavas temizlenen yan stream'ler ana test sonucu bozmaz

### Is 4: Transient retry helper'i tanimla

Olusturulacak dosyalar:

- `integration_test/core/helpers/transient_error_policy.dart`
- `integration_test/core/helpers/contract_waiters.dart`

Degisecek dosyalar:

- `integration_test/core/bootstrap/test_app_bootstrap.dart`
- `integration_test/core/helpers/smoke_artifact_collector.dart`

Beklenen kazanim:

- `cloud_firestore/unavailable` ve `503` kaynakli CI false negative'leri duser

### Is 5: Fixture'lari yuzey bazli ayir

Olusturulacak dosyalar:

- `integration_test/core/fixtures/smoke_seed.auth.json`
- `integration_test/core/fixtures/smoke_seed.feed.json`
- `integration_test/core/fixtures/smoke_seed.profile.json`
- `integration_test/core/fixtures/smoke_seed.chat.json`
- `integration_test/core/fixtures/smoke_seed.notifications.json`

Degisecek dosyalar:

- `scripts/run_turqapp_test_smoke.sh`
- `lib/Core/Services/integration_test_fixture_contract.dart`
- `config/test_suites/turqapp_test_smoke.txt`
- `config/test_suites/extended_smoke.txt`

Beklenen kazanim:

- bir yuzeyin datasizligi baska yuzeyin smoke'unu dusurmez

## 9. Test Ortami Matrisi

### Lokal zorunlu

- `flutter analyze --no-fatal-infos`
- `flutter test`
- Android compile:
  - `./gradlew :app:compileDebugKotlin :app:compileDebugAndroidTestKotlin`

### Lokal gelistirme smoke

- Android emulator:
  - feed contract
  - network resilience
  - auth contract
- iPhone 11 simulator:
  - auth contract
  - feed contract
  - profile contract

### Gercek cihaz dogrulamasi

- Android gercek cihaz:
  - release playback
  - audio ownership
  - uzun oturum
- iPhone gercek cihaz:
  - release boot
  - session restore
  - permission gatings

### CI required

- analyze + unit/widget
- Android Integration Smoke
- iOS Integration Smoke

### Nightly

- long session
- process death
- permission matrix
- product depth

## 10. CI Eslestirmesi

### `config/test_suites/turqapp_test_smoke.txt`

Bugunku icerik:

- `integration_test/feed/feed_production_smoke_suite_test.dart`
- `integration_test/feed/hls_data_usage_suite_test.dart`
- `integration_test/feed/feed_black_flash_smoke_test.dart`
- `integration_test/feed/feed_network_resilience_smoke_test.dart`
- `integration_test/feed/feed_resume_test.dart`

Hedef:

- bu dosya zamanla "feed orchestration + kritik playback" paketi olacak
- auth ve profile kontratlari ayri suite olarak cagrilacak

### `config/test_suites/release_gate_e2e.txt`

Release blocking kalmasi gerekenler:

- complete E2E
- black flash
- fullscreen audio
- network resilience
- normal scroll playback
- shorts entry
- audio ownership
- HLS data usage

Not:

- full smoke paketleri contract testler yesile oturana kadar tek basina guvenilir gate olmayacak

## 11. Definition Of Done

Bu stratejinin tamamlanmis sayilmasi icin:

1. auth, feed ve profile icin ayri contract testleri yesil olacak
2. contract testleri iPhone 11 sim + Android emulator'da stabil olacak
3. transient hata politikasini ortak helper yonetecek
4. fixture'lar yuzey bazli ayrilmis olacak
5. full smoke fail ederse log tek bakista hangi kontratin koptugunu gosterecek
6. GitHub required check'ler kontrat tabanli olacak, implementasyon kirilganligina dayanmayacak

## 12. Hemen Sonraki Icra Sirasi

1. `integration_test/core/helpers/transient_error_policy.dart` olustur
2. `integration_test/core/helpers/contract_waiters.dart` olustur
3. auth churn'u iki contract testine bol
4. feed ilk video + audio toggle contract testlerini ayir
5. profile playback wait zincirini ortak player helper'a tasi
6. feed/profile/chat fixture dosyalarini ayir
7. `feed_production_smoke_suite_test.dart`i orchestration seviyesine indir

Bu siranin disina cikilmamali. Ilk once kontrat testleri, sonra full smoke refactor, en son CI gate yeniden esitlenecek.
