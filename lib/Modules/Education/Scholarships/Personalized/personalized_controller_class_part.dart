part of 'personalized_controller.dart';

class PersonalizedController extends GetxController
    with _PersonalizedControllerBasePart {
  @override
  void onInit() {
    super.onInit();
    _personalizedInit(this);
  }

  @override
  void onClose() {
    _personalizedClose(this);
    super.onClose();
  }
}
