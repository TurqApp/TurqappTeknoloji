part of 'education_controller.dart';

EducationController ensureEducationController({bool permanent = false}) {
  final existing = maybeFindEducationController();
  if (existing != null) return existing;
  return Get.put(EducationController(), permanent: permanent);
}

EducationController? maybeFindEducationController() {
  final isRegistered = Get.isRegistered<EducationController>();
  if (!isRegistered) return null;
  return Get.find<EducationController>();
}

extension EducationControllerFacadePart on EducationController {
  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  void ensureVisibleSurfaceReset() => _ensureVisibleSurfaceResetImpl();

  void resetVisibleSearchOnReturn() => _performResetVisibleSearchOnReturn();
}
