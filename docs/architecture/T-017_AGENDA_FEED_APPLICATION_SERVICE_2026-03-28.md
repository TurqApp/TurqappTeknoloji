# T-017 Agenda Feed Application Service

## Hedef

`AgendaController` icindeki feed orchestration adimlarini tek bir
application service katmanina tasimak ve controller'i daha cok UI state /
side-effect sahibi hale getirmek.

## Tasinan orchestration

- fetched page icin yeni post / highlight / hasMore karari
- refresh baslangicinda playback anchor yakalama
- initial centered index secimi
- resume centered index secimi

## Controller'da kalanlar

- video/playback komut dispatch'i
- timer ve widget frame callback'leri
- QA event kayitlari
- `markHighlighted`, `_addUniqueToAgenda`, `_scheduleReshareFetchForPosts`
- snackbar ve diger UI yan etkileri

## Eklenen katman

- `lib/Modules/Agenda/agenda_feed_application_service.dart`

Bu katman asagidaki davranislari tasir:

- `buildPageApplyPlan`
- `capturePlaybackAnchor`
- `resolveInitialCenteredIndex`
- `resolveResumeIndex`

## Dogrulama

- `dart analyze --no-fatal-warnings lib/Modules/Agenda/agenda_feed_application_service.dart lib/Modules/Agenda/agenda_controller.dart lib/Modules/Agenda/agenda_controller_fields_part.dart lib/Modules/Agenda/agenda_controller_feed_part.dart lib/Modules/Agenda/agenda_controller_loading_part.dart test/unit/modules/agenda/agenda_feed_application_service_test.dart`
- `flutter test test/unit/modules/agenda/agenda_feed_application_service_test.dart`
- `ARCHITECTURE_ARTIFACT_DIR=/tmp/turqapp_t017_architecture_artifacts bash scripts/check_architecture_guards.sh --against HEAD --files lib/Modules/Agenda/agenda_feed_application_service.dart,lib/Modules/Agenda/agenda_controller.dart,lib/Modules/Agenda/agenda_controller_fields_part.dart,lib/Modules/Agenda/agenda_controller_feed_part.dart,lib/Modules/Agenda/agenda_controller_loading_part.dart,test/unit/modules/agenda/agenda_feed_application_service_test.dart,docs/architecture/T-017_AGENDA_FEED_APPLICATION_SERVICE_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`

## Sonuc

`Agenda` icin ilk feed-specific application service katmani olustu.
Bu degisiklikle controller icindeki feed yukleme ve centered playback secim
kararlari daha testlenebilir hale geldi ve `T-018` icin daha temiz bir zemin
hazirlandi.
