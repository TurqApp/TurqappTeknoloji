part of 'admob_banner_warmup_service.dart';

extension AdmobBannerWarmupServiceRuntimePart on AdmobBannerWarmupService {
  Future<bool> _waitForStartupFeedReady() async {
    final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
    for (int attempt = 0; attempt < 10; attempt++) {
      final agenda = maybeFindAgendaController();
      final prefetch = maybeFindPrefetchScheduler();
      final feedRendered = agenda?.renderFeedEntries.isNotEmpty ?? false;
      final startupReady = feedRendered &&
          prefetch != null &&
          prefetch.feedReadyCount >= readyThreshold;
      if (startupReady) {
        return true;
      }
      await Future<void>.delayed(
        attempt == 0
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 900),
      );
    }
    return false;
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

    final target = isFirstLaunch
        ? AdmobBannerWarmupService.splashFirstLaunchTarget
        : AdmobBannerWarmupService.splashDefaultTarget;
    await AdmobKare.warmupPool(
      targetCount: target,
      maxRequestCount: target,
      bypassMinInterval: true,
    );
    if (target >= AdmobBannerWarmupService.lowWaterMark) {
      Future<void>.delayed(AdmobBannerWarmupService._secondaryTopUpDelay,
          () async {
        try {
          await AdmobKare.warmupPool(
            targetCount: target,
            maxRequestCount: AdmobBannerWarmupService.topUpBatchSize,
            bypassMinInterval: true,
          );
        } catch (_) {}
      });
    }
  }

  Future<void> warmForFeedEntry() async {
    await warmForSurfaceEntry(
      surfaceKey: 'feed',
      targetCount: AdmobBannerWarmupService.feedEntryTarget,
    );
  }

  Future<void> warmForPasajEntry({
    required String surfaceKey,
    int targetCount = AdmobBannerWarmupService.pasajEntryTarget,
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
    if (last != null &&
        now.difference(last) <
            AdmobBannerWarmupService._entryWarmupMinInterval) {
      return;
    }
    await ensureInitialized();
    if (!_sdkReady) return;
    _lastWarmupAtBySurface[surfaceKey] = now;
    await AdmobKare.warmupPool(
      targetCount: targetCount,
      maxRequestCount: targetCount,
      bypassMinInterval: true,
    );
  }

  Future<void> _initializeInternal() async {
    try {
      final startupReady = await _waitForStartupFeedReady();
      if (!startupReady) {
        _sdkReady = false;
        return;
      }
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
