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
    final base = _remote?.prefetchBreadthCount ??
        PrefetchScheduler._fallbackBreadthCount;
    return _isOnWiFi
        ? base < PrefetchScheduler._wifiMinBreadthCount
            ? PrefetchScheduler._wifiMinBreadthCount
            : base
        : base;
  }

  int get _depthCount {
    final base =
        _remote?.prefetchDepthCount ?? PrefetchScheduler._fallbackDepthCount;
    return _isOnWiFi
        ? base < PrefetchScheduler._wifiMinDepthCount
            ? PrefetchScheduler._wifiMinDepthCount
            : base
        : base;
  }

  int get _maxConcurrent {
    if (_mobileSeedMode) return 1;
    final base = _remote?.prefetchMaxConcurrent ??
        PrefetchScheduler._fallbackMaxConcurrent;
    return _isOnWiFi
        ? base < PrefetchScheduler._wifiMinMaxConcurrent
            ? PrefetchScheduler._wifiMinMaxConcurrent
            : base
        : base;
  }

  int get _feedFullWindow => _isOnWiFi
      ? (PrefetchScheduler._fallbackFeedFullWindow <
              PrefetchScheduler._wifiMinFeedFullWindow
          ? PrefetchScheduler._wifiMinFeedFullWindow
          : PrefetchScheduler._fallbackFeedFullWindow)
      : PrefetchScheduler._fallbackFeedFullWindow;

  int get _feedPrepWindow => _isOnWiFi
      ? (PrefetchScheduler._fallbackFeedPrepWindow <
              PrefetchScheduler._wifiMinFeedPrepWindow
          ? PrefetchScheduler._wifiMinFeedPrepWindow
          : PrefetchScheduler._fallbackFeedPrepWindow)
      : PrefetchScheduler._fallbackFeedPrepWindow;

  VideoRemoteConfigService? get _remote => VideoRemoteConfigService.maybeFind();

  SegmentCacheManager? _getCacheManager() => SegmentCacheManager.maybeFind();

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
