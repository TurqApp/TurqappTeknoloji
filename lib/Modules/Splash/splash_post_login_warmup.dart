import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_proxy_server.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/mandatory_follow_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

typedef WarmupRunner = Future<void> Function({required bool isFirstLaunch});

class PostLoginWarmup {
  PostLoginWarmup({
    required this.runCriticalWarmStartLoads,
    required this.runWarmStartLoads,
    required this.isMinimumStartupPrepared,
    Future<void> Function({required bool isFirstLaunch})? initializeAdMob,
    Future<void> Function()? fetchTrendingTags,
    Future<void> Function()? enforceMandatoryFollow,
    Future<void> Function()? initializeNotifications,
    bool Function()? isOnWiFiNow,
    bool Function()? skipBackgroundStartupWork,
    bool Function()? isIOS,
  })  : _initializeAdMob = initializeAdMob ?? _defaultInitializeAdMob,
        _fetchTrendingTags = fetchTrendingTags ?? _defaultFetchTrendingTags,
        _enforceMandatoryFollow =
            enforceMandatoryFollow ?? _defaultEnforceMandatoryFollow,
        _initializeNotifications =
            initializeNotifications ?? _defaultInitializeNotifications,
        _isOnWiFiNow = isOnWiFiNow ?? _defaultIsOnWiFiNow,
        _skipBackgroundStartupWork =
            skipBackgroundStartupWork ??
                (() => IntegrationTestMode.skipBackgroundStartupWork),
        _isIOS = isIOS ?? (() => Platform.isIOS);

  final WarmupRunner runCriticalWarmStartLoads;
  final WarmupRunner runWarmStartLoads;
  final bool Function() isMinimumStartupPrepared;
  final Future<void> Function({required bool isFirstLaunch}) _initializeAdMob;
  final Future<void> Function() _fetchTrendingTags;
  final Future<void> Function() _enforceMandatoryFollow;
  final Future<void> Function() _initializeNotifications;
  final bool Function() _isOnWiFiNow;
  final bool Function() _skipBackgroundStartupWork;
  final bool Function() _isIOS;

  static Future<void>? _globalCacheProxyInitFuture;
  static bool _globalCacheProxyReady = false;

  void startNonBlockingStartupWork({
    required bool isFirstLaunch,
    required String effectiveUserId,
  }) {
    if (_skipBackgroundStartupWork()) {
      return;
    }

    unawaited(_requestTrackingPermission());
    unawaited(_initializeAdMob(isFirstLaunch: isFirstLaunch));
    unawaited(_fetchTrendingTags());

    if (effectiveUserId.isNotEmpty) {
      unawaited(_enforceMandatoryFollow());
    }
  }

  void scheduleBackgroundInit({required bool isFirstLaunch}) {
    if (_skipBackgroundStartupWork()) {
      return;
    }
    if (_isIOS()) {
      Future.delayed(const Duration(seconds: 3), () {
        unawaited(runBackgroundInit(isFirstLaunch: isFirstLaunch));
      });
      return;
    }
    unawaited(runBackgroundInit(isFirstLaunch: isFirstLaunch));
  }

  Future<void> initCacheProxy() => _initCacheProxy();

  Future<void> runBackgroundInit({required bool isFirstLaunch}) async {
    try {
      unawaited(_initCacheProxy());

      final hasUser = _hasSignedInUser();
      if (hasUser) {
        if (!isMinimumStartupPrepared()) {
          final criticalDelay = _isIOS()
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
        unawaited(_initializeNotifications());
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

  bool _hasSignedInUser() {
    try {
      return _currentSignedInUserId().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _currentSignedInUserId() {
    return CurrentUserService.instance.effectiveUserId;
  }

  static Future<void> _defaultInitializeAdMob({
    required bool isFirstLaunch,
  }) async {
    await ensureAdmobUnitConfigService().init();
    await ensureAdmobBannerWarmupService().warmFromSplash(
      isFirstLaunch: isFirstLaunch,
    );
  }

  static Future<void> _defaultFetchTrendingTags() async {
    await ensureTopTagsRepository().fetchTrendingTags(
      resultLimit: 30,
      preferCache: false,
      forceRefresh: true,
    );
  }

  static Future<void> _defaultEnforceMandatoryFollow() async {
    await MandatoryFollowService.instance.enforceForCurrentUser();
  }

  static Future<void> _defaultInitializeNotifications() async {
    await NotificationService.instance.initialize();
  }

  static bool _defaultIsOnWiFiNow() {
    try {
      return NetworkAwarenessService.ensure().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestTrackingPermission() async {
    return;
  }
}
