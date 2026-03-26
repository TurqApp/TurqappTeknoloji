part of 'market_repository.dart';

MarketRepository? maybeFindMarketRepository() =>
    Get.isRegistered<MarketRepository>() ? Get.find<MarketRepository>() : null;

MarketRepository ensureMarketRepository() =>
    maybeFindMarketRepository() ?? Get.put(MarketRepository(), permanent: true);
