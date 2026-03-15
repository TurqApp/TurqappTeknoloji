import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'market_schema_seed.dart';

class MarketSchemaService extends GetxService {
  static const String _cacheKey = 'market_schema_v1';
  static const String _cacheVersionKey = 'market_schema_v1_version';
  static const String _assetPath = 'assets/data/market_schema.json';

  final RxMap<String, dynamic> schema = <String, dynamic>{}.obs;
  SharedPreferences? _prefs;

  static MarketSchemaService ensure() {
    if (Get.isRegistered<MarketSchemaService>()) {
      return Get.find<MarketSchemaService>();
    }
    return Get.put(MarketSchemaService(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>> loadSchema({bool forceRefresh = false}) async {
    _prefs ??= await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedRaw = _prefs?.getString(_cacheKey) ?? '';
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
    await _prefs?.setString(_cacheKey, json.encode(fallback));
    await _prefs?.setInt(
      _cacheVersionKey,
      (fallback['version'] as num?)?.toInt() ?? 1,
    );
    return fallback;
  }

  List<Map<String, dynamic>> roundMenuItems() {
    final ui = Map<String, dynamic>.from(schema['ui'] as Map? ?? const {});
    final menu = (ui['recommendedRoundMenu'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    return menu;
  }

  List<Map<String, dynamic>> categories() {
    return (schema['categories'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadFallbackSchema() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      return Map<String, dynamic>.from(json.decode(raw) as Map);
    } catch (_) {
      return Map<String, dynamic>.from(
        json.decode(kMarketSchemaSeedJson) as Map,
      );
    }
  }
}
