part of 'biography_maker_controller.dart';

abstract class _BiographyMakerControllerBase extends GetxController {
  final _state = _BiographyMakerControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBiographyMakerInit(this as BiographyMakerController);
  }

  @override
  void onClose() {
    _handleBiographyMakerClose(this as BiographyMakerController);
    super.onClose();
  }
}
