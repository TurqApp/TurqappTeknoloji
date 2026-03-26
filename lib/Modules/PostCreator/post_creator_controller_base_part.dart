part of 'post_creator_controller.dart';

abstract class _PostCreatorControllerBase extends GetxController
    with WidgetsBindingObserver {
  final _state = _PostCreatorControllerState();

  @override
  void onInit() {
    super.onInit();
    _handlePostCreatorControllerInit(this as PostCreatorController);
  }

  @override
  void onClose() {
    _handlePostCreatorControllerClose(this as PostCreatorController);
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    _handlePostCreatorControllerMetrics(this as PostCreatorController);
  }
}
