part of 'spotify_selector_controller.dart';

class SpotifySelectorController extends GetxController {
  static SpotifySelectorController ensure({String? tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(SpotifySelectorController(), tag: tag);
  }

  static SpotifySelectorController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SpotifySelectorController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SpotifySelectorController>(tag: tag);
  }

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
