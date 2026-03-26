part of 'profile_posts_snapshot_repository.dart';

class _ProfilePostsSnapshotRepositoryState {
  final ProfileRepository profileRepository = ProfileRepository.ensure();
  final MemoryScopedSnapshotStore<ProfileBuckets> memoryStore =
      MemoryScopedSnapshotStore<ProfileBuckets>();
  late final SharedPrefsScopedSnapshotStore<ProfileBuckets> snapshotStore;
  late final CacheFirstCoordinator<ProfileBuckets> coordinator;
  late final CacheFirstQueryPipeline<ProfilePostsSnapshotQuery, ProfileBuckets,
      ProfileBuckets> pipeline;

  void initialize(ProfilePostsSnapshotRepository repository) {
    snapshotStore = SharedPrefsScopedSnapshotStore<ProfileBuckets>(
      prefsPrefix: 'profile_posts_snapshot_v1',
      encode: repository._encodeBuckets,
      decode: repository._decodeBuckets,
    );
    coordinator = CacheFirstCoordinator<ProfileBuckets>(
      memoryStore: memoryStore,
      snapshotStore: snapshotStore,
      telemetry: const CacheFirstKpiTelemetry<ProfileBuckets>(),
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
    pipeline = CacheFirstQueryPipeline<ProfilePostsSnapshotQuery,
        ProfileBuckets, ProfileBuckets>(
      surfaceKey: ProfilePostsSnapshotRepository._surfaceKey,
      coordinator: coordinator,
      userIdResolver: (query) => query.userId.trim(),
      scopeIdBuilder: (query) => query.scopeId,
      fetchRaw: repository._fetchBuckets,
      resolve: (buckets) => buckets,
      loadWarmSnapshot: repository._loadWarmSnapshot,
      isEmpty: (buckets) =>
          buckets.all.isEmpty &&
          buckets.photos.isEmpty &&
          buckets.videos.isEmpty &&
          buckets.scheduled.isEmpty,
      liveSource: CachedResourceSource.server,
    );
  }
}

extension ProfilePostsSnapshotRepositoryFieldsPart
    on ProfilePostsSnapshotRepository {
  ProfileRepository get _profileRepository => _state.profileRepository;
  MemoryScopedSnapshotStore<ProfileBuckets> get _memoryStore =>
      _state.memoryStore;
  SharedPrefsScopedSnapshotStore<ProfileBuckets> get _snapshotStore =>
      _state.snapshotStore;
  CacheFirstCoordinator<ProfileBuckets> get _coordinator => _state.coordinator;
  CacheFirstQueryPipeline<ProfilePostsSnapshotQuery, ProfileBuckets,
      ProfileBuckets> get _pipeline => _state.pipeline;
}
