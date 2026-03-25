import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'market_schema_seed.dart';

part 'market_schema_service_fields_part.dart';
part 'market_schema_service_labels_part.dart';
part 'market_schema_service_runtime_part.dart';

class MarketSchemaService extends GetxService {
  static const String _cacheKey = 'market_schema_v1';
  static const String _cacheVersionKey = 'market_schema_v1_version';
  static const String _assetPath = 'assets/data/market_schema.json';
  final _state = _MarketSchemaServiceState();

  static MarketSchemaService? maybeFind() {
    final isRegistered = Get.isRegistered<MarketSchemaService>();
    if (!isRegistered) return null;
    return Get.find<MarketSchemaService>();
  }

  static MarketSchemaService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MarketSchemaService(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>> loadSchema({bool forceRefresh = false}) =>
      _MarketSchemaServiceRuntimePart(this)
          .loadSchema(forceRefresh: forceRefresh);

  List<Map<String, dynamic>> roundMenuItems() =>
      MarketSchemaServiceLabelsPart(this).roundMenuItems();

  String? _roundMenuLabelFor(String key) =>
      MarketSchemaServiceLabelsPart(this).roundMenuLabelFor(key);

  List<Map<String, dynamic>> categories() =>
      MarketSchemaServiceLabelsPart(this).categories();

  Map<String, dynamic> _localizedCategoryNode(Map<String, dynamic> node) =>
      MarketSchemaServiceLabelsPart(this).localizedCategoryNode(node);

  String? _categoryLabelFor(String key) =>
      MarketSchemaServiceLabelsPart(this).categoryLabelFor(key);
}
