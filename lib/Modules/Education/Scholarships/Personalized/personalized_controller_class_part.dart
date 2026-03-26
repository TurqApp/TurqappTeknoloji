part of 'personalized_controller.dart';

class PersonalizedController extends GetxController
    with _PersonalizedControllerBasePart {
  @override
  void onInit() {
    super.onInit();
    _handlePersonalizedControllerInit(this);
  }

  @override
  void onClose() {
    _handlePersonalizedControllerClose(this);
    super.onClose();
  }
}
