# T-018 Short ve Story Application Service Ayrimi

## Hedef

`ShortController` ve `StoryRowController` icindeki kritik orchestration
adimlarini application service katmanina tasimak ve controller'lari daha cok
UI state / side-effect sahibi hale getirmek.

## Short tarafinda tasinan orchestration

- initial load karari
  - snapshot kullanimi
  - pagination reset ihtiyaci
  - background refresh bootstrap karari
- refresh sonrasi secili index remap karari
- append page sonrasi dedupe + ilk sayfa shuffle karari

Eklenen katman:

- `lib/Modules/Short/short_feed_application_service.dart`

## Story tarafinda tasinan orchestration

- cache-first bootstrap sonrasi silent refresh karari
- expire cleanup calisma karari
- story row kullanici siralama plani
  - current user first
  - unseen stories before seen stories

Eklenen katman:

- `lib/Modules/Story/StoryRow/story_row_application_service.dart`

## Controller'larda kalanlar

- repository/network cagrilari
- timer ve background schedule wiring'i
- cache warmup ve UI yan etkileri
- loading state / debug log / analytics

## Dogrulama

- `dart analyze --no-fatal-warnings lib/Modules/Short/short_feed_application_service.dart lib/Modules/Short/short_controller.dart lib/Modules/Short/short_controller_fields_part.dart lib/Modules/Short/short_controller_loading_part.dart lib/Modules/Story/StoryRow/story_row_application_service.dart lib/Modules/Story/StoryRow/story_row_controller.dart lib/Modules/Story/StoryRow/story_row_controller_fields_part.dart lib/Modules/Story/StoryRow/story_row_controller_load_part.dart test/unit/modules/short/short_feed_application_service_test.dart test/unit/modules/story/story_row_application_service_test.dart`
- `flutter test test/unit/modules/short/short_feed_application_service_test.dart test/unit/modules/story/story_row_application_service_test.dart`
- `ARCHITECTURE_ARTIFACT_DIR=/tmp/turqapp_t018_architecture_artifacts bash scripts/check_architecture_guards.sh --against HEAD --files lib/Modules/Short/short_feed_application_service.dart,lib/Modules/Short/short_controller.dart,lib/Modules/Short/short_controller_fields_part.dart,lib/Modules/Short/short_controller_loading_part.dart,lib/Modules/Story/StoryRow/story_row_application_service.dart,lib/Modules/Story/StoryRow/story_row_controller.dart,lib/Modules/Story/StoryRow/story_row_controller_fields_part.dart,lib/Modules/Story/StoryRow/story_row_controller_load_part.dart,test/unit/modules/short/short_feed_application_service_test.dart,test/unit/modules/story/story_row_application_service_test.dart,docs/architecture/T-018_SHORT_STORY_APPLICATION_SERVICES_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`

## Sonuc

Short ve story tarafinda ilk tasinabilir orchestration pattern'i olustu:

- `Controller -> Application Service -> Repository`

Bu zemin, `T-029` runtime/playback boundary isi ve `T-022` davranis testi
genisletmesi icin daha temiz bir temel saglar.
