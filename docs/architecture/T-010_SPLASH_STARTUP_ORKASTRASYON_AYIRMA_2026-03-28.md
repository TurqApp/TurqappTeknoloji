# T-010 Splash Startup Orkastrasyonunu Ayirma

## Amac

Splash ekraninin icinde toplanan startup ve background orkastrasyonunu widget disina tasiyip,
ekranin sorumlulugunu daha dar hale getirmek.

## Yapilan Degisiklik

- `lib/Modules/Splash/splash_startup_orchestrator.dart` eklendi.
- Startup init, first-launch auth cleanup, dependency registration, background warmup scheduling
  ve global media cache proxy kurulumu `SplashStartupOrchestrator` icine tasindi.
- `lib/Modules/Splash/splash_view_startup_part.dart` yalnizca:
  - orchestrator wiring
  - route secimi / navigation
  gorevini tasir hale getirildi.
- `lib/Modules/Splash/splash_view.dart` icindeki startup wrapper yuzeyi sadeletildi.

## Kapsam Disi Birakilanlar

- `splash_view_warm_part.dart` icindeki warmup ayrisma isi
- `T-011` altindaki `StartupBootstrap / SessionBootstrap / PostLoginWarmup / DependencyRegistrar`
  daha detayli parcasi

## Teknik Dogrulama

- `dart analyze --no-fatal-warnings lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_startup_orchestrator.dart`
- `flutter test test/unit/utils/integration_key_contract_test.dart`
- `git diff --check -- lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_startup_orchestrator.dart`

## Beklenen Kazanim

- Splash widget artik startup/background orchestration merkezi degil.
- Sonraki is olan `T-011` icin daha net bir bootstrap parcasi olustu.
