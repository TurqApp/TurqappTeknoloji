# F2-011 Startup / Auth / Session Secici Sadelestirme Butcesi

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Amac

Startup/Auth/Session sicak kumesinde davranis degistirmeden dosya yuzeyini ve
mikro `class/facade/fields` part dagilimini azaltmak.

## Secilen Kume

Bu tur bilincli olarak yalniz su uc giris noktasiyla sinirli tutuldu:

- `lib/Services/current_user_service*`
- `lib/Services/account_center_service*`
- `lib/Modules/SignIn/sign_in_controller*`

Risk nedeni ile su alanlar dokunulmadi:

- `Splash warm/startup` agir davranis dosyalari
- `SignIn signup` akis dosyalari
- `CurrentUserService` role ve behavior part'lari

## Harcanan Sadelestirme Butcesi

- secilen kume dosya sayisi:
  - once: `33`
  - sonra: `21`
- kaldirilan mikro part sayisi: `12`

Kaldirilan dosyalar:

- `lib/Services/current_user_service_base_part.dart`
- `lib/Services/current_user_service_class_part.dart`
- `lib/Services/current_user_service_facade_part.dart`
- `lib/Services/current_user_service_fields_part.dart`
- `lib/Services/current_user_service_instance_part.dart`
- `lib/Services/current_user_service_story_part.dart`
- `lib/Services/account_center_service_class_part.dart`
- `lib/Services/account_center_service_facade_part.dart`
- `lib/Services/account_center_service_fields_part.dart`
- `lib/Services/account_center_service_keys_part.dart`
- `lib/Modules/SignIn/sign_in_controller_base_part.dart`
- `lib/Modules/SignIn/sign_in_controller_fields_part.dart`

## Uygulanan Sadelestirme

- `CurrentUserService`
  - base/class/instance/state/facade tanimlari ana library dosyasina alindi
  - role, lifecycle, auth, cache ve sync davranis part'lari korunarak davranis
    katmani yerinde birakildi
- `AccountCenterService`
  - class/facade/state/keys tanimlari ana library dosyasina alindi
  - accounts/storage davranis part'lari korunarak veri akis riski acilmadi
- `SignInController`
  - base mixin ve state/field tanimlari ana controller dosyasina alindi
  - auth/account/signup/lifecycle davranis part'lari korunarak ekran davranisi
    yerinde birakildi

## Dogrulama

- `dart analyze --no-fatal-warnings`
  - `lib/Services/current_user_service.dart`
  - `lib/Services/account_center_service.dart`
  - `lib/Modules/SignIn/sign_in_controller.dart`
  - `test/unit/services/current_user_service_role_split_test.dart`
  - `test/unit/modules/sign_in/sign_in_application_service_test.dart`
  - `test/widget/screens/sign_in_test.dart`
- `flutter test`
  - `test/unit/services/current_user_service_role_split_test.dart`
  - `test/unit/modules/sign_in/sign_in_application_service_test.dart`
  - `test/widget/screens/sign_in_test.dart`

Sonuc: `14/14 yesil`

## Sonuc

- Startup/Auth/Session sicak kumesinde ayni davranis icin daha az dosya acilir
  hale gelindi
- `CurrentUserService`, `AccountCenterService` ve `SignInController` icin
  "giris dosyasi + davranis part'lari" ayrimi daha okunur oldu
- `DEBT-001` ve `DEBT-002` repo genelinde kapanmadi ama hedef sicak kume icin
  olculebilir bicimde daraltildi
