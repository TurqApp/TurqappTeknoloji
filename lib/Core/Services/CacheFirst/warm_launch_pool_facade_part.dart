part of 'warm_launch_pool.dart';

WarmLaunchPool? maybeFindWarmLaunchPool() {
  final isRegistered = Get.isRegistered<WarmLaunchPool>();
  if (!isRegistered) return null;
  return Get.find<WarmLaunchPool>();
}

WarmLaunchPool ensureWarmLaunchPool() {
  final existing = maybeFindWarmLaunchPool();
  if (existing != null) return existing;
  return Get.put(WarmLaunchPool(), permanent: true);
}

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
