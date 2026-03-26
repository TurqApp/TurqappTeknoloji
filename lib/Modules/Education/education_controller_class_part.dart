part of 'education_controller.dart';

class EducationController extends GetxController {
  static EducationController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(EducationController(), permanent: permanent);
  }

  static EducationController? maybeFind() {
    final isRegistered = Get.isRegistered<EducationController>();
    if (!isRegistered) return null;
    return Get.find<EducationController>();
  }

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
