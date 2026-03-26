part of 'market_schema_service_library.dart';

abstract class _MarketSchemaServiceBase extends GetxService {
  final _state = _MarketSchemaServiceState();
}

class MarketSchemaService extends _MarketSchemaServiceBase {
  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
