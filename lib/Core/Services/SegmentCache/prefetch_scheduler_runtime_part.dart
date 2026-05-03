part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerRuntimePart on PrefetchScheduler {
  static const double _mobileQuotaFillTargetRatio = 0.02;
  int get activeDownloads => _activeDownloads;
  int get queueSize => _queue.length;
  bool get isPaused => _paused;
  bool get isMobileSeedMode => _mobileSeedMode;
  double get feedReadyRatio => _lastFeedReadyRatio;
  int get feedReadyCount => _lastFeedReadyCount;
  int get feedWindowCount => _lastFeedWindowCount;
  double get avgQueueDispatchLatencyMs => _avgQueueDispatchLatencyMs;
  int get maxConcurrentDownloads => _maxConcurrent;

  bool get _isFeedSurfaceVisible {
    final nav = maybeFindNavBarController();
    return nav == null ||
        (nav.selectedIndex.value == 0 && !nav.mediaOverlayActive);
  }

  bool _isProfilePlaybackHandle(String value) {
    return value.startsWith('social_') || value.startsWith('profile_');
  }

  bool get _hasActiveFeedPlaybackWindow {
    if (!_isFeedSurfaceVisible) return false;
    final hasFeedWindow =
        _lastFeedSurfaceVideoDocIDs.isNotEmpty || _lastFeedDocIDs.isNotEmpty;
    if (!hasFeedWindow) {
      return true;
    }
    final manager = maybeFindVideoStateManager();
    if (manager == null) return true;
    final current = manager.currentPlayingDocID?.trim() ?? '';
    final target = manager.targetPlaybackDocID?.trim() ?? '';
    final hasShortFocus =
        current.startsWith('short:') || target.startsWith('short:');
    final hasProfileFocus =
        _isProfilePlaybackHandle(current) || _isProfilePlaybackHandle(target);
    if (hasShortFocus || hasProfileFocus) {
      return false;
    }
    return current.startsWith('feed:') ||
        target.startsWith('feed:') ||
        _isFeedSurfaceVisible;
  }

  bool get _hasActiveProfilePlaybackWindow {
    final manager = maybeFindVideoStateManager();
    if (manager == null) return false;
    final current = manager.currentPlayingDocID?.trim() ?? '';
    final target = manager.targetPlaybackDocID?.trim() ?? '';
    return _isProfilePlaybackHandle(current) ||
        _isProfilePlaybackHandle(target);
  }

  bool get _hasActiveShortPlaybackWindow {
    final manager = maybeFindVideoStateManager();
    if (manager == null) return false;
    final current = manager.currentPlayingDocID?.trim() ?? '';
    final target = manager.targetPlaybackDocID?.trim() ?? '';
    return current.startsWith('short:') || target.startsWith('short:');
  }

  bool get _hasAnyActivePlaybackFocus {
    final manager = maybeFindVideoStateManager();
    if (manager == null) return false;
    final current = manager.currentPlayingDocID?.trim() ?? '';
    final target = manager.targetPlaybackDocID?.trim() ?? '';
    if (current.isEmpty && target.isEmpty) return false;
    return current.startsWith('feed:') ||
        current.startsWith('social_') ||
        current.startsWith('profile_') ||
        current.startsWith('short:') ||
        target.startsWith('feed:') ||
        target.startsWith('social_') ||
        target.startsWith('profile_') ||
        target.startsWith('short:');
  }

  bool get _shouldAllowBackgroundQuotaFill => true;

  bool get _useMinimalQuotaFillMode => !_hasActiveShortPlaybackWindow;

  bool get _isOnWiFi {
    try {
      final network = NetworkAwarenessService.maybeFind();
      if (network != null) {
        return network.isOnWiFi;
      }
    } catch (_) {}
    return CacheNetworkPolicy.canPrefetch;
  }

  bool get _isOnCellular => CacheNetworkPolicy.isOnCellular;

  bool get _allowMobileQuotaFill => false;

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
    if (profile != null) {
      return profile.streamCacheSoftStopBytes;
    }
    final cache = _getCacheManager();
    if (cache == null) return 0;
    return cache.softLimitBytes;
  }

  int get _quotaFillTargetBytes {
    final baseTargetBytes = _wifiQuotaFillTargetBytes;
    if (baseTargetBytes <= 0) return 0;
    if (_isOnWiFi) return baseTargetBytes;
    if (_allowMobileQuotaFill) {
      return (baseTargetBytes * _mobileQuotaFillTargetRatio).round();
    }
    return 0;
  }

  bool get _isQuotaFillNetworkEligible =>
      (_isOnWiFi && CacheNetworkPolicy.canPrefetch) || _allowMobileQuotaFill;

  bool _hasReachedWifiQuotaFillTarget(SegmentCacheManager cacheManager) {
    final targetBytes = _quotaFillTargetBytes;
    if (targetBytes <= 0) return false;
    return cacheManager.totalTrackedUsageBytes >= targetBytes;
  }

  double _wifiQuotaFillRatio(SegmentCacheManager cacheManager) {
    final targetBytes = _quotaFillTargetBytes;
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
