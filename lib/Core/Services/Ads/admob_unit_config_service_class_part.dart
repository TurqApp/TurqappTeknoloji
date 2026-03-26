part of 'admob_unit_config_service.dart';

class AdmobUnitConfigService extends _AdmobUnitConfigServiceBase {
  @override
  void onClose() {
    _disposeAdmobConfigRuntime(this);
    super.onClose();
  }
}
