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
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
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

  // Firebase/AppCheck bootstrap arka planda tamamlansın; ilk frame bloklanmasın.
  final bootstrapCompleter = Completer<void>();
  firebaseBootstrapFuture = bootstrapCompleter.future;

  // VideoStateManager uygulama boyunca hazır kalsın (route dispose döngüsünde düşmesin)
  if (!Get.isRegistered<VideoStateManager>()) {
    Get.put(VideoStateManager(), permanent: true);
  }
  if (!Get.isRegistered<NetworkAwarenessService>()) {
    Get.put(NetworkAwarenessService(), permanent: true);
  }

  runApp(const MyApp());

  _appLifecycleListener = AppLifecycleListener(
    onInactive: _handleAppBackgroundTransition,
    onPause: _handleAppBackgroundTransition,
    onDetach: _handleAppBackgroundTransition,
  );

  // İlk frame sonrası sistem UI ayarları ve bootstrap.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _bootstrapFirebaseAndCrashlytics().then((_) {
      if (!bootstrapCompleter.isCompleted) bootstrapCompleter.complete();
    }).catchError((e, st) {
      if (!bootstrapCompleter.isCompleted) {
        bootstrapCompleter.completeError(e, st);
      }
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  });
}

void _clearConsumedCacheIfNeeded() {
  try {
    if (Get.isRegistered<SegmentCacheManager>()) {
      unawaited(Get.find<SegmentCacheManager>().clearConsumedCache());
    }
  } catch (_) {}
}

void _handleAppBackgroundTransition() {
  _clearConsumedCacheIfNeeded();
  try {
    if (Get.isRegistered<VideoStateManager>()) {
      Get.find<VideoStateManager>().pauseAllVideos(force: true);
    }
  } catch (_) {}
  try {
    if (Get.isRegistered<AgendaController>()) {
      unawaited(Get.find<AgendaController>().persistWarmLaunchCache());
    }
  } catch (_) {}
  try {
    AudioFocusCoordinator.instance.pauseAllAudioPlayers();
  } catch (_) {}
}

Future<void> _bootstrapFirebaseAndCrashlytics() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _activateAppCheck();

  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exception;
    final stack = details.stack;
    if (_isExpectedNonFatalNoise(error)) {
      debugPrint('Suppressed non-fatal: $error');
      return;
    }
    FirebaseCrashlytics.instance.recordFlutterError(details);
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isExpectedNonFatalNoise(error)) {
      debugPrint('Platform suppressed non-fatal: $error');
      return true;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
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
  final text = error.toString().toLowerCase();
  return text.contains('cloud_firestore/permission-denied') ||
      text.contains('cloud_firestore/failed-precondition') ||
      text.contains('requires an index');
}

bool _isExpectedNonFatalNoise(Object error) {
  final text = error.toString().toLowerCase();
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
    return GetMaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        routingCallback: (routing) {
          if (routing == null) return;
          final current = routing.current;
          final previous = routing.previous;
          if (current == previous) return;
          unawaited(AudioFocusCoordinator.instance.pauseAllAudioPlayers());
        },
        defaultTransition: Transition.fade,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
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
              textStyle: const TextStyle(
                fontSize: 15,
                fontFamily: AppFontFamilies.mmedium,
              ),
              disabledBackgroundColor: Colors.black26,
              disabledForegroundColor: Colors.white70,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontSize: 15,
                fontFamily: AppFontFamilies.mmedium,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontSize: 15,
                fontFamily: AppFontFamilies.mmedium,
              ),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
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
        home: const SplashView());
  }
}
