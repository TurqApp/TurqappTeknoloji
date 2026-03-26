part of 'deleted_stories_controller.dart';

abstract class _DeletedStoriesControllerBase extends GetxController {
  final _DeletedStoriesControllerState _state =
      _DeletedStoriesControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as DeletedStoriesController)._handleDeletedStoriesInit();
  }

  @override
  Future<void> refresh() =>
      (this as DeletedStoriesController)._handleDeletedStoriesRefresh();

  @override
  void onClose() {
    (this as DeletedStoriesController)._handleDeletedStoriesClose();
    super.onClose();
  }
}
