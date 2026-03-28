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

  String? currentPasajTabId() {
    final currentIndex = selectedTab.value;
    if (currentIndex < 0 || currentIndex >= titles.length) {
      return null;
    }
    final tabId = titles[currentIndex].trim();
    return tabId.isEmpty ? null : tabId;
  }
}
