part of 'short_controller.dart';

const bool _verboseShortLogs = false;
const int _initialPreloadCount = 5;
const int _startupReadyMagazineCount = 5;
const double _shortLandscapeAspectThreshold = 1.2;
const double _mobileShortLowQuotaRatio = 0.15;
const Duration _shortLaunchSessionMaxAge = Duration(hours: 1);
final double _activeBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 10.0 : 6.4;
final double _neighborBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 6.0 : 4.8;
final double _prepBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 2.8 : 3.8;
Future<void>? _shortProxyWarmPathFuture;

Future<void> _ensureShortProxyWarmPathReady({
  Duration timeout = const Duration(milliseconds: 1200),
}) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final existingCache = SegmentCacheManager.maybeFind();
  final existingProxy = maybeFindHlsProxyServer();
  if ((existingCache?.isReady ?? false) &&
      (existingProxy?.isStarted ?? false)) {
    return;
  }

  var future = _shortProxyWarmPathFuture;
  if (future == null) {
    final created = () async {
      final startedAt = DateTime.now();
      final cache = SegmentCacheManager.ensure();
      if (!cache.isReady) {
        await cache.init();
      }
      ensurePrefetchScheduler(permanent: true);
      final proxy = ensureHlsProxyServer(permanent: true);
      if (!proxy.isStarted) {
        await proxy.start();
      }
      debugPrint(
        '[ShortProxyWarmPath] status=ready elapsedMs='
        '${DateTime.now().difference(startedAt).inMilliseconds} '
        'proxyStarted=${proxy.isStarted} cacheReady=${cache.isReady}',
      );
    }();
    _shortProxyWarmPathFuture = created;
    created.whenComplete(() {
      if (identical(_shortProxyWarmPathFuture, created)) {
        _shortProxyWarmPathFuture = null;
      }
    });
    future = created;
  }

  try {
    await future.timeout(timeout);
  } on TimeoutException {
    final cache = SegmentCacheManager.maybeFind();
    final proxy = maybeFindHlsProxyServer();
    debugPrint(
      '[ShortProxyWarmPath] status=timeout proxyStarted='
      '${proxy?.isStarted ?? false} cacheReady=${cache?.isReady ?? false}',
    );
  } catch (e) {
    debugPrint('[ShortProxyWarmPath] status=error error=$e');
  }
}

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
    debugPrint(
      '[ShortColdStart] stage=controller_on_init at=${DateTime.now().toIso8601String()}',
    );
    applyUserCacheQuota();
    unawaited(DeviceSessionService.instance.warmDeviceKey());
    _log('[Shorts] 🔄 ShortController.onInit() called');
    _bindFollowingListener();
    _bindNetworkAwareness();
  }

  Future<void> applyUserCacheQuota() async {
    try {
      final preferences = ensureLocalPreferenceRepository();
      final quotaGb = normalizeStorageBudgetPlanGb(
        await preferences.getInt('offline_cache_quota_gb') ?? 3,
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
    _persistVisibleSnapshotTimer?.cancel();
    _persistVisibleSnapshotTimer = null;
    _playbackCoordinator.reset();
    _prefetchedPosterDocIds.clear();
    clearCache();
    _state.followingSub?.cancel();
    _networkWorker?.dispose();
  }

  List<String> _posterWarmUrlsForPost(PostsModel post) {
    final urls = <String>[];

    void addUrl(String rawUrl) {
      final normalized = CdnUrlBuilder.toCdnUrl(rawUrl.trim());
      if (normalized.isEmpty || urls.contains(normalized)) return;
      urls.add(normalized);
    }

    addUrl(post.thumbnail);
    for (final posterUrl in post.preferredVideoPosterUrls) {
      addUrl(posterUrl);
    }
    for (final imageUrl in post.img) {
      addUrl(imageUrl);
    }
    for (final cdnUrl
        in CdnUrlBuilder.buildThumbnailUrlCandidates(post.docID)) {
      addUrl(cdnUrl);
    }
    return urls;
  }

  void warmPosterWindowAround(
    int anchorIndex, {
    int behindCount = 1,
    int aheadCount = _initialPreloadCount,
  }) {
    if (shorts.isEmpty) return;
    final safeAnchor = anchorIndex.clamp(0, shorts.length - 1);
    final start = math.max(0, safeAnchor - behindCount);
    final endExclusive = math.min(shorts.length, safeAnchor + aheadCount + 1);
    for (int i = start; i < endExclusive; i++) {
      final post = shorts[i];
      if (!_prefetchedPosterDocIds.add(post.docID)) continue;
      for (final url in _posterWarmUrlsForPost(post)) {
        TurqImageCacheManager.warmUrl(url).ignore();
      }
    }
  }

  void _bindNetworkAwareness() {
    final network = NetworkAwarenessService.maybeFind();
    if (network == null) return;
    _networkWorker?.dispose();
    _networkWorker = ever<NetworkType>(
      network.currentNetworkRx,
      (networkType) {
        if (_shortSessionSourceMode == _ShortSessionSourceMode.unresolved) {
          _log(
            '[ShortSessionSource] status=defer_runtime_transition '
            'network=${networkType.name}',
          );
          return;
        }
        handleNetworkPolicyTransition(networkType);
      },
    );
  }

  Future<void> ensureShortSurfaceReady({
    required int minimumCount,
  }) async {
    if (shorts.isEmpty) {
      if (_backgroundPreloadFuture != null) {
        await _backgroundPreloadFuture;
      } else {
        await _runInitialLoadOnce();
      }
    }

    var attempts = 0;
    while (shorts.length < minimumCount &&
        hasMore.value &&
        !isLoading.value &&
        attempts < 6) {
      await _loadNextPage(trigger: 'startup_surface_ready_gate');
      attempts++;
    }
  }

  _ShortSessionSourceMode _resolveShortSessionSourceMode({
    required String reason,
  }) {
    final existing = _shortSessionSourceMode;
    if (existing != _ShortSessionSourceMode.unresolved) {
      return existing;
    }
    final network =
        NetworkAwarenessService.maybeFind()?.currentNetworkRx.value ??
            NetworkType.none;
    _shortStartupNetworkType ??= network;
    final offlineReadyCount = _offlineReadyShortPoolCount();
    final resolved = network == NetworkType.wifi
        ? _ShortSessionSourceMode.wifiLive
        : offlineReadyCount > 0
            ? _ShortSessionSourceMode.mobileCacheOnly
            : _ShortSessionSourceMode.mobileNetworkFallback;
    _shortSessionSourceMode = resolved;
    _renderWindowFrozenOnCellular =
        resolved == _ShortSessionSourceMode.mobileCacheOnly;
    debugPrint(
      '[ShortSessionSource] status=resolved reason=$reason '
      'mode=${resolved.name} network=${network.name} '
      'offlineReadyCount=$offlineReadyCount freeze=$_renderWindowFrozenOnCellular',
    );
    return resolved;
  }

  int _offlineReadyShortPoolCount() {
    final cacheManager = maybeFindSegmentCacheManager();
    if (cacheManager == null || !cacheManager.isReady) {
      return 0;
    }
    return cacheManager
        .getOfflineReadyDocIdsForShort(limit: ShortGrowthPolicy.stageOneLimit)
        .length;
  }

  int _mobileShortLowQuotaThresholdCount() {
    final threshold =
        (ShortGrowthPolicy.stageOneLimit * _mobileShortLowQuotaRatio).ceil();
    return math.max(_initialPreloadCount, threshold);
  }

  bool _shouldPromoteShortMobileFallback({
    required String reason,
  }) {
    if (_shortSessionSourceMode != _ShortSessionSourceMode.mobileCacheOnly) {
      return false;
    }
    if (shorts.length > 1) {
      return false;
    }
    final offlineReadyCount = _offlineReadyShortPoolCount();
    final threshold = _mobileShortLowQuotaThresholdCount();
    final shouldPromote = offlineReadyCount <= threshold;
    debugPrint(
      '[ShortSessionSource] status=check_mobile_fallback reason=$reason '
      'currentCount=${shorts.length} offlineReadyCount=$offlineReadyCount '
      'threshold=$threshold shouldPromote=$shouldPromote',
    );
    return shouldPromote;
  }

  bool _promoteShortSessionToMobileNetworkFallback({
    required String reason,
  }) {
    if (!_shouldPromoteShortMobileFallback(reason: reason)) {
      return false;
    }
    _shortSessionSourceMode = _ShortSessionSourceMode.mobileNetworkFallback;
    _renderWindowFrozenOnCellular = false;
    debugPrint(
      '[ShortSessionSource] status=promoted reason=$reason '
      'mode=${_shortSessionSourceMode.name}',
    );
    return true;
  }

  bool _promoteShortSessionToWifiLive({
    required String reason,
  }) {
    if (_shortSessionSourceMode == _ShortSessionSourceMode.wifiLive) {
      return false;
    }
    _shortSessionSourceMode = _ShortSessionSourceMode.wifiLive;
    _renderWindowFrozenOnCellular = false;
    debugPrint(
      '[ShortSessionSource] status=promoted reason=$reason '
      'mode=${_shortSessionSourceMode.name}',
    );
    return true;
  }
}

extension ShortControllerPublicApiPart on ShortController {
  bool isStartupBootstrapInFlight() {
    return _startupPrepareFuture != null ||
        _initialLoadFuture != null ||
        isLoading.value;
  }

  Future<void> ensureStartupReadyForRoute({
    int minimumCount = _initialPreloadCount,
  }) =>
      ensureShortSurfaceReady(minimumCount: minimumCount);

  void handleNetworkPolicyTransition(NetworkType networkType) {
    final mode = _shortSessionSourceMode;
    debugPrint(
      '[ShortNetworkPolicy] status=dispatch network=${networkType.name} '
      'mode=${mode.name} frozen=$_renderWindowFrozenOnCellular '
      'count=${shorts.length}',
    );
    if (mode == _ShortSessionSourceMode.unresolved) {
      debugPrint(
        '[ShortNetworkPolicy] status=deferred_until_session_resolution '
        'network=${networkType.name}',
      );
      return;
    }
    if (networkType == NetworkType.wifi &&
        _promoteShortSessionToWifiLive(
          reason: 'runtime_network_${networkType.name}',
        )) {
      debugPrint(
        '[ShortNetworkPolicy] status=session_upgraded_to_wifi_live '
        'network=${networkType.name} count=${shorts.length}',
      );
      unawaited(prepareStartupSurface(allowBackgroundRefresh: true));
      return;
    }
    if (mode == _ShortSessionSourceMode.mobileCacheOnly) {
      if (_promoteShortSessionToMobileNetworkFallback(
        reason: 'runtime_network_${networkType.name}',
      )) {
        unawaited(prepareStartupSurface(allowBackgroundRefresh: true));
        return;
      }
      _renderWindowFrozenOnCellular = true;
      debugPrint(
        '[ShortNetworkPolicy] status=session_locked_cache_only '
        'network=${networkType.name} count=${shorts.length}',
      );
      return;
    }
    _renderWindowFrozenOnCellular = false;
    debugPrint(
      '[ShortNetworkPolicy] status=session_live '
      'network=${networkType.name} mode=${mode.name} count=${shorts.length}',
    );
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
    final startedAt = DateTime.now();
    final startedEmpty = shorts.isEmpty && !_startupPresentationApplied;
    debugPrint(
      '[ShortColdStart] stage=prepare_start at=${startedAt.toIso8601String()} '
      'count=${shorts.length} isLoading=${isLoading.value} hasMore=${hasMore.value}',
    );
    _resolveShortSessionSourceMode(reason: 'prepare_startup_surface');
    _recordShortMotorContractSnapshot(reason: 'prepare_startup_surface');
    unawaited(_ensureShortProxyWarmPathReady());
    final seededFreshSession = _ensureShortLaunchSessionFresh(
      reason: startedEmpty ? 'startup' : 'surface_visible',
      forceNew: startedEmpty,
    );
    final allowRefresh = allowBackgroundRefresh ??
        ContentPolicy.allowBackgroundRefresh(ContentScreenKind.shorts);
    await ensureShortSurfaceReady(minimumCount: _initialPreloadCount);
    if (shorts.length < ShortGrowthPolicy.initialBlockSize &&
        hasMore.value &&
        !isLoading.value) {
      unawaited(
        warmStart(
          targetCount: ShortGrowthPolicy.initialBlockSize,
          maxPages: 1,
        ),
      );
    }
    await reconcileVisibleShortSurface(
      trigger: 'primary_surface_visible_reconcile',
    );
    if (shorts.isNotEmpty) {
      warmPosterWindowAround(
        _currentVisibleShortIndex(this),
        behindCount: 0,
        aheadCount: _initialPreloadCount,
      );
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
    if (ShortFetchPolicy.shouldRefreshAfterStartupSurface(
      startedEmpty: startedEmpty,
      seededFreshSession: seededFreshSession,
      hasShorts: shorts.isNotEmpty,
      isRefreshing: isRefreshing.value,
      isLoading: isLoading.value,
      allowBackgroundRefresh: allowRefresh,
    )) {
      unawaited(refreshShorts());
    }
    if (!allowRefresh || shorts.isEmpty) return;
    if (shorts.length < ShortGrowthPolicy.initialBlockSize) {
      unawaited(
        warmStart(
          targetCount: ShortGrowthPolicy.initialBlockSize,
          maxPages: 1,
        ),
      );
      return;
    }
    unawaited(backgroundPreload());
    debugPrint(
      '[ShortColdStart] stage=prepare_end elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
      'count=${shorts.length} isLoading=${isLoading.value} hasMore=${hasMore.value}',
    );
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
      clearPreferredLaunchAnchor(preferFreshIndex: true);
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
    await ensureStartupSnapshotShardStore().clear(
      surface: 'short',
      userId: userId,
    );
  }

  Future<void> persistStartupArtifacts() async {
    await persistStartupShard();
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
}
