part of 'saved_posts_controller.dart';

SavedPostsController? maybeFindSavedPostsController() =>
    Get.isRegistered<SavedPostsController>()
        ? Get.find<SavedPostsController>()
        : null;

SavedPostsController ensureSavedPostsController({bool permanent = false}) =>
    maybeFindSavedPostsController() ??
    Get.put(
      SavedPostsController(),
      permanent: permanent,
    );
