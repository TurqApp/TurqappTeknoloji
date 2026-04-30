part of 'market_schema_service_library.dart';

abstract class _MarketSchemaServiceBase extends GetxService {
  final _state = _MarketSchemaServiceState();
}

class MarketSchemaService extends _MarketSchemaServiceBase {
  @override
  void onInit() {
    super.onInit();
    _preferences = ensureLocalPreferenceRepository();
  }
}

class _MarketSchemaServiceState {
  final schema = <String, dynamic>{}.obs;
  LocalPreferenceRepository? preferences;
}

extension MarketSchemaServiceFieldsPart on MarketSchemaService {
  RxMap<String, dynamic> get schema => _state.schema;
  LocalPreferenceRepository? get _preferences => _state.preferences;
  set _preferences(LocalPreferenceRepository? value) =>
      _state.preferences = value;
}
