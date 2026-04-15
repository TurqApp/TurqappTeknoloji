import 'dart:async';

import 'package:flutter/foundation.dart';
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

  Future<T> _profileStartupPhase<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final startedAt = DateTime.now();
    debugPrint('[StartupBootstrap] start:$label');
    try {
      final result = await action();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[StartupBootstrap] end:$label elapsedMs=$elapsedMs');
      return result;
    } catch (error) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
        '[StartupBootstrap] fail:$label elapsedMs=$elapsedMs error=$error',
      );
      rethrow;
    }
  }

  Future<void> initializeApp() async {
    var shouldScheduleBackgroundInit = false;
    var scheduledBackgroundInitFirstLaunch = false;
    try {
      final prefs = await _profileStartupPhase(
        'startup_bootstrap',
        () => _startupBootstrap.run(),
      );
      final sessionResult = await _profileStartupPhase(
        'session_bootstrap',
        () => _bootstrapSession(prefs: prefs),
      );

      await _profileStartupPhase(
        'hydrate_startup_manifest',
        () => hydrateStartupManifestContext(
          loggedIn: sessionResult.loggedIn,
        ),
      );
      await _profileStartupPhase('dependency_registration', () async {
        _dependencyRegistrar.registerStartupDependencies();
      });
      await _profileStartupPhase(
        'prepare_startup_before_navigation',
        () => _prepareStartupBeforeNavigation(sessionResult),
      );
      _postLoginWarmup.startNonBlockingStartupWork(
        isFirstLaunch: sessionResult.isFirstLaunch,
        effectiveUserId: CurrentUserService.instance.effectiveUserId,
      );
      shouldScheduleBackgroundInit = true;
      scheduledBackgroundInitFirstLaunch = sessionResult.isFirstLaunch;
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
    unawaited(_startupBootstrap.initializeDeferredAudioContext());
    unawaited(Future<void>(() {
      _dependencyRegistrar.registerDeferredDependencies();
    }));
    if (shouldScheduleBackgroundInit) {
      _postLoginWarmup.scheduleBackgroundInit(
        isFirstLaunch: scheduledBackgroundInitFirstLaunch,
      );
    }
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
