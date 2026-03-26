part of 'deleted_stories_controller.dart';

DeletedStoriesController ensureDeletedStoriesController() {
  final existing = maybeFindDeletedStoriesController();
  if (existing != null) return existing;
  return Get.put(DeletedStoriesController());
}

DeletedStoriesController? maybeFindDeletedStoriesController() {
  final isRegistered = Get.isRegistered<DeletedStoriesController>();
  if (!isRegistered) return null;
  return Get.find<DeletedStoriesController>();
}

extension DeletedStoriesControllerFacadePart on DeletedStoriesController {
  void goToPage(int index) {
    _handleGoToPage(index);
  }
}
