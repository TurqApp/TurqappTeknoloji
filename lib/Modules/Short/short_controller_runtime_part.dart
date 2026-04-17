part of 'short_controller.dart';

const bool _verboseShortLogs = false;
const int _initialPreloadCount = 5;
const int _startupReadyMagazineCount = 5;
const double _shortLandscapeAspectThreshold = 1.2;
const Duration _shortLaunchSessionMaxAge = Duration(hours: 1);
final double _activeBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 5.0 : 4.8;
final double _neighborBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 3.6 : 3.6;
final double _prepBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 2.8 : 3.0;

ShortController _ensureShortController() {
  final existing = _maybeFindShortController();
  if (existing != null) return existing;
  return Get.put(ShortController());
}

ShortController? _maybeFindShortController() {
  final isRegistered = Get.isRegistered<ShortController>();
  if (!isRegistered) return null;
  return Get.find<ShortController>();
}

extension _ShortControllerRuntimeX on ShortController {
  void log(String message) {
    if (_verboseShortLogs) debugPrint(message);
  }

  bool isEligibleShortPost(PostsModel post) {
    if (!post.hasPlayableVideo) return false;
    if (post.isFloodSeriesContent) return false;
    final ar = post.aspectRatio.toDouble();
    if (ar > _shortLandscapeAspectThreshold) {
      return false;
    }
    return true;
  }

  void handleOnInit() {
    applyUserCacheQuota();
    unawaited(DeviceSessionService.instance.warmDeviceKey());
    _log('[Shorts] 🔄 ShortController.onInit() called');
    _bindFollowingListener();
    _bindNetworkAwareness();
  }

  Future<void> applyUserCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotaGb = normalizeStorageBudgetPlanGb(
        prefs.getInt('offline_cache_quota_gb') ?? 3,
      );
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(quotaGb);
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch != null) {
        prefetch.resetWifiQuotaFillPlan();
      }
    } catch (e) {
      _log('Shorts cache quota apply error: $e');
    }
  }

  void handleOnClose() {
    _log('[Shorts] ❌ ShortController.onClose() called');
    _playbackCoordinator.reset();
    clearCache();
    _state.followingSub?.cancel();
    _networkWorker?.dispose();
  }

  void _bindNetworkAwareness() {
    final network = NetworkAwarenessService.maybeFind();
    if (network == null) return;
    _networkWorker?.dispose();
    _networkWorker = ever<NetworkType>(
      network.currentNetworkRx,
      (networkType) {
        if (networkType == NetworkType.cellular) {
          _renderWindowFrozenOnCellular = true;
          _log('[Shorts] Cellular freeze enabled - keep current list only');
          return;
        }
        final shouldResume =
            networkType == NetworkType.wifi && _renderWindowFrozenOnCellular;
        _renderWindowFrozenOnCellular = false;
        if (!shouldResume) return;
        _log('[Shorts] Wi-Fi restored - short motor resumes');
        unawaited(prepareStartupSurface(allowBackgroundRefresh: true));
      },
    );
  }
}

extension ShortControllerPublicApiPart on ShortController {
  void handleNetworkPolicyTransition(NetworkType networkType) {
    debugPrint(
      '[ShortNetworkPolicy] status=dispatch network=${networkType.name} '
      'frozen=$_renderWindowFrozenOnCellular count=${shorts.length}',
    );
    if (networkType == NetworkType.cellular) {
      if (_renderWindowFrozenOnCellular) return;
      _renderWindowFrozenOnCellular = true;
      debugPrint(
        '[ShortNetworkPolicy] status=cellular_freeze count=${shorts.length}',
      );
      return;
    }
    final shouldResume =
        networkType == NetworkType.wifi && _renderWindowFrozenOnCellular;
    _renderWindowFrozenOnCellular = false;
    if (!shouldResume) return;
    debugPrint(
        '[ShortNetworkPolicy] status=wifi_resume count=${shorts.length}');
    unawaited(prepareStartupSurface(allowBackgroundRefresh: true));
  }

  Future<void> onPrimarySurfaceVisible() => prepareStartupSurface(
        allowBackgroundRefresh:
            ContentPolicy.allowBackgroundRefresh(ContentScreenKind.shorts),
      );

  Future<void> prepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) {
    final active = _startupPrepareFuture;
    if (active != null) {
      return active;
    }
    final future = _performPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );
    _startupPrepareFuture = future;
    return future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
  }

  Future<void> _performPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) async {
    _recordShortMotorContractSnapshot(reason: 'prepare_startup_surface');
    final seededFreshSession = _ensureShortLaunchSessionFresh(
      reason: shorts.isEmpty && !_startupPresentationApplied
          ? 'startup'
          : 'surface_visible',
      forceNew: shorts.isEmpty && !_startupPresentationApplied,
    );
    final allowRefresh = allowBackgroundRefresh ??
        ContentPolicy.allowBackgroundRefresh(ContentScreenKind.shorts);
    if (shorts.isEmpty) {
      if (_backgroundPreloadFuture != null) {
        await _backgroundPreloadFuture;
      } else {
        await _runInitialLoadOnce();
      }
    }
    if (shorts.length < shortMotorStageOneLimit() &&
        hasMore.value &&
        !isLoading.value) {
      await warmStart(
        targetCount: shortMotorStageOneLimit(),
        maxPages: 4,
      );
    }
    await reconcileVisibleShortSurface(
      trigger: 'primary_surface_visible_reconcile',
    );
    if (shorts.isNotEmpty) {
      primeStartupReadyMagazine(
        _currentVisibleShortIndex(this),
        count: _startupReadyMagazineCount,
        minimumSegmentCount: 1,
      );
      primePlaybackWindowReadySegments(
        _currentVisibleShortIndex(this),
        minimumSegmentCount: 2,
      );
      unawaited(
        warmStartupFirstSegments(
          _currentVisibleShortIndex(this),
          count: _initialPreloadCount,
          minimumSegmentCount: 1,
        ),
      );
      unawaited(preloadRange(_currentVisibleShortIndex(this), range: 0));
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 700)).then((_) async {
          if (shorts.isEmpty) return;
          await reconcileVisibleShortSurface(
            trigger: 'primary_surface_visible_follow_up_reconcile',
          );
        }),
      );
    }
    await _recordShortStartupSurface(
      source: 'short_surface_ready',
    );
    if (seededFreshSession &&
        shorts.isNotEmpty &&
        !isRefreshing.value &&
        !isLoading.value) {
      unawaited(refreshShorts());
    }
    if (!allowRefresh || shorts.isEmpty) return;
    if (shorts.length < shortMotorStageOneLimit()) {
      unawaited(
        warmStart(
          targetCount: shortMotorStageOneLimit(),
          maxPages: 4,
        ),
      );
      return;
    }
    unawaited(backgroundPreload());
  }

  bool _ensureShortLaunchSessionFresh({
    required String reason,
    bool forceNew = false,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final currentSeed = startupSurfaceSessionSeed(sessionNamespace: 'short');
    final ageMs = nowMs - currentSeed;
    final shouldRotate = forceNew ||
        ageMs < 0 ||
        ageMs >= _shortLaunchSessionMaxAge.inMilliseconds;
    final deviceSession = DeviceSessionService.instance;
    final deviceSalt = deviceSession.cachedDeviceKey;
    if (shouldRotate) {
      beginStartupSurfaceSession(
        sessionNamespace: 'short',
        deviceSalt: deviceSalt,
        forceNew: true,
      );
      _log(
        '[ShortLaunchMotorSession] reason=$reason forceNew=true '
        'ageMs=$ageMs seed=${startupSurfaceSessionSeed(sessionNamespace: 'short')}',
      );
    }
    if (deviceSalt.isEmpty) {
      unawaited(
        deviceSession.warmDeviceKey().then((_) {
          final warmedSalt = deviceSession.cachedDeviceKey;
          if (warmedSalt.isEmpty) return;
          beginStartupSurfaceSession(
            sessionNamespace: 'short',
            deviceSalt: warmedSalt,
          );
        }),
      );
    }
    return shouldRotate;
  }

  Future<void> persistStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final ordered = shorts.toList(growable: false);
    await _persistShortStartupShardOnly(
      userId: userId,
      ordered: ordered,
      snapshotAt: DateTime.now(),
      source: 'short_runtime',
    );
  }

  Future<void> persistStartupArtifacts() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final snapshotAt = DateTime.now();
    final ordered = shorts.toList(growable: false);
    if (ordered.isEmpty) {
      await _persistShortStartupShardOnly(
        userId: userId,
        ordered: ordered,
        snapshotAt: snapshotAt,
        source: 'none',
      );
      return;
    }
    final snapshotLimit =
        ContentPolicy.initialPoolLimit(ContentScreenKind.shorts);
    await _shortSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: ordered,
      limit: snapshotLimit,
      source: CachedResourceSource.memory,
      snapshotAt: snapshotAt,
    );
    await _persistShortStartupShardOnly(
      userId: userId,
      ordered: ordered,
      snapshotAt: snapshotAt,
      source: 'short_runtime',
    );
  }

  Future<void> _recordShortStartupSurface({
    required String source,
    int? itemCount,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final count = itemCount ?? shorts.length;
    bool startupShardHydrated = false;
    int? startupShardAgeMs;
    if (count > 0) {
      try {
        final existingManifest =
            await ensureStartupSnapshotManifestStore().load(userId: userId);
        final existingRecord = existingManifest?.surfaces['short'];
        startupShardHydrated = existingRecord?.startupShardHydrated == true;
        startupShardAgeMs = existingRecord?.startupShardAgeMs;
      } catch (_) {}
    }
    await ensureStartupSnapshotManifestStore().recordSurfaceState(
      surface: 'short',
      userId: userId,
      itemCount: count,
      hasLocalSnapshot: count > 0,
      source: count > 0 ? source : 'none',
      startupShardHydrated: startupShardHydrated,
      startupShardAgeMs: startupShardAgeMs,
    );
  }

  Future<void> _persistShortStartupShardOnly({
    required String userId,
    required List<PostsModel> ordered,
    required DateTime snapshotAt,
    required String source,
  }) async {
    final shardLimit = ordered.length >= 6 ? 6 : ordered.length;
    if (shardLimit <= 0) {
      await ensureStartupSnapshotShardStore().clear(
        surface: 'short',
        userId: userId,
      );
      await _recordShortStartupSurface(
        source: 'none',
        itemCount: 0,
      );
      return;
    }
    await ensureStartupSnapshotShardStore().save(
      surface: 'short',
      userId: userId,
      itemCount: ordered.length,
      limit: shardLimit,
      source: source,
      snapshotAt: snapshotAt,
      payload: _shortSnapshotRepository.encodeHomeStartupPayload(
        ordered,
        limit: shardLimit,
      ),
    );
    await _recordShortStartupSurface(
      source: source,
      itemCount: ordered.length,
    );
  }
}
