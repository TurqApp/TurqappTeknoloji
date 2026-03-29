import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Models/posts_model.dart';

/// Transitional facade over [IndexPoolStore].
///
/// This layer makes the intended role explicit:
/// fast warm launches for renderable post cards, not the long-term scoped
/// snapshot contract used by primary surfaces.
abstract class _WarmLaunchPoolBase extends GetxService {
  _WarmLaunchPoolBase(this._delegate);

  final IndexPoolStore _delegate;
}

class WarmLaunchPool extends _WarmLaunchPoolBase {
  WarmLaunchPool({IndexPoolStore? delegate})
      : super(delegate ?? IndexPoolStore());
}

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

  Future<void> clearKind(IndexPoolKind kind) => _delegate.clearKind(kind);

  Future<void> clear() => _delegate.clear();
}
