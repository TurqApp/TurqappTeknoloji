# T-030 Part-Sprawl Envanteri

## Envanter Ozeti

- Baslangic sayimi: `523` adet `*_facade_part.dart`, `*_fields_part.dart`,
  `*_class_part.dart`
- Baslangic cluster sayisi: `258`
- Bu tur sonrasi sayim: `518` part-sprawl dosyasi
- Bu tur sonrasi cluster sayisi: `258`
- Bu turdaki azalis: `5` dosya

## Sicak Alan Gozlemi

En yuksek yogunluk halen `3` part dosyali cluster'larda:

- `AgendaController`
- `ChatListingController`
- `FeedSnapshotRepository`
- `JobRepository`
- `NetworkAwarenessService`
- `UploadQueueService`
- `UnreadMessagesController`

Bu tablo, sorunun repo geneline yayilmis oldugunu gosteriyor; bu iste toplu
temizlik yapilmadi.

## Secili Sadelestirme

Bu turda son refactorlarda aktif kullandigimiz, fakat kucuk `class/facade`
part dosyalari tasiyan sicak controller kumeleri secildi:

- `SignInController`
  - `sign_in_controller_class_part.dart` kaldirildi
  - `sign_in_controller_facade_part.dart` kaldirildi
  - class ve `ensure/maybeFind` facade ana library dosyasina tasindi
- `AdsCenterController`
  - `ads_center_controller_class_part.dart` kaldirildi
  - `ads_center_controller_facade_part.dart` kaldirildi
  - class ve `ensure/maybeFind` facade ana library dosyasina tasindi
- `StoryRowController`
  - `story_row_controller_class_part.dart` kaldirildi
  - controller class ana library dosyasina tasindi

## Neden Bu Kume

- Son resmi islerde aktif dokunulan sicak alanlar
- Davranis riski dusuk
- Okuma yolu gereksiz iki-uc dosyaya dagiliyordu
- `fields` gibi daha buyuk state parcalari bu turda bilincli olarak
  yerinde birakildi

## Kabul Sonucu

- Secili sicak kumelerde `class/facade` mikro parcaciklari azaldi
- Ana library dosyasi daha kendi kendini tarif eder hale geldi
- Toplu repo temizlik yerine secili ve guvenli sadeleştirme yapildi

## Dogrulama

- `dart analyze --no-fatal-warnings ...`
- `flutter test test/unit/modules/sign_in/sign_in_application_service_test.dart test/unit/modules/profile/ads_center_application_service_test.dart test/unit/modules/story/story_row_application_service_test.dart`
- `bash scripts/check_architecture_guards.sh --against HEAD --files ...`
- `git diff --check`
