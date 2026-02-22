import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Ads/AdmobKare.dart';

import 'package:turqappv2/Core/NotificationService.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_proxy_server.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Modules/Maintenance/MaintenanceView.dart';
import 'package:turqappv2/Modules/NavBar/NavBarView.dart';
import 'package:turqappv2/Modules/SignIn/SignIn.dart';
import 'package:turqappv2/Themes/AppColors.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../Core/Helpers/GlobalLoader/GlobalLoaderController.dart';
import '../../Modules/Agenda/AgendaController.dart';
import '../../Modules/Education/EducationController.dart';
import '../../Modules/Explore/ExploreController.dart';
import '../../Modules/JobFinder/JobFinderController.dart';
import '../../Modules/NavBar/NavBarController.dart';
import '../../Modules/Profile/MyProfile/ProfileController.dart';
import '../../Modules/Profile/SavedPosts/SavedPostsController.dart';
import '../../Modules/RecommendedUserList/RecommendedUserListController.dart';
import '../../Modules/Short/ShortController.dart';
import '../../Modules/Story/StoryRow/StoryRowController.dart';
import '../../Services/FirebaseMyStore.dart';
import '../../Services/StoryInteractionOptimizer.dart';
import '../../Core/Helpers/UnreadMessagesController/UnreadMessagesController.dart';
import '../../Services/current_user_service.dart';
import '../../Core/Services/FirestoreConfig.dart';
import '../../Core/Services/NetworkAwarenessService.dart';
import '../../Core/Services/VideoRemoteConfigService.dart';
import '../../Services/offline_mode_service.dart';
import '../../main.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const Duration _syncStartupMaxWait = Duration(seconds: 6);
  static const Duration _syncMinSplashDuration = Duration(milliseconds: 1800);
  static const Duration _syncMinLaunchToNavDuration =
      Duration(milliseconds: 5000);
  static const int _minFeedPostsForNav = 6;
  static const int _minStoryUsersForNav = 1;
  static const int _minShortsForNav = 3;

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _minimumStartupPrepared = false;
  static Future<void>? _globalCacheProxyInitFuture;
  static bool _globalCacheProxyReady = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    final splashInitDelta =
        DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    debugPrint(
        '[StartupTrace] launch->Splash.initState = ${splashInitDelta}ms');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final splashFrameDelta =
          DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
      debugPrint(
          '[StartupTrace] launch->Splash.firstFrame = ${splashFrameDelta}ms');
    });

    // Firebase hazır olmadan FirebasePerformance çağrısı yapılmasın.
    unawaited(_initApp());
  }

  Future<void> _initApp() async {
    final startupStopwatch = Stopwatch()..start();
    try {
      // Firebase başlatımı artık runApp sonrasına taşındı.
      await firebaseBootstrapFuture;

      // Firestore settings ilk erişimden önce set edilmeli.
      await FirestoreConfig.initialize();

      // ⚡ Kalan işleri paralel başlat — en yavaş olan süreyi belirler
      late final bool shouldLockApp;
      late final bool isFirstLaunch;
      final userService = CurrentUserService.instance;
      Get.put(userService);

      await Future.wait([
        _initAudioContext(),
        _handleFirstLaunchAuthCleanup().then((v) => isFirstLaunch = v),
        _checkLockApp().then((v) => shouldLockApp = v),
        userService.initialize(), // Cache'den ~10ms, sync arka planda
      ]);

      // 🔥 Bakım modu kontrolü
      if (shouldLockApp) {
        if (!mounted) return;
        Get.offAll(() => const MaintenanceView());
        return;
      }

      // GetX bağımlılıklarını hazırla
      _registerDependencies();

      // Login kullanıcıda: feed açılmadan önce minimum hazırlık (timeout'lu)
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      if (loggedIn) {
        await _prepareSynchronizedStartupBeforeNav(
            isFirstLaunch: isFirstLaunch);
      }

      // 🚀 Ağır işleri arka plana at — navigasyonu BLOKLAMA
      unawaited(_backgroundInit(isFirstLaunch: isFirstLaunch));
    } catch (e, stack) {
      debugPrint('❌ SplashView _initApp HATA: $e');
      debugPrint('$stack');
    }

    if (!mounted) return;
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final navDelta = DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    debugPrint(
        '[StartupTrace] launch->NavDecision(${loggedIn ? 'NavBar' : 'SignIn'}) = ${navDelta}ms');
    startupStopwatch.stop();
    debugPrint('⚡ App startup: ${startupStopwatch.elapsedMilliseconds}ms');
    if (loggedIn) {
      Get.offAll(() => NavBarView());
    } else {
      Get.offAll(() => SignIn());
    }
  }

  /// Navigasyonu bloklamayan arka plan işleri
  Future<void> _backgroundInit({required bool isFirstLaunch}) async {
    try {
      // HLS Proxy + Cache Manager başlat (arka planda, navigasyonu bloklamaz)
      unawaited(_initCacheProxy());

      // Warm start — sadece giriş yapmış kullanıcı için
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      if (loggedIn) {
        // Kritik warm start: feed + story + önerilen kullanıcıları erken hazırla
        if (!_minimumStartupPrepared) {
          Future.delayed(Duration(milliseconds: isFirstLaunch ? 250 : 600), () {
            unawaited(_runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch));
          });
        }

        // Genişletilmiş warm start: kısa süre sonra derinleşsin
        Future.delayed(Duration(seconds: isFirstLaunch ? 5 : 8), () {
          unawaited(_runWarmStartLoads(isFirstLaunch: isFirstLaunch));
        });
      }

      // Orta öncelik: AppCheck + bildirim hazırlığı
      Future.delayed(const Duration(milliseconds: 900), () {
        unawaited(NotificationService.instance.initialize());
      });

      // Düşük öncelik: AdMob + ATT (WebView yükü oluşturabilir)
      Future.delayed(Duration(seconds: isFirstLaunch ? 2 : 4), () {
        unawaited(_requestTrackingPermission());
        unawaited(_initAdMob(targetCount: isFirstLaunch ? 6 : 5));
      });
    } catch (_) {}
  }

  Future<void> _initCacheProxy() async {
    if (_globalCacheProxyReady) return;
    final inFlight = _globalCacheProxyInitFuture;
    if (inFlight != null) return inFlight;

    final future = _initCacheProxyInternal();
    _globalCacheProxyInitFuture = future;
    return future;
  }

  Future<void> _initCacheProxyInternal() async {
    try {
      final remote = Get.isRegistered<VideoRemoteConfigService>()
          ? Get.find<VideoRemoteConfigService>()
          : Get.put(VideoRemoteConfigService(), permanent: true);
      if (!remote.isReady) {
        await remote.initialize();
      }

      final server = Get.isRegistered<HLSProxyServer>()
          ? Get.find<HLSProxyServer>()
          : Get.put(HLSProxyServer(), permanent: true);
      if (!server.isStarted) {
        await server.start();
      }

      if (!Get.isRegistered<SegmentCacheManager>()) {
        final cache = Get.put(SegmentCacheManager(), permanent: true);
        await cache.init();
      }

      if (!Get.isRegistered<PrefetchScheduler>()) {
        Get.put(PrefetchScheduler(), permanent: true);
      }
      _globalCacheProxyReady = true;
    } catch (e) {
      debugPrint('[Splash] Cache proxy init error: $e');
      _globalCacheProxyReady = false;
    } finally {
      _globalCacheProxyInitFuture = null;
    }
  }

  Future<void> _initAudioContext() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _initAdMob({int targetCount = 4}) async {
    try {
      if (kDebugMode) {
        // Debug'da Ads SDK log gürültüsünü azalt.
        return;
      }
      await MobileAds.instance.initialize();
      unawaited(AdmobKare.warmupPool(targetCount: targetCount));
      Future.delayed(const Duration(seconds: 2), () {
        unawaited(AdmobKare.warmupPool(targetCount: targetCount));
      });
    } catch (_) {}
  }

  void _registerDependencies() {
    // Network & Offline servisleri
    Get.put(NetworkAwarenessService());
    Get.put(OfflineModeService.instance);

    Get.put(GlobalLoaderController());
    Get.put(FirebaseMyStore());
    Get.put(StoryInteractionOptimizer());
    Get.lazyPut(() => UnreadMessagesController());
    Get.lazyPut(() => NavBarController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => AgendaController());
    Get.lazyPut(() => RecommendedUserListController());
    Get.lazyPut(() => ExploreController());
    Get.lazyPut(() => ShortController());
    Get.lazyPut(() => EducationController());
    Get.lazyPut(() => SavedPostsController());
    Get.lazyPut(() => JobFinderController());
    Get.lazyPut(() => StoryRowController());
  }

  Future<void> _runCriticalWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final bool onWiFi = _isOnWiFiNow();
      final storyController = Get.find<StoryRowController>();
      final agendaController = Get.find<AgendaController>();
      final recommended = Get.find<RecommendedUserListController>();

      // İlk kurulumda daha küçük hedefle hızlı başlangıç
      try {
        final shorts = Get.find<ShortController>();
        // Kritik: Short ekranına ilk girişte spinner dönmemesi için
        // ilk batch + ilk birkaç adapter preload'u bekle.
        await shorts.backgroundPreload().timeout(
              Duration(seconds: onWiFi ? 4 : 2),
              onTimeout: () {},
            );
        shorts.warmStart(
          targetCount:
              onWiFi ? (isFirstLaunch ? 6 : 8) : (isFirstLaunch ? 3 : 4),
          maxPages: onWiFi ? 2 : 1,
        );
      } catch (_) {}

      await _forceLoadStoriesSync(
        storyController,
        limit: onWiFi ? (isFirstLaunch ? 20 : 30) : (isFirstLaunch ? 10 : 16),
      );

      try {
        await agendaController
            .fetchAgendaBigData(initial: true)
            .timeout(const Duration(seconds: 3));
        await _ensureMinimumFeedPosts(
          agendaController,
          minPosts: onWiFi ? (isFirstLaunch ? 8 : 10) : (isFirstLaunch ? 5 : 6),
          maxExtraFetch: onWiFi ? 2 : 1,
        );
      } catch (_) {}

      try {
        await recommended.ensureLoaded(
          limit:
              onWiFi ? (isFirstLaunch ? 140 : 220) : (isFirstLaunch ? 80 : 120),
        );
      } catch (_) {}

      // Açılışta profil isim/avatar geç gelmesin: hafif metadata + avatar warmup.
      unawaited(_warmUserMetaAndAvatars(
        agendaController: agendaController,
        storyController: storyController,
        recommendedController: recommended,
        onWiFi: onWiFi,
      ));
    } catch (_) {}
  }

  Future<void> _runWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final bool onWiFi = _isOnWiFiNow();
      final storyController = Get.find<StoryRowController>();

      // Shorts tarafında çok hafif ısınma yap.
      try {
        final shorts = Get.find<ShortController>();
        shorts.warmStart(
          targetCount:
              onWiFi ? (isFirstLaunch ? 8 : 10) : (isFirstLaunch ? 4 : 6),
          maxPages: onWiFi ? 2 : 1,
        );
      } catch (_) {}

      // Post + toplu kullanıcı preload bu fazda kapalı.
      // Sadece story tarafını hafif şekilde hazırla.
      await _forceLoadStoriesSync(storyController, limit: onWiFi ? 30 : 18);
    } catch (_) {}
  }

  Future<void> _prepareMinimumStartupBeforeNav(
      {required bool isFirstLaunch}) async {
    const timeout = Duration(seconds: 5);

    try {
      await Future.any([
        _prepareMinimumStartupCore(
          isFirstLaunch: isFirstLaunch,
          onWiFi: true,
        ),
        Future.delayed(timeout),
      ]);
      _minimumStartupPrepared = true;
    } catch (_) {}
  }

  Future<void> _prepareSynchronizedStartupBeforeNav(
      {required bool isFirstLaunch}) async {
    final syncWatch = Stopwatch()..start();
    debugPrint('[StartupSync] phase=begin');

    await Future.wait([
      _prepareMinimumStartupBeforeNav(isFirstLaunch: isFirstLaunch),
      _ensureMinSplashDuration(),
    ]);
    debugPrint(
        '[StartupSync] phase=minimum_ready elapsed=${syncWatch.elapsedMilliseconds}ms');

    await _waitForCriticalDataReadiness(timeout: _syncStartupMaxWait);
    await _ensureMinLaunchToNavDuration();
    debugPrint(
        '[StartupSync] phase=critical_ready elapsed=${syncWatch.elapsedMilliseconds}ms');
  }

  Future<void> _ensureMinSplashDuration() async {
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    final remainingMs = _syncMinSplashDuration.inMilliseconds - elapsedMs;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }
  }

  Future<void> _ensureMinLaunchToNavDuration() async {
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    final remainingMs = _syncMinLaunchToNavDuration.inMilliseconds - elapsedMs;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }
  }

  Future<void> _waitForCriticalDataReadiness(
      {required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final feedReady = _isFeedReady();
      final storyReady = _isStoryReady();
      final shortsReady = _isShortsReady();
      if (feedReady && storyReady && shortsReady) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 140));
    }
    debugPrint(
        '[StartupSync] phase=critical_timeout feed=${_isFeedReady()} story=${_isStoryReady()} shorts=${_isShortsReady()}');
  }

  bool _isFeedReady() {
    if (!Get.isRegistered<AgendaController>()) return false;
    return Get.find<AgendaController>().agendaList.length >=
        _minFeedPostsForNav;
  }

  bool _isStoryReady() {
    if (!Get.isRegistered<StoryRowController>()) return false;
    return Get.find<StoryRowController>().users.length >= _minStoryUsersForNav;
  }

  bool _isShortsReady() {
    if (!Get.isRegistered<ShortController>()) return false;
    return Get.find<ShortController>().shorts.length >= _minShortsForNav;
  }

  Future<void> _prepareMinimumStartupCore({
    required bool isFirstLaunch,
    required bool onWiFi,
  }) async {
    try {
      await _initCacheProxy().timeout(
        onWiFi ? const Duration(seconds: 3) : const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {}

    try {
      await _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch).timeout(
        onWiFi ? const Duration(seconds: 2) : const Duration(seconds: 1),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  Future<void> _ensureMinimumFeedPosts(
    AgendaController agendaController, {
    required int minPosts,
    required int maxExtraFetch,
  }) async {
    try {
      var extra = 0;
      while (agendaController.agendaList.length < minPosts &&
          agendaController.hasMore.value &&
          extra < maxExtraFetch) {
        await agendaController.fetchAgendaBigData();
        extra++;
      }
    } catch (_) {}
  }

  bool _isOnWiFiNow() {
    try {
      return Get.find<NetworkAwarenessService>().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  Future<void> _warmUserMetaAndAvatars({
    required AgendaController agendaController,
    required StoryRowController storyController,
    required RecommendedUserListController recommendedController,
    required bool onWiFi,
  }) async {
    try {
      final Set<String> userIds = {};

      final int feedTake = onWiFi ? 20 : 10;
      final int storyTake = onWiFi ? 20 : 10;
      final int recommendedTake = onWiFi ? 20 : 10;

      for (final post in agendaController.agendaList.take(feedTake)) {
        userIds.add(post.userID);
      }
      for (final user in storyController.users.take(storyTake)) {
        userIds.add(user.userID);
      }
      for (final user in recommendedController.list.take(recommendedTake)) {
        userIds.add(user.userID);
      }

      if (userIds.isEmpty) return;

      final ids = userIds.toList();
      final avatarUrls = <String>[];
      for (int i = 0; i < ids.length; i += 10) {
        final chunk =
            ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final pf = (doc.data()['pfImage'] ?? '').toString();
          if (pf.isNotEmpty) avatarUrls.add(pf);
        }
      }

      final int warmCount = onWiFi ? 30 : 8;
      for (final url in avatarUrls.take(warmCount)) {
        try {
          final provider = CachedNetworkImageProvider(url);
          if (mounted) {
            await precacheImage(provider, context);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _forceLoadStoriesSync(StoryRowController storyController,
      {int limit = 30}) async {
    try {
      await storyController.loadStories(
          limit: limit, cacheFirst: true, silentLoad: false);
      if (storyController.users.isEmpty) {
        await storyController.addMyUserImmediately();
      }
    } catch (_) {
      try {
        await storyController.addMyUserImmediately();
      } catch (_) {}
    }
  }

  Future<void> _requestTrackingPermission() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {}
  }

  /// 🔐 First launch detection - Clear Firebase Auth if app was reinstalled
  ///
  /// This prevents auto-login when user deletes and reinstalls the app.
  /// Firebase Auth persists session in device keychain/keystore even after uninstall,
  /// but SharedPreferences gets cleared. We use this difference to detect fresh installs.
  Future<bool> _handleFirstLaunchAuthCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const String firstLaunchKey = 'app_has_launched_before';

      final bool hasLaunchedBefore = prefs.getBool(firstLaunchKey) ?? false;
      final bool isFirstLaunch = !hasLaunchedBefore;
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      // If Firebase Auth has a user BUT SharedPreferences says first launch,
      // this means the app was reinstalled → clear Firebase Auth session
      if (!hasLaunchedBefore && firebaseUser != null) {
        print('🔐 First launch detected with existing Firebase Auth session');
        print('🧹 Clearing Firebase Auth to force login screen...');

        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Clear CurrentUserService cache
        await CurrentUserService.instance.logout();

        print('✅ Auth cleared - User will see login screen');
      }

      // Mark that app has launched before
      if (!hasLaunchedBefore) {
        await prefs.setBool(firstLaunchKey, true);
        print('📝 First launch flag set');
      }
      return isFirstLaunch;
    } catch (e) {
      print('❌ First launch auth cleanup error: $e');
      // If error occurs, fail safe by signing out
      try {
        await FirebaseAuth.instance.signOut();
        await CurrentUserService.instance.logout();
      } catch (_) {}
      return true;
    }
  }

  /// 🔥 Early lockApp check - Debug/TestFlight bypass + cache
  Future<bool> _checkLockApp() async {
    try {
      if (kDebugMode) return false;

      // TestFlight kontrolü
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final bool isTestFlight = packageInfo.packageName.contains(".beta") ||
          packageInfo.packageName.contains("TestFlight") ||
          packageInfo.buildSignature.contains("TestFlight");
      if (isTestFlight) return false;

      // Cache'den hızlı karar — son 1 saat içinde kontrol edildiyse Firestore'a gitme
      final prefs = await SharedPreferences.getInstance();
      final cachedLock = prefs.getBool('lockApp_cached');
      final cachedTime = prefs.getInt('lockApp_timestamp') ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
      final cacheValid = age < const Duration(hours: 1).inMilliseconds;

      if (cachedLock != null && cacheValid) {
        // Arka planda Firestore'dan güncelle
        unawaited(_refreshLockAppCache(prefs));
        return !cachedLock;
      }

      // Cache yok veya eski — Firestore'dan çek (timeout ile)
      final doc = await _getLockConfigDoc().timeout(const Duration(seconds: 3),
          onTimeout: () {
        // Timeout durumunda son cache'e güven veya aç
        return cachedLock == null
            ? throw TimeoutException('lockApp timeout')
            : throw TimeoutException('use cache');
      });

      final bool lockApp = doc.get("lockApp") ?? true;
      await prefs.setBool('lockApp_cached', lockApp);
      await prefs.setInt(
          'lockApp_timestamp', DateTime.now().millisecondsSinceEpoch);
      return !lockApp;
    } on TimeoutException {
      // Timeout — cache varsa kullan, yoksa aç
      final prefs = await SharedPreferences.getInstance();
      final cachedLock = prefs.getBool('lockApp_cached');
      return cachedLock != null ? !cachedLock : false;
    } catch (e) {
      print("❌ lockApp kontrolü hatası: $e");
      return !kDebugMode;
    }
  }

  Future<void> _refreshLockAppCache(SharedPreferences prefs) async {
    try {
      final doc = await _getLockConfigDoc();
      final bool lockApp = doc.get("lockApp") ?? true;
      await prefs.setBool('lockApp_cached', lockApp);
      await prefs.setInt(
          'lockApp_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getLockConfigDoc() async {
    return FirebaseFirestore.instance
        .collection("adminConfig")
        .doc("service")
        .get();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryColor, AppColors.secondColor],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.05).animate(_scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TurqApp',
                    style: TextStyle(
                      fontFamily: 'Noe',
                      fontSize: 36,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
