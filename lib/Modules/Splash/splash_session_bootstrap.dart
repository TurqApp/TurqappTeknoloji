import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

typedef FirstLaunchCleanupRunner = Future<bool> Function(
  SharedPreferences prefs,
);

typedef SessionAuthReadyRunner = Future<String?> Function({
  required Duration timeout,
});

class SessionBootstrapResult {
  const SessionBootstrapResult({
    required this.isFirstLaunch,
    required this.loggedIn,
  });

  final bool isFirstLaunch;
  final bool loggedIn;
}

class SessionBootstrap {
  SessionBootstrap({
    Future<void> Function()? initializeAccountCenter,
    Future<void> Function()? initializeCurrentUser,
    FirstLaunchCleanupRunner? handleFirstLaunchCleanup,
    String Function()? readEffectiveUserId,
    SessionAuthReadyRunner? ensureAuthReady,
    Future<void> Function()? syncCurrentAccountToAccountCenter,
    bool Function()? isIOS,
    StartupSessionFailureReporter? failureReporter,
  })  : _initializeAccountCenter =
            initializeAccountCenter ?? _defaultInitializeAccountCenter,
        _initializeCurrentUser =
            initializeCurrentUser ?? _defaultInitializeCurrentUser,
        _handleFirstLaunchCleanup =
            handleFirstLaunchCleanup ?? _defaultHandleFirstLaunchCleanup,
        _readEffectiveUserId =
            readEffectiveUserId ?? _defaultReadEffectiveUserId,
        _ensureAuthReady = ensureAuthReady ?? _defaultEnsureAuthReady,
        _syncCurrentAccountToAccountCenter =
            syncCurrentAccountToAccountCenter ??
                _defaultSyncCurrentAccountToAccountCenter,
        _isIOS = isIOS ?? (() => Platform.isIOS),
        _failureReporter =
            failureReporter ?? StartupSessionFailureReporter.defaultReporter;

  final Future<void> Function() _initializeAccountCenter;
  final Future<void> Function() _initializeCurrentUser;
  final FirstLaunchCleanupRunner _handleFirstLaunchCleanup;
  final String Function() _readEffectiveUserId;
  final SessionAuthReadyRunner _ensureAuthReady;
  final Future<void> Function() _syncCurrentAccountToAccountCenter;
  final bool Function() _isIOS;
  final StartupSessionFailureReporter _failureReporter;

  Future<SessionBootstrapResult> run({
    required SharedPreferences prefs,
  }) async {
    await _initializeAccountCenter();

    late final bool isFirstLaunch;
    if (_isIOS()) {
      isFirstLaunch = await _runFirstLaunchCleanupSafely(prefs)
          .timeout(const Duration(milliseconds: 350), onTimeout: () => false);
      unawaited(_initializeCurrentUser());
    } else {
      await Future.wait([
        _runFirstLaunchCleanupSafely(prefs)
            .then((value) => isFirstLaunch = value),
        _initializeCurrentUser(),
      ]);
    }

    var loggedIn = _readEffectiveUserId().isNotEmpty;
    if (!loggedIn) {
      final restoredUid = await _attemptAuthRestoreUid();
      if (restoredUid.isNotEmpty) {
        await _initializeCurrentUser();
        loggedIn = _readEffectiveUserId().isNotEmpty || restoredUid.isNotEmpty;
      }
    }
    if (loggedIn) {
      unawaited(_syncCurrentAccountToAccountCenter());
    }

    return SessionBootstrapResult(
      isFirstLaunch: isFirstLaunch,
      loggedIn: loggedIn,
    );
  }

  Duration get _authRestoreWait => IntegrationTestMode.enabled
      ? const Duration(seconds: 3)
      : _isIOS()
          ? const Duration(milliseconds: 450)
          : const Duration(milliseconds: 900);

  Future<bool> _runFirstLaunchCleanupSafely(SharedPreferences prefs) async {
    try {
      return await _handleFirstLaunchCleanup(prefs);
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.firstLaunchCleanup,
        operation: 'SessionBootstrap.handleFirstLaunchCleanup',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await FirebaseAuth.instance.signOut();
        await CurrentUserService.instance.logout();
        await ensureAccountCenterService().signOutAllLocal();
      } catch (recoveryError, recoveryStackTrace) {
        _failureReporter.record(
          kind: StartupSessionFailureKind.firstLaunchCleanup,
          operation: 'SessionBootstrap.recoverFromCleanupFailure',
          error: recoveryError,
          stackTrace: recoveryStackTrace,
        );
      }
      return true;
    }
  }

  Future<String> _attemptAuthRestoreUid() async {
    try {
      return (await _ensureAuthReady(timeout: _authRestoreWait))?.trim() ?? '';
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.authStateRestore,
        operation: 'SessionBootstrap.ensureAuthReady',
        error: error,
        stackTrace: stackTrace,
      );
      return '';
    }
  }

  static Future<void> _defaultInitializeAccountCenter() async {
    await ensureAccountCenterService().init();
  }

  static Future<void> _defaultInitializeCurrentUser() async {
    await ensureCurrentUserService().initialize();
  }

  static Future<bool> _defaultHandleFirstLaunchCleanup(
    SharedPreferences prefs,
  ) async {
    const firstLaunchKey = 'app_has_launched_before';
    final hasLaunchedBefore = prefs.getBool(firstLaunchKey) ?? false;
    final isFirstLaunch = !hasLaunchedBefore;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (!hasLaunchedBefore && firebaseUser != null) {
      await FirebaseAuth.instance.signOut();
      await CurrentUserService.instance.logout();
      await ensureAccountCenterService().signOutAllLocal();
    }

    if (!hasLaunchedBefore) {
      await prefs.setBool(firstLaunchKey, true);
    }
    return isFirstLaunch;
  }

  static String _defaultReadEffectiveUserId() {
    return CurrentUserService.instance.effectiveUserId;
  }

  static Future<String?> _defaultEnsureAuthReady({
    required Duration timeout,
  }) {
    return CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      timeout: timeout,
    );
  }

  static Future<void> _defaultSyncCurrentAccountToAccountCenter() async {
    final userService = CurrentUserService.instance;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final currentUser = userService.currentUser;
    if (firebaseUser == null || currentUser == null) return;

    await ensureAccountCenterService().addCurrentAccount(
      currentUser: currentUser,
      firebaseUser: firebaseUser,
    );
  }
}
