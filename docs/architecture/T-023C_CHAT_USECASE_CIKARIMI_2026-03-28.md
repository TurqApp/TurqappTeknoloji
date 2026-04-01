# T-023C Chat UseCase Cikarimi

## Hedef

`ChatController` icindeki ilk send/read policy orkestrasyonunu tek bir
application service katmanina tasimaya baslamak.

## Tasinan orchestration

- counterpart uid cozumu
- conversation envelope hazirlama karari
- send plani: payload, preview text, notification body, reply policy
- read receipt / delivered policy plani
- conversation opened timestamp persistence policy

## Controller'da kalanlar

- moderation guard ve kufur kontrolu
- mesaj edit akisi
- optimistic UI merge ve local cache guncellemesi
- notification dispatch, snackbar ve diger UI yan etkileri
- realtime stream yasam dongusu

## Eklenen katman

- `lib/Modules/Chat/chat_conversation_application_service.dart`

Bu katman asagidaki davranislari tasir:

- `prepareSendPlan`
- `ensureConversationReady`
- `buildReadPolicyPlan`
- `buildOpenedStorageKey`
- `shouldPersistOpenedAt`

## Dogrulama

- `dart analyze --no-fatal-warnings lib/Modules/Chat/chat_conversation_application_service.dart lib/Modules/Chat/chat_controller.dart lib/Modules/Chat/chat_controller_base_part.dart lib/Modules/Chat/chat_controller_shell_part.dart lib/Modules/Chat/chat_controller_fields_part.dart lib/Modules/Chat/chat_controller_send_part.dart lib/Modules/Chat/chat_controller_actions_part.dart lib/Modules/Chat/chat_controller_conversation.dart test/unit/modules/chat_conversation_application_service_test.dart`
- `flutter test test/unit/modules/chat_conversation_application_service_test.dart`
- `ARCHITECTURE_ARTIFACT_DIR=/tmp/t023c_architecture_artifacts bash scripts/check_architecture_guards.sh --against HEAD --files lib/Modules/Chat/chat_conversation_application_service.dart,lib/Modules/Chat/chat_controller.dart,lib/Modules/Chat/chat_controller_base_part.dart,lib/Modules/Chat/chat_controller_shell_part.dart,lib/Modules/Chat/chat_controller_fields_part.dart,lib/Modules/Chat/chat_controller_send_part.dart,lib/Modules/Chat/chat_controller_actions_part.dart,lib/Modules/Chat/chat_controller_conversation.dart,test/unit/modules/chat_conversation_application_service_test.dart,docs/architecture/T-023C_CHAT_USECASE_CIKARIMI_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`

## Sonuc

Chat icin ilk bounded-context usecase/application service cikarmi basladi.
Send ve read policy zinciri controller'dan ayrilarak daha testlenebilir hale
geldi ve sonraki chat/refactor dalgasi icin tasinabilir bir kalip olustu.
