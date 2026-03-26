part of 'admob_unit_config_service.dart';

AdmobUnitConfigService? maybeFindAdmobUnitConfigService() {
  final isRegistered = Get.isRegistered<AdmobUnitConfigService>();
  if (!isRegistered) return null;
  return Get.find<AdmobUnitConfigService>();
}

AdmobUnitConfigService ensureAdmobUnitConfigService({
  bool permanent = false,
}) {
  final existing = maybeFindAdmobUnitConfigService();
  if (existing != null) return existing;
  return Get.put(AdmobUnitConfigService(), permanent: permanent);
}

extension AdmobUnitConfigServiceFacadePart on AdmobUnitConfigService {
  Future<AdmobUnitConfigService> init() async {
    if (_initialized) return this;
    final pending = _initFuture;
    if (pending != null) {
      await pending;
      return this;
    }

    final future = _initInternalAdmobConfig(this);
    _initFuture = future;
    try {
      await future;
    } finally {
      _initFuture = null;
    }
    return this;
  }

  String nextSquareAdUnitId({required bool isTestMode}) {
    if (isTestMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return _nextAdmobUnitId(
        this,
        ids: _config.ios.squareIds,
        cursorKey: _iosSquareCursorKey,
        fallback: _AdmobUnitConfig.defaultIosSquareIds.first,
      );
    }
    return _nextAdmobUnitId(
      this,
      ids: _config.android.squareIds,
      cursorKey: _androidSquareCursorKey,
      fallback: _AdmobUnitConfig.defaultAndroidSquareIds.first,
    );
  }

  List<String> squareAdUnitIdsForCurrentPlatform({required bool isTestMode}) {
    if (isTestMode) {
      return <String>[
        Platform.isIOS
            ? 'ca-app-pub-3940256099942544/2934735716'
            : 'ca-app-pub-3940256099942544/6300978111',
      ];
    }
    final ids =
        Platform.isIOS ? _config.ios.squareIds : _config.android.squareIds;
    return List<String>.from(ids, growable: false);
  }

  String nextInterstitialAdUnitId({required bool isTestMode}) {
    if (isTestMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isIOS) {
      return _nextAdmobUnitId(
        this,
        ids: _config.ios.interstitialIds,
        cursorKey: _iosInterstitialCursorKey,
        fallback: _AdmobUnitConfig.defaultIosInterstitialIds.first,
      );
    }
    return _nextAdmobUnitId(
      this,
      ids: _config.android.interstitialIds,
      cursorKey: _androidInterstitialCursorKey,
      fallback: _AdmobUnitConfig.defaultAndroidInterstitialIds.first,
    );
  }

  List<String> interstitialAdUnitIdsForCurrentPlatform({
    required bool isTestMode,
  }) {
    if (isTestMode) {
      return <String>[
        Platform.isIOS
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712',
      ];
    }
    final ids = Platform.isIOS
        ? _config.ios.interstitialIds
        : _config.android.interstitialIds;
    return List<String>.from(ids, growable: false);
  }
}
