part of 'market_controller.dart';

abstract class _MarketControllerBase extends GetxController {
  final _state = _MarketControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as MarketController)._handleLifecycleInit();
  }

  @override
  void onClose() {
    (this as MarketController)._handleLifecycleClose();
    super.onClose();
  }
}
