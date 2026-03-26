part of 'create_tutoring_controller.dart';

abstract class _CreateTutoringControllerBase extends GetxController {
  final _state = _CreateTutoringControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as CreateTutoringController)._handleRuntimeInit();
  }

  @override
  void onClose() {
    (this as CreateTutoringController)._handleRuntimeClose();
    super.onClose();
  }
}
