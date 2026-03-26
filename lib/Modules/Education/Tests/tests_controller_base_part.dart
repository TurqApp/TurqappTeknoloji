part of 'tests_controller.dart';

abstract class _TestsControllerBase extends GetxController {
  final _state = _TestsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
