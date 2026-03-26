part of 'market_schema_service_library.dart';

MarketSchemaService? maybeFindMarketSchemaService() {
  final isRegistered = Get.isRegistered<MarketSchemaService>();
  if (!isRegistered) return null;
  return Get.find<MarketSchemaService>();
}

MarketSchemaService ensureMarketSchemaService() {
  final existing = maybeFindMarketSchemaService();
  if (existing != null) return existing;
  return Get.put(MarketSchemaService(), permanent: true);
}

extension MarketSchemaServiceFacadePart on MarketSchemaService {
  Future<Map<String, dynamic>> loadSchema({bool forceRefresh = false}) =>
      _MarketSchemaServiceRuntimePart(this)
          .loadSchema(forceRefresh: forceRefresh);

  List<Map<String, dynamic>> roundMenuItems() =>
      MarketSchemaServiceLabelsPart(this).roundMenuItems();

  List<Map<String, dynamic>> categories() =>
      MarketSchemaServiceLabelsPart(this).categories();
}
