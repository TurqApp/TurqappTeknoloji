part of 'spotify_selector_controller.dart';

class SpotifySelectorController extends GetxController {
  final _state = _SpotifySelectorControllerState();

  @override
  void onInit() {
    super.onInit();
    SpotifySelectorControllerRuntimePart(this).onInit();
  }

  @override
  void onClose() {
    SpotifySelectorControllerRuntimePart(this).onClose();
    super.onClose();
  }
}
