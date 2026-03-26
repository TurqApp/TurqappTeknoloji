part of 'post_count_manager.dart';

PostCountManager? _maybeFindPostCountManager() {
  final isRegistered = Get.isRegistered<PostCountManager>();
  if (!isRegistered) return null;
  return Get.find<PostCountManager>();
}

PostCountManager _ensurePostCountManager() {
  final existing = _maybeFindPostCountManager();
  if (existing != null) {
    PostCountManager._instance = existing;
    return existing;
  }
  final created = Get.put(PostCountManager());
  PostCountManager._instance = created;
  return created;
}

PostCountManager _postCountManagerInstance() =>
    PostCountManager._instance ??= _ensurePostCountManager();
