import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_proxy_server.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/profile_posts_cache_service.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';

import '../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../Core/Repositories/feed_snapshot_repository.dart';
import '../../Core/Repositories/job_home_snapshot_repository.dart';
import '../../Core/Repositories/short_snapshot_repository.dart';
import '../../Core/Services/CacheFirst/cached_resource.dart';
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
import '../../Services/user_analytics_service.dart';
import '../../Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import '../../Services/current_user_service.dart';
import '../../Services/account_center_service.dart';
import '../../Core/Services/upload_queue_service.dart';
import '../../Core/Services/firestore_config.dart';
import '../../Core/Services/network_awareness_service.dart';
import '../../Core/Services/turq_image_cache_manager.dart';
import '../../Core/Repositories/market_snapshot_repository.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../../Core/Services/video_emotion_config_service.dart';
import '../../Core/Services/mandatory_follow_service.dart';
import '../../Models/market_item_model.dart';
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
  static const String _splashWord = 'TurqApp';
  static const int _minFeedPostsForNav = 3;
  static const int _minStoryUsersForNav = 1;
  static const int _minShortsForNav = 1;

  bool _minimumStartupPrepared = false;
  bool _feedWarmSnapshotHit = false;
  bool _shortWarmSnapshotHit = false;
  String _feedWarmSnapshotSource = 'none';
  String _shortWarmSnapshotSource = 'none';
  int? _feedWarmSnapshotAgeMs;
  int? _shortWarmSnapshotAgeMs;
  static Future<void>? _globalCacheProxyInitFuture;
  static bool _globalCacheProxyReady = false;
  Timer? _startupWatchdogTimer;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _didNavigate = false;
  bool _navigationScheduled = false;
  int _typedLength = 0;
  bool _showCursor = true;
  late final Duration _remainingIntroBudget;

  Duration get _introRevealDuration => Duration(
        milliseconds: IntegrationTestMode.splashIntroMs.clamp(0, 2000),
      );

  @override
  void initState() {
    super.initState();
    final elapsedSinceLaunch = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
    );
    final remainingMs = (_introRevealDuration.inMilliseconds -
            elapsedSinceLaunch.inMilliseconds)
        .clamp(0, _introRevealDuration.inMilliseconds);
    _remainingIntroBudget = Duration(milliseconds: remainingMs);
    _startTypewriter();

    // Firebase hazır olmadan FirebasePerformance çağrısı yapılmasın.
    unawaited(_initApp());
    final watchdogDuration = IntegrationTestMode.splashWatchdogSeconds > 0
        ? Duration(seconds: IntegrationTestMode.splashWatchdogSeconds)
        : Platform.isIOS
            ? const Duration(seconds: 4)
            : const Duration(seconds: 8);
    _startupWatchdogTimer = Timer(watchdogDuration, () {
      if (!mounted || _didNavigate) return;
      _navigateToPrimaryRoute();

      // Bazı iOS anlarında ilk yönlendirme UI thread yoğunluğunda kaçabiliyor.
      // Kısa aralıklarla birkaç kez daha deneyip beyaz ekranda kalmayı engelle.
      for (final retryMs in <int>[900, 1800, 2800]) {
        Future.delayed(Duration(milliseconds: retryMs), () {
          if (!mounted || _didNavigate) return;
          _navigateToPrimaryRoute();
        });
      }
    });
  }

  Future<void> _initApp() async {
    final startupStopwatch = Stopwatch()..start();
    try {
      // Firebase + SharedPreferences + AudioContext paralel başlat
      // En yavaş olan toplam süreyi belirler (sıralı değil)
      late final SharedPreferences prefs;
      await Future.wait([
        (() async {
          await firebaseBootstrapFuture.timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
          await FirestoreConfig.initialize().timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        })(),
        SharedPreferences.getInstance().then((v) => prefs = v),
        _initAudioContext().catchError((_) {}),
      ]);

      // ⚡ Kalan işleri paralel başlat — en yavaş olan süreyi belirler
      late final bool isFirstLaunch;
      final userService = CurrentUserService.ensure();
      final accountCenter = AccountCenterService.ensure();
      await accountCenter.init();

      if (Platform.isIOS) {
        isFirstLaunch = await _handleFirstLaunchAuthCleanup(prefs: prefs)
            .timeout(const Duration(milliseconds: 350), onTimeout: () => false);
        unawaited(userService.initialize());
      } else {
        await Future.wait([
          _handleFirstLaunchAuthCleanup(prefs: prefs)
              .then((v) => isFirstLaunch = v),
          userService.initialize(), // Cache'den ~10ms, sync arka planda
        ]);
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
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final currentUser = userService.currentUser;
        if (firebaseUser != null && currentUser != null) {
          unawaited(accountCenter.addCurrentAccount(
            currentUser: currentUser,
            firebaseUser: firebaseUser,
          ));
        }
        if (IntegrationTestMode.deterministicStartup) {
          _minimumStartupPrepared = true;
        } else if (Platform.isIOS) {
          // iOS USB/wireless launch senaryolarinda ilk acilista
          // warm-start ve medya/cache hazirligi jetsam/watchdog riskini artiriyor.
          // Navigasyonu hemen ac; agir hazirliklari sonrasina birak.
          _minimumStartupPrepared = true;
        } else {
          await Future.any([
            _prepareSynchronizedStartupBeforeNav(isFirstLaunch: isFirstLaunch),
            Future.delayed(const Duration(milliseconds: 700)),
          ]);
        }
      }

      // 🚀 Ağır işleri arka plana at — navigasyonu BLOKLAMA
      if (IntegrationTestMode.skipBackgroundStartupWork) {
        return;
      }
      if (Platform.isIOS) {
        Future.delayed(const Duration(seconds: 3), () {
          unawaited(_backgroundInit(isFirstLaunch: isFirstLaunch));
        });
      } else {
        unawaited(_backgroundInit(isFirstLaunch: isFirstLaunch));
      }
    } catch (_, __) {}

    if (!mounted) return;
    startupStopwatch.stop();
    _navigateToPrimaryRoute();
  }

  Future<void> _navigateToPrimaryRoute() async {
    if (!mounted || _didNavigate || _navigationScheduled) return;
    _navigationScheduled = true;

    final elapsed = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
    );
    final remaining = _introRevealDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (!mounted || _didNavigate) return;

    bool loggedIn = false;
    try {
      loggedIn = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      loggedIn = false;
    }
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi != null) {
      playbackKpi.track(
        PlaybackKpiEventType.startup,
        {
          'launchToRouteMs':
              DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
          'loggedIn': loggedIn,
          'minimumStartupPrepared': _minimumStartupPrepared,
          'feedWarmSnapshotHit': _feedWarmSnapshotHit,
          'feedWarmSnapshotSource': _feedWarmSnapshotSource,
          'feedWarmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
          'shortWarmSnapshotHit': _shortWarmSnapshotHit,
          'shortWarmSnapshotSource': _shortWarmSnapshotSource,
          'shortWarmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
        },
      );
      if (loggedIn) {
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'feed',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'feed_',
            ),
            renderDiff: playbackKpi.summarizeRenderDiff(surface: 'feed'),
            playbackWindow: playbackKpi.summarizePlaybackWindow(
              surface: 'feed',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
              'warmSnapshotHit': _feedWarmSnapshotHit,
              'warmSnapshotSource': _feedWarmSnapshotSource,
              'warmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
            },
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'short',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'short_',
            ),
            renderDiff: playbackKpi.summarizeRenderDiff(surface: 'short'),
            playbackWindow: playbackKpi.summarizePlaybackWindow(
              surface: 'short',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
              'warmSnapshotHit': _shortWarmSnapshotHit,
              'warmSnapshotSource': _shortWarmSnapshotSource,
              'warmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
            },
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'market',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'market_',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
            },
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'jobs',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'jobs_',
            ),
            extra: <String, dynamic>{
              'launchToRouteMs':
                  DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs,
            },
          ),
        );
      }
    }
    _didNavigate = true;
    if (loggedIn) {
      NavBarController.maybeFind()?.selectedIndex.value = 0;
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
      final remote = VideoRemoteConfigService.ensure();
      if (!remote.isReady) {
        await remote.initialize();
      }

      final server = HLSProxyServer.ensure(permanent: true);
      if (!server.isStarted) {
        await server.start();
      }

      final cache = SegmentCacheManager.ensure();
      await cache.init();
      await _applyGlobalMediaCacheQuota();

      PrefetchScheduler.ensure(permanent: true);
      _globalCacheProxyReady = true;
    } catch (_) {
      _globalCacheProxyReady = false;
    } finally {
      _globalCacheProxyInitFuture = null;
    }
  }

  Future<void> _applyGlobalMediaCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGb = (prefs.getInt('offline_cache_quota_gb') ?? 3).clamp(3, 6);
      final quotaGb = (savedGb + 1).clamp(4, 7);
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      final cache = SegmentCacheManager.maybeFind();
      if (cache == null) return;
      await cache.setUserLimitGB(quotaGb);
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
      await AdmobBannerWarmupService.ensure().warmFromSplash(
        isFirstLaunch:
            targetCount >= AdmobBannerWarmupService.splashFirstLaunchTarget,
      );
    } catch (_) {}
  }

  void _registerDependencies() {
    // Network & Offline servisleri — lazy: ilk erişimde init olur, navigasyonu bloklamaz
    Get.lazyPut(() => NetworkAwarenessService());
    Get.lazyPut(() => OfflineModeService.instance);

    GlobalLoaderController.ensure();
    AdmobBannerWarmupService.ensure();
    StoryInteractionOptimizer.ensure();
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
    UploadQueueService.ensure(permanent: true);
    if (!Platform.isIOS) {
      DeepLinkService.ensure();
    }
    IndexPoolStore.ensure(permanent: true);
    UserProfileCacheService.ensure();
    StorageBudgetManager.ensure();
    PlaybackPolicyEngine.ensure();
    PlaybackKpiService.ensure();
  }

  Future<void> _runCriticalWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final bool onWiFi = _isOnWiFiNow();
      final storyController = StoryRowController.maybeFind();
      if (storyController == null) return;
      final agendaController = AgendaController.ensure();

      // Paralel: shorts + story + feed + recommended aynı anda başlasın
      await Future.wait([
        // Shorts
        (() async {
          try {
            final shorts = ShortController.maybeFind();
            if (shorts == null) return;
            await _warmShortSnapshotForStartup(
              onWiFi: onWiFi,
              isFirstLaunch: isFirstLaunch,
            );
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
            await _warmFeedSnapshotForStartup(
              onWiFi: onWiFi,
              isFirstLaunch: isFirstLaunch,
            );
            await agendaController
                .ensureInitialFeedLoaded()
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
        // Market / Mabil Pazar
        (() async {
          try {
            await _warmMarketListings(onWiFi: onWiFi).timeout(
              Duration(milliseconds: onWiFi ? 1400 : 900),
              onTimeout: () {},
            );
          } catch (_) {}
        })(),
        // Jobs / Is Veren
        (() async {
          try {
            await _warmJobListings(onWiFi: onWiFi).timeout(
              Duration(milliseconds: onWiFi ? 1400 : 900),
              onTimeout: () {},
            );
          } catch (_) {}
        })(),
      ]);

      unawaited(() async {
        try {
          final recommended = RecommendedUserListController.ensure();
          await recommended.ensureLoaded(
            limit: onWiFi
                ? (isFirstLaunch ? 140 : 220)
                : (isFirstLaunch ? 80 : 120),
          );
        } catch (_) {}
      }());

      // Açılışta profil isim/avatar geç gelmesin: feed'e düşmeden önce
      // merkezi profile cache ve disk image cache'i ısıt.
      unawaited(
        _warmUserMetaAndAvatars(
          agendaController: agendaController,
          storyController: storyController,
          recommendedController: null,
          onWiFi: onWiFi,
        ).timeout(
          Duration(milliseconds: onWiFi ? 900 : 500),
          onTimeout: () {},
        ),
      );
      unawaited(
        _warmProfileCacheSurfaces(onWiFi: onWiFi).timeout(
          Duration(milliseconds: onWiFi ? 900 : 500),
          onTimeout: () {},
        ),
      );
      unawaited(
        _warmSliderCaches(onWiFi: onWiFi).timeout(
          Duration(milliseconds: onWiFi ? 1200 : 650),
          onTimeout: () {},
        ),
      );
    } catch (_) {}
  }

  void _primeShortVideoSegments(ShortController shorts) {
    try {
      final prefetch = PrefetchScheduler.maybeFind();
      if (prefetch == null) return;
      final docIds = shorts.shorts
          .where((p) => p.hasPlayableVideo)
          .map((p) => p.docID)
          .where((id) => id.isNotEmpty)
          .take(12)
          .toList();
      if (docIds.isEmpty) return;
      unawaited(prefetch.updateQueue(docIds, 0));
    } catch (_) {}
  }

  void _primeFeedVideoSegments(AgendaController agendaController) {
    try {
      final prefetch = PrefetchScheduler.maybeFind();
      if (prefetch == null) return;
      final docIds = agendaController.agendaList
          .where((p) => p.hasPlayableVideo)
          .map((p) => p.docID)
          .where((id) => id.isNotEmpty)
          .take(15)
          .toList();
      if (docIds.isEmpty) return;
      unawaited(prefetch.updateFeedQueue(docIds, 0));
    } catch (_) {}
  }

  Future<void> _runWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final bool onWiFi = _isOnWiFiNow();
      final storyController = StoryRowController.maybeFind();
      if (storyController == null) return;
      final shortTarget =
          onWiFi ? (isFirstLaunch ? 8 : 10) : (isFirstLaunch ? 4 : 6);
      final storyTarget = onWiFi ? 30 : 18;

      // Shorts tarafında çok hafif ısınma yap.
      try {
        final shorts = ShortController.maybeFind();
        if (shorts != null && shorts.shorts.length < shortTarget) {
          shorts.warmStart(
            targetCount: shortTarget,
            maxPages: onWiFi ? 2 : 1,
          );
        }
      } catch (_) {}

      // Post + toplu kullanıcı preload bu fazda kapalı.
      // Sadece story tarafını hafif şekilde hazırla.
      if (storyController.users.length < storyTarget) {
        await _forceLoadStoriesSync(storyController, limit: storyTarget);
      }
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
    await Future.wait([
      _prepareMinimumStartupBeforeNav(isFirstLaunch: isFirstLaunch),
      _ensureMinSplashDuration(),
    ]);

    // Kritik veriyi nav öncesi bekletme: feed ekranı erkenden açılsın.
    // Hazır olma kontrolü arka planda devam eder.
    unawaited(_waitForCriticalDataReadiness(timeout: _syncStartupMaxWait));
    await _ensureMinLaunchToNavDuration();
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
  }

  bool _isFeedReady() {
    return (AgendaController.maybeFind()?.agendaList.length ?? 0) >=
        _minFeedPostsForNav;
  }

  bool _isStoryReady() {
    final storyController = StoryRowController.maybeFind();
    if (storyController == null) return false;
    return storyController.users.length >= _minStoryUsersForNav;
  }

  bool _isShortsReady() {
    return (ShortController.maybeFind()?.shorts.length ?? 0) >=
        _minShortsForNav;
  }

  Future<void> _prepareMinimumStartupCore({
    required bool isFirstLaunch,
    required bool onWiFi,
  }) async {
    // Cache proxy navigasyonu bloklamasın; warm start öncelikli kalsın.
    unawaited(
      _initCacheProxy()
          .timeout(
            onWiFi ? const Duration(seconds: 3) : const Duration(seconds: 2),
            onTimeout: () {},
          )
          .catchError((_) {}),
    );
    await _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch)
        .timeout(
          onWiFi ? const Duration(seconds: 2) : const Duration(seconds: 1),
          onTimeout: () {},
        )
        .catchError((_) {});
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
      return NetworkAwarenessService.ensure().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  Future<void> _warmMarketListings({required bool onWiFi}) async {
    try {
      final warmLimit = onWiFi ? 18 : 10;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final cached = await MarketSnapshotRepository.ensure()
          .openHome(
            userId: userId,
            limit: warmLimit,
          )
          .first;
      _trackStartupSnapshot(
        surface: 'market',
        resource: cached,
        itemCount: (cached.data ?? const <MarketItemModel>[]).length,
      );
      final cachedItems = cached.data ?? const <MarketItemModel>[];

      // Minimum sıcak başlangıç hedefi: en az 10 aktif ilan.
      if (cachedItems.where((item) => item.status == 'active').length >= 10) {
        return;
      }

      await MarketSnapshotRepository.ensure().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmJobListings({required bool onWiFi}) async {
    try {
      final warmLimit = onWiFi ? 18 : 10;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final cached = await JobHomeSnapshotRepository.ensure()
          .openHome(
            userId: userId,
            limit: warmLimit,
          )
          .first;
      _trackStartupSnapshot(
        surface: 'jobs',
        resource: cached,
        itemCount: (cached.data ?? const <dynamic>[]).length,
      );
      final cachedItems = cached.data ?? const <dynamic>[];

      if (cachedItems.length >= 10) {
        return;
      }

      await JobHomeSnapshotRepository.ensure().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmFeedSnapshotForStartup({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return;
      final warmLimit =
          onWiFi ? (isFirstLaunch ? 8 : 10) : (isFirstLaunch ? 5 : 6);
      final snapshot = await FeedSnapshotRepository.ensure().bootstrapHome(
        userId: userId,
        limit: warmLimit,
      );
      _feedWarmSnapshotHit = snapshot.hasLocalSnapshot;
      _feedWarmSnapshotSource = snapshot.source.name;
      _feedWarmSnapshotAgeMs = snapshot.snapshotAt == null
          ? null
          : DateTime.now().difference(snapshot.snapshotAt!).inMilliseconds;
      _trackStartupSnapshot(
        surface: 'feed',
        resource: snapshot,
        itemCount: (snapshot.data ?? const <dynamic>[]).length,
      );
    } catch (_) {}
  }

  Future<void> _warmShortSnapshotForStartup({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return;
      final warmLimit =
          onWiFi ? (isFirstLaunch ? 6 : 8) : (isFirstLaunch ? 3 : 4);
      final snapshot = await ShortSnapshotRepository.ensure().bootstrapHome(
        userId: userId,
        limit: warmLimit,
      );
      _shortWarmSnapshotHit = snapshot.hasLocalSnapshot;
      _shortWarmSnapshotSource = snapshot.source.name;
      _shortWarmSnapshotAgeMs = snapshot.snapshotAt == null
          ? null
          : DateTime.now().difference(snapshot.snapshotAt!).inMilliseconds;
      _trackStartupSnapshot(
        surface: 'short',
        resource: snapshot,
        itemCount: (snapshot.data ?? const <dynamic>[]).length,
      );
    } catch (_) {}
  }

  void _trackStartupSnapshot<T>({
    required String surface,
    required CachedResource<T> resource,
    required int itemCount,
  }) {
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi == null) return;
    playbackKpi.track(
      PlaybackKpiEventType.startup,
      <String, dynamic>{
        'surface': surface,
        'hasLocalSnapshot': resource.hasLocalSnapshot,
        'source': resource.source.name,
        'isStale': resource.isStale,
        'snapshotAgeMs': resource.snapshotAt == null
            ? null
            : DateTime.now().difference(resource.snapshotAt!).inMilliseconds,
        'itemCount': itemCount,
      },
    );
  }

  Future<void> _warmUserMetaAndAvatars({
    required AgendaController agendaController,
    required StoryRowController storyController,
    RecommendedUserListController? recommendedController,
    required bool onWiFi,
  }) async {
    try {
      final Set<String> userIds = {};
      final currentUid = CurrentUserService.instance.userId.trim();
      if (currentUid.isNotEmpty) {
        userIds.add(currentUid);
      }

      final int feedTake = onWiFi ? 28 : 14;
      final int storyTake = onWiFi ? 18 : 10;
      final int recommendedTake = onWiFi ? 18 : 10;

      for (final post in agendaController.agendaList.take(feedTake)) {
        userIds.add(post.userID);
        if (post.originalUserID.isNotEmpty) {
          userIds.add(post.originalUserID);
        }
      }
      for (final user in storyController.users.take(storyTake)) {
        userIds.add(user.userID);
      }
      if (recommendedController != null) {
        for (final user in recommendedController.list.take(recommendedTake)) {
          userIds.add(user.userID);
        }
      }

      if (userIds.isEmpty) return;

      final userCache = UserProfileCacheService.ensure();
      final profiles = await userCache.getProfiles(
        userIds.toList(),
        preferCache: true,
      );

      final avatarUrls = <String>[];
      for (final uid in userIds) {
        final url = (profiles[uid]?['avatarUrl'] ?? '').toString().trim();
        if (url.isNotEmpty) avatarUrls.add(url);
      }

      final int warmCount = onWiFi ? 36 : 12;
      for (final url in avatarUrls.take(warmCount)) {
        try {
          await TurqImageCacheManager.instance.getSingleFile(url);
          final provider = CachedNetworkImageProvider(
            url,
            cacheManager: TurqImageCacheManager.instance,
          );
          if (mounted) {
            await precacheImage(provider, context);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _warmProfileCacheSurfaces({required bool onWiFi}) async {
    try {
      final uid = CurrentUserService.instance.userId.trim();
      if (uid.isEmpty) return;

      final urls = <String>{};
      final avatarUrl = CurrentUserService.instance.avatarUrl.trim();
      if (avatarUrl.isNotEmpty) {
        urls.add(avatarUrl);
        try {
          await TurqImageCacheManager.instance.getSingleFile(avatarUrl);
          if (mounted) {
            await precacheImage(
              CachedNetworkImageProvider(
                avatarUrl,
                cacheManager: TurqImageCacheManager.instance,
              ),
              context,
            );
          }
        } catch (_) {}
      }

      final cache = ProfilePostsCacheService();
      final buckets = await Future.wait([
        cache.readBucket(uid: uid, bucket: 'all'),
        cache.readBucket(uid: uid, bucket: 'photos'),
        cache.readBucket(uid: uid, bucket: 'videos'),
        cache.readBucket(uid: uid, bucket: 'scheduled'),
      ]);

      for (final bucket in buckets) {
        for (final post in bucket.take(onWiFi ? 18 : 10)) {
          if (post.thumbnail.trim().isNotEmpty) {
            urls.add(post.thumbnail.trim());
          }
          for (final img in post.img.take(2)) {
            final normalized = img.trim();
            if (normalized.isNotEmpty) {
              urls.add(normalized);
            }
          }
        }
      }

      for (final url
          in urls.where((e) => e.isNotEmpty).take(onWiFi ? 40 : 20)) {
        try {
          await TurqImageCacheManager.instance.getSingleFile(url);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _warmSliderCaches({required bool onWiFi}) async {
    try {
      const sliderIds = <String>[
        'is_bul',
        'online_sinav',
        'cevap_anahtari',
        'ozel_ders',
        'denemeler',
      ];
      final cache = SliderCacheService();

      for (final sliderId in sliderIds) {
        final snapshot = await cache.readSnapshot(sliderId);
        if (snapshot.hasItems) {
          for (final url in snapshot.items
              .where((e) => e.startsWith('http'))
              .take(onWiFi ? 8 : 4)) {
            try {
              await TurqImageCacheManager.instance.getSingleFile(url);
            } catch (_) {}
          }
          if (snapshot.isFresh) {
            continue;
          }
        }

        final resolved = await cache.refreshAndCacheSources(
          sliderId,
          warmRemoteLimit: onWiFi ? 8 : 4,
        );
        if (resolved.isEmpty) continue;
      }
    } catch (_) {}
  }

  Future<void> _forceLoadStoriesSync(StoryRowController storyController,
      {int limit = 30}) async {
    try {
      if (storyController.users.length >= limit ||
          storyController.isLoading.value) {
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
        return;
      }
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
    // iOS launch hattinda native plugin register crash'ini engellemek icin
    // tracking izni istegini gecici olarak devre disi birakiyoruz.
    return;
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
        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Clear CurrentUserService cache
        await CurrentUserService.instance.logout();
        await AccountCenterService.ensure().signOutAllLocal();
      }

      // Mark that app has launched before
      if (!hasLaunchedBefore) {
        await prefs.setBool(firstLaunchKey, true);
      }
      return isFirstLaunch;
    } catch (_) {
      // If error occurs, fail safe by signing out
      try {
        await FirebaseAuth.instance.signOut();
        await CurrentUserService.instance.logout();
        await AccountCenterService.ensure().signOutAllLocal();
      } catch (_) {}
      return true;
    }
  }

  @override
  void dispose() {
    _startupWatchdogTimer?.cancel();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    if (_remainingIntroBudget <= Duration.zero) {
      _typedLength = _splashWord.length;
      _showCursor = false;
      return;
    }

    _typedLength = 1;
    final remainingChars =
        (_splashWord.length - 1).clamp(0, _splashWord.length);
    if (remainingChars == 0) {
      _showCursor = false;
      return;
    }

    final stepMs = (_remainingIntroBudget.inMilliseconds / _splashWord.length)
        .round()
        .clamp(1, 1000);

    _typingTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _splashWord.length) {
        _showCursor = false;
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _typedLength += 1;
      });
    });

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedLength >= _splashWord.length) {
        _showCursor = false;
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _splashWord.substring(
                      0,
                      _typedLength.clamp(0, _splashWord.length),
                    ),
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontFamily: 'Noe',
                      fontSize: 100,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedOpacity(
                    opacity: _showCursor ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: 3,
                      height: 84,
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
