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

  Future<void> clearLaunchArtifacts({
    required String userId,
    Iterable<int> additionalLimits = const <int>[],
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final scopeLimits = <int>{
      ReadBudgetRegistry.shortHomeInitialLimitValue,
      ...additionalLimits.where((value) => value > 0),
    };

    await Future.wait(<Future<void>>[
      for (final scopeLimit in scopeLimits)
        Future.wait(<Future<void>>[
          _memoryStore.clearScope(
            ScopedSnapshotKey(
              surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
              userId: normalizedUserId,
              scopeId: ShortSnapshotQuery(
                userId: normalizedUserId,
                limit: scopeLimit,
              ).scopeId,
            ),
          ),
          _snapshotStore.clearScope(
            ScopedSnapshotKey(
              surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
              userId: normalizedUserId,
              scopeId: ShortSnapshotQuery(
                userId: normalizedUserId,
                limit: scopeLimit,
              ).scopeId,
            ),
          ),
        ]),
      _warmLaunchPool.clearKind(IndexPoolKind.shortFullscreen),
      ensureStartupSnapshotShardStore().clear(
        surface: 'short',
        userId: normalizedUserId,
      ),
    ]);
  }

  Future<void> pruneLaunchArtifacts({
    required String userId,
    required Iterable<String> docIds,
    Iterable<int> additionalLimits = const <int>[],
  }) async {
    final normalizedUserId = userId.trim();
    final removeIds = docIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalizedUserId.isEmpty || removeIds.isEmpty) return;

    final scopeLimits = <int>{
      ReadBudgetRegistry.shortHomeInitialLimitValue,
      ...additionalLimits.where((value) => value > 0),
    };

    for (final scopeLimit in scopeLimits) {
      final key = ScopedSnapshotKey(
        surfaceKey: ShortSnapshotRepository._homeSurfaceKey,
        userId: normalizedUserId,
        scopeId: ShortSnapshotQuery(
          userId: normalizedUserId,
          limit: scopeLimit,
        ).scopeId,
      );
      final memoryRecord = await _memoryStore.read(key, allowStale: true);
      final diskRecord = await _snapshotStore.read(key, allowStale: true);
      final record = memoryRecord ?? diskRecord;
      if (record == null) continue;

      final filtered = _normalizePosts(record.data)
          .where((post) => !removeIds.contains(post.docID))
          .take(scopeLimit)
          .toList(growable: false);

      if (filtered.length == record.data.length) continue;

      if (filtered.isEmpty) {
        await Future.wait(<Future<void>>[
          _memoryStore.clearScope(key),
          _snapshotStore.clearScope(key),
        ]);
        continue;
      }

      final nextRecord = ScopedSnapshotRecord<List<PostsModel>>(
        data: filtered,
        snapshotAt: record.snapshotAt,
        schemaVersion: record.schemaVersion,
        generationId: record.generationId,
        source: record.source,
      );
      await Future.wait(<Future<void>>[
        _memoryStore.write(key, nextRecord),
        _snapshotStore.write(key, nextRecord),
      ]);
    }

    await _warmLaunchPool.removePosts(
      IndexPoolKind.shortFullscreen,
      removeIds.toList(growable: false),
    );

    final shardStore = ensureStartupSnapshotShardStore();
    final shard = await shardStore.load(
      surface: 'short',
      userId: normalizedUserId,
      maxAge: StartupSnapshotShardStore.defaultFreshWindow,
    );
    if (shard == null || shard.itemCount <= 0 || shard.payload.isEmpty) return;

    final effectiveLimit = shard.limit > 0
        ? shard.limit
        : ReadBudgetRegistry.shortHomeInitialLimitValue;
    final current = _normalizePosts(_performDecodePosts(shard.payload))
        .take(effectiveLimit)
        .toList(growable: false);
    if (current.isEmpty) {
      await shardStore.clear(
        surface: 'short',
        userId: normalizedUserId,
      );
      return;
    }

    final filtered = current
        .where((post) => !removeIds.contains(post.docID))
        .take(effectiveLimit)
        .toList(growable: false);
    if (filtered.length == current.length) return;

    if (filtered.isEmpty) {
      await shardStore.clear(
        surface: 'short',
        userId: normalizedUserId,
      );
      return;
    }

    await shardStore.save(
      surface: 'short',
      userId: normalizedUserId,
      itemCount: filtered.length,
      limit: effectiveLimit,
      source: shard.source,
      snapshotAt: shard.snapshotAt,
      payload: encodeHomeStartupPayload(
        filtered,
        limit: effectiveLimit,
      ),
    );
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
