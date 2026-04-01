# T-011 Startup Rollerini Ayirma

## Amac

`T-010` ile widget disina alinan startup orkestrasyonunu daha net alt rollere ayirmak.

Bu is sonunda startup akisinda su roller isimli siniflar halinde ayrildi:

- `StartupBootstrap`
- `SessionBootstrap`
- `PostLoginWarmup`
- `DependencyRegistrar`

## Yapilan Degisiklik

- `lib/Modules/Splash/splash_startup_bootstrap.dart`
  - Firebase bootstrap bekleme
  - Firestore config init
  - SharedPreferences yukleme
  - audio context init
- `lib/Modules/Splash/splash_session_bootstrap.dart`
  - account center init
  - first-launch auth cleanup
  - current user initialize
  - loginli durumda startup-before-nav hazirligi
- `lib/Modules/Splash/splash_post_login_warmup.dart`
  - non-blocking startup side effectleri
  - background warmup scheduling
  - cache proxy ve media quota kurulumu
- `lib/Modules/Splash/splash_dependency_registrar.dart`
  - GetX/service registration sorumlulugu
- `lib/Modules/Splash/splash_startup_orchestrator.dart`
  - artik bu rolleri sirayla birlestiren koordinatordur

## Birim Testi

`test/unit/modules/splash/splash_bootstrap_roles_test.dart`

Kapsanan noktalar:

- `StartupBootstrap` cekirdek startup onkosullarini kosuyor mu
- `SessionBootstrap` deterministic loginli akista minimum startup hazirligini dogru isaretliyor mu
- `PostLoginWarmup` signed-in olmayan durumda zorunlu takip gibi loginli yan etkileri calistirmiyor mu

## Teknik Dogrulama

- `dart analyze --no-fatal-warnings lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_startup_orchestrator.dart lib/Modules/Splash/splash_startup_bootstrap.dart lib/Modules/Splash/splash_session_bootstrap.dart lib/Modules/Splash/splash_post_login_warmup.dart lib/Modules/Splash/splash_dependency_registrar.dart test/unit/modules/splash/splash_bootstrap_roles_test.dart`
- `flutter test test/unit/modules/splash/splash_bootstrap_roles_test.dart`
- `git diff --check -- lib/Modules/Splash/... test/unit/modules/splash/splash_bootstrap_roles_test.dart`

## Beklenen Kazanim

- Startup akisinda hangi kodun hangi rolde oldugu daha net
- `T-012` ve `T-014` icin daha kontrollu refactor zemini
- Splash startup akisinin okunabilirligi ve testlenebilirligi daha yuksek
