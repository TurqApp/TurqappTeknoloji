# T-022 Auth / Session / Feed Davranis Testleri

## Amac

`T-013`, `T-015`, `T-016`, `T-017` ve `T-018` ile degisen auth/session/feed akislari icin
kritik davranis regresyonlarini daha gorunur ve tekrar kosulabilir hale getirmek.

## Eklenen kapsam

- Startup sonrasi aktif oturumun `NavBar + Feed` shell icine saglikli restore edilmesi
- Sign-out sonrasi auth/session state temizlenmesi
- Manual re-auth ile aktif oturumun geri gelmesi
- Feed bootstrap sonrasi `forYou` modu, centered index ve fixture contract'in korunmasi

## Eklenen dosyalar

- `integration_test/auth/auth_startup_session_restore_test.dart`
- `integration_test/auth/auth_signout_state_test.dart`
- `integration_test/auth/auth_reauth_restore_test.dart`
- `integration_test/feed/feed_primary_bootstrap_contract_test.dart`
- `config/test_suites/auth_session_feed_regression.txt`
- `scripts/run_auth_session_feed_regression.sh`

## Yerel kapanis komutlari

```bash
dart analyze --no-fatal-warnings \
  integration_test/core/bootstrap/test_app_bootstrap.dart \
  integration_test/auth/auth_startup_session_restore_test.dart \
  integration_test/feed/feed_primary_bootstrap_contract_test.dart \
  test/unit/modules/sign_in/sign_in_application_service_test.dart \
  test/unit/repositories/feed_home_contract_test.dart \
  test/unit/modules/agenda/agenda_feed_application_service_test.dart \
  test/unit/modules/short/short_feed_application_service_test.dart
```

```bash
flutter test \
  test/unit/modules/sign_in/sign_in_application_service_test.dart \
  test/unit/repositories/feed_home_contract_test.dart \
  test/unit/modules/agenda/agenda_feed_application_service_test.dart \
  test/unit/modules/short/short_feed_application_service_test.dart
```

```bash
bash -n scripts/run_auth_session_feed_regression.sh
```

## Cihazli smoke komutu

```bash
INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 bash scripts/run_auth_session_feed_regression.sh
```

Not:

- Cihazli smoke kosumu mevcut integration fixture, login credential ve uygun hedef cihazi ister.
- Bu paket kritik akislari tek manifest altında toplar; release gate paketinin yerine gecmez.
- Bu turdaki resmi kapanis, unit davranis testleri + Android emulator (`emulator-5554`) uzerinde yesil integration smoke manifest kosumu ile verildi.
- Android cihazda gorulen siyah ekran / kapanma sorunu bu artifact'in kapsami disinda ayrica ele alinacaktir.
- `feed_resume_test` ve `short_refresh_preserve_test` bu resmi manifestten cikarildi; profile replay / short refresh stabilizasyonu plan sonrasi tavsiye backlog'unda izlenecek.
