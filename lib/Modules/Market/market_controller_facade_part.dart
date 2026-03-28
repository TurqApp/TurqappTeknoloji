part of 'market_controller.dart';

MarketController ensureMarketController({bool permanent = false}) =>
    maybeFindMarketController() ??
    Get.put(MarketController(), permanent: permanent);

MarketController? maybeFindMarketController() =>
    Get.isRegistered<MarketController>() ? Get.find<MarketController>() : null;

extension MarketControllerFacadeApiPart on MarketController {
  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) =>
      _performPrepareStartupSurface(
        allowBackgroundRefresh: allowBackgroundRefresh,
      );

  Future<void> persistStartupShard() => _persistMarketStartupShard();
}
