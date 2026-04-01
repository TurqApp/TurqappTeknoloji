part of 'explore_controller.dart';

abstract class _ExploreControllerBase extends GetxController {
  final _state = _ExploreControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as ExploreController)._handleOnInit();
  }

  @override
  void onClose() {
    (this as ExploreController)._handleOnClose();
    super.onClose();
  }
}
