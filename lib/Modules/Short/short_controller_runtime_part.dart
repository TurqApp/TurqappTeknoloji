part of 'short_controller.dart';

const bool _verboseShortLogs = false;
const int _initialPreloadCount = 3;
const double _shortLandscapeAspectThreshold = 1.2;
final double _activeBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 5.0 : 4.8;
final double _neighborBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 3.6 : 3.6;
final double _prepBufferSeconds =
    defaultTargetPlatform == TargetPlatform.android ? 2.8 : 3.0;
bool _globalShuffleCompleted = false;

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
    final ar = post.aspectRatio.toDouble();
    if (ar > _shortLandscapeAspectThreshold) {
      return false;
    }
    return true;
  }

  void handleOnInit() {
    applyUserCacheQuota();
    _log('[Shorts] 🔄 ShortController.onInit() called');
    _bindFollowingListener();
  }

  Future<void> applyUserCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGb = (prefs.getInt('offline_cache_quota_gb') ?? 3).clamp(3, 6);
      final quotaGb = (savedGb + 1).clamp(4, 7);
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(quotaGb);
    } catch (e) {
      _log('Shorts cache quota apply error: $e');
    }
  }

  void handleOnClose() {
    _log('[Shorts] ❌ ShortController.onClose() called');
    _playbackCoordinator.reset();
    clearCache();
    _state.followingSub?.cancel();
  }
}

extension ShortControllerPublicApiPart on ShortController {
  Future<void> prepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) async {
    final allowRefresh = allowBackgroundRefresh ??
        ContentPolicy.allowBackgroundRefresh(ContentScreenKind.shorts);
    if (shorts.isEmpty) {
      if (_backgroundPreloadFuture != null) {
        await _backgroundPreloadFuture;
      } else {
        await _runInitialLoadOnce();
      }
    }
    if (shorts.isNotEmpty) {
      await preloadRange(0, range: 0);
    }
    if (!allowRefresh || shorts.isEmpty) return;
    unawaited(backgroundPreload());
  }

  Future<void> persistStartupShard() => persistStartupArtifacts();

  Future<void> persistStartupArtifacts() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty || shorts.isEmpty) return;
    final snapshotAt = DateTime.now();
    final ordered = shorts.toList(growable: false);
    final snapshotLimit =
        ContentPolicy.initialPoolLimit(ContentScreenKind.shorts);
    await _shortSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: ordered,
      limit: snapshotLimit,
      source: CachedResourceSource.memory,
      snapshotAt: snapshotAt,
    );
    final shardLimit = ordered.length >= 6 ? 6 : ordered.length;
    if (shardLimit <= 0) return;
    await ensureStartupSnapshotShardStore().save(
      surface: 'short',
      userId: userId,
      itemCount: ordered.length,
      limit: shardLimit,
      source: 'short_runtime',
      snapshotAt: snapshotAt,
      payload: _shortSnapshotRepository.encodeHomeStartupPayload(
        ordered,
        limit: shardLimit,
      ),
    );
    await ensureStartupSnapshotManifestStore().recordSurfaceState(
      surface: 'short',
      userId: userId,
      itemCount: ordered.length,
      hasLocalSnapshot: true,
      source: 'short_runtime',
    );
  }
}
