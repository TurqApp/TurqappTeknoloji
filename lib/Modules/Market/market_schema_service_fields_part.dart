part of 'market_schema_service.dart';

class _MarketSchemaServiceState {
  final schema = <String, dynamic>{}.obs;
  SharedPreferences? prefs;
}

extension MarketSchemaServiceFieldsPart on MarketSchemaService {
  RxMap<String, dynamic> get schema => _state.schema;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
}
