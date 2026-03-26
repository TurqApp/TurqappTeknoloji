part of 'market_create_controller.dart';

class MarketCreateController extends GetxController {
  static MarketCreateController ensure({
    MarketItemModel? initialItem,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MarketCreateController(initialItem: initialItem),
      tag: tag,
      permanent: permanent,
    );
  }

  static MarketCreateController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MarketCreateController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MarketCreateController>(tag: tag);
  }

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
