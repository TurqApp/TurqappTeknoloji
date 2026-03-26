part of 'saved_posts_controller.dart';

SavedPostsController? maybeFindSavedPostsController() {
  final isRegistered = Get.isRegistered<SavedPostsController>();
  if (!isRegistered) return null;
  return Get.find<SavedPostsController>();
}

SavedPostsController ensureSavedPostsController({bool permanent = false}) {
  final existing = maybeFindSavedPostsController();
  if (existing != null) return existing;
  return Get.put(
    SavedPostsController(),
    permanent: permanent,
  );
}
