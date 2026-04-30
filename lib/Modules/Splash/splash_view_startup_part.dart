part of 'splash_view.dart';

String resolveStartupManifestRouteHint({
  required int? manifestAgeMs,
  required int freshWindowMs,
  required String routeHint,
}) {
  if (manifestAgeMs == null || manifestAgeMs < 0) {
    return StartupRouteHint.unknown.value;
  }
  if (manifestAgeMs > freshWindowMs) return StartupRouteHint.unknown.value;
  return normalizeStartupRouteHint(routeHint);
}

class _StartupRouteTelemetryValues {
  const _StartupRouteTelemetryValues({
    required this.requestedStartupRouteHint,
    required this.effectiveStartupRouteHint,
    required this.resolvedStartupRouteHint,
  });

  final String requestedStartupRouteHint;
  final String effectiveStartupRouteHint;
  final String resolvedStartupRouteHint;

  bool get fallbackApplied =>
      requestedStartupRouteHint != effectiveStartupRouteHint;
}

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

      _previousStartupRouteHint =
          manifest?.routeHint ?? StartupRouteHint.unknown.value;
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
      _previousStartupRouteHint = StartupRouteHint.unknown.value;
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
    await _primeFeedStartupShard(
      shardStore: shardStore,
      userId: userId,
    );
    await shardStore.clear(
      surface: 'short',
      userId: userId,
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

  String _requestedStartupRouteHint() {
    return resolveStartupManifestRouteHint(
      manifestAgeMs: _previousStartupManifestAgeMs,
      freshWindowMs:
          _SplashViewState._startupManifestFreshWindow.inMilliseconds,
      routeHint: _previousStartupRouteHint,
    );
  }

  String _effectiveStartupRouteHint() {
    if (QALabMode.enabled) {
      return StartupRouteHint.feed.value;
    }
    final requested = _requestedStartupRouteHint();
    if (startupRouteHintRequiresWarmReadiness(requested)) {
      return _isStartupRouteWarm(requested)
          ? requested
          : StartupRouteHint.feed.value;
    }
    return requested;
  }

  StartupRouteHint _effectiveStartupRouteHintKind() {
    return startupRouteHintKind(_effectiveStartupRouteHint());
  }

  bool _shouldRequireFeedReadiness() {
    return !startupRouteHintRequiresWarmReadiness(_effectiveStartupRouteHint());
  }

  bool _shouldPrioritizeProfileWarmups() {
    return _effectiveStartupRouteHintKind() == StartupRouteHint.profile;
  }

  bool _shouldPrioritizeExploreWarmups() {
    return _effectiveStartupRouteHintKind() == StartupRouteHint.explore;
  }

  String? _effectiveEducationTabId() {
    if (_effectiveStartupRouteHintKind() != StartupRouteHint.education) {
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
    switch (startupRouteHintKind(routeHint)) {
      case StartupRouteHint.explore:
        return _surfaceRecordIsWarm(
          _startupSurfaceRecord('explore'),
        );
      case StartupRouteHint.profile:
        return _surfaceRecordIsWarm(
          _startupSurfaceRecord('profile'),
          minItemCount: 0,
          allowHeaderOnly: true,
        );
      case StartupRouteHint.education:
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
      case StartupRouteHint.feed:
      case StartupRouteHint.home:
        return true;
      case StartupRouteHint.unknown:
        return false;
    }
  }

  String _resolvedStartupRouteHintForTelemetry({
    required StartupDecision startupDecision,
    required bool educationEnabled,
  }) {
    if (!startupDecision.shouldOpenAuthenticatedHome) return 'sign_in';
    final primaryTab = startupDecision.primaryTab;
    if (primaryTab == null) return StartupRouteHint.feed.value;
    return PrimaryTabRouter.routeHintFor(
      primaryTab,
      educationEnabled: educationEnabled,
    );
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

  Map<String, dynamic> _startupWarmupPriorityTelemetryFields() {
    return <String, dynamic>{
      'startupRequiresFeedReadiness': _shouldRequireFeedReadiness(),
      'startupPrioritizeExploreWarmups': _shouldPrioritizeExploreWarmups(),
      'startupPrioritizeProfileWarmups': _shouldPrioritizeProfileWarmups(),
      'startupPrioritizeEducationWarmups': _shouldPrioritizeEducationWarmups(),
    };
  }

  Map<String, dynamic> _startupManifestContextTelemetryFields() {
    return <String, dynamic>{
      'previousStartupRouteHint': _previousStartupRouteHint,
      'previousStartupLoggedIn': _previousStartupLoggedIn,
      'previousStartupMinimumPrepared': _previousStartupMinimumPrepared,
      'previousStartupNavIndex': _previousStartupNavIndex,
      'previousEducationTabId': _previousEducationTabId,
      'previousStartupManifestAgeMs': _previousStartupManifestAgeMs,
    };
  }

  Map<String, dynamic> _startupRouteTelemetryFields(
    _StartupRouteTelemetryValues routeTelemetry,
  ) {
    return <String, dynamic>{
      'requestedStartupRouteHint': routeTelemetry.requestedStartupRouteHint,
      'effectiveStartupRouteHint': routeTelemetry.effectiveStartupRouteHint,
      'resolvedStartupRouteHint': routeTelemetry.resolvedStartupRouteHint,
      'startupRouteFallbackApplied': routeTelemetry.fallbackApplied,
    };
  }

  Map<String, dynamic> _startupAnalyticsExtra({
    required String surface,
    required int launchToRouteMs,
    required _StartupRouteTelemetryValues routeTelemetry,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    return <String, dynamic>{
      'launchToRouteMs': launchToRouteMs,
      ..._startupRouteTelemetryFields(routeTelemetry),
      ..._startupWarmupPriorityTelemetryFields(),
      ..._startupManifestContextTelemetryFields(),
      ..._startupSurfaceTelemetryFields(surface, prefix: 'manifest'),
      ...extra,
    };
  }

  Map<String, dynamic> _startupDecisionTelemetryFields({
    required _StartupRouteTelemetryValues routeTelemetry,
    required StartupDecision startupDecision,
  }) {
    return <String, dynamic>{
      ..._startupRouteTelemetryFields(routeTelemetry),
      'startupRootTarget': startupDecision.rootTarget.name,
      'startupPrimaryTab': startupDecision.primaryTab?.name,
      ..._startupWarmupPriorityTelemetryFields(),
    };
  }

  Map<String, dynamic> _startupWarmReadinessTelemetryFields() {
    return <String, dynamic>{
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
      ..._startupManifestContextTelemetryFields(),
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
    };
  }

  Map<String, dynamic> _startupNavigationManifestExtra({
    required _StartupRouteTelemetryValues routeTelemetry,
    required StartupDecision startupDecision,
    required int? startupNavSelectedIndex,
  }) {
    return <String, dynamic>{
      ..._startupDecisionTelemetryFields(
        routeTelemetry: routeTelemetry,
        startupDecision: startupDecision,
      ),
      ..._startupWarmReadinessTelemetryFields(),
      'navSelectedIndex': startupNavSelectedIndex,
    };
  }

  void _trackStartupRuntimeHealthSummary({
    required PlaybackKpiService playbackKpi,
    required String surface,
    required int launchToRouteMs,
    required _StartupRouteTelemetryValues routeTelemetry,
    bool includeRenderDiff = false,
    bool includePlaybackWindow = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    unawaited(
      UserAnalyticsService.instance.trackRuntimeHealthSummary(
        surface: surface,
        cacheFirst: playbackKpi.summarizeCacheFirst(
          surfaceKeyPrefix: '${surface}_',
        ),
        renderDiff: includeRenderDiff
            ? playbackKpi.summarizeRenderDiff(surface: surface)
            : null,
        playbackWindow: includePlaybackWindow
            ? playbackKpi.summarizePlaybackWindow(surface: surface)
            : null,
        extra: _startupAnalyticsExtra(
          surface: surface,
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: routeTelemetry,
          extra: extra,
        ),
      ),
    );
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

  bool _startupEducationEnabled() {
    return maybeFindSettingsController()?.educationScreenIsOn.value ?? false;
  }

  StartupDecision _decideStartupRoute({
    required bool loggedIn,
    required bool educationEnabled,
    String effectiveUserId = '',
    String? requestedStartupRouteHint,
    String? effectiveStartupRouteHint,
  }) {
    final requested = requestedStartupRouteHint ?? _requestedStartupRouteHint();
    final effective = effectiveStartupRouteHint ?? _effectiveStartupRouteHint();
    return const AppDecisionCoordinator().decideStartup(
      StartupDecisionInput(
        authState: loggedIn
            ? StartupAuthState.authenticated
            : StartupAuthState.unauthenticated,
        effectiveUserId: effectiveUserId,
        requestedRouteHint: effective,
        educationEnabled: educationEnabled,
        minimumStartupPrepared: _minimumStartupPrepared,
        routeHintIsWarm: requested == effective,
      ),
    );
  }

  int? _startupNavSelectedIndex({
    required bool loggedIn,
    required StartupDecision startupDecision,
    required bool educationEnabled,
  }) {
    if (!loggedIn || !startupDecision.shouldOpenAuthenticatedHome) return null;
    return PrimaryTabRouter.selectedIndexForDecision(
      startupDecision,
      educationEnabled: educationEnabled,
    );
  }

  Future<void> _performNavigateToPrimaryRoute() async {
    if (!mounted || _didNavigate || _navigationScheduled) return;
    _navigationScheduled = true;

    await _waitForSplashIntroCompletion();
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
    final educationEnabled = _startupEducationEnabled();
    final startupDecision = _decideStartupRoute(
      loggedIn: loggedIn,
      educationEnabled: educationEnabled,
      effectiveUserId: effectiveUserId,
      requestedStartupRouteHint: requestedStartupRouteHint,
      effectiveStartupRouteHint: effectiveStartupRouteHint,
    );
    final startupNavSelectedIndex = _startupNavSelectedIndex(
      loggedIn: loggedIn,
      startupDecision: startupDecision,
      educationEnabled: educationEnabled,
    );
    final resolvedStartupRouteHint = _resolvedStartupRouteHintForTelemetry(
      startupDecision: startupDecision,
      educationEnabled: educationEnabled,
    );
    final startupRouteTelemetry = _StartupRouteTelemetryValues(
      requestedStartupRouteHint: requestedStartupRouteHint,
      effectiveStartupRouteHint: effectiveStartupRouteHint,
      resolvedStartupRouteHint: resolvedStartupRouteHint,
    );
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi != null) {
      playbackKpi.track(
        PlaybackKpiEventType.startup,
        {
          'launchToRouteMs': launchToRouteMs,
          'loggedIn': loggedIn,
          ..._startupDecisionTelemetryFields(
            routeTelemetry: startupRouteTelemetry,
            startupDecision: startupDecision,
          ),
          'minimumStartupPrepared': _minimumStartupPrepared,
          ..._startupWarmReadinessTelemetryFields(),
        },
      );
      if (loggedIn) {
        _trackStartupRuntimeHealthSummary(
          playbackKpi: playbackKpi,
          surface: 'feed',
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: startupRouteTelemetry,
          includeRenderDiff: true,
          includePlaybackWindow: true,
          extra: <String, dynamic>{
            'warmSnapshotHit': _feedWarmSnapshotHit,
            'warmSnapshotSource': _feedWarmSnapshotSource,
            'warmSnapshotAgeMs': _feedWarmSnapshotAgeMs,
            'startupShardHydrated': _feedStartupShardHydrated,
            'startupShardAgeMs': _feedStartupShardAgeMs,
          },
        );
        _trackStartupRuntimeHealthSummary(
          playbackKpi: playbackKpi,
          surface: 'short',
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: startupRouteTelemetry,
          includeRenderDiff: true,
          includePlaybackWindow: true,
          extra: <String, dynamic>{
            'warmSnapshotHit': _shortWarmSnapshotHit,
            'warmSnapshotSource': _shortWarmSnapshotSource,
            'warmSnapshotAgeMs': _shortWarmSnapshotAgeMs,
            'startupShardHydrated': _shortStartupShardHydrated,
            'startupShardAgeMs': _shortStartupShardAgeMs,
          },
        );
        _trackStartupRuntimeHealthSummary(
          playbackKpi: playbackKpi,
          surface: 'explore',
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: startupRouteTelemetry,
          includeRenderDiff: true,
        );
        _trackStartupRuntimeHealthSummary(
          playbackKpi: playbackKpi,
          surface: 'profile',
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: startupRouteTelemetry,
          includeRenderDiff: true,
        );
        _trackStartupRuntimeHealthSummary(
          playbackKpi: playbackKpi,
          surface: 'market',
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: startupRouteTelemetry,
        );
        _trackStartupRuntimeHealthSummary(
          playbackKpi: playbackKpi,
          surface: 'jobs',
          launchToRouteMs: launchToRouteMs,
          routeTelemetry: startupRouteTelemetry,
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
        extra: _startupNavigationManifestExtra(
          routeTelemetry: startupRouteTelemetry,
          startupDecision: startupDecision,
          startupNavSelectedIndex: startupNavSelectedIndex,
        ),
      ),
    );
    _didNavigate = true;
    if (startupDecision.shouldOpenAuthenticatedHome) {
      if (startupNavSelectedIndex != null) {
        ensureNavBarController().selectedIndex.value = startupNavSelectedIndex;
      }
      await AppRootNavigationService.offAllToAuthenticatedHome();
      return;
    }
    if (startupDecision.shouldOpenSignIn) {
      await AppRootNavigationService.offAllToSignIn();
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
    if (_effectiveStartupRouteHintKind() == StartupRouteHint.education) {
      try {
        final marketEnabled = _shouldPrioritizeEducationMarketWarmups()
            ? await _isSplashPasajTabEnabled(PasajTabIds.market)
            : false;
        final jobEnabled = _shouldPrioritizeEducationJobWarmups()
            ? await _isSplashPasajTabEnabled(PasajTabIds.jobFinder)
            : false;
        await Future.wait([
          if (marketEnabled)
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
          if (jobEnabled)
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
      final prepareFuture = agendaController.prepareStartupSurface(
        allowBackgroundRefresh: false,
        source: 'splash_primary_route_ready',
      );
      if (ContentPolicy.isConnected) {
        unawaited(prepareFuture.catchError((_) {}));
        return;
      }
      await prepareFuture.timeout(
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
