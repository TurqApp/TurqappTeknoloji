import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

/// Global AdMob banner warmup rules.
///
/// We treat banner inventory as an app-wide warm pool instead of creating
/// independent speculative warmups on every page.
class AdmobBannerWarmupService extends GetxService {
  // Shared pool upper bound is 8, so startup primes most of the inventory
  // without saturating the pool or triggering rate limiting on low-fill sessions.
  static const int splashFirstLaunchTarget = 3;
  static const int splashDefaultTarget = 2;
  static const int feedEntryTarget = 1;
  static const int pasajEntryTarget = 2;
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

  Future<void> ensureInitialized() async {
    if (_sdkReady) return;
    final pending = _initFuture;
    if (pending != null) {
      await pending;
      return;
    }

    final future = _initializeInternal();
    _initFuture = future;
    try {
      await future;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> warmFromSplash({
    required bool isFirstLaunch,
  }) async {
    await ensureInitialized();
    if (!_sdkReady) return;

    final target =
        isFirstLaunch ? splashFirstLaunchTarget : splashDefaultTarget;
    await AdmobKare.warmupPool(targetCount: target);
    if (target >= 3) {
      Future<void>.delayed(_secondaryTopUpDelay, () async {
        try {
          await AdmobKare.warmupPool(targetCount: target);
        } catch (_) {}
      });
    }
  }

  Future<void> warmForFeedEntry() async {
    await warmForSurfaceEntry(
      surfaceKey: 'feed',
      targetCount: feedEntryTarget,
    );
  }

  Future<void> warmForPasajEntry({
    required String surfaceKey,
    int targetCount = pasajEntryTarget,
  }) async {
    await warmForSurfaceEntry(
      surfaceKey: 'pasaj:$surfaceKey',
      targetCount: targetCount,
    );
  }

  Future<void> warmForSurfaceEntry({
    required String surfaceKey,
    required int targetCount,
  }) async {
    final now = DateTime.now();
    final last = _lastWarmupAtBySurface[surfaceKey];
    if (last != null && now.difference(last) < _entryWarmupMinInterval) {
      return;
    }
    _lastWarmupAtBySurface[surfaceKey] = now;

    await ensureInitialized();
    if (!_sdkReady) return;
    await AdmobKare.warmupPool(targetCount: targetCount);
  }

  Future<void> _initializeInternal() async {
    try {
      await MobileAds.instance.initialize();
      _sdkReady = true;
    } catch (error) {
      _sdkReady = false;
      if (kDebugMode) {
        debugPrint('[AdmobBannerWarmupService] init failed: $error');
      }
    }
  }
}
