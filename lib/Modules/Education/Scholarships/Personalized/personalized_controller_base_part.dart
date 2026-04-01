part of 'personalized_controller.dart';

abstract class _PersonalizedControllerBase extends GetxController {
  final _state = _PersonalizedControllerState();

  @override
  void onInit() {
    super.onInit();
    _personalizedInit(this as PersonalizedController);
  }

  @override
  void onClose() {
    _personalizedClose(this as PersonalizedController);
    super.onClose();
  }
}
