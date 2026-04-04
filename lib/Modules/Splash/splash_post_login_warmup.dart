import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Runtime/feature_runtime_services.dart';
import 'package:turqappv2/Runtime/startup_session_failure.dart';
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
    String Function()? currentSignedInUserId,
    bool Function()? skipBackgroundStartupWork,
    bool Function()? isIOS,
    StartupSessionFailureReporter? failureReporter,
  })  : _initializeAdMob = initializeAdMob ?? _defaultInitializeAdMob,
        _fetchTrendingTags = fetchTrendingTags ?? _defaultFetchTrendingTags,
        _enforceMandatoryFollow =
            enforceMandatoryFollow ?? _defaultEnforceMandatoryFollow,
        _initializeNotifications =
            initializeNotifications ?? _defaultInitializeNotifications,
        _isOnWiFiNow = isOnWiFiNow ?? _defaultIsOnWiFiNow,
        _currentSignedInUserIdProvider =
            currentSignedInUserId ?? _defaultCurrentSignedInUserId,
        _skipBackgroundStartupWork = skipBackgroundStartupWork ??
            (() => IntegrationTestMode.skipBackgroundStartupWork),
        _isIOS = isIOS ?? (() => Platform.isIOS),
        _failureReporter =
            failureReporter ?? StartupSessionFailureReporter.defaultReporter;

  final WarmupRunner runCriticalWarmStartLoads;
  final WarmupRunner runWarmStartLoads;
  final bool Function() isMinimumStartupPrepared;
  final Future<void> Function({required bool isFirstLaunch}) _initializeAdMob;
  final Future<void> Function() _fetchTrendingTags;
  final Future<void> Function() _enforceMandatoryFollow;
  final Future<void> Function() _initializeNotifications;
  final bool Function() _isOnWiFiNow;
  final String Function() _currentSignedInUserIdProvider;
  final bool Function() _skipBackgroundStartupWork;
  final bool Function() _isIOS;
  final StartupSessionFailureReporter _failureReporter;

  static Future<void>? _globalCacheProxyInitFuture;
  static bool _globalCacheProxyReady = false;
  static bool _globalCacheProxyUnavailable = false;

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
        Future.delayed(
          Duration(
            milliseconds:
                isFirstLaunch ? (onWiFi ? 900 : 1200) : (onWiFi ? 1400 : 1800),
          ),
          () {
            unawaited(runWarmStartLoads(isFirstLaunch: isFirstLaunch));
          },
        );
      }

      Future.delayed(const Duration(milliseconds: 900), () {
        unawaited(_initializeNotifications());
      });
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.backgroundWarmup,
        operation: 'PostLoginWarmup.runBackgroundInit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _initCacheProxy() async {
    if (_globalCacheProxyReady || _globalCacheProxyUnavailable) return;
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

      final cache = SegmentCacheManager.ensure();
      await cache.init();
      await _applyGlobalMediaCacheQuota();

      ensurePrefetchScheduler(permanent: true);
      final server = ensureHlsProxyServer(permanent: true);
      if (!server.isStarted) {
        await server.start();
      }
      _globalCacheProxyReady = true;
      _globalCacheProxyUnavailable = false;
    } catch (error, stackTrace) {
      if (_shouldDisableCacheProxyForSession(error)) {
        _globalCacheProxyUnavailable = true;
        debugPrint(
          '[cache-proxy] disabled for this session: $error',
        );
      }
      _failureReporter.record(
        kind: StartupSessionFailureKind.cacheProxyInitialization,
        operation: 'PostLoginWarmup.initCacheProxy',
        error: error,
        stackTrace: stackTrace,
      );
      _globalCacheProxyReady = false;
    } finally {
      _globalCacheProxyInitFuture = null;
    }
  }

  bool _shouldDisableCacheProxyForSession(Object error) {
    if (!_isIOS() || !kDebugMode) {
      return false;
    }
    final text = error.toString().toLowerCase();
    return text.contains('dobjc_initializeapi') ||
        text.contains("objective_c.framework/objective_c") ||
        text.contains('target native_assets required define sdkroot') ||
        text.contains('failed to load dynamic library');
  }

  Future<void> _applyGlobalMediaCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotaGb = normalizeStorageBudgetPlanGb(
        prefs.getInt('offline_cache_quota_gb') ?? 3,
      );
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      final cache = SegmentCacheManager.maybeFind();
      if (cache == null) return;
      await cache.setUserLimitGB(quotaGb);
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.mediaCacheQuota,
        operation: 'PostLoginWarmup.applyGlobalMediaCacheQuota',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _hasSignedInUser() {
    try {
      return _currentSignedInUserId().isNotEmpty;
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.authStateRestore,
        operation: 'PostLoginWarmup.hasSignedInUser',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String _currentSignedInUserId() {
    return _currentSignedInUserIdProvider();
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
      resultLimit: ReadBudgetRegistry.exploreTrendingTagsLimit,
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

  static String _defaultCurrentSignedInUserId() {
    return CurrentUserService.instance.effectiveUserId;
  }

  static bool _defaultIsOnWiFiNow() {
    try {
      return const NetworkRuntimeService().isOnWiFi;
    } catch (error, stackTrace) {
      StartupSessionFailureReporter.defaultReporter.record(
        kind: StartupSessionFailureKind.backgroundWarmup,
        operation: 'PostLoginWarmup.isOnWiFiNow',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _requestTrackingPermission() async {
    return;
  }
}
