part of 'deneme_sinavlari_controller.dart';

class DenemeSinavlariController extends _DenemeSinavlariControllerBase {
  @override
  void onInit() {
    super.onInit();
    _denemeInit(this);
  }

  @override
  void onClose() {
    _denemeClose(this);
    super.onClose();
  }
}
