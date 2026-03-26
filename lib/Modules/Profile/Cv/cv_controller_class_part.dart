part of 'cv_controller.dart';

class CvController extends GetxController {
  final _state = _CvControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleCvControllerInit(this);
  }

  @override
  void onClose() {
    _handleCvControllerClose(this);
    super.onClose();
  }
}
