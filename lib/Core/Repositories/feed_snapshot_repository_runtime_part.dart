part of 'feed_snapshot_repository.dart';

Future<CachedResource<List<PostsModel>>> bootstrapFeedHome(
  FeedSnapshotRepository repository, {
  required String userId,
  int limit = 30,
}) {
  final query = FeedSnapshotQuery(
    userId: userId,
    limit: limit,
  );
  return repository._coordinator.bootstrap(
    repository._homeKey(query),
    loadWarmSnapshot: () => repository._loadWarmHomeSnapshot(query),
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      FeedSnapshotRepository._homeSurfaceKey,
    ),
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
  final normalized =
      repository._normalizePosts(posts).take(limit).toList(growable: false);
  if (normalized.isEmpty) return;
  final key = repository._homeKey(FeedSnapshotQuery(
    userId: userId,
    limit: limit,
  ));
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

extension FeedSnapshotRepositoryStartupShardPart on FeedSnapshotRepository {
  Map<String, dynamic> encodeHomeStartupPayload(
    List<PostsModel> posts, {
    int limit = FeedSnapshotRepository._defaultPersistLimit,
  }) {
    final normalized =
        _normalizePosts(posts).take(limit).toList(growable: false);
    return _encodePosts(normalized);
  }

  Future<bool> primeHomeFromStartupPayload({
    required String userId,
    required Map<String, dynamic> payload,
    int limit = FeedSnapshotRepository._defaultPersistLimit,
    DateTime? snapshotAt,
    CachedResourceSource source = CachedResourceSource.scopedDisk,
  }) async {
    final decoded = _decodePosts(payload);
    final normalized =
        _normalizePosts(decoded).take(limit).toList(growable: false);
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
        limit: limit,
      )),
      record,
    );
    return true;
  }
}
