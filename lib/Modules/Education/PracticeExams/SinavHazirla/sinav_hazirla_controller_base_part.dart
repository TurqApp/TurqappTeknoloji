part of 'sinav_hazirla_controller.dart';

abstract class _SinavHazirlaControllerBase extends GetxController {
  _SinavHazirlaControllerBase({SinavModel? sinavModel})
      : _state = _SinavHazirlaControllerState() {
    _state.sinavModel = sinavModel;
  }

  final _SinavHazirlaControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleSinavHazirlaInit(this as SinavHazirlaController);
  }

  @override
  void onClose() {
    _handleSinavHazirlaClose(this as SinavHazirlaController);
    super.onClose();
  }
}
