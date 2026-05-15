import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_entry_warm_service.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';
import 'package:turqappv2/Runtime/system_navigation_surface_controller.dart';

class AppRootNavigationService {
  const AppRootNavigationService._();

  static bool get _hasNavigationContext => Get.key.currentContext != null;

  static Future<void> offAllToAuthenticatedHome() async {
    if (!_hasNavigationContext) return;
    setFilteredSystemNavigationSurface(false);
    if (kDebugMode) {
      debugPrint('[StartupNav] action=offAllToAuthenticatedHome_start');
    }
    await Get.offAll(() => NavBarView());
    if (kDebugMode) {
      debugPrint('[StartupNav] action=offAllToAuthenticatedHome_end');
    }
  }

  static Future<void> offToAuthenticatedHome() async {
    if (!_hasNavigationContext) return;
    setFilteredSystemNavigationSurface(false);
    await Get.off(() => NavBarView());
  }

  static Future<void> offAllToSignIn({
    String initialIdentifier = '',
    String storedAccountUid = '',
    bool isFirstLaunch = false,
  }) async {
    if (!_hasNavigationContext) return;
    setFilteredSystemNavigationSurface(false);
    unawaited(
      SignInEntryWarmService.ensureStarted(
        source: 'app_root_navigation',
        isFirstLaunch: isFirstLaunch,
      ),
    );
    await Get.offAll(
      () => SignIn(
        initialIdentifier: initialIdentifier,
        storedAccountUid: storedAccountUid,
        isFirstLaunch: isFirstLaunch,
      ),
    );
  }

  static Future<void> offAllToSplash() async {
    if (!_hasNavigationContext) return;
    setFilteredSystemNavigationSurface(true);
    await Get.offAll(() => const SplashView());
  }
}
