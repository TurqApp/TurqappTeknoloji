import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';

part 'admob_unit_config_service_models_part.dart';
part 'admob_unit_config_service_runtime_part.dart';

class AdmobUnitConfigService extends GetxService {
  static const String _legacyDocId = 'admobUnits';
  static const String _iosSquareCursorKey = 'ios_square';
  static const String _iosInterstitialCursorKey = 'ios_interstitial';
  static const String _androidSquareCursorKey = 'android_square';
  static const String _androidInterstitialCursorKey = 'android_interstitial';

  static AdmobUnitConfigService? maybeFind() {
    final isRegistered = Get.isRegistered<AdmobUnitConfigService>();
    if (!isRegistered) return null;
    return Get.find<AdmobUnitConfigService>();
  }

  static AdmobUnitConfigService ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AdmobUnitConfigService(), permanent: permanent);
  }

  _AdmobUnitConfig _config = _AdmobUnitConfig.defaults;
  final Map<String, int> _cursorByKey = <String, int>{};
  StreamSubscription<Map<String, dynamic>>? _sub;
  Future<void>? _initFuture;
  bool _initialized = false;

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

  @override
  void onClose() {
    _disposeAdmobConfigRuntime(this);
    super.onClose();
  }
}
