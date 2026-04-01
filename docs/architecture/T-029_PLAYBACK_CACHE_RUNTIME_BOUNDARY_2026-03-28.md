# T-029 Playback / Cache Runtime Boundary

## Amaç

`VideoStateManager` ve `SegmentCacheManager` kullanimini `feed`, `short` ve `story` sicak yollarinda dar bir runtime boundary arkasina toplamak.

## Uygulanan sinir

- Yeni ortak boundary: `lib/Modules/PlaybackRuntime/playback_cache_runtime_service.dart`
- Ayrilan runtime yuzeyleri:
  - `PlaybackRuntimeService`
  - `SegmentCacheRuntimeService`

## Tasinan sicak yollar

- `Agenda/Common/post_content_base*`
- `Short/short_view*`
- `Short/single_short_view*`
- `Story/StoryViewer/story_viewer.dart`

## Kapsam icinde kalan lifecycle davranislari

- pause-all ve exclusive-mode gecisleri
- current playing doc takibi
- playback state save/restore delegasyonu
- cache first-segment hazirlik kontrolu
- active doc `markPlaying`
- geriye donuk `touchEntry`
- watch progress guncellemesi

## Bilincli kapsam disi

- `ShortController` runtime quota ayarlari
- `AgendaController` icindeki diger dogrudan `VideoStateManager` cagrilari
- `VideoStateManager` ve `SegmentCacheManager` siniflarinin kendi ic tasariminin yeniden yazimi

## T-029 kanit seti

- boundary service kodu
- hot-path kaynak tarama testi
- playback lifecycle unit testi
- segment cache helper unit testi

## Kapanis komutlari

- `dart analyze --no-fatal-warnings lib/Modules/PlaybackRuntime/playback_cache_runtime_service.dart lib/Modules/Agenda/Common/post_content_base.dart lib/Modules/Agenda/Common/post_content_base_lifecycle_part.dart lib/Modules/Agenda/Common/post_content_base_playback_part.dart lib/Modules/Short/short_view.dart lib/Modules/Short/short_view_playback_part.dart lib/Modules/Short/single_short_view.dart lib/Modules/Short/single_short_view_helpers_part.dart lib/Modules/Short/single_short_view_playback_part.dart lib/Modules/Short/single_short_view_ui_part.dart lib/Modules/Short/single_short_view_controller_bootstrap_part.dart lib/Modules/Short/single_short_view_controller_sync_part.dart lib/Modules/Story/StoryViewer/story_viewer.dart test/unit/modules/playback_runtime/playback_cache_runtime_service_test.dart`
- `flutter test test/unit/modules/playback_runtime/playback_cache_runtime_service_test.dart`
- `bash scripts/check_architecture_guards.sh --against HEAD --files lib/Modules/PlaybackRuntime/playback_cache_runtime_service.dart,lib/Modules/Agenda/Common/post_content_base.dart,lib/Modules/Agenda/Common/post_content_base_lifecycle_part.dart,lib/Modules/Agenda/Common/post_content_base_playback_part.dart,lib/Modules/Short/short_view.dart,lib/Modules/Short/short_view_playback_part.dart,lib/Modules/Short/single_short_view.dart,lib/Modules/Short/single_short_view_helpers_part.dart,lib/Modules/Short/single_short_view_playback_part.dart,lib/Modules/Short/single_short_view_ui_part.dart,lib/Modules/Short/single_short_view_controller_bootstrap_part.dart,lib/Modules/Short/single_short_view_controller_sync_part.dart,lib/Modules/Story/StoryViewer/story_viewer.dart,test/unit/modules/playback_runtime/playback_cache_runtime_service_test.dart,docs/architecture/T-029_PLAYBACK_CACHE_RUNTIME_BOUNDARY_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`
