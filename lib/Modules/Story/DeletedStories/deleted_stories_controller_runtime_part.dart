part of 'deleted_stories_controller.dart';

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
