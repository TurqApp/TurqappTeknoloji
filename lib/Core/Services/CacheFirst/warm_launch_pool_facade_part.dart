part of 'warm_launch_pool.dart';

extension WarmLaunchPoolFacadePart on WarmLaunchPool {
  Future<void> init() => _delegate.init();

  Future<List<PostsModel>> loadPosts(
    IndexPoolKind kind, {
    int limit = 20,
    bool allowStale = true,
  }) {
    return _delegate.loadPosts(
      kind,
      limit: limit,
      allowStale: allowStale,
    );
  }

  Future<void> savePosts(
    IndexPoolKind kind,
    List<PostsModel> posts, {
    Map<String, Map<String, dynamic>> userMeta = const {},
  }) {
    return _delegate.savePosts(
      kind,
      posts,
      userMeta: userMeta,
    );
  }

  Future<void> removePosts(
    IndexPoolKind kind,
    List<String> docIds,
  ) {
    return _delegate.removePosts(kind, docIds);
  }

  Future<void> clear() => _delegate.clear();
}
