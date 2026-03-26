part of 'short_snapshot_repository.dart';

class _ShortSnapshotRepositoryShellState {
  _ShortSnapshotRepositoryShellState(this.repository)
      : shortRepository = ShortRepository.ensure(),
        invariantGuard = RuntimeInvariantGuard.ensure(),
        userSummaryResolver = UserSummaryResolver.ensure(),
        visibilityPolicy = VisibilityPolicyService.ensure(),
        warmLaunchPool = WarmLaunchPool.ensure(),
        memoryStore = MemoryScopedSnapshotStore<List<PostsModel>>(),
        snapshotStore = SharedPrefsScopedSnapshotStore<List<PostsModel>>(
          prefsPrefix: 'short_snapshot_v1',
          encode: _performEncodePosts,
          decode: _performDecodePosts,
        ) {
    coordinator = CacheFirstCoordinator<List<PostsModel>>(
      memoryStore: memoryStore,
      snapshotStore: snapshotStore,
      telemetry: const CacheFirstKpiTelemetry<List<PostsModel>>(),
      policy: const CacheFirstPolicy(
        snapshotTtl: Duration(minutes: 12),
        minLiveSyncInterval: Duration(seconds: 20),
        syncOnOpen: true,
        allowWarmLaunchFallback: true,
        persistWarmLaunchSnapshot: true,
        treatWarmLaunchAsStale: true,
        preservePreviousOnEmptyLive: true,
      ),
    );
    homePipeline = CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
        List<PostsModel>>(
      surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
      coordinator: coordinator,
      userIdResolver: (query) => query.userId.trim(),
      scopeIdBuilder: (query) => query.scopeId,
      fetchRaw: (query) => _performFetchEligibleSnapshot(repository, query),
      resolve: (items) => items,
      loadWarmSnapshot: (query) => _performLoadWarmSnapshot(repository, query),
      isEmpty: (items) => items.isEmpty,
      liveSource: CachedResourceSource.server,
    );
  }

  final ShortSnapshotRepository repository;
  final ShortRepository shortRepository;
  final RuntimeInvariantGuard invariantGuard;
  final UserSummaryResolver userSummaryResolver;
  final VisibilityPolicyService visibilityPolicy;
  final WarmLaunchPool warmLaunchPool;
  final MemoryScopedSnapshotStore<List<PostsModel>> memoryStore;
  final SharedPrefsScopedSnapshotStore<List<PostsModel>> snapshotStore;
  late CacheFirstCoordinator<List<PostsModel>> coordinator;
  late CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
      List<PostsModel>> homePipeline;
}

extension ShortSnapshotRepositoryFieldsPart on ShortSnapshotRepository {
  ShortRepository get _shortRepository => _shellState.shortRepository;
  RuntimeInvariantGuard get _invariantGuard => _shellState.invariantGuard;
  UserSummaryResolver get _userSummaryResolver =>
      _shellState.userSummaryResolver;
  VisibilityPolicyService get _visibilityPolicy => _shellState.visibilityPolicy;
  WarmLaunchPool get _warmLaunchPool => _shellState.warmLaunchPool;
  MemoryScopedSnapshotStore<List<PostsModel>> get _memoryStore =>
      _shellState.memoryStore;
  SharedPrefsScopedSnapshotStore<List<PostsModel>> get _snapshotStore =>
      _shellState.snapshotStore;
  CacheFirstCoordinator<List<PostsModel>> get _coordinator =>
      _shellState.coordinator;
  CacheFirstQueryPipeline<ShortSnapshotQuery, List<PostsModel>,
      List<PostsModel>> get _homePipeline => _shellState.homePipeline;
}
