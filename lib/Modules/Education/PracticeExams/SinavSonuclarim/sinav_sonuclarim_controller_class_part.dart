part of 'sinav_sonuclarim_controller.dart';

class SinavSonuclarimController extends GetxController {
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
