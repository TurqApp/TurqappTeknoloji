# T-023B Ads Center UseCase Pilot

## Hedef

`AdsCenterController` icindeki dashboard, campaign save/status ve delivery
preview orchestration adimlarini tek bir application service katmanina tasimak.

## Tasinan orchestration

- dashboard metriklerini repository + managed config yuzeyinden birlestirme
- campaign save sonrasi dashboard yenileme
- campaign status guncelleme sonrasi dashboard yenileme
- preview context kurma + admin delivery simulate zinciri
- preview impression analytics dispatch'i

## Controller'da kalanlar

- creative save / review akislarinin dogrudan repository kullanimi
- feature flag kaydetme
- loading, snackbar ve `errorText` gibi UI state guncellemeleri
- stream binding ve watcher yasam dongusu

## Eklenen katman

- `lib/Modules/Profile/Settings/AdsCenter/ads_center_application_service.dart`

Bu katman asagidaki davranislari tasir:

- `loadDashboard`
- `saveCampaign`
- `updateCampaignStatus`
- `runPreview`
- `trackPreviewImpression`

## Dogrulama

- `dart analyze --no-fatal-warnings lib/Modules/Profile/Settings/AdsCenter/ads_center_application_service.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_library.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_base_part.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_class_part.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_fields_part.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_actions_part.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_stream_part.dart test/unit/modules/profile/ads_center_application_service_test.dart`
- `flutter test test/unit/modules/profile/ads_center_application_service_test.dart`
- `ARCHITECTURE_ARTIFACT_DIR=/tmp/t023b_architecture_artifacts bash scripts/check_architecture_guards.sh --against HEAD --files lib/Modules/Profile/Settings/AdsCenter/ads_center_application_service.dart,lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_library.dart,lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_base_part.dart,lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_class_part.dart,lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_fields_part.dart,lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_actions_part.dart,lib/Modules/Profile/Settings/AdsCenter/ads_center_controller_stream_part.dart,test/unit/modules/profile/ads_center_application_service_test.dart,docs/architecture/T-023B_ADS_CENTER_USECASE_PILOT_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`

## Sonuc

Ads Center icin ikinci kucuk usecase/application service pilotu olustu.
Bu degisiklikle dashboard ve preview policy kararlari controller'dan ayrildi ve
`T-023C` ile sonraki bounded-context refactorlari icin tasinabilir bir kalip
uretildi.
