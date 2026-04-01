part of 'market_create_controller.dart';

MarketCreateController ensureMarketCreateController({
  MarketItemModel? initialItem,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMarketCreateController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MarketCreateController(initialItem: initialItem),
    tag: tag,
    permanent: permanent,
  );
}

MarketCreateController? maybeFindMarketCreateController({String? tag}) {
  final isRegistered = Get.isRegistered<MarketCreateController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MarketCreateController>(tag: tag);
}
