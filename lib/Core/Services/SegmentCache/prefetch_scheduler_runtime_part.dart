part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerRuntimePart on PrefetchScheduler {
  int get activeDownloads => _activeDownloads;
  int get queueSize => _queue.length;
  bool get isPaused => _paused;
  bool get isMobileSeedMode => _mobileSeedMode;
  double get feedReadyRatio => _lastFeedReadyRatio;
  int get feedReadyCount => _lastFeedReadyCount;
  int get feedWindowCount => _lastFeedWindowCount;
  double get avgQueueDispatchLatencyMs => _avgQueueDispatchLatencyMs;
  int get maxConcurrentDownloads => _maxConcurrent;

  bool get _isOnWiFi {
    try {
      final network = NetworkAwarenessService.maybeFind();
      if (network != null) {
        return network.isOnWiFi;
      }
    } catch (_) {}
    return CacheNetworkPolicy.canPrefetch;
  }

  int get _breadthCount {
    final base = ReadBudgetRegistry.segmentPrefetchBreadthCount;
    return _isOnWiFi
        ? base < _prefetchSchedulerWifiMinBreadthCount
            ? _prefetchSchedulerWifiMinBreadthCount
            : base
        : base;
  }

  int get _depthCount {
    final base = ReadBudgetRegistry.segmentPrefetchDepthCount;
    return _isOnWiFi
        ? base < _prefetchSchedulerWifiMinDepthCount
            ? _prefetchSchedulerWifiMinDepthCount
            : base
        : base;
  }

  int get _maxConcurrent {
    if (_mobileSeedMode) return 1;
    final base = ReadBudgetRegistry.segmentPrefetchMaxConcurrent;
    return _isOnWiFi
        ? base < _prefetchSchedulerWifiMinMaxConcurrent
            ? _prefetchSchedulerWifiMinMaxConcurrent
            : base
        : base;
  }

  int get _feedFullWindow => _isOnWiFi
      ? (_prefetchSchedulerFallbackFeedFullWindow <
              _prefetchSchedulerWifiMinFeedFullWindow
          ? _prefetchSchedulerWifiMinFeedFullWindow
          : _prefetchSchedulerFallbackFeedFullWindow)
      : _prefetchSchedulerFallbackFeedFullWindow;

  int get _feedPrepWindow => _isOnWiFi
      ? (_prefetchSchedulerFallbackFeedPrepWindow <
              _prefetchSchedulerWifiMinFeedPrepWindow
          ? _prefetchSchedulerWifiMinFeedPrepWindow
          : _prefetchSchedulerFallbackFeedPrepWindow)
      : _prefetchSchedulerFallbackFeedPrepWindow;

  SegmentCacheManager? _getCacheManager() {
    final cache = SegmentCacheManager.maybeFind();
    if (cache == null || !cache.isReady) return null;
    return cache;
  }

  StorageBudgetProfile? get _storageBudgetProfile {
    final manager = StorageBudgetManager.maybeFind();
    if (manager == null) return null;
    final profile = manager.currentProfile;
    return profile.isValid ? profile : null;
  }

  int get _wifiQuotaFillTargetBytes {
    if (!_isOnWiFi) return 0;
    final profile = _storageBudgetProfile;
    if (profile == null) return 0;
    return (profile.streamCacheHardStopBytes *
            _prefetchSchedulerWifiQuotaFillRatio)
        .round();
  }

  bool _hasReachedWifiQuotaFillTarget(SegmentCacheManager cacheManager) {
    final targetBytes = _wifiQuotaFillTargetBytes;
    if (targetBytes <= 0) return false;
    return cacheManager.totalSizeBytes >= targetBytes;
  }

  double _wifiQuotaFillRatio(SegmentCacheManager cacheManager) {
    final targetBytes = _wifiQuotaFillTargetBytes;
    if (targetBytes <= 0) return 0.0;
    return (cacheManager.totalSizeBytes / targetBytes).clamp(0.0, 1.0);
  }

  void _handlePrefetchSchedulerClose() {
    _watchdogTimer?.cancel();
    _workerSub?.cancel();
    _worker?.stop();
    if (_pendingDownloadBytes > 0) {
      final int downloadMb = (_pendingDownloadBytes / (1024 * 1024)).ceil();
      final network = NetworkAwarenessService.maybeFind();
      if (network != null) {
        unawaited(network.trackDataUsage(uploadMB: 0, downloadMB: downloadMb));
      }
      _pendingDownloadBytes = 0;
    }
    _httpClient.close();
  }
}
