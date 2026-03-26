part of 'market_controller.dart';

class MarketController extends GetxController {
  static MarketController ensure({bool permanent = false}) =>
      maybeFind() ?? Get.put(MarketController(), permanent: permanent);

  static MarketController? maybeFind() => Get.isRegistered<MarketController>()
      ? Get.find<MarketController>()
      : null;
  final _state = _MarketControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }
}
