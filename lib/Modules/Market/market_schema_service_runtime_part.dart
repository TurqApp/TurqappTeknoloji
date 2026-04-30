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

extension _MarketSchemaServiceRuntimePart on MarketSchemaService {
  Future<Map<String, dynamic>> loadSchema({bool forceRefresh = false}) async {
    final preferences = _preferences ??= ensureLocalPreferenceRepository();

    if (!forceRefresh) {
      final cachedRaw =
          await preferences.getString(_marketSchemaCacheKey) ?? '';
      if (cachedRaw.isNotEmpty) {
        try {
          final parsed = Map<String, dynamic>.from(
            json.decode(cachedRaw) as Map,
          );
          schema.assignAll(parsed);
          return parsed;
        } catch (_) {}
      }
    }

    final fallback = await _loadFallbackSchema();
    schema.assignAll(fallback);
    await preferences.setString(
      _marketSchemaCacheKey,
      json.encode(fallback),
    );
    await preferences.setInt(
      _marketSchemaCacheVersionKey,
      (fallback['version'] as num?)?.toInt() ?? 1,
    );
    return fallback;
  }

  Future<Map<String, dynamic>> _loadFallbackSchema() async {
    try {
      final raw = await rootBundle.loadString(_marketSchemaAssetPath);
      return Map<String, dynamic>.from(json.decode(raw) as Map);
    } catch (_) {
      return Map<String, dynamic>.from(
        json.decode(kMarketSchemaSeedJson) as Map,
      );
    }
  }
}

extension MarketSchemaServiceFacadePart on MarketSchemaService {
  Future<Map<String, dynamic>> loadSchema({bool forceRefresh = false}) =>
      _MarketSchemaServiceRuntimePart(this)
          .loadSchema(forceRefresh: forceRefresh);
}
