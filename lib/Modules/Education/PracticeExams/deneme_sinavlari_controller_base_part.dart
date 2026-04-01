part of 'deneme_sinavlari_controller.dart';

abstract class _DenemeSinavlariControllerBase extends GetxController {
  final _state = _DenemeSinavlariControllerState();

  @override
  void onInit() {
    super.onInit();
    _denemeInit(this as DenemeSinavlariController);
  }

  @override
  void onClose() {
    _denemeClose(this as DenemeSinavlariController);
    super.onClose();
  }
}
