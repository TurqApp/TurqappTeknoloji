import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'profile_posts_snapshot_repository_codec_part.dart';

class ProfilePostsSnapshotRepository extends GetxService {
  static const String _surfaceKey = 'profile_posts_snapshot';

  static ProfilePostsSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfilePostsSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfilePostsSnapshotRepository>();
  }

  static ProfilePostsSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfilePostsSnapshotRepository(), permanent: true);
  }

  final _ProfilePostsSnapshotRepositoryState _state;

  ProfilePostsSnapshotRepository()
      : _state = _ProfilePostsSnapshotRepositoryState() {
    _state.initialize(this);
  }
}

class _ProfilePostsSnapshotRepositoryState {
  final ProfileRepository profileRepository = ensureProfileRepository();
  final MemoryScopedSnapshotStore<ProfileBuckets> memoryStore =
      MemoryScopedSnapshotStore<ProfileBuckets>();
  late final SharedPrefsScopedSnapshotStore<ProfileBuckets> snapshotStore;
  late final CacheFirstCoordinator<ProfileBuckets> coordinator;
  late final CacheFirstQueryPipeline<ProfilePostsSnapshotQuery, ProfileBuckets,
      ProfileBuckets> pipeline;

  void initialize(ProfilePostsSnapshotRepository repository) {
    snapshotStore = SharedPrefsScopedSnapshotStore<ProfileBuckets>(
      prefsPrefix: 'profile_posts_snapshot_v2',
      encode: repository._encodeBuckets,
      decode: repository._decodeBuckets,
    );
    coordinator = CacheFirstCoordinator<ProfileBuckets>(
      memoryStore: memoryStore,
      snapshotStore: snapshotStore,
      telemetry: const CacheFirstKpiTelemetry<ProfileBuckets>(),
      policy: CacheFirstPolicyRegistry.policyForSurface(
        ProfilePostsSnapshotRepository._surfaceKey,
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
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        ProfilePostsSnapshotRepository._surfaceKey,
      ),
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

extension ProfilePostsSnapshotRepositoryFacadePart
    on ProfilePostsSnapshotRepository {
  Stream<CachedResource<ProfileBuckets>> openProfile({
    required String userId,
    int limit = 24,
    bool forceSync = false,
  }) {
    return _pipeline.open(
      ProfilePostsSnapshotQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<ProfileBuckets>> loadProfile({
    required String userId,
    int limit = 24,
    bool forceSync = false,
  }) {
    return openProfile(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<CachedResource<ProfileBuckets>> bootstrapProfile({
    required String userId,
    int limit = 24,
  }) {
    final query = ProfilePostsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return _coordinator.bootstrap(
      ScopedSnapshotKey(
        surfaceKey: ProfilePostsSnapshotRepository._surfaceKey,
        userId: query.userId.trim(),
        scopeId: query.scopeId,
      ),
      loadWarmSnapshot: () => _loadWarmSnapshot(query),
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        ProfilePostsSnapshotRepository._surfaceKey,
      ),
    );
  }

  Future<void> persistBuckets({
    required String userId,
    required ProfileBuckets buckets,
    int limit = 24,
    CachedResourceSource source = CachedResourceSource.server,
  }) async {
    if (userId.trim().isEmpty) return;
    final normalized = ProfileBuckets(
      all: buckets.all.take(limit).toList(growable: false),
      photos: buckets.photos.take(limit).toList(growable: false),
      videos: buckets.videos.take(limit).toList(growable: false),
      scheduled: buckets.scheduled.take(limit).toList(growable: false),
    );
    final query = ProfilePostsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: ProfilePostsSnapshotRepository._surfaceKey,
      userId: query.userId.trim(),
      scopeId: query.scopeId,
    );
    final record = ScopedSnapshotRecord<ProfileBuckets>(
      data: normalized,
      snapshotAt: DateTime.now(),
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        ProfilePostsSnapshotRepository._surfaceKey,
      ),
      generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    );
    await Future.wait(<Future<void>>[
      _memoryStore.write(key, record),
      _snapshotStore.write(key, record),
      _profileRepository.writeBuckets(userId, normalized),
    ]);
  }

  Future<void> clearUserSnapshots({
    String? userId,
  }) =>
      _coordinator.clearSurface(
        ProfilePostsSnapshotRepository._surfaceKey,
        userId: userId?.trim().isEmpty ?? true ? null : userId!.trim(),
      );
}

class ProfilePostsSnapshotQuery {
  const ProfilePostsSnapshotQuery({
    required this.userId,
    this.limit = 24,
    this.scopeTag = 'my_profile',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: limit,
        scopeTag: scopeTag,
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          ProfilePostsSnapshotRepository._surfaceKey,
        ),
      );
}
