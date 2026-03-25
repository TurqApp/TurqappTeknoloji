import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

part 'admob_banner_warmup_service_runtime_part.dart';

/// Global AdMob banner warmup rules.
///
/// We treat banner inventory as an app-wide warm pool instead of creating
/// independent speculative warmups on every page.
class AdmobBannerWarmupService extends GetxService {
  static const int steadyStateTarget = 5;
  // Shared pool upper bound is 8, so keeping 5 renderable banners ready leaves
  // headroom while still rotating through all configured square ad units.
  static const int splashFirstLaunchTarget = steadyStateTarget;
  static const int splashDefaultTarget = steadyStateTarget;
  static const int feedEntryTarget = steadyStateTarget;
  static const int pasajEntryTarget = steadyStateTarget;
  static const Duration _entryWarmupMinInterval = Duration(seconds: 20);
  static const Duration _secondaryTopUpDelay = Duration(milliseconds: 2500);

  Future<void>? _initFuture;
  bool _sdkReady = false;
  final Map<String, DateTime> _lastWarmupAtBySurface = <String, DateTime>{};

  static AdmobBannerWarmupService? maybeFind() {
    final isRegistered = Get.isRegistered<AdmobBannerWarmupService>();
    if (!isRegistered) return null;
    return Get.find<AdmobBannerWarmupService>();
  }

  static AdmobBannerWarmupService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AdmobBannerWarmupService(), permanent: true);
  }
}
