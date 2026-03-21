import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Models/posts_model.dart';

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

  static WarmLaunchPool _ensureService() {
    if (Get.isRegistered<WarmLaunchPool>()) {
      return Get.find<WarmLaunchPool>();
    }
    return Get.put(WarmLaunchPool(), permanent: true);
  }

  static WarmLaunchPool ensure() {
    return _ensureService();
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
