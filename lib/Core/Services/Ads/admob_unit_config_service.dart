import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';
part 'admob_unit_config_service_models_part.dart';

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

    final future = _initInternal();
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
      return _nextId(
        ids: _config.ios.squareIds,
        cursorKey: _iosSquareCursorKey,
        fallback: _AdmobUnitConfig.defaultIosSquareIds.first,
      );
    }
    return _nextId(
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
      return _nextId(
        ids: _config.ios.interstitialIds,
        cursorKey: _iosInterstitialCursorKey,
        fallback: _AdmobUnitConfig.defaultIosInterstitialIds.first,
      );
    }
    return _nextId(
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

  Future<void> _initInternal() async {
    try {
      final currentData = await ConfigRepository.ensure().getAdminConfigDoc(
        AdsCollections.admobUnitsDoc,
        preferCache: true,
        ttl: const Duration(hours: 6),
      );
      if (currentData != null && currentData.isNotEmpty) {
        _config = _AdmobUnitConfig.fromMap(currentData);
        await _writeRemoteDoc(_config.toMap());
      } else {
        final legacyData = await ConfigRepository.ensure().getAdminConfigDoc(
          _legacyDocId,
          preferCache: true,
          ttl: const Duration(hours: 6),
        );
        if (legacyData != null && legacyData.isNotEmpty) {
          _config = _AdmobUnitConfig.fromMap(legacyData);
          await _writeRemoteDoc(_config.toMap());
        } else {
          await _writeRemoteDoc(_config.toMap());
        }
      }
    } catch (_) {
      _config = _AdmobUnitConfig.defaults;
    }

    _sub?.cancel();
    _sub = ConfigRepository.ensure()
        .watchAdminConfigDoc(
      AdsCollections.admobUnitsDoc,
      ttl: const Duration(hours: 6),
    )
        .listen((data) {
      if (data.isEmpty) return;
      _config = _AdmobUnitConfig.fromMap(data);
    });
    _initialized = true;
  }

  Future<void> _writeRemoteDoc(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection(AdsCollections.adminConfig)
          .doc(AdsCollections.admobUnitsDoc)
          .set(data, SetOptions(merge: true));
      await ConfigRepository.ensure().putAdminConfigDoc(
        AdsCollections.admobUnitsDoc,
        data,
      );
    } catch (_) {}
  }

  String _nextId({
    required List<String> ids,
    required String cursorKey,
    required String fallback,
  }) {
    if (ids.isEmpty) return fallback;
    final currentIndex = _cursorByKey[cursorKey] ?? 0;
    final next = ids[currentIndex % ids.length];
    _cursorByKey[cursorKey] = (currentIndex + 1) % ids.length;
    return next;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
