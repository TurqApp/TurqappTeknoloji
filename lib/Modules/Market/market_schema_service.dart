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

  static MarketSchemaService _ensureService() {
    if (Get.isRegistered<MarketSchemaService>()) {
      return Get.find<MarketSchemaService>();
    }
    return Get.put(MarketSchemaService(), permanent: true);
  }

  static MarketSchemaService ensure() => _ensureService();

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
        .map((item) {
      final mapped = Map<String, dynamic>.from(item);
      final key = (mapped['key'] ?? '').toString();
      final localized = _roundMenuLabelFor(key);
      if (localized != null) {
        mapped['label'] = localized;
      }
      return mapped;
    }).toList(growable: false);
    return menu;
  }

  String? _roundMenuLabelFor(String key) {
    switch (key) {
      case 'create':
        return 'pasaj.market.menu.create'.tr;
      case 'my_items':
        return 'pasaj.market.menu.my_items'.tr;
      case 'saved':
        return 'pasaj.market.menu.saved'.tr;
      case 'offers':
        return 'pasaj.market.menu.offers'.tr;
      case 'categories':
        return 'pasaj.market.menu.categories'.tr;
      case 'nearby':
        return 'pasaj.market.menu.nearby'.tr;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> categories() {
    return (schema['categories'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => _localizedCategoryNode(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _localizedCategoryNode(Map<String, dynamic> node) {
    final mapped = Map<String, dynamic>.from(node);
    final key = (mapped['key'] ?? '').toString();
    final localized = _categoryLabelFor(key);
    if (localized != null) {
      mapped['localizedLabel'] = localized;
    }
    final children = mapped['children'];
    if (children is List) {
      mapped['children'] = children
          .whereType<Map>()
          .map((child) =>
              _localizedCategoryNode(Map<String, dynamic>.from(child)))
          .toList(growable: false);
    }
    return mapped;
  }

  String? _categoryLabelFor(String key) {
    switch (key) {
      case 'elektronik':
        return 'pasaj.market.category.electronics'.tr;
      case 'telefon':
        return 'pasaj.market.category.phone'.tr;
      case 'bilgisayar':
        return 'pasaj.market.category.computer'.tr;
      case 'oyun-elektronigi':
        return 'pasaj.market.category.gaming_electronics'.tr;
      case 'giyim':
        return 'pasaj.market.category.clothing'.tr;
      case 'ev-yasam':
        return 'pasaj.market.category.home_living'.tr;
      case 'spor':
        return 'pasaj.market.category.sports'.tr;
      case 'emlak':
        return 'pasaj.market.category.real_estate'.tr;
      default:
        return null;
    }
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
