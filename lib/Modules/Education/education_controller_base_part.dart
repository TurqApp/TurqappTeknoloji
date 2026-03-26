part of 'education_controller.dart';

abstract class _EducationControllerBase extends GetxController {
  final _state = _EducationControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as EducationController)._initializeEducationController();
  }

  @override
  void onClose() {
    (this as EducationController)._disposeEducationController();
    super.onClose();
  }
}
