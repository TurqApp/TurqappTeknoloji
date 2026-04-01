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

extension DeletedStoriesControllerRuntimePart on DeletedStoriesController {
  void _handleDeletedStoriesInit() {
    fetch(initial: true);
  }

  Future<void> _handleDeletedStoriesRefresh() async {
    await fetch(initial: false, forceRemote: true);
  }

  void _handleGoToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleDeletedStoriesClose() {
    pageController.dispose();
  }
}

extension DeletedStoriesControllerFacadePart on DeletedStoriesController {
  void goToPage(int index) {
    _handleGoToPage(index);
  }
}
