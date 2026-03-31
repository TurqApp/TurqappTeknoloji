part of 'short_snapshot_repository.dart';

extension ShortSnapshotRepositoryRuntimeX on ShortSnapshotRepository {
  Stream<CachedResource<List<PostsModel>>> openHome({
    required String userId,
    int limit = ShortSnapshotRepository._defaultPersistLimit,
    bool forceSync = false,
  }) =>
      _openHome(
        this,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<PostsModel>>> bootstrapHome({
    required String userId,
    int limit = ShortSnapshotRepository._defaultPersistLimit,
  }) =>
      _bootstrapHome(
        this,
        userId: userId,
        limit: limit,
      );

  Future<CachedResource<List<PostsModel>>> loadHome({
    required String userId,
    int limit = ShortSnapshotRepository._defaultPersistLimit,
    bool forceSync = false,
  }) =>
      _loadHome(
        this,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<void> persistHomeSnapshot({
    required String userId,
    required List<PostsModel> posts,
    int limit = ShortSnapshotRepository._defaultPersistLimit,
    CachedResourceSource source = CachedResourceSource.server,
    DateTime? snapshotAt,
  }) =>
      _persistHomeSnapshot(
        this,
        userId: userId,
        posts: posts,
        limit: ReadBudgetRegistry.resolveShortHomeInitialLimit(limit),
        source: source,
        snapshotAt: snapshotAt,
      );

  Map<String, dynamic> encodeHomeStartupPayload(
    List<PostsModel> posts, {
    int limit = ShortSnapshotRepository._defaultPersistLimit,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveShortHomeInitialLimit(limit);
    final normalized =
        _normalizePosts(posts).take(effectiveLimit).toList(growable: false);
    return _performEncodePosts(normalized);
  }

  Future<bool> primeHomeFromStartupPayload({
    required String userId,
    required Map<String, dynamic> payload,
    int limit = ShortSnapshotRepository._defaultPersistLimit,
    Iterable<int> additionalLimits = const <int>[],
    DateTime? snapshotAt,
    CachedResourceSource source = CachedResourceSource.scopedDisk,
  }) async {
    final effectiveLimit =
        ReadBudgetRegistry.resolveShortHomeInitialLimit(limit);
    TurqImageCacheManager.hydratePosterHintsFromPayload(payload);
    final decoded = _performDecodePosts(payload);
    final normalized =
        _normalizePosts(decoded).take(effectiveLimit).toList(growable: false);
    if (normalized.isEmpty) return false;
    final scopeLimits = <int>{
      effectiveLimit,
      ...additionalLimits.where((value) => value > 0),
    };
    final record = ScopedSnapshotRecord<List<PostsModel>>(
      data: normalized,
      snapshotAt: snapshotAt ?? DateTime.now(),
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        ShortSnapshotRepository._homeSurfaceKey,
      ),
      generationId: 'startup_shard:${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    );
    await Future.wait(
      scopeLimits.map(
        (scopeLimit) => _memoryStore.write(
          ScopedSnapshotKey(
            surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
            userId: userId.trim(),
            scopeId: ShortSnapshotQuery(
              userId: userId,
              limit: scopeLimit,
            ).scopeId,
          ),
          record,
        ),
      ),
    );
    return true;
  }

  Future<Set<String>> _loadFollowingIds(String userId) =>
      _performLoadFollowingIds(
        this,
        userId,
      );

  Future<List<PostsModel>> _filterEligiblePosts(
    List<PostsModel> posts, {
    required String currentUserId,
    required Set<String> followingIds,
  }) =>
      _performFilterEligiblePosts(
        this,
        posts,
        currentUserId: currentUserId,
        followingIds: followingIds,
      );

  List<PostsModel> _normalizePosts(List<PostsModel> posts) =>
      _performNormalizePosts(posts);
}
