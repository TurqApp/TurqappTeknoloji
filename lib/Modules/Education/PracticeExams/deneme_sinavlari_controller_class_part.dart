part of 'deneme_sinavlari_controller.dart';

class DenemeSinavlariController extends GetxController
    with _DenemeSinavlariControllerBasePart {
  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinavlariInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinavlariClose(this);
    super.onClose();
  }
}
