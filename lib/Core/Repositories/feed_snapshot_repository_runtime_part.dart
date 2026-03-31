part of 'feed_snapshot_repository.dart';

Future<CachedResource<List<PostsModel>>> bootstrapFeedHome(
  FeedSnapshotRepository repository, {
  required String userId,
  int limit = ReadBudgetRegistry.feedHomeInitialLimit,
}) {
  final effectiveLimit = ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
  final query = FeedSnapshotQuery(
    userId: userId,
    limit: effectiveLimit,
  );
  return repository._coordinator.bootstrap(
    repository._homeKey(query),
    loadWarmSnapshot: () => repository._loadWarmHomeSnapshot(query),
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      FeedSnapshotRepository._homeSurfaceKey,
    ),
  );
}

Future<CachedResource<List<PostsModel>>> inspectWarmFeedHome(
  FeedSnapshotRepository repository, {
  required String userId,
  int limit = FeedSnapshotRepository.startupHomeLimit,
}) async {
  final effectiveLimit = ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
  final query = FeedSnapshotQuery(
    userId: userId,
    limit: effectiveLimit,
  );
  final warmData = await repository._loadWarmHomeSnapshot(query);
  if (warmData == null || warmData.isEmpty) {
    return const CachedResource<List<PostsModel>>.empty();
  }
  return CachedResource<List<PostsModel>>(
    data: warmData,
    hasLocalSnapshot: true,
    isRefreshing: false,
    isStale: repository._coordinator.policy.treatWarmLaunchAsStale,
    hasLiveError: false,
    snapshotAt: null,
    source: CachedResourceSource.warmLaunchPool,
  );
}

Future<void> persistFeedHomeSnapshot(
  FeedSnapshotRepository repository, {
  required String userId,
  required List<PostsModel> posts,
  int limit = FeedSnapshotRepository._defaultPersistLimit,
  CachedResourceSource source = CachedResourceSource.server,
  DateTime? snapshotAt,
}) async {
  final effectiveLimit = ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
  final normalized = repository
      ._normalizePosts(posts)
      .take(effectiveLimit)
      .toList(growable: false);
  final key = repository._homeKey(FeedSnapshotQuery(
    userId: userId,
    limit: effectiveLimit,
  ));
  if (normalized.isEmpty) {
    await Future.wait(<Future<void>>[
      repository._memoryStore.clearScope(key),
      repository._snapshotStore.clearScope(key),
      repository._warmLaunchPool.clearKind(IndexPoolKind.feed),
    ]);
    return;
  }
  final record = ScopedSnapshotRecord<List<PostsModel>>(
    data: normalized,
    snapshotAt: snapshotAt ?? DateTime.now(),
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      FeedSnapshotRepository._homeSurfaceKey,
    ),
    generationId: 'manual:${DateTime.now().millisecondsSinceEpoch}',
    source: source,
  );
  final userMeta = await repository._buildUserMeta(normalized);
  await Future.wait(<Future<void>>[
    repository._memoryStore.write(key, record),
    repository._snapshotStore.write(key, record),
    repository._warmLaunchPool.savePosts(
      IndexPoolKind.feed,
      normalized,
      userMeta: userMeta,
    ),
  ]);
}

Future<void> pruneFeedHomeSnapshots(
  FeedSnapshotRepository repository, {
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
    ReadBudgetRegistry.feedHomeInitialLimitValue,
    ...additionalLimits
        .where((value) => value > 0)
        .map(ReadBudgetRegistry.resolveFeedHomeInitialLimit),
  };

  for (final scopeLimit in scopeLimits) {
    final key = repository._homeKey(
      FeedSnapshotQuery(
        userId: normalizedUserId,
        limit: scopeLimit,
      ),
    );
    final memoryRecord = await repository._memoryStore.read(
      key,
      allowStale: true,
    );
    final diskRecord = await repository._snapshotStore.read(
      key,
      allowStale: true,
    );

    final record = memoryRecord ?? diskRecord;
    if (record == null) continue;

    final filtered = repository
        ._normalizePosts(record.data)
        .where((post) => !removeIds.contains(post.docID))
        .take(scopeLimit)
        .toList(growable: false);

    if (filtered.length == record.data.length) continue;

    if (filtered.isEmpty) {
      await Future.wait(<Future<void>>[
        repository._memoryStore.clearScope(key),
        repository._snapshotStore.clearScope(key),
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
      repository._memoryStore.write(key, nextRecord),
      repository._snapshotStore.write(key, nextRecord),
    ]);
  }
}

Future<void> pruneFeedHomeStartupShard(
  FeedSnapshotRepository repository, {
  required String userId,
  required Iterable<String> docIds,
}) async {
  final normalizedUserId = userId.trim();
  final removeIds = docIds
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (normalizedUserId.isEmpty || removeIds.isEmpty) return;

  final shardStore = ensureStartupSnapshotShardStore();
  final shard = await shardStore.load(
    surface: 'feed',
    userId: normalizedUserId,
    maxAge: StartupSnapshotShardStore.defaultFreshWindow,
  );
  if (shard == null || shard.itemCount <= 0 || shard.payload.isEmpty) return;

  final effectiveLimit = shard.limit > 0
      ? shard.limit
      : ReadBudgetRegistry.feedHomeInitialLimitValue;
  final current = repository
      ._normalizePosts(repository._decodePosts(shard.payload))
      .take(effectiveLimit)
      .toList(growable: false);
  if (current.isEmpty) {
    await shardStore.clear(
      surface: 'feed',
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
      surface: 'feed',
      userId: normalizedUserId,
    );
    return;
  }

  await shardStore.save(
    surface: 'feed',
    userId: normalizedUserId,
    itemCount: filtered.length,
    limit: effectiveLimit,
    source: shard.source,
    snapshotAt: shard.snapshotAt,
    payload: repository.encodeHomeStartupPayload(
      filtered,
      limit: effectiveLimit,
    ),
  );
}

extension FeedSnapshotRepositoryStartupShardPart on FeedSnapshotRepository {
  Map<String, dynamic> encodeHomeStartupPayload(
    List<PostsModel> posts, {
    int limit = FeedSnapshotRepository._defaultPersistLimit,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
    final normalized =
        _normalizePosts(posts).take(effectiveLimit).toList(growable: false);
    return _encodePosts(normalized);
  }

  Future<bool> primeHomeFromStartupPayload({
    required String userId,
    required Map<String, dynamic> payload,
    int limit = FeedSnapshotRepository._defaultPersistLimit,
    DateTime? snapshotAt,
    CachedResourceSource source = CachedResourceSource.scopedDisk,
  }) async {
    final effectiveLimit =
        ReadBudgetRegistry.resolveFeedHomeInitialLimit(limit);
    TurqImageCacheManager.hydratePosterHintsFromPayload(payload);
    final decoded = _decodePosts(payload);
    final normalized =
        _normalizePosts(decoded).take(effectiveLimit).toList(growable: false);
    if (normalized.isEmpty) return false;
    final record = ScopedSnapshotRecord<List<PostsModel>>(
      data: normalized,
      snapshotAt: snapshotAt ?? DateTime.now(),
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        FeedSnapshotRepository._homeSurfaceKey,
      ),
      generationId: 'startup_shard:${DateTime.now().millisecondsSinceEpoch}',
      source: source,
    );
    await _memoryStore.write(
      _homeKey(FeedSnapshotQuery(
        userId: userId,
        limit: effectiveLimit,
      )),
      record,
    );
    return true;
  }
}
