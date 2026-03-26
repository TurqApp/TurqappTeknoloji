part of 'market_schema_service.dart';

class MarketSchemaService extends _MarketSchemaServiceBase {
  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }
}
