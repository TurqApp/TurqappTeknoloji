part of 'deleted_stories_controller.dart';

class DeletedStoriesController extends GetxController {
  final _DeletedStoriesControllerState _state =
      _DeletedStoriesControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleDeletedStoriesInit();
  }

  @override
  Future<void> refresh() async {
    await _handleDeletedStoriesRefresh();
  }

  void goToPage(int index) {
    _handleGoToPage(index);
  }

  @override
  void onClose() {
    _handleDeletedStoriesClose();
    super.onClose();
  }
}
