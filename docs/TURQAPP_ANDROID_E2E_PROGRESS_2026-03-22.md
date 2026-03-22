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

## Ana Test Yapısı

- `integration_test/turqapp_complete_e2e_test.dart`
  - tek resmi ana E2E entrypoint
  - eski `full`, `all_tabs` ve `master` kapsamını tek uzun oturumda birleştirir
  - launch + auth bootstrap
  - feed like/comment/reply yüzeyi
  - profile edit + settings
  - composer draft
  - explore sekmeleri
  - education/pasaj sekmeleri
  - chat sekmeleri
  - notifications sekmeleri + more sheet
  - short + background/resume
  - her adımda progress/artifact kaydı
  - native Exo audio ownership assertion

- `integration_test/core/helpers/turqapp_complete_e2e_flow.dart`
  - complete E2E akışının reusable gövdesi
  - daha sonra iOS eşlemesinde de aynı matris mantığı korunacak

- `integration_test/feed/turqapp_audio_ownership_e2e_test.dart`
  - off-feed yüzeylerde audible feed leak assertion
  - profile
  - education + tüm visible pasaj sekmeleri
  - chat
  - notifications
  - short
  - background/resume sonrası tekrar assertion

- `integration_test/feed/feed_production_smoke_suite_test.dart`
  - feed playback
  - normal/fast/aggressive scroll
  - perf monitor
  - background/resume
  - network override

- `integration_test/feed/feed_black_flash_smoke_test.dart`
  - black flash / renderer stall / surface rebind erken başlangıç smoke

- `integration_test/feed/feed_fullscreen_audio_smoke_test.dart`
  - fullscreen handoff
  - ses ve playback continuity

- `integration_test/feed/feed_network_resilience_smoke_test.dart`
  - cellular/offline resilience

- `integration_test/shorts/short_ten_video_smoke_test.dart`
  - ilk 10 short playback continuity

- `integration_test/feed/feed_native_exoplayer_truth_smoke_test.dart`
  - native ExoPlayer truth smoke hattı

## Resmi Set ve Genisletilmis Havuz

Resmi master release-gate set:

- `integration_test/turqapp_complete_e2e_test.dart`
- `integration_test/feed/feed_black_flash_smoke_test.dart`
- `integration_test/feed/feed_fullscreen_audio_smoke_test.dart`
- `integration_test/feed/feed_network_resilience_smoke_test.dart`
- `integration_test/feed/feed_normal_scroll_playback_smoke_test.dart`
- `integration_test/shorts/short_first_two_playback_test.dart`
- `integration_test/feed/turqapp_audio_ownership_e2e_test.dart`
- `integration_test/feed/hls_data_usage_suite_test.dart`

Genisletilmis ama master disi uzman havuz:

- `integration_test/feed/feed_production_smoke_suite_test.dart`
- `integration_test/feed/feed_native_exoplayer_truth_smoke_test.dart`
- `integration_test/feed/feed_resume_test.dart`
- `integration_test/explore/explore_preview_gate_test.dart`
- `integration_test/profile/profile_resume_test.dart`
- `integration_test/notifications/notifications_snapshot_mutation_test.dart`
- `integration_test/chat/chat_listing_smoke_test.dart`
- `integration_test/shorts/short_five_item_playback_stress_test.dart`
- `integration_test/shorts/short_ten_video_smoke_test.dart`
- diger tek-risk odakli playback ve replay testleri

## Native Truth / Log Katmanı

- Android native snapshot:
  - `android/app/src/main/kotlin/com/turqapp/app/ExoPlayerPlugin.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/ExoPlayerView.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/ExoPlayerSmokeRegistry.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/PlaybackHealthMonitor.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/ExoPlayerPlaybackProbe.kt`

- Flutter side helpers:
  - `integration_test/core/helpers/native_exoplayer_probe.dart`
  - `integration_test/core/helpers/smoke_artifact_collector.dart`
  - `integration_test/core/helpers/e2e_matrix_logger.dart`
  - `integration_test/core/helpers/e2e_progress_tracker.dart`
  - `integration_test/core/helpers/test_state_probe.dart`

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

- `integration_test/turqapp_complete_e2e_test.dart`
  - gerçek cihazda geçti
  - explore iç sekmeleri dahil
  - pasaj iç sekmeleri dahil

- `integration_test/feed/turqapp_audio_ownership_e2e_test.dart`
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

- `integration_test/feed/feed_production_smoke_suite_test.dart`
  - geçti

- `integration_test/feed/feed_black_flash_smoke_test.dart`
  - geçti

- `integration_test/feed/feed_network_resilience_smoke_test.dart`
  - geçti

- `integration_test/feed/feed_fullscreen_audio_smoke_test.dart`
  - son düzeltmeler sonrası geçti

- `integration_test/shorts/short_ten_video_smoke_test.dart`
  - geçti

## Mevcut Fonksiyonel Coverage Karari

Guclu taraf:

- launch + auth
- feed playback
- short playback
- ownership / off-screen audio
- profile temel akislar
- explore/profile/chat/notifications/education tab traversal

Kismi taraf:

- comments
- chat derinligi
- notifications route derinligi
- story interaksiyonlari
- market ve education detail akislar
- uzun oturum trendi

Net eksik Phase 3 alanlari:

- yorumda gercek reply send
- yorum delete
- chat icinde gercek conversation acip mesaj gonderme
- notification item deep-link hedef route dogrulamasi
- single short'a gercek entrypoint'ten gitme
- story reply/reaction
- market detail derin akisi
- education detail derin akislar:
  - burs detay
  - job finder detay
  - test solve
- 10-15 dakikalik stress/memory assertion lane

Unutulmaya acik ikinci halka bosluklar:

- auth/session churn:
  - logout
  - stored account reauth
  - account switch
- explore gercek search mode + recent search persistence
- social graph + safety:
  - follow/unfollow
  - report/block
- post publish + media persistence
- permission matrix:
  - camera
  - gallery
  - microphone
  - location
- passage owner/applicant mutasyonlari:
  - job apply
  - tutoring create/save
  - practice exam apply/save
  - answer key saved/owner yuzeyleri
- story management:
  - story maker
  - highlights
  - deleted stories restore/repost/delete
  - story music
- settings/raw-form round-trip persistence

Onerilen yeni entrypoint ailesi:

- `integration_test/comment_reply_send_e2e_test.dart`
- `integration_test/comment_delete_e2e_test.dart`
- `integration_test/chat_conversation_send_e2e_test.dart`
- `integration_test/notifications_deeplink_route_e2e_test.dart`
- `integration_test/short_real_entry_e2e_test.dart`
- `integration_test/story_reply_reaction_e2e_test.dart`
- `integration_test/market_detail_deep_e2e_test.dart`
- `integration_test/education_detail_deep_e2e_test.dart`
- `integration_test/long_session_stress_memory_e2e_test.dart`

Ikinci halka onerilen entrypointler:

- `integration_test/auth_session_churn_e2e_test.dart`
- `integration_test/explore_search_mode_e2e_test.dart`
- `integration_test/social_graph_safety_e2e_test.dart`
- `integration_test/post_publish_persistence_e2e_test.dart`
- `integration_test/permission_matrix_e2e_test.dart`
- `integration_test/passage_actions_e2e_test.dart`
- `integration_test/story_management_e2e_test.dart`
- `integration_test/settings_roundtrip_e2e_test.dart`

Karar:

- complete E2E artik eskisine gore anlamli sekilde daha genis
- ama uygulamanin tum islevsel derinligi acisindan Phase 3 kapanmis degil
- buna ek olarak operasyonel sertlik acisindan ikinci halka bosluklar da acik
- yeni derin akislari tek bir dev complete teste yigmamak gerekir
- once uzman entrypoint olarak yesile cekip, sonra uygun olanlari master sete promote etmek gerekir

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

Tek ana E2E:

```bash
flutter test integration_test/turqapp_complete_e2e_test.dart \
  -d 192.168.1.196:5555 \
  --dart-define=RUN_INTEGRATION_SMOKE=true \
  --dart-define=INTEGRATION_LOGIN_EMAIL=turqapp@gmail.com \
  --dart-define=INTEGRATION_LOGIN_PASSWORD=Nisa1512.
```

Complete E2E + uzman smoke zinciri:

```bash
bash scripts/run_turqapp_master_e2e.sh
```

Phase 3 kanonik dokumani:

- `docs/TURQAPP_TEST_SYSTEM_2026-03-22.md`

## Not

Bu dosya Android odaklıdır.
İstek gereği iOS sona bırakılmıştır.
