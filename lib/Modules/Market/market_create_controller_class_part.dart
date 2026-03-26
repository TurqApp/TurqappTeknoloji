part of 'market_create_controller.dart';

class MarketCreateController extends GetxController {
  MarketCreateController({MarketItemModel? initialItem})
      : _state = _MarketCreateControllerState(initialItem: initialItem);

  static const int maxImages = 4;
  final _MarketCreateControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleMarketCreateInit();
  }

  @override
  void onClose() {
    _handleMarketCreateClose();
    super.onClose();
  }
}
