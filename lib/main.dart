import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
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
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Native launch ekranını uzatmamak için Firebase bootstrap'ı
  // ilk frame sonrasına ertelenir.
  final bootstrapCompleter = Completer<void>();
  firebaseBootstrapFuture = bootstrapCompleter.future;

  // VideoStateManager lazy olarak yüklensin
  Get.lazyPut(() => VideoStateManager());

  runApp(const MyApp());

  _appLifecycleListener = AppLifecycleListener(
    onPause: _clearConsumedCacheIfNeeded,
    onDetach: _clearConsumedCacheIfNeeded,
  );

  // İlk frame'i geciktirmemek için sistem UI ayarlarını sonrasına bırak.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _bootstrapFirebaseAndCrashlytics()
        .then((_) {
          if (!bootstrapCompleter.isCompleted) bootstrapCompleter.complete();
        })
        .catchError((e, st) {
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

Future<void> _bootstrapFirebaseAndCrashlytics() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
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
          final topGap = GetPlatform.isIOS ? _globalTopGapIOS : _globalTopGapAndroid;
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
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      final currentFocus = FocusScope.of(ctx);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: child ?? const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
        home: const SplashView());
  }
}
