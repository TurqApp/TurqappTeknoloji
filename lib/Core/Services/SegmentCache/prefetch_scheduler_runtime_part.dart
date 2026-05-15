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

  bool get _isFeedSurfaceVisible {
    final nav = maybeFindNavBarController();
    if (nav == null) return false;
    if (nav.selectedIndex.value != 0 || nav.mediaOverlayActive) return false;
    final route = Get.currentRoute.trim();
    return route.isEmpty || route == '/NavBarView' || route == 'NavBarView';
  }

  bool get _isExploreSurfaceVisible {
    final nav = maybeFindNavBarController();
    if (nav == null) return false;
    if (nav.selectedIndex.value != 1 || nav.mediaOverlayActive) return false;
    final route = Get.currentRoute.trim();
    return route.isEmpty || route == '/NavBarView' || route == 'NavBarView';
  }

  String get _quotaSurfaceLabel {
    final nav = maybeFindNavBarController();
    if (nav == null) return 'none';
    if (nav.mediaOverlayActive) return 'overlay';
    if (_isFeedSurfaceVisible) return 'feed';
    if (_isExploreSurfaceVisible) return 'explore';
    switch (nav.selectedIndex.value) {
      case 2:
        return 'short_or_education';
      case 3:
        return 'pasaj_or_profile';
      case 4:
        return 'profile';
      default:
        return 'nav_${nav.selectedIndex.value}';
    }
  }

  String get _quotaFocusDebugLabel {
    final nav = maybeFindNavBarController();
    final manager = maybeFindVideoStateManager();
    return 'surface=$_quotaSurfaceLabel '
        'nav=${nav?.selectedIndex.value ?? -1} '
        'overlay=${nav?.mediaOverlayActive ?? false} '
        'route=${Get.currentRoute.trim()} '
        'current=${manager?.currentPlayingDocID ?? ''} '
        'target=${manager?.targetPlaybackDocID ?? ''}';
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

  bool _shouldAllowQuotaFillForDoc(String docID) {
    if (!_shouldAllowQuotaFillWithCurrentFocus) return false;
    if (!_hasActiveFeedPlaybackWindow) {
      return true;
    }

    final shortTier = classifyShortTransferDoc(docID);
    final feedTier = classifyFeedTransferDoc(docID);
    final inShortWindow = shortTier?['allowedSegmentWarm'] == true ||
        shortTier?['allowedCacheOnly'] == true;
    final inFeedWindow = feedTier?['allowedSegmentWarm'] == true ||
        feedTier?['allowedCacheOnly'] == true;
    final inFeedBank = _lastFeedBankDocIDs.contains(docID);
    return inShortWindow || inFeedWindow || inFeedBank;
  }

  bool get _shouldAllowBackgroundQuotaFill =>
      _prefetchSchedulerOfflineQuotaFillEnabled &&
      _automaticQuotaFillEnabled &&
      _hasQuotaEligibleSurfaceMounted &&
      _isOnWiFi &&
      CacheNetworkPolicy.canPrefetch;

  bool get _shouldAllowQuotaFillWithCurrentFocus =>
      _shouldAllowBackgroundQuotaFill && !_hasActiveFeedPlaybackWindow;

  bool get _hasQuotaEligibleSurfaceMounted {
    final nav = maybeFindNavBarController();
    if (nav == null || nav.mediaOverlayActive) return false;
    final route = Get.currentRoute.trim().toLowerCase();
    if (route.contains('signin') ||
        route.contains('sign_in') ||
        route.contains('login') ||
        route.contains('splash')) {
      return false;
    }
    return true;
  }

  bool get _useMinimalQuotaFillMode => _hasAnyActivePlaybackFocus;

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

  bool get _usesWifiPlaybackNetworkBehavior =>
      CacheNetworkPolicy.usesWifiPlaybackBehavior;

  bool get _allowMobileQuotaFill => false;

  bool get _isSurfacePrefetchNetworkEligible =>
      shouldAllowSurfacePrefetchNetwork(
        isOnWiFi: _usesWifiPlaybackNetworkBehavior,
        isOnCellular: false,
        canPrefetch: CacheNetworkPolicy.canPrefetch,
        canFetchOnDemand: CacheNetworkPolicy.canFetchOnDemand,
        canFetchPlaylist: CacheNetworkPolicy.canFetchPlaylist,
        cacheOnlyMode: CacheNetworkPolicy.cacheOnlyMode,
      );

  bool get _usesWifiSurfaceWarmSettings => _usesWifiPlaybackNetworkBehavior;

  int get _breadthCount {
    final base = ReadBudgetRegistry.segmentPrefetchBreadthCountValue;
    return _usesWifiSurfaceWarmSettings
        ? base < _prefetchSchedulerWifiMinBreadthCount
            ? _prefetchSchedulerWifiMinBreadthCount
            : base
        : base;
  }

  int get _depthCount {
    final base = ReadBudgetRegistry.segmentPrefetchDepthCountValue;
    return _usesWifiSurfaceWarmSettings
        ? base < _prefetchSchedulerWifiMinDepthCount
            ? _prefetchSchedulerWifiMinDepthCount
            : base
        : base;
  }

  int get _maxConcurrent {
    if (_mobileSeedMode) return 1;
    final base = ReadBudgetRegistry.segmentPrefetchMaxConcurrentValue;
    return _usesWifiSurfaceWarmSettings
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
