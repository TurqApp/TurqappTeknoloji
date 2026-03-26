part of 'warm_launch_pool.dart';

/// Transitional facade over [IndexPoolStore].
///
/// This layer makes the intended role explicit:
/// fast warm launches for renderable post cards, not the long-term scoped
/// snapshot contract used by primary surfaces.
class WarmLaunchPool extends GetxService {
  WarmLaunchPool({
    IndexPoolStore? delegate,
  }) : _delegate = delegate ?? IndexPoolStore();

  final IndexPoolStore _delegate;

  static WarmLaunchPool? maybeFind() {
    final isRegistered = Get.isRegistered<WarmLaunchPool>();
    if (!isRegistered) return null;
    return Get.find<WarmLaunchPool>();
  }

  static WarmLaunchPool ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(WarmLaunchPool(), permanent: true);
  }

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
