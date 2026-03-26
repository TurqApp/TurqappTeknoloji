part of 'market_schema_service.dart';

class MarketSchemaService extends GetxService {
  static const String _cacheKey = 'market_schema_v1';
  static const String _cacheVersionKey = 'market_schema_v1_version';
  static const String _assetPath = 'assets/data/market_schema.json';
  final _state = _MarketSchemaServiceState();

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  String? _roundMenuLabelFor(String key) =>
      MarketSchemaServiceLabelsPart(this).roundMenuLabelFor(key);

  Map<String, dynamic> _localizedCategoryNode(Map<String, dynamic> node) =>
      MarketSchemaServiceLabelsPart(this).localizedCategoryNode(node);

  String? _categoryLabelFor(String key) =>
      MarketSchemaServiceLabelsPart(this).categoryLabelFor(key);
}
