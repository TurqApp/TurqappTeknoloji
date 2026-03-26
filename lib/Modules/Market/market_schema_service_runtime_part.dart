part of 'market_schema_service.dart';

extension _MarketSchemaServiceRuntimePart on MarketSchemaService {
  Future<Map<String, dynamic>> loadSchema({bool forceRefresh = false}) async {
    _prefs ??= await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedRaw = _prefs?.getString(_marketSchemaCacheKey) ?? '';
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
    await _prefs?.setString(
      _marketSchemaCacheKey,
      json.encode(fallback),
    );
    await _prefs?.setInt(
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
