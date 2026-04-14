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

  bool get _hasActiveFeedPlaybackWindow {
    final hasFeedWindow =
        _lastFeedSurfaceVideoDocIDs.isNotEmpty || _lastFeedDocIDs.isNotEmpty;
    if (!hasFeedWindow) return false;
    final nav = maybeFindNavBarController();
    final feedVisible =
        nav == null || (nav.selectedIndex.value == 0 && !nav.mediaOverlayActive);
    if (!feedVisible) return false;
    final manager = maybeFindVideoStateManager();
    if (manager == null) return true;
    final current = manager.currentPlayingDocID?.trim() ?? '';
    final target = manager.targetPlaybackDocID?.trim() ?? '';
    return current.startsWith('feed:') ||
        target.startsWith('feed:') ||
        feedVisible;
  }

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
    final base = ReadBudgetRegistry.segmentPrefetchBreadthCountValue;
    return _isOnWiFi
        ? base < _prefetchSchedulerWifiMinBreadthCount
            ? _prefetchSchedulerWifiMinBreadthCount
            : base
        : base;
  }

  int get _depthCount {
    final base = ReadBudgetRegistry.segmentPrefetchDepthCountValue;
    return _isOnWiFi
        ? base < _prefetchSchedulerWifiMinDepthCount
            ? _prefetchSchedulerWifiMinDepthCount
            : base
        : base;
  }

  int get _maxConcurrent {
    if (_mobileSeedMode) return 1;
    final base = ReadBudgetRegistry.segmentPrefetchMaxConcurrentValue;
    return _isOnWiFi
        ? base < _prefetchSchedulerWifiMinMaxConcurrent
            ? _prefetchSchedulerWifiMinMaxConcurrent
            : base
        : base;
  }

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
    final profile = _storageBudgetProfile;
    if (profile == null) return 0;
    return profile.streamCacheSoftStopBytes;
  }

  int get _wifiQuotaFillStopBytes {
    final profile = _storageBudgetProfile;
    if (profile == null) return 0;
    return profile.streamCacheHardStopBytes;
  }

  bool _hasReachedWifiQuotaFillTarget(SegmentCacheManager cacheManager) {
    final stopBytes = _wifiQuotaFillStopBytes;
    if (stopBytes <= 0) return false;
    return cacheManager.totalTrackedUsageBytes >= stopBytes;
  }

  double _wifiQuotaFillRatio(SegmentCacheManager cacheManager) {
    final targetBytes = _wifiQuotaFillTargetBytes;
    if (targetBytes <= 0) return 0.0;
    return (cacheManager.totalTrackedUsageBytes / targetBytes).clamp(0.0, 1.0);
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
