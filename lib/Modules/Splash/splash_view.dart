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
import 'package:turqappv2/Ads/admob_kare.dart';

import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_proxy_server.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Modules/Maintenance/maintenance_view.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../Modules/Agenda/agenda_controller.dart';
import '../../Modules/Education/education_controller.dart';
import '../../Modules/Explore/explore_controller.dart';
import '../../Modules/JobFinder/job_finder_controller.dart';
import '../../Modules/NavBar/nav_bar_controller.dart';
import '../../Modules/Profile/MyProfile/profile_controller.dart';
import '../../Modules/Profile/SavedPosts/saved_posts_controller.dart';
import '../../Modules/RecommendedUserList/recommended_user_list_controller.dart';
import '../../Modules/Short/short_controller.dart';
import '../../Modules/Story/StoryRow/story_row_controller.dart';
import '../../Services/story_interaction_optimizer.dart';
import '../../Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import '../../Services/current_user_service.dart';
import '../../Core/Services/upload_queue_service.dart';
import '../../Core/Services/firestore_config.dart';
import '../../Core/Services/network_awareness_service.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../../Core/Services/video_emotion_config_service.dart';
import '../../Core/Services/mandatory_follow_service.dart';
import '../../Services/offline_mode_service.dart';
import '../../Core/Services/deep_link_service.dart';
import '../../main.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const Duration _syncStartupMaxWait = Duration(milliseconds: 900);
  static const Duration _syncMinSplashDuration = Duration(milliseconds: 120);
  static const Duration _syncMinLaunchToNavDuration = Duration.zero;
  static const int _minFeedPostsForNav = 3;
  static const int _minStoryUsersForNav = 1;
  static const int _minShortsForNav = 1;

  bool _minimumStartupPrepared = false;
  static Future<void>? _globalCacheProxyInitFuture;
  static bool _globalCacheProxyReady = false;
  Timer? _uiTickTimer;
  Timer? _startupWatchdogTimer;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();

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
    final watchdogDuration = Platform.isIOS
        ? const Duration(seconds: 4)
        : const Duration(seconds: 8);
    _startupWatchdogTimer = Timer(watchdogDuration, () {
      if (!mounted || _didNavigate) return;
      debugPrint('[StartupTrace] watchdog fired -> fallback navigation');
      _navigateToPrimaryRoute();

      // Bazı iOS anlarında ilk yönlendirme UI thread yoğunluğunda kaçabiliyor.
      // Kısa aralıklarla birkaç kez daha deneyip beyaz ekranda kalmayı engelle.
      for (final retryMs in <int>[900, 1800, 2800]) {
        Future.delayed(Duration(milliseconds: retryMs), () {
          if (!mounted || _didNavigate) return;
          debugPrint(
              '[StartupTrace] watchdog retry +${retryMs}ms -> fallback navigation');
          _navigateToPrimaryRoute();
        });
      }
    });

    _uiTickTimer = Timer.periodic(const Duration(milliseconds: 240), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initApp() async {
    final startupStopwatch = Stopwatch()..start();
    try {
      // Firebase + SharedPreferences + AudioContext paralel başlat
      // En yavaş olan toplam süreyi belirler (sıralı değil)
      late final SharedPreferences prefs;
      await Future.wait([
        firebaseBootstrapFuture.then((_) => FirestoreConfig.initialize()),
        SharedPreferences.getInstance().then((v) => prefs = v),
        _initAudioContext().catchError((_) {}),
      ]);

      // ⚡ Kalan işleri paralel başlat — en yavaş olan süreyi belirler
      bool shouldLockApp = false;
      late final bool isFirstLaunch;
      final userService = CurrentUserService.instance;
      Get.put(userService);

      if (Platform.isIOS) {
        // iOS'ta nav öncesi bloklamayı azalt:
        // lock check + user init arka planda yürüsün.
        unawaited(_checkLockApp(prefs: prefs).then((v) async {
          if (!mounted) return;
          if (v) {
            _didNavigate = true;
            Get.offAll(() => const MaintenanceView());
          }
        }));
        isFirstLaunch = await _handleFirstLaunchAuthCleanup(prefs: prefs)
            .timeout(const Duration(milliseconds: 350), onTimeout: () => false);
        unawaited(userService.initialize());
      } else {
        await Future.wait([
          _handleFirstLaunchAuthCleanup(prefs: prefs)
              .then((v) => isFirstLaunch = v),
          _checkLockApp(prefs: prefs).then((v) => shouldLockApp = v),
          userService.initialize(), // Cache'den ~10ms, sync arka planda
        ]);
      }

      // 🔥 Bakım modu kontrolü
      if (shouldLockApp) {
        if (!mounted) return;
        _didNavigate = true;
        Get.offAll(() => const MaintenanceView());
        return;
      }

      // GetX bağımlılıklarını hazırla
      _registerDependencies();

      // Zorunlu takip listesi (adminConfig) arka planda uygulanır.
      if (FirebaseAuth.instance.currentUser != null) {
        unawaited(MandatoryFollowService.instance.enforceForCurrentUser());
      }

      // Login kullanıcıda: feed açılmadan önce minimum hazırlık (timeout'lu)
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      if (loggedIn) {
        if (Platform.isIOS) {
          // iOS'ta açılışı bloklamayalım; veri hazırlığı arka planda sürsün.
          _minimumStartupPrepared =
              true; // Çift tetiklemeyi engelle: _backgroundInit tekrar _runCriticalWarmStartLoads çağırmasın
          unawaited(_prepareSynchronizedStartupBeforeNav(
              isFirstLaunch: isFirstLaunch));
        } else {
          await Future.any([
            _prepareSynchronizedStartupBeforeNav(isFirstLaunch: isFirstLaunch),
            Future.delayed(const Duration(milliseconds: 700)),
          ]);
        }
      }

      // 🚀 Ağır işleri arka plana at — navigasyonu BLOKLAMA
      unawaited(_backgroundInit(isFirstLaunch: isFirstLaunch));
    } catch (e, stack) {
      debugPrint('❌ SplashView _initApp HATA: $e');
      debugPrint('$stack');
    }

    if (!mounted) return;
    startupStopwatch.stop();
    debugPrint('⚡ App startup: ${startupStopwatch.elapsedMilliseconds}ms');
    _navigateToPrimaryRoute();
  }

  void _navigateToPrimaryRoute() {
    if (!mounted || _didNavigate) return;
    bool loggedIn = false;
    try {
      loggedIn = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      loggedIn = false;
    }
    final navDelta = DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    debugPrint(
        '[StartupTrace] launch->NavDecision(${loggedIn ? 'NavBar' : 'SignIn'}) = ${navDelta}ms');
    _didNavigate = true;
    if (loggedIn) {
      if (Get.isRegistered<NavBarController>()) {
        Get.find<NavBarController>().selectedIndex.value = 0;
      }
      Get.offAll(() => NavBarView());
      return;
    }
    Get.offAll(() => SignIn());
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
        // WiFi ve mobil veri fark etmez — _runCriticalWarmStartLoads içinde
        // zaten onWiFi'ye göre limit ayarlanıyor.
        if (!_minimumStartupPrepared) {
          final criticalDelay = Platform.isIOS
              ? Duration.zero
              : Duration(milliseconds: isFirstLaunch ? 250 : 600);
          if (criticalDelay == Duration.zero) {
            unawaited(_runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch));
          } else {
            Future.delayed(criticalDelay, () {
              unawaited(
                  _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch));
            });
          }
        }

        // Genişletilmiş warm start: kısa süre sonra derinleşsin
        final bool onWiFi = _isOnWiFiNow();
        Future.delayed(Duration(seconds: isFirstLaunch ? 5 : 8), () {
          if (onWiFi) {
            unawaited(_runWarmStartLoads(isFirstLaunch: isFirstLaunch));
          }
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

      final cache = Get.isRegistered<SegmentCacheManager>()
          ? Get.find<SegmentCacheManager>()
          : Get.put(SegmentCacheManager(), permanent: true);
      await cache.init();
      await _applyGlobalMediaCacheQuota();

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

  Future<void> _applyGlobalMediaCacheQuota() async {
    try {
      if (!Get.isRegistered<SegmentCacheManager>()) return;
      final prefs = await SharedPreferences.getInstance();
      final savedGb = prefs.getInt('offline_cache_quota_gb') ?? 3;
      final quotaGb = savedGb.clamp(2, 5);
      await Get.find<SegmentCacheManager>().setUserLimitGB(quotaGb);
    } catch (_) {}
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
    // Network & Offline servisleri — lazy: ilk erişimde init olur, navigasyonu bloklamaz
    Get.lazyPut(() => NetworkAwarenessService());
    Get.lazyPut(() => OfflineModeService.instance);

    if (!Get.isRegistered<GlobalLoaderController>()) {
      Get.put(GlobalLoaderController(), permanent: true);
    }
    Get.put(StoryInteractionOptimizer());
    Get.lazyPut(() => UnreadMessagesController());
    Get.lazyPut(() => NavBarController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => AgendaController());
    Get.lazyPut(() => RecommendedUserListController(), fenix: true);
    Get.lazyPut(() => ExploreController());
    Get.lazyPut(() => ShortController());
    Get.lazyPut(() => EducationController());
    Get.lazyPut(() => SavedPostsController());
    Get.lazyPut(() => JobFinderController());
    Get.lazyPut(() => StoryRowController(), fenix: true);
    if (!Get.isRegistered<UploadQueueService>()) {
      Get.put(UploadQueueService(), permanent: true);
    }
    if (!Get.isRegistered<DeepLinkService>()) {
      Get.put(DeepLinkService(), permanent: true);
    }
    if (!Get.isRegistered<IndexPoolStore>()) {
      Get.put(IndexPoolStore(), permanent: true);
    }
    if (!Get.isRegistered<UserProfileCacheService>()) {
      Get.put(UserProfileCacheService(), permanent: true);
    }
  }

  Future<void> _runCriticalWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final bool onWiFi = _isOnWiFiNow();
      final storyController = Get.find<StoryRowController>();
      final agendaController = Get.find<AgendaController>();
      final recommended = Get.find<RecommendedUserListController>();

      // Paralel: shorts + story + feed + recommended aynı anda başlasın
      await Future.wait([
        // Shorts
        (() async {
          try {
            final shorts = Get.find<ShortController>();
            await shorts.backgroundPreload().timeout(
                  Duration(seconds: onWiFi ? 4 : 2),
                  onTimeout: () {},
                );
            shorts.warmStart(
              targetCount:
                  onWiFi ? (isFirstLaunch ? 6 : 8) : (isFirstLaunch ? 3 : 4),
              maxPages: onWiFi ? 2 : 1,
            );
            _primeShortVideoSegments(shorts);
          } catch (_) {}
        })(),
        // Stories
        _forceLoadStoriesSync(
          storyController,
          limit: onWiFi ? (isFirstLaunch ? 20 : 30) : (isFirstLaunch ? 10 : 16),
        ),
        // Feed
        (() async {
          try {
            await agendaController
                .fetchAgendaBigData(initial: true)
                .timeout(const Duration(seconds: 3));
            await _ensureMinimumFeedPosts(
              agendaController,
              minPosts:
                  onWiFi ? (isFirstLaunch ? 8 : 10) : (isFirstLaunch ? 5 : 6),
              maxExtraFetch: onWiFi ? 2 : 1,
            );
            _primeFeedVideoSegments(agendaController);
          } catch (_) {}
        })(),
        // Recommended users
        (() async {
          try {
            await recommended.ensureLoaded(
              limit: onWiFi
                  ? (isFirstLaunch ? 140 : 220)
                  : (isFirstLaunch ? 80 : 120),
            );
          } catch (_) {}
        })(),
      ]);

      // Açılışta profil isim/avatar geç gelmesin: hafif metadata + avatar warmup.
      unawaited(_warmUserMetaAndAvatars(
        agendaController: agendaController,
        storyController: storyController,
        recommendedController: recommended,
        onWiFi: onWiFi,
      ));
    } catch (_) {}
  }

  void _primeShortVideoSegments(ShortController shorts) {
    try {
      if (!Get.isRegistered<PrefetchScheduler>()) return;
      final docIds = shorts.shorts
          .where((p) => p.hasPlayableVideo)
          .map((p) => p.docID)
          .where((id) => id.isNotEmpty)
          .take(12)
          .toList();
      if (docIds.isEmpty) return;
      unawaited(Get.find<PrefetchScheduler>().updateQueue(docIds, 0));
    } catch (_) {}
  }

  void _primeFeedVideoSegments(AgendaController agendaController) {
    try {
      if (!Get.isRegistered<PrefetchScheduler>()) return;
      final docIds = agendaController.agendaList
          .where((p) => p.hasPlayableVideo)
          .map((p) => p.docID)
          .where((id) => id.isNotEmpty)
          .take(15)
          .toList();
      if (docIds.isEmpty) return;
      unawaited(Get.find<PrefetchScheduler>().updateFeedQueue(docIds, 0));
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
    const timeout = Duration(milliseconds: 1000);

    try {
      await Future.any([
        _prepareMinimumStartupCore(
          isFirstLaunch: isFirstLaunch,
          onWiFi: _isOnWiFiNow(),
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

    // Kritik veriyi nav öncesi bekletme: feed ekranı erkenden açılsın.
    // Hazır olma kontrolü arka planda devam eder.
    unawaited(_waitForCriticalDataReadiness(timeout: _syncStartupMaxWait));
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
    // Paralel: cache proxy + warm start aynı anda başlasın
    await Future.wait([
      _initCacheProxy()
          .timeout(
            onWiFi ? const Duration(seconds: 3) : const Duration(seconds: 2),
            onTimeout: () {},
          )
          .catchError((_) {}),
      _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch)
          .timeout(
            onWiFi ? const Duration(seconds: 2) : const Duration(seconds: 1),
            onTimeout: () {},
          )
          .catchError((_) {}),
    ]);
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
          final pf = (doc.data()['avatarUrl'] ?? '').toString();
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
  Future<bool> _handleFirstLaunchAuthCleanup(
      {required SharedPreferences prefs}) async {
    try {
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
  /// Returns `true` when app should be locked (show maintenance).
  Future<bool> _checkLockApp({required SharedPreferences prefs}) async {
    try {
      if (kDebugMode) return false;

      // Cache'den hızlı karar — PackageInfo platform channel çağrısından ÖNCE kontrol et
      final cachedLock = prefs.getBool('lockApp_cached');
      final cachedTime = prefs.getInt('lockApp_timestamp') ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
      final cacheValid = age < const Duration(hours: 1).inMilliseconds;

      if (cachedLock != null && cacheValid) {
        // Arka planda Firestore'dan güncelle
        unawaited(_refreshLockAppCache(prefs));
        // Kalıcı güvenlik: cache'teki true tek başına lock tetiklemesin.
        // Yalnızca sunucu doğrularsa bakım ekranı aç.
        if (!cachedLock) return false;
        try {
          final doc = await _getLockConfigDoc().timeout(const Duration(
            seconds: 2,
          ));
          final bool confirmedLock = _readLockApp(doc);
          await _saveLockAppCache(prefs, confirmedLock);
          return confirmedLock;
        } catch (_) {
          await _saveLockAppCache(prefs, false);
          return false;
        }
      }

      // Cache yoksa TestFlight kontrolü yap (PackageInfo platform channel çağrısı)
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final bool isTestFlight = packageInfo.packageName.contains(".beta") ||
          packageInfo.packageName.contains("TestFlight") ||
          packageInfo.buildSignature.contains("TestFlight");
      if (isTestFlight) return false;

      // Cache yok veya eski — Firestore'dan çek (timeout ile)
      final doc = await _getLockConfigDoc().timeout(const Duration(seconds: 3),
          onTimeout: () {
        throw TimeoutException('lockApp timeout');
      });

      final bool lockApp = _readLockApp(doc);
      await _saveLockAppCache(prefs, lockApp);
      return lockApp;
    } on TimeoutException {
      // Kalıcı fail-open: timeout durumunda kullanıcıyı yanlışlıkla kilitleme.
      await _saveLockAppCache(prefs, false);
      return false;
    } catch (e) {
      print("❌ lockApp kontrolü hatası: $e");
      // Permission/network errors should not lock real users out.
      await _saveLockAppCache(prefs, false);
      return false;
    }
  }

  Future<void> _refreshLockAppCache(SharedPreferences prefs) async {
    try {
      final doc = await _getLockConfigDoc();
      final bool lockApp = _readLockApp(doc);
      await _saveLockAppCache(prefs, lockApp);
    } catch (_) {}
  }

  bool _readLockApp(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final raw = data?['lockApp'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes' || v == 'on';
    }
    // Alan eksik/bozuk ise güvenli varsayılan: uygulamayı kilitleme.
    return false;
  }

  Future<void> _saveLockAppCache(SharedPreferences prefs, bool lockApp) async {
    await prefs.setBool('lockApp_cached', lockApp);
    await prefs.setInt(
        'lockApp_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getLockConfigDoc() async {
    return FirebaseFirestore.instance
        .collection("adminConfig")
        .doc("service")
        .get();
  }

  @override
  void dispose() {
    _uiTickTimer?.cancel();
    _startupWatchdogTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheReady = _globalCacheProxyReady;
    final feedReady = _isFeedReady();
    final shortsReady = _isShortsReady();
    final storyReady = _isStoryReady();
    final readyCount = [
      cacheReady,
      feedReady,
      shortsReady,
      storyReady,
    ].where((v) => v).length;
    final progress = readyCount / 4.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FCFF),
                  Color(0xFFEFF7FF),
                  Color(0xFFF6FBF4),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: (MediaQuery.of(context).size.width * 0.56)
                  .clamp(180.0, 220.0),
              height: (MediaQuery.of(context).size.width * 0.56)
                  .clamp(180.0, 220.0),
              decoration: BoxDecoration(
                color: const Color(0xFF7BC6FF).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: Container(
              width: (MediaQuery.of(context).size.width * 0.62)
                  .clamp(190.0, 240.0),
              height: (MediaQuery.of(context).size.width * 0.62)
                  .clamp(190.0, 240.0),
              decoration: BoxDecoration(
                color: const Color(0xFF7FD8A6).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.96, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: const Text(
                      'TurqApp',
                      style: TextStyle(
                        fontFamily: 'MontserratBold',
                        fontSize: 38,
                        letterSpacing: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    progress >= 0.99
                        ? 'Hazır'
                        : 'İlk içerikler hazırlanıyor...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'MontserratMedium',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress == 0 ? null : progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00A86B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _statusRow('Feed', feedReady),
                  const SizedBox(height: 8),
                  _statusRow('Shorts', shortsReady),
                  const SizedBox(height: 8),
                  _statusRow('Cache', cacheReady),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool ready) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: ready ? const Color(0xFF00A86B) : Colors.black26,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: ready ? Colors.black87 : Colors.black45,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ],
    );
  }
}
