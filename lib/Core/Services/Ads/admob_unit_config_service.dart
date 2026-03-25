import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';

part 'admob_unit_config_service_models_part.dart';
part 'admob_unit_config_service_facade_part.dart';
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

  @override
  void onClose() {
    _disposeAdmobConfigRuntime(this);
    super.onClose();
  }
}
