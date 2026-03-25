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
  }) =>
      _persistHomeSnapshot(
        this,
        userId: userId,
        posts: posts,
        limit: limit,
        source: source,
      );

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
