import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_entry_warm_service.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';

class AppRootNavigationService {
  const AppRootNavigationService._();

  static bool get _hasNavigationContext => Get.key.currentContext != null;

  static Future<void> offAllToAuthenticatedHome() async {
    if (!_hasNavigationContext) return;
    await Get.offAll(() => NavBarView());
  }

  static Future<void> offToAuthenticatedHome() async {
    if (!_hasNavigationContext) return;
    await Get.off(() => NavBarView());
  }

  static Future<void> offAllToSignIn({
    String initialIdentifier = '',
    String storedAccountUid = '',
    bool isFirstLaunch = false,
  }) async {
    if (!_hasNavigationContext) return;
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
    await Get.offAll(() => const SplashView());
  }
}
