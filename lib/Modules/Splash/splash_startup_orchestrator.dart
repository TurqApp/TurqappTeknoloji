import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_proxy_server.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/firestore_config.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/upload_queue_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/RecommendedUserList/recommended_user_list_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/offline_mode_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import 'package:turqappv2/Core/Services/deep_link_service.dart';
import 'package:turqappv2/main.dart';

typedef SplashStartupRunner = Future<void> Function({
  required bool isFirstLaunch,
});

typedef SplashNavigationRunner = Future<void> Function();

class SplashStartupOrchestrator {
  SplashStartupOrchestrator({
    required this.firebaseStartupWait,
    required this.isMounted,
    required this.navigateToPrimaryRoute,
    required this.prepareSynchronizedStartupBeforeNav,
    required this.runCriticalWarmStartLoads,
    required this.runWarmStartLoads,
    required this.markMinimumStartupPrepared,
    required this.isMinimumStartupPrepared,
  });

  final Duration firebaseStartupWait;
  final bool Function() isMounted;
  final SplashNavigationRunner navigateToPrimaryRoute;
  final SplashStartupRunner prepareSynchronizedStartupBeforeNav;
  final SplashStartupRunner runCriticalWarmStartLoads;
  final SplashStartupRunner runWarmStartLoads;
  final void Function(bool value) markMinimumStartupPrepared;
  final bool Function() isMinimumStartupPrepared;

  static Future<void>? _globalCacheProxyInitFuture;
  static bool _globalCacheProxyReady = false;

  Future<void> initializeApp() async {
    final startupStopwatch = Stopwatch()..start();
    try {
      late final SharedPreferences prefs;
      await Future.wait([
        (() async {
          await firebaseBootstrapFuture.timeout(
            firebaseStartupWait,
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

      late final bool isFirstLaunch;
      final userService = ensureCurrentUserService();
      final accountCenter = ensureAccountCenterService();
      await accountCenter.init();

      if (Platform.isIOS) {
        isFirstLaunch = await _handleFirstLaunchAuthCleanup(prefs: prefs)
            .timeout(const Duration(milliseconds: 350), onTimeout: () => false);
        unawaited(userService.initialize());
      } else {
        await Future.wait([
          _handleFirstLaunchAuthCleanup(prefs: prefs)
              .then((v) => isFirstLaunch = v),
          userService.initialize(),
        ]);
      }

      _registerDependencies();
      if (!IntegrationTestMode.skipBackgroundStartupWork) {
        unawaited(_requestTrackingPermission());
        unawaited(_initAdMob(isFirstLaunch: isFirstLaunch));
        unawaited(
          ensureTopTagsRepository().fetchTrendingTags(
            resultLimit: 30,
            preferCache: false,
            forceRefresh: true,
          ),
        );

        if (userService.effectiveUserId.isNotEmpty) {
          unawaited(MandatoryFollowService.instance.enforceForCurrentUser());
        }
      }

      final loggedIn = userService.effectiveUserId.isNotEmpty;
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
          markMinimumStartupPrepared(true);
        } else {
          await prepareSynchronizedStartupBeforeNav(
            isFirstLaunch: isFirstLaunch,
          );
        }
      }

      if (IntegrationTestMode.skipBackgroundStartupWork) {
        return;
      }
      if (Platform.isIOS) {
        Future.delayed(const Duration(seconds: 3), () {
          unawaited(runBackgroundInit(isFirstLaunch: isFirstLaunch));
        });
      } else {
        unawaited(runBackgroundInit(isFirstLaunch: isFirstLaunch));
      }
    } catch (_, __) {}

    startupStopwatch.stop();
    if (!isMounted()) return;
    await navigateToPrimaryRoute();
  }

  Future<void> runBackgroundInit({required bool isFirstLaunch}) async {
    try {
      unawaited(_initCacheProxy());

      final loggedIn = CurrentUserService.instance.effectiveUserId.isNotEmpty;
      if (loggedIn) {
        if (!isMinimumStartupPrepared()) {
          final criticalDelay = Platform.isIOS
              ? Duration.zero
              : Duration(milliseconds: isFirstLaunch ? 250 : 600);
          if (criticalDelay == Duration.zero) {
            unawaited(runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch));
          } else {
            Future.delayed(criticalDelay, () {
              unawaited(
                runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch),
              );
            });
          }
        }

        final onWiFi = _isOnWiFiNow();
        Future.delayed(Duration(seconds: isFirstLaunch ? 5 : 8), () {
          if (onWiFi) {
            unawaited(runWarmStartLoads(isFirstLaunch: isFirstLaunch));
          }
        });
      }

      Future.delayed(const Duration(milliseconds: 900), () {
        unawaited(NotificationService.instance.initialize());
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
      final remote = ensureVideoRemoteConfigService();
      if (!remote.isReady) {
        await remote.initialize();
      }

      final server = ensureHlsProxyServer(permanent: true);
      if (!server.isStarted) {
        await server.start();
      }

      final cache = SegmentCacheManager.ensure();
      await cache.init();
      await _applyGlobalMediaCacheQuota();

      ensurePrefetchScheduler(permanent: true);
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

  Future<void> _initAdMob({required bool isFirstLaunch}) async {
    try {
      await ensureAdmobUnitConfigService().init();
      await ensureAdmobBannerWarmupService().warmFromSplash(
        isFirstLaunch: isFirstLaunch,
      );
    } catch (_) {}
  }

  void _registerDependencies() {
    Get.lazyPut(() => NetworkAwarenessService());
    Get.lazyPut(() => OfflineModeService.instance);

    GlobalLoaderController.ensure();
    ensureAdmobBannerWarmupService();
    ensureAdmobUnitConfigService(permanent: true);
    ensureStoryInteractionOptimizer();
    Get.lazyPut(() => UnreadMessagesController());
    Get.lazyPut(() => NavBarController());
    Get.lazyPut(() => ProfileController());
    if (maybeFindAgendaController() == null) {
      Get.put(AgendaController(), permanent: true);
    }
    Get.lazyPut(() => RecommendedUserListController(), fenix: true);
    Get.lazyPut(() => ExploreController());
    Get.lazyPut(() => ShortController());
    Get.lazyPut(() => EducationController());
    Get.lazyPut(() => SavedPostsController());
    Get.lazyPut(() => JobFinderController());
    Get.lazyPut(() => StoryRowController(), fenix: true);
    UploadQueueService.ensure(permanent: true);
    if (!Platform.isIOS) {
      ensureDeepLinkService();
    }
    IndexPoolStore.ensure(permanent: true);
    ensureUserProfileCacheService();
    StorageBudgetManager.ensure();
    ensurePlaybackPolicyEngine();
    ensurePlaybackKpiService();
  }

  Future<void> _requestTrackingPermission() async {
    return;
  }

  Future<bool> _handleFirstLaunchAuthCleanup({
    required SharedPreferences prefs,
  }) async {
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

  bool _isOnWiFiNow() {
    try {
      return NetworkAwarenessService.ensure().isOnWiFi;
    } catch (_) {
      return false;
    }
  }
}
