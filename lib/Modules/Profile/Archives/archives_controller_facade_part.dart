part of 'archives_controller.dart';

ArchiveController ensureArchiveController({bool permanent = false}) {
  final existing = maybeFindArchiveController();
  if (existing != null) return existing;
  return Get.put(ArchiveController(), permanent: permanent);
}

ArchiveController? maybeFindArchiveController() {
  final isRegistered = Get.isRegistered<ArchiveController>();
  if (!isRegistered) return null;
  return Get.find<ArchiveController>();
}

extension ArchiveControllerFacadePart on ArchiveController {
  Future<void> fetchData({bool silent = false}) async {
    await _ArchiveControllerDataPart(this).fetchArchiveData(silent: silent);
  }
}
