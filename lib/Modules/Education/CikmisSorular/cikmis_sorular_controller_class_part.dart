part of 'cikmis_sorular_controller.dart';

class CikmisSorularController extends GetxController {
  static CikmisSorularController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CikmisSorularController(), permanent: permanent);
  }

  static CikmisSorularController? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularController>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularController>();
  }

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
