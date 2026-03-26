part of 'cikmis_sorular_controller.dart';

CikmisSorularController ensureCikmisSorularController({
  bool permanent = false,
}) {
  final existing = maybeFindCikmisSorularController();
  if (existing != null) return existing;
  return Get.put(CikmisSorularController(), permanent: permanent);
}

CikmisSorularController? maybeFindCikmisSorularController() {
  final isRegistered = Get.isRegistered<CikmisSorularController>();
  if (!isRegistered) return null;
  return Get.find<CikmisSorularController>();
}

extension CikmisSorularControllerFacadePart on CikmisSorularController {
  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  void requestScrollReset() => _requestScrollReset();
}
