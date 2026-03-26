part of 'education_controller.dart';

class EducationController extends GetxController {
  final _state = _EducationControllerState();

  @override
  void onInit() {
    super.onInit();
    _initializeEducationController();
  }

  @override
  void onClose() {
    _disposeEducationController();
    super.onClose();
  }

  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  void ensureVisibleSurfaceReset() => _ensureVisibleSurfaceResetImpl();

  void resetVisibleSearchOnReturn() => _performResetVisibleSearchOnReturn();
}
