import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';

class _AdmobPlatformUnitConfig {
  const _AdmobPlatformUnitConfig({
    required this.squareIds,
    required this.interstitialIds,
  });

  final List<String> squareIds;
  final List<String> interstitialIds;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kare': squareIds,
      'gecis': interstitialIds,
    };
  }
}

class _AdmobUnitConfig {
  const _AdmobUnitConfig({
    required this.ios,
    required this.android,
  });

  static const List<String> defaultIosSquareIds = <String>[
    'ca-app-pub-4558422035199571/8122867409',
    'ca-app-pub-4558422035199571/8962191459',
    'ca-app-pub-4558422035199571/3881293152',
    'ca-app-pub-4558422035199571/9209603468',
    'ca-app-pub-4558422035199571/9672675885',
  ];

  static const List<String> defaultIosInterstitialIds = <String>[
    'ca-app-pub-4558422035199571/5999655265',
    'ca-app-pub-4558422035199571/8523207750',
    'ca-app-pub-4558422035199571/2987562624',
    'ca-app-pub-4558422035199571/1674480958',
    'ca-app-pub-4558422035199571/3877385732',
  ];

  static const List<String> defaultAndroidSquareIds = <String>[
    'ca-app-pub-4558422035199571/2790203845',
    'ca-app-pub-4558422035199571/9097922825',
    'ca-app-pub-4558422035199571/9648587166',
    'ca-app-pub-4558422035199571/2340942782',
    'ca-app-pub-4558422035199571/3689721460',
  ];

  static const List<String> defaultAndroidInterstitialIds = <String>[
    'ca-app-pub-4558422035199571/8183250889',
    'ca-app-pub-4558422035199571/6503549079',
    'ca-app-pub-4558422035199571/9552970979',
    'ca-app-pub-4558422035199571/8359594210',
    'ca-app-pub-4558422035199571/6926807632',
  ];

  static final _AdmobUnitConfig defaults = _AdmobUnitConfig(
    ios: const _AdmobPlatformUnitConfig(
      squareIds: defaultIosSquareIds,
      interstitialIds: defaultIosInterstitialIds,
    ),
    android: const _AdmobPlatformUnitConfig(
      squareIds: defaultAndroidSquareIds,
      interstitialIds: defaultAndroidInterstitialIds,
    ),
  );

  final _AdmobPlatformUnitConfig ios;
  final _AdmobPlatformUnitConfig android;

  factory _AdmobUnitConfig.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    final iosRaw = Map<String, dynamic>.from(
      source['ios'] as Map? ?? const <String, dynamic>{},
    );
    final androidRaw = Map<String, dynamic>.from(
      source['android'] as Map? ?? const <String, dynamic>{},
    );

    if (source['iosSquare'] is Iterable) {
      iosRaw['square'] = source['iosSquare'];
    }
    if (source['iosInterstitial'] is Iterable) {
      iosRaw['interstitial'] = source['iosInterstitial'];
    }
    if (source['androidSquare'] is Iterable) {
      androidRaw['square'] = source['androidSquare'];
    }
    if (source['androidInterstitial'] is Iterable) {
      androidRaw['interstitial'] = source['androidInterstitial'];
    }

    return _AdmobUnitConfig(
      ios: _AdmobPlatformUnitConfig(
        squareIds: _sanitizeIds(
          _extractIds(
            iosRaw,
            keys: const <String>[
              'square',
              'kare',
              'squareIds',
              'kareIds',
            ],
          ),
          fallback: defaultIosSquareIds,
        ),
        interstitialIds: _sanitizeIds(
          _extractIds(
            iosRaw,
            keys: const <String>[
              'interstitial',
              'transition',
              'gecis',
              'geçiş',
              'interstitialIds',
              'transitionIds',
              'gecisIds',
            ],
          ),
          fallback: defaultIosInterstitialIds,
        ),
      ),
      android: _AdmobPlatformUnitConfig(
        squareIds: _sanitizeIds(
          _extractIds(
            androidRaw,
            keys: const <String>[
              'square',
              'kare',
              'squareIds',
              'kareIds',
            ],
          ),
          fallback: defaultAndroidSquareIds,
        ),
        interstitialIds: _sanitizeIds(
          _extractIds(
            androidRaw,
            keys: const <String>[
              'interstitial',
              'transition',
              'gecis',
              'geçiş',
              'interstitialIds',
              'transitionIds',
              'gecisIds',
            ],
          ),
          fallback: defaultAndroidInterstitialIds,
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ios': ios.toMap(),
      'android': android.toMap(),
    };
  }

  static List<String> _extractIds(
    Map<String, dynamic> map, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is Iterable) {
        return value.map((e) => e.toString()).toList(growable: false);
      }
    }
    return const <String>[];
  }

  static List<String> _sanitizeIds(
    Iterable<String> rawIds, {
    required List<String> fallback,
  }) {
    final cleaned = LinkedHashSet<String>.from(
      rawIds.map((e) => e.trim()).where((e) => e.isNotEmpty).take(10),
    ).toList(growable: false);
    if (cleaned.isNotEmpty) {
      return cleaned;
    }
    return List<String>.from(fallback, growable: false);
  }
}

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
