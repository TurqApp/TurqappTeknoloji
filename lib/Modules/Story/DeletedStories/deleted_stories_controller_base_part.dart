part of 'deleted_stories_controller.dart';

abstract class _DeletedStoriesControllerBase extends GetxController {
  final _DeletedStoriesControllerState _state =
      _DeletedStoriesControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleDeletedStoriesInit();
  }

  @override
  Future<void> refresh() => _handleDeletedStoriesRefresh();

  @override
  void onClose() {
    _handleDeletedStoriesClose();
    super.onClose();
  }
}
