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
