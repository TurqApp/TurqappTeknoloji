part of 'education_info_controller.dart';

abstract class _EducationInfoControllerBase extends GetxController
    with GetTickerProviderStateMixin {
  final _state = _EducationInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    _EducationInfoControllerLifecyclePart(
      this as EducationInfoController,
    ).handleOnInit();
  }

  @override
  void onClose() {
    _EducationInfoControllerLifecyclePart(
      this as EducationInfoController,
    ).handleOnClose();
    super.onClose();
  }
}
