part of 'tutoring_controller.dart';

abstract class _TutoringControllerBase extends GetxController {
  final _state = _TutoringControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleTutoringControllerInit(this as TutoringController);
  }

  @override
  void onClose() {
    _handleTutoringControllerClose(this as TutoringController);
    super.onClose();
  }
}
