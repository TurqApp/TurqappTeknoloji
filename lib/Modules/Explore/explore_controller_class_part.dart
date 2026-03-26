part of 'explore_controller.dart';

class ExploreController extends GetxController {
  static ExploreController ensure() =>
      maybeFind() ?? Get.put(ExploreController());
  static ExploreController? maybeFind() => Get.isRegistered<ExploreController>()
      ? Get.find<ExploreController>()
      : null;

  final _state = _ExploreControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
