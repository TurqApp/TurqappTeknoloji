part of 'market_create_controller.dart';

abstract class _MarketCreateControllerBase extends GetxController {
  _MarketCreateControllerBase({MarketItemModel? initialItem})
      : _state = _MarketCreateControllerState(initialItem: initialItem);

  final _MarketCreateControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as MarketCreateController)._handleMarketCreateInit();
  }

  @override
  void onClose() {
    (this as MarketCreateController)._handleMarketCreateClose();
    super.onClose();
  }
}
