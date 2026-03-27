part of 'cikmis_sorular_controller.dart';

class CikmisSorularController extends GetxController {
  final _state = _CikmisSorularControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}

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
