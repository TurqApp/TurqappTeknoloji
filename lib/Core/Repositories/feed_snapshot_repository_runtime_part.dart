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
  );
}

Future<void> persistFeedHomeSnapshot(
  FeedSnapshotRepository repository, {
  required String userId,
  required List<PostsModel> posts,
  int limit = FeedSnapshotRepository._defaultPersistLimit,
  CachedResourceSource source = CachedResourceSource.server,
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
    snapshotAt: DateTime.now(),
    schemaVersion: 1,
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
