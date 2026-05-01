import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/notification_service.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
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
import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';
import 'package:turqappv2/Core/Repositories/short_manifest_repository.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
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
  Future<void>? _backgroundInitFuture;

  void startNonBlockingStartupWork({
    required bool isFirstLaunch,
    required String effectiveUserId,
  }) {
    if (_skipBackgroundStartupWork()) {
      return;
    }

    unawaited(_requestTrackingPermission());
    unawaited(_fetchTrendingTags());

    if (effectiveUserId.isNotEmpty) {
      unawaited(_enforceMandatoryFollow());
    }
  }

  void scheduleBackgroundInit({required bool isFirstLaunch}) {
    if (_skipBackgroundStartupWork()) {
      return;
    }
    debugPrint(
      '[StartupWarmGuest] status=schedule isFirstLaunch=$isFirstLaunch',
    );
    unawaited(runBackgroundInit(isFirstLaunch: isFirstLaunch));
  }

  Future<void> initCacheProxy() => _initCacheProxy();

  Future<void> runBackgroundInit({required bool isFirstLaunch}) async {
    final existing = _backgroundInitFuture;
    if (existing != null) {
      debugPrint(
        '[StartupWarmGuest] status=join_existing isFirstLaunch=$isFirstLaunch',
      );
      return existing;
    }
    final future = _runBackgroundInitInternal(isFirstLaunch: isFirstLaunch);
    _backgroundInitFuture = future;
    return future.whenComplete(() {
      if (identical(_backgroundInitFuture, future)) {
        _backgroundInitFuture = null;
      }
    });
  }

  Future<void> _runBackgroundInitInternal({
    required bool isFirstLaunch,
  }) async {
    debugPrint(
      '[StartupWarmGuest] status=begin isFirstLaunch=$isFirstLaunch',
    );
    try {
      final onWiFi = _isOnWiFiNow();
      final cacheProxyDelay = _cacheProxyInitDelay(
        isFirstLaunch: isFirstLaunch,
        onWiFi: onWiFi,
      );
      if (cacheProxyDelay == Duration.zero) {
        unawaited(_initCacheProxy());
      } else {
        Future.delayed(cacheProxyDelay, () {
          unawaited(_initCacheProxy());
        });
      }

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

        Future.delayed(
          Duration(
            milliseconds:
                isFirstLaunch ? (onWiFi ? 900 : 1200) : (onWiFi ? 1400 : 1800),
          ),
          () {
            unawaited(runWarmStartLoads(isFirstLaunch: isFirstLaunch));
          },
        );
      } else {
        const guestManifestDelay = Duration.zero;
        Future.delayed(guestManifestDelay, () {
          if (_skipBackgroundStartupWork()) return;
          unawaited(
            _warmGuestStartupManifests(onWiFi: onWiFi),
          );
        });
      }

      _scheduleNotificationInitWhenStartupReady(
        isFirstLaunch: isFirstLaunch,
      );

      final admobDelay = Duration(
        milliseconds:
            isFirstLaunch ? (onWiFi ? 2200 : 2600) : (onWiFi ? 2800 : 3200),
      );
      _scheduleAdmobInitWhenStartupReady(
        isFirstLaunch: isFirstLaunch,
        initialDelay: admobDelay,
      );
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.backgroundWarmup,
        operation: 'PostLoginWarmup.runBackgroundInit',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      debugPrint(
        '[StartupWarmGuest] status=finish isFirstLaunch=$isFirstLaunch',
      );
    }
  }

  void _scheduleAdmobInitWhenStartupReady({
    required bool isFirstLaunch,
    required Duration initialDelay,
  }) {
    void scheduleAttempt({int attemptIndex = 0}) {
      final delay =
          attemptIndex == 0 ? initialDelay : const Duration(milliseconds: 900);
      Future.delayed(delay, () {
        if (_skipBackgroundStartupWork()) {
          return;
        }
        final agenda = maybeFindAgendaController();
        final prefetch = maybeFindPrefetchScheduler();
        final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
        final feedRendered = agenda?.renderFeedEntries.isNotEmpty ?? false;
        final startupReady = feedRendered &&
            prefetch != null &&
            prefetch.feedReadyCount >= readyThreshold;
        if (!startupReady) {
          if (attemptIndex < 12) {
            scheduleAttempt(attemptIndex: attemptIndex + 1);
          }
          return;
        }
        unawaited(_initializeAdMob(isFirstLaunch: isFirstLaunch));
      });
    }

    scheduleAttempt();
  }

  void _scheduleNotificationInitWhenStartupReady({
    required bool isFirstLaunch,
  }) {
    void scheduleAttempt({int attemptIndex = 0}) {
      final delay = attemptIndex == 0
          ? Duration(milliseconds: isFirstLaunch ? 2400 : 1800)
          : const Duration(milliseconds: 900);
      Future.delayed(delay, () {
        if (_skipBackgroundStartupWork()) return;
        if (!isMinimumStartupPrepared()) {
          if (attemptIndex < 8) {
            scheduleAttempt(attemptIndex: attemptIndex + 1);
          }
          return;
        }
        unawaited(_initializeNotifications());
      });
    }

    scheduleAttempt();
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

  Duration _cacheProxyInitDelay({
    required bool isFirstLaunch,
    required bool onWiFi,
  }) {
    if (_isIOS()) {
      return Duration.zero;
    }
    return Duration(
      milliseconds:
          isFirstLaunch ? (onWiFi ? 1200 : 1500) : (onWiFi ? 900 : 1200),
    );
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
      final preferences = ensureLocalPreferenceRepository();
      final quotaGb = normalizeStorageBudgetPlanGb(
        await preferences.getInt('offline_cache_quota_gb') ?? 3,
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

  Future<void> _warmGuestStartupManifests({
    required bool onWiFi,
  }) async {
    try {
      Future<void> runStep(
        String label,
        Future<void> Function() action,
      ) async {
        final startedAt = DateTime.now();
        debugPrint('[StartupWarmGuest] status=start label=$label onWiFi=$onWiFi');
        try {
          await action();
          debugPrint(
            '[StartupWarmGuest] status=refresh_ok label=$label '
            'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
          );
        } catch (error) {
          debugPrint(
            '[StartupWarmGuest] status=refresh_fail label=$label '
            'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
            'error=$error',
          );
          rethrow;
        }
      }

      Future<void> runFloodStep() async {
        final startedAt = DateTime.now();
        debugPrint('[StartupWarmGuest] status=start label=flood_manifest onWiFi=$onWiFi');
        try {
          final roots = await ExploreRepository.ensure().ensureFloodManifestStoreReady();
          if (roots <= 0) {
            throw StateError('flood_manifest_empty');
          }
          debugPrint(
            '[StartupWarmGuest] status=refresh_ok label=flood_manifest '
            'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} roots=$roots',
          );
        } catch (error) {
          debugPrint(
            '[StartupWarmGuest] status=refresh_fail label=flood_manifest '
            'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
            'error=$error',
          );
          rethrow;
        }
      }

      await runStep(
        'feed_manifest',
        () => ensureFeedManifestRepository().warmStartupWindow(),
      );
      await runStep(
        'short_manifest',
        () => ensureShortManifestRepository().warmStartupWindow(),
      );
      await runFloodStep();
    } catch (error, stackTrace) {
      _failureReporter.record(
        kind: StartupSessionFailureKind.backgroundWarmup,
        operation: 'PostLoginWarmup.warmGuestStartupManifests',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
