part of 'feed_snapshot_repository.dart';

class _FeedSnapshotRepositoryState {
  _FeedSnapshotRepositoryState(this.repository);

  final FeedSnapshotRepository repository;

  late final PostRepository postRepository = PostRepository.ensure();
  late final RuntimeInvariantGuard invariantGuard =
      RuntimeInvariantGuard.ensure();
  late final UserSummaryResolver userSummaryResolver =
      UserSummaryResolver.ensure();
  late final VisibilityPolicyService visibilityPolicy =
      VisibilityPolicyService.ensure();
  late final WarmLaunchPool warmLaunchPool = WarmLaunchPool.ensure();
  late final MemoryScopedSnapshotStore<List<PostsModel>> memoryStore =
      MemoryScopedSnapshotStore<List<PostsModel>>();
  late final SharedPrefsScopedSnapshotStore<List<PostsModel>> snapshotStore =
      SharedPrefsScopedSnapshotStore<List<PostsModel>>(
    prefsPrefix: 'feed_snapshot_v1',
    encode: repository._encodePosts,
    decode: repository._decodePosts,
  );
  late final CacheFirstCoordinator<List<PostsModel>> coordinator =
      CacheFirstCoordinator<List<PostsModel>>(
    memoryStore: memoryStore,
    snapshotStore: snapshotStore,
    telemetry: const CacheFirstKpiTelemetry<List<PostsModel>>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 10),
      minLiveSyncInterval: Duration(seconds: 20),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );
  late final CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>,
          List<PostsModel>> homePipeline =
      CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>,
          List<PostsModel>>(
    surfaceKey: FeedSnapshotRepository._homeSurfaceKey,
    coordinator: coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: repository._fetchHomeSnapshot,
    resolve: (items) => items,
    loadWarmSnapshot: repository._loadWarmHomeSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );
}

extension FeedSnapshotRepositoryFieldsPart on FeedSnapshotRepository {
  bool get _shouldLogDiagnostics => kDebugMode && !IntegrationTestMode.enabled;
  PostRepository get _postRepository => _state.postRepository;
  RuntimeInvariantGuard get _invariantGuard => _state.invariantGuard;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  WarmLaunchPool get _warmLaunchPool => _state.warmLaunchPool;
  MemoryScopedSnapshotStore<List<PostsModel>> get _memoryStore =>
      _state.memoryStore;
  SharedPrefsScopedSnapshotStore<List<PostsModel>> get _snapshotStore =>
      _state.snapshotStore;
  CacheFirstCoordinator<List<PostsModel>> get _coordinator =>
      _state.coordinator;
  CacheFirstQueryPipeline<FeedSnapshotQuery, List<PostsModel>, List<PostsModel>>
      get _homePipeline => _state.homePipeline;
}
