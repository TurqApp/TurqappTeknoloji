part of 'admob_unit_config_service.dart';

class AdmobUnitConfigService extends GetxService {
  static const String _legacyDocId = 'admobUnits';
  static const String _iosSquareCursorKey = 'ios_square';
  static const String _iosInterstitialCursorKey = 'ios_interstitial';
  static const String _androidSquareCursorKey = 'android_square';
  static const String _androidInterstitialCursorKey = 'android_interstitial';

  _AdmobUnitConfig _config = _AdmobUnitConfig.defaults;
  final Map<String, int> _cursorByKey = <String, int>{};
  StreamSubscription<Map<String, dynamic>>? _sub;
  Future<void>? _initFuture;
  bool _initialized = false;

  @override
  void onClose() {
    _disposeAdmobConfigRuntime(this);
    super.onClose();
  }
}
