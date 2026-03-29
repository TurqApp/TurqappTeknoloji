part of 'splash_view.dart';

extension _SplashViewStartupPart on _SplashViewState {
  int? _asNullableManifestInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Duration get _firebaseStartupWait => IntegrationTestMode.enabled
      ? const Duration(seconds: 18)
      : const Duration(seconds: 3);

  SplashStartupOrchestrator get _startupOrchestrator =>
      SplashStartupOrchestrator(
        firebaseStartupWait: _firebaseStartupWait,
        isMounted: () => mounted,
        navigateToPrimaryRoute: _navigateToPrimaryRoute,
        prepareSynchronizedStartupBeforeNav: ({required isFirstLaunch}) =>
            _prepareSynchronizedStartupBeforeNav(
          isFirstLaunch: isFirstLaunch,
        ),
        runCriticalWarmStartLoads: ({required isFirstLaunch}) =>
            _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch),
        runWarmStartLoads: ({required isFirstLaunch}) =>
            _runWarmStartLoads(isFirstLaunch: isFirstLaunch),
        markMinimumStartupPrepared: (value) {
          _minimumStartupPrepared = value;
        },
        isMinimumStartupPrepared: () => _minimumStartupPrepared,
        hydrateStartupManifestContext: ({required loggedIn}) =>
            _hydrateStartupManifestContext(loggedIn: loggedIn),
      );

  Future<void> _performInitApp() async => _startupOrchestrator.initializeApp();

  Future<void> _hydrateStartupManifestContext({
    required bool loggedIn,
  }) async {
    _feedStartupShardHydrated = false;
    _shortStartupShardHydrated = false;
    _feedStartupShardAgeMs = null;
    _shortStartupShardAgeMs = null;
    try {
      final effectiveUserId =
          CurrentUserService.instance.effectiveUserId.trim();
      final store = ensureStartupSnapshotManifestStore();
      final manifest = await store.load(
            userId: effectiveUserId.isEmpty ? null : effectiveUserId,
          ) ??
          (effectiveUserId.isNotEmpty ? await store.load(userId: null) : null);

      _previousStartupRouteHint = manifest?.routeHint ?? 'unknown';
      _previousStartupLoggedIn = manifest?.loggedIn ?? loggedIn;
      _previousStartupMinimumPrepared =
          manifest?.minimumStartupPrepared ?? false;
      _previousStartupNavIndex =
          _asNullableManifestInt(manifest?.extra['navSelectedIndex']);
      final educationTabId =
          (manifest?.extra['educationTabId'] ?? '').toString().trim();
      _previousEducationTabId =
          pasajTabs.contains(educationTabId) ? educationTabId : null;
      _previousStartupSurfaces =
          manifest?.surfaces ?? const <String, StartupSnapshotSurfaceRecord>{};
      _previousStartupManifestAgeMs =
          manifest == null || manifest.savedAtMs <= 0
              ? null
              : DateTime.now().millisecondsSinceEpoch - manifest.savedAtMs;
      await _hydrateStartupPayloadShards(
        loggedIn: loggedIn,
        userId: effectiveUserId,
      );
    } catch (_) {
      _previousStartupRouteHint = 'unknown';
      _previousStartupLoggedIn = loggedIn;
      _previousStartupMinimumPrepared = false;
      _previousStartupNavIndex = null;
      _previousEducationTabId = null;
      _previousStartupSurfaces = const <String, StartupSnapshotSurfaceRecord>{};
      _previousStartupManifestAgeMs = null;
      _feedStartupShardHydrated = false;
      _shortStartupShardHydrated = false;
      _feedStartupShardAgeMs = null;
      _shortStartupShardAgeMs = null;
    }
  }

  Future<void> _hydrateStartupPayloadShards({
    required bool loggedIn,
    required String userId,
  }) async {
    if (!loggedIn || userId.trim().isEmpty) return;
    final manifestAgeMs = _previousStartupManifestAgeMs;
    if (manifestAgeMs == null || manifestAgeMs < 0) return;
    if (manifestAgeMs >
        _SplashViewState._startupManifestFreshWindow.inMilliseconds) {
      return;
    }

    final shardStore = ensureStartupSnapshotShardStore();
    final onWiFi = _isOnWiFiNow();
    await _primeFeedStartupShard(
      shardStore: shardStore,
      userId: userId,
    );
    await _primeShortStartupShard(
      shardStore: shardStore,
      userId: userId,
      onWiFi: onWiFi,
    );
  }

  Future<void> _primeFeedStartupShard({
    required StartupSnapshotShardStore shardStore,
    required String userId,
  }) async {
    final shard = await shardStore.load(
      surface: 'feed',
      userId: userId,
      maxAge: StartupSnapshotShardStore.defaultFreshWindow,
    );
    if (shard == null || shard.itemCount <= 0) return;
    final didPrime =
        await ensureFeedSnapshotRepository().primeHomeFromStartupPayload(
      userId: userId,
      payload: shard.payload,
      limit: _feedWarmPoolLimit(),
      snapshotAt: shard.snapshotAt,
    );
    if (!didPrime) return;
    _feedStartupShardHydrated = true;
    _feedStartupShardAgeMs =
        DateTime.now().millisecondsSinceEpoch - shard.savedAtMs;
  }

  Future<void> _primeShortStartupShard({
    required StartupSnapshotShardStore shardStore,
    required String userId,
    required bool onWiFi,
  }) async {
    final shard = await shardStore.load(
      surface: 'short',
      userId: userId,
      maxAge: StartupSnapshotShardStore.defaultFreshWindow,
    );
    if (shard == null || shard.itemCount <= 0) return;
    final didPrime =
        await ensureShortSnapshotRepository().primeHomeFromStartupPayload(
      userId: userId,
      payload: shard.payload,
      limit: _shortStartupShardLimit(onWiFi: onWiFi),
      additionalLimits: onWiFi ? const <int>[6, 8] : const <int>[3, 4],
      snapshotAt: shard.snapshotAt,
    );
    if (!didPrime) return;
    _shortStartupShardHydrated = true;
    _shortStartupShardAgeMs =
        DateTime.now().millisecondsSinceEpoch - shard.savedAtMs;
  }

  int _feedStartupShardLimit() {
    final warmLimit = _feedWarmPoolLimit();
    if (warmLimit <= 0) return 0;
    return warmLimit > 10 ? 10 : warmLimit;
  }

  int _shortStartupShardLimit({
    required bool onWiFi,
  }) {
    return onWiFi ? 6 : 4;
  }

  Future<void> _persistFeedStartupShard(
    CachedResource<List<PostsModel>> resource,
  ) async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final shardStore = ensureStartupSnapshotShardStore();
    final posts = resource.data ?? const <PostsModel>[];
    if (posts.isEmpty) {
      await shardStore.clear(
        surface: 'feed',
        userId: userId,
      );
      return;
    }
    final limit = _feedStartupShardLimit();
    if (limit <= 0) return;
    await shardStore.save(
      surface: 'feed',
      userId: userId,
      itemCount: posts.length < limit ? posts.length : limit,
      limit: limit,
      source: resource.source.name,
      snapshotAt: resource.snapshotAt,
      payload: ensureFeedSnapshotRepository().encodeHomeStartupPayload(
        posts,
        limit: limit,
      ),
    );
  }

  Future<void> _persistShortStartupShard(
    CachedResource<List<PostsModel>> resource, {
    required bool onWiFi,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final shardStore = ensureStartupSnapshotShardStore();
    final posts = resource.data ?? const <PostsModel>[];
    if (posts.isEmpty) {
      await shardStore.clear(
        surface: 'short',
        userId: userId,
      );
      return;
    }
    final limit = _shortStartupShardLimit(onWiFi: onWiFi);
    if (limit <= 0) return;
    await shardStore.save(
      surface: 'short',
      userId: userId,
      itemCount: posts.length < limit ? posts.length : limit,
      limit: limit,
      source: resource.source.name,
      snapshotAt: resource.snapshotAt,
      payload: ensureShortSnapshotRepository().encodeHomeStartupPayload(
        posts,
        limit: limit,
      ),
    );
  }

  String _requestedStartupRouteHint() {
    final ageMs = _previousStartupManifestAgeMs;
    if (ageMs == null || ageMs < 0) return 'unknown';
    if (ageMs > _SplashViewState._startupManifestFreshWindow.inMilliseconds) {
      return 'unknown';
    }
    return _previousStartupRouteHint;
  }

  String _effectiveStartupRouteHint() {
    final requested = _requestedStartupRouteHint();
    switch (requested) {
      case 'nav_explore':
      case 'nav_profile':
      case 'nav_education':
        return _isStartupRouteWarm(requested) ? requested : 'nav_feed';
      default:
        return requested;
    }
  }

  bool _shouldRequireFeedReadiness() {
    switch (_effectiveStartupRouteHint()) {
      case 'nav_explore':
      case 'nav_profile':
      case 'nav_education':
        return false;
      default:
        return true;
    }
  }

  bool _shouldPrioritizeProfileWarmups() {
    return _effectiveStartupRouteHint() == 'nav_profile';
  }

  bool _shouldPrioritizeExploreWarmups() {
    return _effectiveStartupRouteHint() == 'nav_explore';
  }

  String? _effectiveEducationTabId() {
    if (_effectiveStartupRouteHint() != 'nav_education') {
      return null;
    }
    final tabId = (_previousEducationTabId ?? '').trim();
    if (tabId.isEmpty || !pasajTabs.contains(tabId)) {
      return null;
    }
    return tabId;
  }

  bool _shouldPrioritizeEducationMarketWarmups() {
    final tabId = _effectiveEducationTabId();
    return tabId == null || tabId == PasajTabIds.market;
  }

  bool _shouldPrioritizeEducationJobWarmups() {
    final tabId = _effectiveEducationTabId();
    return tabId == null || tabId == PasajTabIds.jobFinder;
  }

  StartupSnapshotSurfaceRecord? _startupSurfaceRecord(String surface) {
    final normalized = surface.trim();
    if (normalized.isEmpty) return null;
    return _previousStartupSurfaces[normalized];
  }

  bool _surfaceRecordIsWarm(
    StartupSnapshotSurfaceRecord? record, {
    int minItemCount = 1,
    bool allowHeaderOnly = false,
  }) {
    if (record == null) return false;
    if (record.startupShardHydrated == true) return true;
    if (!record.hasLocalSnapshot) return false;
    if (allowHeaderOnly) return true;
    return record.itemCount >= minItemCount;
  }

  bool _isStartupRouteWarm(String routeHint) {
    switch (routeHint) {
      case 'nav_explore':
        return _surfaceRecordIsWarm(
          _startupSurfaceRecord('explore'),
        );
      case 'nav_profile':
        return _surfaceRecordIsWarm(
          _startupSurfaceRecord('profile'),
          minItemCount: 0,
          allowHeaderOnly: true,
        );
      case 'nav_education':
        final tabId = (_previousEducationTabId ?? '').trim();
        if (tabId == PasajTabIds.market) {
          return _surfaceRecordIsWarm(
            _startupSurfaceRecord('market'),
          );
        }
        if (tabId == PasajTabIds.jobFinder) {
          return _surfaceRecordIsWarm(
            _startupSurfaceRecord('jobs'),
          );
        }
        if (tabId.isNotEmpty && pasajTabs.contains(tabId)) {
          return false;
        }
        return _surfaceRecordIsWarm(_startupSurfaceRecord('market')) ||
            _surfaceRecordIsWarm(_startupSurfaceRecord('jobs'));
      case 'nav_feed':
      case 'nav_home':
        return true;
      default:
        return false;
    }
  }

  String _resolvedStartupRouteHintForTelemetry({
    required bool loggedIn,
  }) {
    if (!loggedIn) return 'sign_in';
    return _resolvedLoggedInStartupRouteHint();
  }

  Map<String, dynamic> _startupSurfaceTelemetryFields(
    String surface, {
    required String prefix,
  }) {
    final record = _startupSurfaceRecord(surface);
    if (record == null) {
      return <String, dynamic>{
        '${prefix}Known': false,
      };
    }
    final recordedAgeMs = record.recordedAtMs <= 0
        ? null
        : DateTime.now().millisecondsSinceEpoch - record.recordedAtMs;
    return <String, dynamic>{
      '${prefix}Known': true,
      '${prefix}HasLocalSnapshot': record.hasLocalSnapshot,
      '${prefix}ItemCount': record.itemCount,
      '${prefix}Source': record.source,
      '${prefix}IsStale': record.isStale,
      '${prefix}SnapshotAgeMs': record.snapshotAgeMs,
      '${prefix}StartupShardHydrated': record.startupShardHydrated,
      '${prefix}StartupShardAgeMs': record.startupShardAgeMs,
      '${prefix}RecordedAgeMs': recordedAgeMs,
    };
  }

  Map<String, dynamic> _startupAnalyticsExtra({
    required String surface,
    required int launchToRouteMs,
    required bool loggedIn,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    return <String, dynamic>{
      'launchToRouteMs': launchToRouteMs,
      'resolvedStartupRouteHint': _resolvedStartupRouteHintForTelemetry(
        loggedIn: loggedIn,
      ),
      'effectiveStartupRouteHint': _effectiveStartupRouteHint(),
      'requestedStartupRouteHint': _requestedStartupRouteHint(),
      'startupRouteFallbackApplied':
          _requestedStartupRouteHint() != _effectiveStartupRouteHint(),
      'startupRequiresFeedReadiness': _shouldRequireFeedReadiness(),
      'startupPrioritizeExploreWarmups': _shouldPrioritizeExploreWarmups(),
      'startupPrioritizeProfileWarmups': _shouldPrioritizeProfileWarmups(),
      'startupPrioritizeEducationWarmups': _shouldPrioritizeEducationWarmups(),
      'previousStartupRouteHint': _previousStartupRouteHint,
      'previousStartupLoggedIn': _previousStartupLoggedIn,
      'previousStartupMinimumPrepared': _previousStartupMinimumPrepared,
      'previousStartupNavIndex': _previousStartupNavIndex,
      'previousEducationTabId': _previousEducationTabId,
      'previousStartupManifestAgeMs': _previousStartupManifestAgeMs,
      ..._startupSurfaceTelemetryFields(surface, prefix: 'manifest'),
      ...extra,
    };
  }

  bool _hasWarmStartupSurface(
    String surface, {
    int minItemCount = 1,
    bool requirePositiveItems = true,
  }) {
    switch (surface.trim()) {
      case 'feed':
        if (_feedStartupShardHydrated) return true;
        break;
      case 'short':
        if (_shortStartupShardHydrated) return true;
        break;
    }
    return _surfaceRecordIsWarm(
      _startupSurfaceRecord(surface),
      minItemCount: minItemCount,
      allowHeaderOnly: !requirePositiveItems,
    );
  }

  String _resolvedLoggedInStartupRouteHint() {
    final hasEducation =
        maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
    switch (_preferredStartupNavIndex()) {
      case 1:
        return 'nav_explore';
      case 3:
        return hasEducation ? 'nav_education' : 'nav_profile';
      case 4:
        return 'nav_profile';
      case 0:
      default:
        return 'nav_feed';
    }
  }

  Future<void> _performNavigateToPrimaryRoute() async {
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

    var loggedIn = false;
    var effectiveUserId = '';
    try {
      effectiveUserId = CurrentUserService.instance.effectiveUserId.trim();
      loggedIn = effectiveUserId.isNotEmpty;
    } catch (error, stackTrace) {
      StartupSessionFailureReporter.defaultReporter.record(
        kind: StartupSessionFailureKind.primaryRouteReadiness,
        operation: 'SplashView.readEffectiveUserId',
        error: error,
        stackTrace: stackTrace,
      );
      loggedIn = false;
    }
    if (loggedIn) {
      await _ensureAuthenticatedPrimaryRouteReady();
    }
    final launchToRouteMs =
        DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    final requestedStartupRouteHint = _requestedStartupRouteHint();
    final effectiveStartupRouteHint = _effectiveStartupRouteHint();
    final resolvedStartupRouteHint = _resolvedStartupRouteHintForTelemetry(
      loggedIn: loggedIn,
    );
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi != null) {
      playbackKpi.track(
        PlaybackKpiEventType.startup,
        {
          'launchToRouteMs': launchToRouteMs,
          'loggedIn': loggedIn,
          'requestedStartupRouteHint': requestedStartupRouteHint,
          'effectiveStartupRouteHint': effectiveStartupRouteHint,
          'resolvedStartupRouteHint': resolvedStartupRouteHint,
          'startupRouteFallbackApplied':
              requestedStartupRouteHint != effectiveStartupRouteHint,
          'minimumStartupPrepared': _minimumStartupPrepared,
          'startupRequiresFeedReadiness': _shouldRequireFeedReadiness(),
          'startupPrioritizeExploreWarmups': _shouldPrioritizeExploreWarmups(),
          'startupPrioritizeProfileWarmups': _shouldPrioritizeProfileWarmups(),
          'startupPrioritizeEducationWarmups':
              _shouldPrioritizeEducationWarmups(),
          'feedWarmSnapshotHit': _feedWarmSnapshotHit,
          'feedWarmSnapshotSource': _feedWarmSnapshotSource,
          'feedWarmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
          'feedStartupShardHydrated': _feedStartupShardHydrated,
          'feedStartupShardAgeMs': _feedStartupShardAgeMs,
          'shortWarmSnapshotHit': _shortWarmSnapshotHit,
          'shortWarmSnapshotSource': _shortWarmSnapshotSource,
          'shortWarmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
          'shortStartupShardHydrated': _shortStartupShardHydrated,
          'shortStartupShardAgeMs': _shortStartupShardAgeMs,
          'previousStartupRouteHint': _previousStartupRouteHint,
          'previousStartupLoggedIn': _previousStartupLoggedIn,
          'previousStartupMinimumPrepared': _previousStartupMinimumPrepared,
          'previousStartupNavIndex': _previousStartupNavIndex,
          'previousEducationTabId': _previousEducationTabId,
          'previousStartupManifestAgeMs': _previousStartupManifestAgeMs,
          ..._startupSurfaceTelemetryFields('feed', prefix: 'manifestFeed'),
          ..._startupSurfaceTelemetryFields('short', prefix: 'manifestShort'),
          ..._startupSurfaceTelemetryFields(
            'explore',
            prefix: 'manifestExplore',
          ),
          ..._startupSurfaceTelemetryFields(
            'profile',
            prefix: 'manifestProfile',
          ),
          ..._startupSurfaceTelemetryFields('market', prefix: 'manifestMarket'),
          ..._startupSurfaceTelemetryFields('jobs', prefix: 'manifestJobs'),
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
            extra: _startupAnalyticsExtra(
              surface: 'feed',
              launchToRouteMs: launchToRouteMs,
              loggedIn: loggedIn,
              extra: <String, dynamic>{
                'warmSnapshotHit': _feedWarmSnapshotHit,
                'warmSnapshotSource': _feedWarmSnapshotSource,
                'warmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
                'startupShardHydrated': _feedStartupShardHydrated,
                'startupShardAgeMs': _feedStartupShardAgeMs,
              },
            ),
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
            extra: _startupAnalyticsExtra(
              surface: 'short',
              launchToRouteMs: launchToRouteMs,
              loggedIn: loggedIn,
              extra: <String, dynamic>{
                'warmSnapshotHit': _shortWarmSnapshotHit,
                'warmSnapshotSource': _shortWarmSnapshotSource,
                'warmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
                'startupShardHydrated': _shortStartupShardHydrated,
                'startupShardAgeMs': _shortStartupShardAgeMs,
              },
            ),
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'explore',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'explore_',
            ),
            renderDiff: playbackKpi.summarizeRenderDiff(surface: 'explore'),
            extra: _startupAnalyticsExtra(
              surface: 'explore',
              launchToRouteMs: launchToRouteMs,
              loggedIn: loggedIn,
            ),
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'profile',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'profile_',
            ),
            renderDiff: playbackKpi.summarizeRenderDiff(surface: 'profile'),
            extra: _startupAnalyticsExtra(
              surface: 'profile',
              launchToRouteMs: launchToRouteMs,
              loggedIn: loggedIn,
            ),
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'market',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'market_',
            ),
            extra: _startupAnalyticsExtra(
              surface: 'market',
              launchToRouteMs: launchToRouteMs,
              loggedIn: loggedIn,
            ),
          ),
        );
        unawaited(
          UserAnalyticsService.instance.trackRuntimeHealthSummary(
            surface: 'jobs',
            cacheFirst: playbackKpi.summarizeCacheFirst(
              surfaceKeyPrefix: 'jobs_',
            ),
            extra: _startupAnalyticsExtra(
              surface: 'jobs',
              launchToRouteMs: launchToRouteMs,
              loggedIn: loggedIn,
            ),
          ),
        );
      }
    }
    unawaited(
      ensureStartupSnapshotManifestStore().markNavigation(
        userId: effectiveUserId,
        routeHint: resolvedStartupRouteHint,
        loggedIn: loggedIn,
        minimumStartupPrepared: _minimumStartupPrepared,
        launchToRouteMs: launchToRouteMs,
        extra: <String, dynamic>{
          'requestedStartupRouteHint': requestedStartupRouteHint,
          'effectiveStartupRouteHint': effectiveStartupRouteHint,
          'resolvedStartupRouteHint': resolvedStartupRouteHint,
          'startupRouteFallbackApplied':
              requestedStartupRouteHint != effectiveStartupRouteHint,
          'startupRequiresFeedReadiness': _shouldRequireFeedReadiness(),
          'startupPrioritizeExploreWarmups': _shouldPrioritizeExploreWarmups(),
          'startupPrioritizeProfileWarmups': _shouldPrioritizeProfileWarmups(),
          'startupPrioritizeEducationWarmups':
              _shouldPrioritizeEducationWarmups(),
          'feedWarmSnapshotHit': _feedWarmSnapshotHit,
          'feedWarmSnapshotSource': _feedWarmSnapshotSource,
          'feedWarmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
          'feedStartupShardHydrated': _feedStartupShardHydrated,
          'feedStartupShardAgeMs': _feedStartupShardAgeMs,
          'shortWarmSnapshotHit': _shortWarmSnapshotHit,
          'shortWarmSnapshotSource': _shortWarmSnapshotSource,
          'shortWarmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
          'shortStartupShardHydrated': _shortStartupShardHydrated,
          'shortStartupShardAgeMs': _shortStartupShardAgeMs,
          'previousStartupRouteHint': _previousStartupRouteHint,
          'previousStartupLoggedIn': _previousStartupLoggedIn,
          'previousStartupMinimumPrepared': _previousStartupMinimumPrepared,
          'previousStartupNavIndex': _previousStartupNavIndex,
          'previousEducationTabId': _previousEducationTabId,
          'previousStartupManifestAgeMs': _previousStartupManifestAgeMs,
          'navSelectedIndex': loggedIn ? _preferredStartupNavIndex() : null,
          ..._startupSurfaceTelemetryFields('feed', prefix: 'manifestFeed'),
          ..._startupSurfaceTelemetryFields('short', prefix: 'manifestShort'),
          ..._startupSurfaceTelemetryFields(
            'explore',
            prefix: 'manifestExplore',
          ),
          ..._startupSurfaceTelemetryFields(
            'profile',
            prefix: 'manifestProfile',
          ),
          ..._startupSurfaceTelemetryFields('market', prefix: 'manifestMarket'),
          ..._startupSurfaceTelemetryFields('jobs', prefix: 'manifestJobs'),
        },
      ),
    );
    _didNavigate = true;
    if (loggedIn) {
      final preferredIndex = _preferredStartupNavIndex();
      if (preferredIndex != null) {
        ensureNavBarController().selectedIndex.value = preferredIndex;
      }
      Get.offAll(() => NavBarView());
      return;
    }
    Get.offAll(() => SignIn());
  }

  int? _preferredStartupNavIndex() {
    final storedIndex = _previousStartupNavIndex;
    final hasEducation =
        maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
    if (storedIndex != null && storedIndex >= 0 && storedIndex <= 4) {
      final normalizedIndex = storedIndex == 2 ? 0 : storedIndex;
      if (_isStartupNavIndexWarm(
        normalizedIndex,
        hasEducation: hasEducation,
      )) {
        return normalizedIndex;
      }
    }
    final profileIndex = hasEducation ? 4 : 3;
    switch (_effectiveStartupRouteHint()) {
      case 'nav_feed':
      case 'nav_home':
        return 0;
      case 'nav_explore':
        return 1;
      case 'nav_education':
        return hasEducation ? 3 : 0;
      case 'nav_profile':
        return profileIndex;
      default:
        return null;
    }
  }

  bool _isStartupNavIndexWarm(
    int navIndex, {
    required bool hasEducation,
  }) {
    switch (navIndex) {
      case 0:
        return true;
      case 1:
        return _isStartupRouteWarm('nav_explore');
      case 3:
        return hasEducation
            ? _isStartupRouteWarm('nav_education')
            : _isStartupRouteWarm('nav_profile');
      case 4:
        return _isStartupRouteWarm('nav_profile');
      default:
        return false;
    }
  }

  Future<void> _ensureAuthenticatedPrimaryRouteReady() async {
    if (_shouldPrioritizeExploreWarmups()) {
      try {
        if (_hasWarmStartupSurface('explore')) {
          return;
        }
        final exploreController =
            maybeFindExploreController() ?? ensureExploreController();
        if (exploreController.explorePosts.isNotEmpty ||
            exploreController.trendingTags.isNotEmpty) {
          return;
        }
        await exploreController
            .prepareStartupSurface(
              allowBackgroundRefresh: ContentPolicy.allowBackgroundRefresh(
                ContentScreenKind.explore,
              ),
            )
            .timeout(
              const Duration(milliseconds: 900),
              onTimeout: () {},
            );
        return;
      } catch (error, stackTrace) {
        StartupSessionFailureReporter.defaultReporter.record(
          kind: StartupSessionFailureKind.primaryRouteReadiness,
          operation: 'SplashView.ensureExplorePrimaryRouteReady',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return;
    }
    if (_shouldPrioritizeProfileWarmups()) {
      try {
        if (_hasWarmStartupSurface(
          'profile',
          minItemCount: 0,
          requirePositiveItems: false,
        )) {
          return;
        }
        final profileController =
            ProfileController.maybeFind() ?? ProfileController.ensure();
        if (profileController.headerDisplayName.value.trim().isNotEmpty ||
            profileController.allPosts.isNotEmpty) {
          return;
        }
        await profileController
            .prepareStartupSurface(
              allowBackgroundRefresh: ContentPolicy.allowBackgroundRefresh(
                ContentScreenKind.profile,
              ),
            )
            .timeout(
              const Duration(milliseconds: 900),
              onTimeout: () {},
            );
      } catch (error, stackTrace) {
        StartupSessionFailureReporter.defaultReporter.record(
          kind: StartupSessionFailureKind.primaryRouteReadiness,
          operation: 'SplashView.ensureProfilePrimaryRouteReady',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return;
    }
    if (_effectiveStartupRouteHint() == 'nav_education') {
      try {
        await Future.wait([
          if (_shouldPrioritizeEducationMarketWarmups())
            if (_hasWarmStartupSurface('market'))
              Future<void>.value()
            else
              prepareMarketStartupSurface(
                maybeFindMarketController() ?? ensureMarketController(),
                allowBackgroundRefresh: _isOnWiFiNow(),
              ).timeout(
                const Duration(milliseconds: 900),
                onTimeout: () {},
              ),
          if (_shouldPrioritizeEducationJobWarmups())
            if (_hasWarmStartupSurface('jobs'))
              Future<void>.value()
            else
              prepareJobFinderStartupSurface(
                maybeFindJobFinderController() ?? ensureJobFinderController(),
                allowBackgroundRefresh: _isOnWiFiNow(),
              ).timeout(
                const Duration(milliseconds: 900),
                onTimeout: () {},
              ),
        ]);
      } catch (error, stackTrace) {
        StartupSessionFailureReporter.defaultReporter.record(
          kind: StartupSessionFailureKind.primaryRouteReadiness,
          operation: 'SplashView.ensureEducationPrimaryRouteReady',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return;
    }
    if (!_shouldRequireFeedReadiness()) {
      return;
    }
    try {
      if (_hasWarmStartupSurface(
        'feed',
        minItemCount: _SplashViewState._minFeedPostsForNav,
      )) {
        return;
      }
      final agendaController =
          maybeFindAgendaController() ?? ensureAgendaController();
      if (agendaController.agendaList.isNotEmpty) {
        return;
      }
      await agendaController
          .prepareStartupSurface(
            allowBackgroundRefresh: false,
          )
          .timeout(
            const Duration(milliseconds: 900),
            onTimeout: () {},
          );
    } catch (error, stackTrace) {
      StartupSessionFailureReporter.defaultReporter.record(
        kind: StartupSessionFailureKind.primaryRouteReadiness,
        operation: 'SplashView.ensureAuthenticatedPrimaryRouteReady',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
