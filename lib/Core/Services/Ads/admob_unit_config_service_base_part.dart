part of 'admob_unit_config_service.dart';

abstract class _AdmobUnitConfigServiceBase extends GetxService {
  _AdmobUnitConfig _config = _AdmobUnitConfig.defaults;
  final Map<String, int> _cursorByKey = <String, int>{};
  StreamSubscription<Map<String, dynamic>>? _sub;
  Future<void>? _initFuture;
  bool _initialized = false;

  @override
  void onClose() {
    _disposeAdmobConfigRuntime(this as AdmobUnitConfigService);
    super.onClose();
  }
}
