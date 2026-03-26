part of 'sinav_hazirla_controller.dart';

class SinavHazirlaController extends GetxController {
  final _state = _SinavHazirlaControllerState();

  SinavHazirlaController({SinavModel? sinavModel}) {
    this.sinavModel = sinavModel;
  }

  @override
  void onInit() {
    super.onInit();
    _handleSinavHazirlaInit(this);
  }

  @override
  void onClose() {
    _handleSinavHazirlaClose(this);
    super.onClose();
  }
}
