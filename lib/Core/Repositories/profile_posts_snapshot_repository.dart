import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'profile_posts_snapshot_repository_codec_part.dart';

class ProfilePostsSnapshotRepository extends GetxService {
  static const String _surfaceKey = 'profile_posts_snapshot';
  static const int _defaultScopeLimit =
      ReadBudgetRegistry.profilePostsInitialLimit;

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
    int limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
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
    int limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
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
    int limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
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
    int limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
    CachedResourceSource source = CachedResourceSource.server,
  }) async {
    await writeLocalBuckets(
      userId: userId,
      buckets: buckets,
      limit: limit,
      source: source,
    );
  }

  Future<void> clearUserSnapshots({
    String? userId,
  }) =>
      _coordinator.clearSurface(
        ProfilePostsSnapshotRepository._surfaceKey,
        userId: userId?.trim().isEmpty ?? true ? null : userId!.trim(),
      );

  Future<ProfileBuckets?> readLocalBuckets({
    required String userId,
    int limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    final key = _localScopeKey(
      userId: normalizedUserId,
      limit: limit,
    );
    final memory = await _memoryStore.read(key, allowStale: true);
    if (memory != null) return memory.data;
    final disk = await _snapshotStore.read(key, allowStale: true);
    if (disk == null) return null;
    await _memoryStore.write(key, disk);
    return disk.data;
  }

  Future<void> writeLocalBuckets({
    required String userId,
    required ProfileBuckets buckets,
    int limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
    CachedResourceSource source = CachedResourceSource.server,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    final normalized = ProfileBuckets(
      all: buckets.all.take(limit).toList(growable: false),
      photos: buckets.photos.take(limit).toList(growable: false),
      videos: buckets.videos.take(limit).toList(growable: false),
      scheduled: buckets.scheduled.take(limit).toList(growable: false),
    );
    final key = _localScopeKey(
      userId: normalizedUserId,
      limit: limit,
    );
    final isEmptyBuckets = normalized.all.isEmpty &&
        normalized.photos.isEmpty &&
        normalized.videos.isEmpty &&
        normalized.scheduled.isEmpty;
    if (isEmptyBuckets) {
      await Future.wait(<Future<void>>[
        _memoryStore.clearScope(key),
        _snapshotStore.clearScope(key),
      ]);
      return;
    }
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
    ]);
  }

  Future<void> removePostLocally({
    required String userId,
    required String docId,
    Iterable<int> additionalLimits = const <int>[],
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedDocId = docId.trim();
    if (normalizedUserId.isEmpty || normalizedDocId.isEmpty) return;
    final limits = <int>{
      ProfilePostsSnapshotRepository._defaultScopeLimit,
      ...additionalLimits.where((value) => value > 0),
    };
    for (final limit in limits) {
      final existing = await readLocalBuckets(
        userId: normalizedUserId,
        limit: limit,
      );
      if (existing == null) continue;
      final filtered = ProfileBuckets(
        all: existing.all
            .where((post) => post.docID != normalizedDocId)
            .toList(growable: false),
        photos: existing.photos
            .where((post) => post.docID != normalizedDocId)
            .toList(growable: false),
        videos: existing.videos
            .where((post) => post.docID != normalizedDocId)
            .toList(growable: false),
        scheduled: existing.scheduled
            .where((post) => post.docID != normalizedDocId)
            .toList(growable: false),
      );
      await writeLocalBuckets(
        userId: normalizedUserId,
        buckets: filtered,
        limit: limit,
      );
    }
  }

  Future<void> clearLocalUser({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    final limits = <int>{ProfilePostsSnapshotRepository._defaultScopeLimit};
    for (final limit in limits) {
      final key = _localScopeKey(
        userId: normalizedUserId,
        limit: limit,
      );
      await Future.wait(<Future<void>>[
        _memoryStore.clearScope(key),
        _snapshotStore.clearScope(key),
      ]);
    }
  }

  ScopedSnapshotKey _localScopeKey({
    required String userId,
    required int limit,
  }) {
    final query = ProfilePostsSnapshotQuery(
      userId: userId,
      limit: limit,
    );
    return ScopedSnapshotKey(
      surfaceKey: ProfilePostsSnapshotRepository._surfaceKey,
      userId: query.userId.trim(),
      scopeId: query.scopeId,
    );
  }
}

class ProfilePostsSnapshotQuery {
  const ProfilePostsSnapshotQuery({
    required this.userId,
    this.limit = ProfilePostsSnapshotRepository._defaultScopeLimit,
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
