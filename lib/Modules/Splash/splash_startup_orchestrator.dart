import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'package:turqappv2/Modules/Splash/splash_dependency_registrar.dart';
import 'package:turqappv2/Modules/Splash/splash_post_login_warmup.dart';
import 'package:turqappv2/Modules/Splash/splash_session_bootstrap.dart';
import 'package:turqappv2/Modules/Splash/splash_startup_bootstrap.dart';

typedef SplashStartupRunner = Future<void> Function({
  required bool isFirstLaunch,
});

typedef SplashNavigationRunner = Future<void> Function();
typedef StartupManifestHydrator = Future<void> Function({
  required bool loggedIn,
});

class SplashStartupOrchestrator {
  SplashStartupOrchestrator({
    required this.firebaseStartupWait,
    required this.isMounted,
    required this.navigateToPrimaryRoute,
    required this.prepareSynchronizedStartupBeforeNav,
    required this.runCriticalWarmStartLoads,
    required this.runWarmStartLoads,
    required this.markMinimumStartupPrepared,
    required this.isMinimumStartupPrepared,
    required this.hydrateStartupManifestContext,
    StartupBootstrap? startupBootstrap,
    SessionBootstrap? sessionBootstrap,
    DependencyRegistrar? dependencyRegistrar,
    PostLoginWarmup? postLoginWarmup,
    StartupSessionFailureReporter? failureReporter,
  })  : _startupBootstrap = startupBootstrap ??
            StartupBootstrap(firebaseStartupWait: firebaseStartupWait),
        _sessionBootstrap = sessionBootstrap ?? SessionBootstrap(),
        _dependencyRegistrar = dependencyRegistrar ?? DependencyRegistrar(),
        _postLoginWarmup = postLoginWarmup ??
            PostLoginWarmup(
              runCriticalWarmStartLoads: runCriticalWarmStartLoads,
              runWarmStartLoads: runWarmStartLoads,
              isMinimumStartupPrepared: isMinimumStartupPrepared,
            ),
        _failureReporter =
            failureReporter ?? StartupSessionFailureReporter.defaultReporter;

  final Duration firebaseStartupWait;
  final bool Function() isMounted;
  final SplashNavigationRunner navigateToPrimaryRoute;
  final SplashStartupRunner prepareSynchronizedStartupBeforeNav;
  final SplashStartupRunner runCriticalWarmStartLoads;
  final SplashStartupRunner runWarmStartLoads;
  final void Function(bool value) markMinimumStartupPrepared;
  final bool Function() isMinimumStartupPrepared;
  final StartupManifestHydrator hydrateStartupManifestContext;
  final StartupBootstrap _startupBootstrap;
  final SessionBootstrap _sessionBootstrap;
  final DependencyRegistrar _dependencyRegistrar;
  final PostLoginWarmup _postLoginWarmup;
  final StartupSessionFailureReporter _failureReporter;

  Future<void> initializeApp() async {
    try {
      final prefs = await _startupBootstrap.run();
      final sessionResult = await _bootstrapSession(prefs: prefs);

      await hydrateStartupManifestContext(
        loggedIn: sessionResult.loggedIn,
      );
      _dependencyRegistrar.register();
      await _prepareStartupBeforeNavigation(sessionResult);
      _postLoginWarmup.startNonBlockingStartupWork(
        isFirstLaunch: sessionResult.isFirstLaunch,
        effectiveUserId: CurrentUserService.instance.effectiveUserId,
      );
      _postLoginWarmup.scheduleBackgroundInit(
        isFirstLaunch: sessionResult.isFirstLaunch,
      );
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.startupOrchestration,
        operation: 'SplashStartupOrchestrator.initializeApp',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!isMounted()) return;
    await navigateToPrimaryRoute();
  }

  Future<void> runBackgroundInit({required bool isFirstLaunch}) {
    return _postLoginWarmup.runBackgroundInit(isFirstLaunch: isFirstLaunch);
  }

  Future<void> initCacheProxy() => _postLoginWarmup.initCacheProxy();

  Future<SessionBootstrapResult> _bootstrapSession({
    required SharedPreferences prefs,
  }) {
    return _sessionBootstrap.run(prefs: prefs);
  }

  Future<void> _prepareStartupBeforeNavigation(
    SessionBootstrapResult sessionResult,
  ) async {
    if (!sessionResult.loggedIn) return;
    if (IntegrationTestMode.deterministicStartup) {
      markMinimumStartupPrepared(true);
      return;
    }
    await prepareSynchronizedStartupBeforeNav(
      isFirstLaunch: sessionResult.isFirstLaunch,
    );
  }
}
