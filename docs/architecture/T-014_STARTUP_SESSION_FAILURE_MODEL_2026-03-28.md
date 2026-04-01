# T-014 Startup Session Failure Modeli

Tarih: 2026-03-28

## Amac

Startup ve session eksenindeki genis `catch (_) {}` bloklarini ayni sessiz davranisla birakmadan, siniflandirilmis bir failure modeli uzerinden gorunur hale getirmek.

## Eklenen failure modeli

- Yeni tip: `lib/Runtime/startup_session_failure.dart`
- Ana tipler:
  - `StartupSessionFailureKind`
  - `StartupSessionFailure`
  - `StartupSessionFailureReporter`

## Failure siniflandirmasi uygulanan alanlar

- Splash:
  - `SplashStartupOrchestrator.initializeApp`
  - `SplashView.readEffectiveUserId`
  - `SplashView.ensureAuthenticatedPrimaryRouteReady`
  - `PostLoginWarmup.runBackgroundInit`
  - `PostLoginWarmup.initCacheProxy`
  - `PostLoginWarmup.applyGlobalMediaCacheQuota`
  - `PostLoginWarmup.hasSignedInUser`
  - `PostLoginWarmup.isOnWiFiNow`
- Session:
  - `SessionBootstrap.handleFirstLaunchCleanup`
  - `SessionBootstrap.ensureAuthReady`
  - `CurrentUserAuthRole.resolveAuthUser`
  - `CurrentUserAuthRole.ensureAuthReady.forceTokenRefresh`
  - `CurrentUserAuthRole.refreshAuthTokenIfNeeded`
  - `CurrentUserSyncRole.initialize`
  - `CurrentUserSyncRole.forceRefresh`
  - `CurrentUserSyncRole.startFirebaseSync`
  - `CurrentUserSyncRole.startFirebaseSync.listen`
  - `CurrentUserSyncRole.validateExclusiveSessionFromServer`
  - `CurrentUserAccountCenterRole.*`
  - `AccountSessionVault.read`
  - `AccountSessionVault.removeStoredPasswords`

## Korunan davranis

- Kullanici akisi sert sekilde degistirilmedi.
- Hata durumunda onceki fallback davranislari korunmaya devam ediyor.
- Fark: artik hata sessizce yutulmuyor; siniflandirilmis kod ile loglanabiliyor ve testte yakalanabiliyor.

## Teknik dogrulama

- `dart analyze --no-fatal-warnings lib/Runtime/startup_session_failure.dart lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_startup_orchestrator.dart lib/Modules/Splash/splash_post_login_warmup.dart lib/Modules/Splash/splash_session_bootstrap.dart lib/Services/current_user_service.dart lib/Services/current_user_service_auth_role_part.dart lib/Services/current_user_service_sync_role_part.dart lib/Services/current_user_service_account_center_role_part.dart lib/Services/account_session_vault.dart test/unit/modules/splash/splash_bootstrap_roles_test.dart test/unit/services/current_user_service_role_split_test.dart`
- `flutter test test/unit/modules/splash/splash_bootstrap_roles_test.dart test/unit/services/current_user_service_role_split_test.dart`
