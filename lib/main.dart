import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/qa_lab_mode.dart';
import 'package:turqappv2/Core/Localization/app_language_service.dart';
import 'package:turqappv2/Core/Localization/app_translations.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Buttons/turq_button_tokens.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'firebase_options.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final int appLaunchEpochMs = DateTime.now().millisecondsSinceEpoch;
late final Future<void> firebaseBootstrapFuture;
// ignore: unused_element
AppLifecycleListener? _appLifecycleListener;

Duration get _startupBootstrapWait => IntegrationTestMode.enabled
    ? const Duration(seconds: 20)
    : const Duration(seconds: 5);

Duration get _firebaseInitTimeout => IntegrationTestMode.enabled
    ? const Duration(seconds: 18)
    : const Duration(seconds: 4);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureQALabIfEnabled();
  if (QALabMode.freshStartOnLaunch && !IntegrationTestMode.enabled) {
    await prepareQALabFreshStartIfNeeded(trigger: 'app_launch').timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('[qa-lab] fresh-start cleanup timed out; continuing.');
      },
    );
  }
  if (QALabMode.enabled && !IntegrationTestMode.enabled) {
    WidgetsBinding.instance.addTimingsCallback(recordQALabFrameTimings);
  }
  ErrorWidget.builder = (FlutterErrorDetails details) {
    _reportStartupFallbackError(details);
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Uygulama başlatılırken bir hata oluştu.\nLütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: AppFontFamilies.mmedium,
              ),
            ),
          ),
        ),
      ),
    );
  };

  // iOS'ta launch anında jetsam/watchdog riskini azaltmak için
  // decode image cache'i daha dengeli tut.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 1200;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Firebase'i widget agacina girmeden once hazirla; aksi halde Splash,
  // CurrentUserService ve SignIn gibi erken ayaga kalkan akislarda
  // FirebaseFunctions/FirebaseAuth Firebase initialize edilmeden
  // cagrilip startup fallback ekranina dusuyordu.
  firebaseBootstrapFuture = _bootstrapFirebaseAndCrashlytics();
  await firebaseBootstrapFuture.timeout(
    _startupBootstrapWait,
    onTimeout: () {
      debugPrint('[bootstrap] startup timed out before runApp; continuing.');
    },
  );

  // VideoStateManager uygulama boyunca hazır kalsın (route dispose döngüsünde düşmesin)
  VideoStateManager.instance;
  NetworkAwarenessService.ensure();
  await AppLanguageService.ensureInitialized();

  runApp(const MyApp());

  _appLifecycleListener = AppLifecycleListener(
    onResume: _handleAppResumeTransition,
    onInactive: () => _handleAppBackgroundTransition('inactive'),
    onPause: () => _handleAppBackgroundTransition('pause'),
    onDetach: () => _handleAppBackgroundTransition('detach'),
  );

  // Ilk frame sonrasi yalnizca sistem UI ayarlari.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  });
}

void _reportStartupFallbackError(FlutterErrorDetails details) {
  final error = details.exception;
  recordQALabFlutterError(
    details,
    suppressed: _isExpectedNonFatalNoise(error),
    sourceLabel: 'startup_fallback',
  );
  if (_isExpectedNonFatalNoise(error)) {
    debugPrint('Suppressed fallback error: $error');
    return;
  }

  FlutterError.presentError(details);
  debugPrint('Fallback ErrorWidget triggered by: $error');
  if (details.stack != null) {
    debugPrintStack(stackTrace: details.stack);
  }

  try {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  } catch (_) {}
}

void _clearConsumedCacheIfNeeded() {
  try {
    final cacheManager = SegmentCacheManager.maybeFind();
    if (cacheManager != null) {
      unawaited(cacheManager.clearConsumedCache());
    }
  } catch (_) {}
}

void _handleAppResumeTransition() {
  recordQALabLifecycleState('resume');
  unawaited(
    refreshQALabPermissionSnapshot(trigger: 'resume'),
  );
}

void _handleAppBackgroundTransition(String state) {
  recordQALabLifecycleState(state);
  _clearConsumedCacheIfNeeded();
  try {
    VideoStateManager.maybeFind()?.pauseAllVideos(force: true);
  } catch (_) {}
  try {
    final agendaController = AgendaController.maybeFind();
    if (agendaController != null) {
      unawaited(agendaController.persistWarmLaunchCache());
    }
  } catch (_) {}
  try {
    AudioFocusCoordinator.instance.pauseAllAudioPlayers();
  } catch (_) {}
}

Future<void> _bootstrapFirebaseAndCrashlytics() async {
  var firebaseReady = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(_firebaseInitTimeout);
    firebaseReady = true;
  } catch (e, st) {
    debugPrint('[bootstrap] Firebase.initializeApp failed: $e');
    debugPrintStack(stackTrace: st);
  }

  if (firebaseReady) {
    try {
      await _activateAppCheck().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('[AppCheck] activation timed out.');
        },
      );
    } catch (e, st) {
      debugPrint('[AppCheck] activation failed before handlers: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exception;
    final stack = details.stack;
    recordQALabFlutterError(
      details,
      suppressed: _isExpectedNonFatalNoise(error),
      sourceLabel: 'flutter_on_error',
    );
    if (_isExpectedNonFatalNoise(error)) {
      debugPrint('Suppressed non-fatal: $error');
      return;
    }
    FlutterError.presentError(details);
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
    debugPrint('FlutterError captured: $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    recordQALabPlatformError(
      error,
      stack,
      suppressed: _isExpectedNonFatalNoise(error),
      sourceLabel: 'platform_dispatcher',
    );
    if (_isExpectedNonFatalNoise(error)) {
      debugPrint('Platform suppressed non-fatal: $error');
      return true;
    }
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    }
    return true;
  };
}

Future<void> _activateAppCheck() async {
  if (kDebugMode) {
    debugPrint('[AppCheck] debug mode: activation skipped.');
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );

    if (!kReleaseMode) {
      final mode = kDebugMode ? 'debug' : 'profile';
      debugPrint(
        '[AppCheck] $mode provider enabled for local development.',
      );
    }
  } catch (e, st) {
    debugPrint('[AppCheck] activation failed: $e');
    FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
  }
}

bool _isFirestoreConfigError(Object error) {
  final text = normalizeLowercase(error.toString());
  return text.contains('cloud_firestore/permission-denied') ||
      text.contains('cloud_firestore/failed-precondition') ||
      text.contains('requires an index');
}

bool _isExpectedNonFatalNoise(Object error) {
  final text = normalizeLowercase(error.toString());
  if (_isFirestoreConfigError(error)) return true;
  return text.contains('firebase_app_check/unknown') ||
      text.contains('exchangedevicechecktoken') ||
      text.contains('exchangedebugtoken') ||
      text.contains('app attestation failed') ||
      text.contains('app not registered');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const double _globalTopGapAndroid = 8.0;
  static const double _globalTopGapIOS = -2.0; // iOS'ta 10px daha az boşluk

  @override
  Widget build(BuildContext context) {
    final languageService = AppLanguageService.maybeFind();
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      routingCallback: (routing) {
        if (routing == null) return;
        final current = routing.current;
        final previous = routing.previous;
        if (current == previous) return;
        recordQALabRouteChange(
          current: current,
          previous: previous,
        );
      },
      defaultTransition: Transition.fade,
      translations: AppTranslations(),
      locale:
          languageService?.currentLocale ?? AppLanguageService.fallbackLocale,
      fallbackLocale: AppLanguageService.fallbackLocale,
      supportedLocales: AppLanguageService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'TurqApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: AppFontFamilies.mregular,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Colors.black,
        ),
        textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black),
        textTheme: const TextTheme(
          bodySmall: TextStyle(
            fontSize: 12,
            fontFamily: AppFontFamilies.mregular,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontFamily: AppFontFamilies.mregular,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontFamily: AppFontFamilies.mregular,
            color: Colors.black,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontFamily: AppFontFamilies.mmedium,
            color: Colors.black,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontFamily: AppFontFamilies.mmedium,
            color: Colors.black,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontFamily: AppFontFamilies.mbold,
            color: Colors.black,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontFamily: AppFontFamilies.mmedium,
            color: Colors.white,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, TurqButtonTokens.height),
            padding: const EdgeInsets.symmetric(
              horizontal: TurqButtonTokens.horizontalPadding,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontFamily: AppFontFamilies.mmedium,
            ),
            disabledBackgroundColor: Colors.black26,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TurqButtonTokens.radius),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, TurqButtonTokens.height),
            padding: const EdgeInsets.symmetric(
              horizontal: TurqButtonTokens.horizontalPadding,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontFamily: AppFontFamilies.mmedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TurqButtonTokens.radius),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: const Size(0, TurqButtonTokens.height),
            padding: const EdgeInsets.symmetric(
              horizontal: TurqButtonTokens.horizontalPadding,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontFamily: AppFontFamilies.mmedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TurqButtonTokens.radius),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: const Size(0, TurqButtonTokens.height),
            padding: const EdgeInsets.symmetric(
              horizontal: TurqButtonTokens.horizontalPadding,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontFamily: AppFontFamilies.mmedium,
            ),
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TurqButtonTokens.radius),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          titleSpacing: 8,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
        ),
      ),
      builder: (ctx, child) {
        final mq = MediaQuery.of(ctx);
        final topGap =
            GetPlatform.isIOS ? _globalTopGapIOS : _globalTopGapAndroid;
        final adjustedPadding = mq.padding.copyWith(
          top: mq.padding.top + topGap,
        );
        final adjustedViewPadding = mq.viewPadding.copyWith(
          top: mq.viewPadding.top + topGap,
        );
        return MediaQuery(
          data: mq.copyWith(
            padding: adjustedPadding,
            viewPadding: adjustedViewPadding,
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarContrastEnforced: false,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: adjustedViewPadding.top,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: child ?? const SplashView(),
                ),
              ],
            ),
          ),
        );
      },
      home: const SplashView(),
    );
  }
}
