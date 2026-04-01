part of 'sinav_sonuclari_preview_controller.dart';

class SinavSonuclariPreviewController
    extends _SinavSonuclariPreviewControllerBase {
  SinavSonuclariPreviewController({required super.model});
}

abstract class _SinavSonuclariPreviewControllerBase extends GetxController {
  _SinavSonuclariPreviewControllerBase({required SinavModel model})
      : _state = _SinavSonuclariPreviewControllerState(model: model);
  final _SinavSonuclariPreviewControllerState _state;
  @override
  void onInit() {
    super.onInit();
    (this as SinavSonuclariPreviewController)._handleInit();
  }
}
