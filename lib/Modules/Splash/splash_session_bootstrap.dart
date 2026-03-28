import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

typedef FirstLaunchCleanupRunner = Future<bool> Function(
  SharedPreferences prefs,
);

typedef SplashStartupPreparationRunner = Future<void> Function({
  required bool isFirstLaunch,
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
    Future<void> Function()? syncCurrentAccountToAccountCenter,
    SplashStartupPreparationRunner? prepareSynchronizedStartupBeforeNav,
    void Function(bool value)? markMinimumStartupPrepared,
    bool Function()? deterministicStartup,
    bool Function()? isIOS,
  })  : _initializeAccountCenter =
            initializeAccountCenter ?? _defaultInitializeAccountCenter,
        _initializeCurrentUser =
            initializeCurrentUser ?? _defaultInitializeCurrentUser,
        _handleFirstLaunchCleanup =
            handleFirstLaunchCleanup ?? _defaultHandleFirstLaunchCleanup,
        _readEffectiveUserId = readEffectiveUserId ?? _defaultReadEffectiveUserId,
        _syncCurrentAccountToAccountCenter =
            syncCurrentAccountToAccountCenter ??
                _defaultSyncCurrentAccountToAccountCenter,
        _prepareSynchronizedStartupBeforeNav =
            prepareSynchronizedStartupBeforeNav,
        _markMinimumStartupPrepared = markMinimumStartupPrepared,
        _deterministicStartup =
            deterministicStartup ?? (() => IntegrationTestMode.deterministicStartup),
        _isIOS = isIOS ?? (() => Platform.isIOS);

  final Future<void> Function() _initializeAccountCenter;
  final Future<void> Function() _initializeCurrentUser;
  final FirstLaunchCleanupRunner _handleFirstLaunchCleanup;
  final String Function() _readEffectiveUserId;
  final Future<void> Function() _syncCurrentAccountToAccountCenter;
  final SplashStartupPreparationRunner? _prepareSynchronizedStartupBeforeNav;
  final void Function(bool value)? _markMinimumStartupPrepared;
  final bool Function() _deterministicStartup;
  final bool Function() _isIOS;

  Future<SessionBootstrapResult> run({
    required SharedPreferences prefs,
  }) async {
    await _initializeAccountCenter();

    late final bool isFirstLaunch;
    if (_isIOS()) {
      isFirstLaunch = await _handleFirstLaunchCleanup(prefs)
          .timeout(const Duration(milliseconds: 350), onTimeout: () => false);
      unawaited(_initializeCurrentUser());
    } else {
      await Future.wait([
        _handleFirstLaunchCleanup(prefs).then((value) => isFirstLaunch = value),
        _initializeCurrentUser(),
      ]);
    }

    final loggedIn = _readEffectiveUserId().isNotEmpty;
    if (loggedIn) {
      unawaited(_syncCurrentAccountToAccountCenter());
      if (_deterministicStartup()) {
        _markMinimumStartupPrepared?.call(true);
      } else if (_prepareSynchronizedStartupBeforeNav != null) {
        await _prepareSynchronizedStartupBeforeNav(
          isFirstLaunch: isFirstLaunch,
        );
      }
    }

    return SessionBootstrapResult(
      isFirstLaunch: isFirstLaunch,
      loggedIn: loggedIn,
    );
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
    try {
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
    } catch (_) {
      try {
        await FirebaseAuth.instance.signOut();
        await CurrentUserService.instance.logout();
        await ensureAccountCenterService().signOutAllLocal();
      } catch (_) {}
      return true;
    }
  }

  static String _defaultReadEffectiveUserId() {
    return CurrentUserService.instance.effectiveUserId;
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
