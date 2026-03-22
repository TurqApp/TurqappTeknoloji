# TurqApp Android E2E Progress

Tarih: 2026-03-22

Bu dosya Android gerçek cihaz E2E/test ilerleme durumunu kalıcı olarak tutar.
Amaç:
- mola sonrası aynı noktadan devam etmek
- hangi testlerin hazır olduğunu unutmamak
- son gerçek cihaz sonuçlarını tek yerde görmek

## Kapsam

Bu E2E/test matrisi şu alanları kapsar:

- launch + auth bootstrap
- feed açılışı
- explore, profile, chat, notifications, short, education erişimi
- keşfet iç sekmeleri
- pasaj iç sekmeleri
- feed -> başka ekran geçişleri
- background / foreground dönüşleri
- short playback smoke
- feed production smoke
- black flash smoke
- fullscreen audio smoke
- network resilience smoke
- native ExoPlayer truth snapshot
- off-screen audible feed playback assertion

## Ana Test Dosyaları

- `integration_test/turqapp_master_e2e_test.dart`
  - tek uzun oturumlu ana matris
  - launch + auth bootstrap
  - feed like/comment/reply/delete yüzeyi
  - profile edit + settings
  - composer draft
  - explore sekmeleri
  - education/pasaj sekmeleri
  - chat sekmeleri
  - notifications sekmeleri + more sheet
  - short + background/resume
  - her adımda progress/artifact kaydı
  - native Exo audio ownership assertion

- `integration_test/turqapp_full_e2e_test.dart`
  - ana kullanıcı yolculuğu
  - feed like
  - comment
  - profile edit
  - settings aç/kapat
  - post creator draft akışı

- `integration_test/turqapp_all_tabs_e2e_test.dart`
  - ana tab yüzeyleri
  - explore iç sekmeleri
  - education/pasaj iç sekmeleri
  - chat
  - notifications
  - short

- `integration_test/turqapp_audio_ownership_e2e_test.dart`
  - off-feed yüzeylerde audible feed leak assertion
  - profile
  - education + tüm visible pasaj sekmeleri
  - chat
  - notifications
  - short
  - background/resume sonrası tekrar assertion

- `integration_test/feed_production_smoke_suite_test.dart`
  - feed playback
  - normal/fast/aggressive scroll
  - perf monitor
  - background/resume
  - network override

- `integration_test/feed_black_flash_smoke_test.dart`
  - black flash / renderer stall / surface rebind erken başlangıç smoke

- `integration_test/feed_fullscreen_audio_smoke_test.dart`
  - fullscreen handoff
  - ses ve playback continuity

- `integration_test/feed_network_resilience_smoke_test.dart`
  - cellular/offline resilience

- `integration_test/short_ten_video_smoke_test.dart`
  - ilk 10 short playback continuity

- `integration_test/feed_native_exoplayer_truth_smoke_test.dart`
  - native ExoPlayer truth smoke hattı

## Native Truth / Log Katmanı

- Android native snapshot:
  - `android/app/src/main/kotlin/com/turqapp/app/ExoPlayerPlugin.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/ExoPlayerView.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/ExoPlayerSmokeRegistry.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/PlaybackHealthMonitor.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/ExoPlayerPlaybackProbe.kt`

- Flutter side helpers:
  - `integration_test/helpers/native_exoplayer_probe.dart`
  - `integration_test/helpers/smoke_artifact_collector.dart`
  - `integration_test/helpers/e2e_matrix_logger.dart`
  - `integration_test/helpers/e2e_progress_tracker.dart`
  - `integration_test/helpers/test_state_probe.dart`

## Key / Probe Hazırlığı

Bugün master E2E için eklenen yüzeyler:

- yorum ekranı key’i
- yorum item / like / reply / delete key’leri
- yorum reply clear / gif picker action key’leri
- chat search / create / top tab / tile key’leri
- notifications more / mark all read / delete all key’leri
- `IntegrationTestStateProbe` içine:
  - `explore`
  - `education`
  - `chat`
  snapshot’ları

Bu hazırlıkla tek senaryoda daha fazla ekran state’i ve kırık adımı loglanabilir hale geldi.

Native snapshot artık şunları da taşır:
- `viewId`
- `currentUrl`
- `isSoftHeld`
- `heldVolume`
- `playerVolume`
- `isMuted`
- `isPlayingRuntime`
- `currentPositionMs`
- `playWhenReady`
- `selectedBitrateKbps`
- `selectedResolution`
- `rebufferCount`
- `playerState`

## Son Gerçek Cihaz Sonuçları

Cihaz:
- `192.168.1.196:5555`

### Geçenler

- `integration_test/turqapp_all_tabs_e2e_test.dart`
  - gerçek cihazda geçti
  - explore iç sekmeleri dahil
  - pasaj iç sekmeleri dahil

- `integration_test/turqapp_audio_ownership_e2e_test.dart`
  - yazıldı
  - gerçek cihaz koşusu başlatıldı
  - son görülen ilerleme:
    - `profile` geçti
    - `resume_profile` geçti
    - `education`
    - `education_tab_market`
    - `education_tab_job_finder`
    - `education_tab_scholarships`
    - `education_tab_question_bank`
    - `education_tab_practice_exams`
    - `education_tab_online_exam`
    - `education_tab_answer_key`
    - `education_tab_tutoring`
    - `resume_education`
  - bu noktaya kadar audible feed leak assertion düşmedi

- `integration_test/feed_production_smoke_suite_test.dart`
  - geçti

- `integration_test/feed_black_flash_smoke_test.dart`
  - geçti

- `integration_test/feed_network_resilience_smoke_test.dart`
  - geçti

- `integration_test/feed_fullscreen_audio_smoke_test.dart`
  - son düzeltmeler sonrası geçti

- `integration_test/short_ten_video_smoke_test.dart`
  - geçti

### Kök Fix Özetleri

- feed/short ownership conflict kapatıldı
- feed tab dışına çıkınca playback claim route-aware hale getirildi
- header üzerinden açılan chat/notifications/post creator akışları sert overlay suspend hattına alındı
- pasaj açıkken feed kartlarının yeniden claim alması kapatıldı
- tab değişiminde önce pause sonra selectedIndex akışı uygulandı
- pasaj sekme değişimlerinde education controller tarafı feed’i tekrar force-pause edecek şekilde sertleştirildi
- off-screen audible feed leak için native ExoPlayer truth assertion eklendi

## Son Commitler

- `84ff81b6`
  - `Fix feed and shorts playback ownership conflict`

- `bfb1555c`
  - `Tighten feed pause and tab traversal coverage`

- `110a6a63`
  - `Pause feed earlier during tab transitions`

## Sonraki Adım

Devam edilecek ilk komut:

```bash
flutter test integration_test/turqapp_master_e2e_test.dart \
  -d 192.168.1.196:5555 \
  --dart-define=RUN_INTEGRATION_SMOKE=true \
  --dart-define=INTEGRATION_LOGIN_EMAIL=turqapp@gmail.com \
  --dart-define=INTEGRATION_LOGIN_PASSWORD=Nisa1512.
```

Ardından toplu matris koşusu:

```bash
bash scripts/run_turqapp_android_e2e_matrix.sh
```

## Not

Bu dosya Android odaklıdır.
İstek gereği iOS sona bırakılmıştır.
