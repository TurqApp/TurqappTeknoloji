part of 'feed_snapshot_repository.dart';

FeedSnapshotRepository? maybeFindFeedSnapshotRepository() {
  final isRegistered = Get.isRegistered<FeedSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<FeedSnapshotRepository>();
}

FeedSnapshotRepository ensureFeedSnapshotRepository() {
  final existing = maybeFindFeedSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(FeedSnapshotRepository(), permanent: true);
}

extension FeedSnapshotRepositoryFacadePart on FeedSnapshotRepository {
  Stream<CachedResource<List<PostsModel>>> openHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return _homePipeline.open(
      FeedSnapshotQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<PostsModel>>> loadHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<CachedResource<List<PostsModel>>> bootstrapHome({
    required String userId,
    int limit = 30,
  }) =>
      bootstrapFeedHome(
        this,
        userId: userId,
        limit: limit,
      );

  Future<void> persistHomeSnapshot({
    required String userId,
    required List<PostsModel> posts,
    int limit = FeedSnapshotRepository._defaultPersistLimit,
    CachedResourceSource source = CachedResourceSource.server,
  }) =>
      persistFeedHomeSnapshot(
        this,
        userId: userId,
        posts: posts,
        limit: limit,
        source: source,
      );
}
