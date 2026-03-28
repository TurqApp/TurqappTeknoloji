part of 'market_controller.dart';

MarketController ensureMarketController({bool permanent = false}) =>
    maybeFindMarketController() ??
    Get.put(MarketController(), permanent: permanent);

MarketController? maybeFindMarketController() =>
    Get.isRegistered<MarketController>() ? Get.find<MarketController>() : null;

Future<void> prepareMarketStartupSurface(
  MarketController controller, {
  bool? allowBackgroundRefresh,
}) =>
    controller._performPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );

extension MarketControllerFacadeApiPart on MarketController {
  Future<void> persistStartupShard() => _persistMarketStartupShard();
}
