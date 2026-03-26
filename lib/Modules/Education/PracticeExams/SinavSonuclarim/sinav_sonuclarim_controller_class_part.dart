part of 'sinav_sonuclarim_controller.dart';

class SinavSonuclarimController extends GetxController {
  static SinavSonuclarimController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SinavSonuclarimController(), permanent: permanent);
  }

  static SinavSonuclarimController? maybeFind() {
    final isRegistered = Get.isRegistered<SinavSonuclarimController>();
    if (!isRegistered) return null;
    return Get.find<SinavSonuclarimController>();
  }

  final _state = _SinavSonuclarimControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSinavSonuclarimControllerInit(this);
  }

  @override
  void onClose() {
    _handleSinavSonuclarimControllerClose(this);
    super.onClose();
  }
}
