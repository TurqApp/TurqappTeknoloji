part of 'network_awareness_service.dart';

extension NetworkAwarenessServicePolicyPart on NetworkAwarenessService {
  static const Duration _connectivityPollInterval = Duration(seconds: 3);
  static const Duration _offlineConfirmationDelay = Duration(seconds: 4);
  static const MethodChannel _androidNetworkStateChannel = MethodChannel(
    'turqapp.network_state/method',
  );

  void _startNetworkMonitoring() async {
    final connectivity = await Connectivity().checkConnectivity();
    debugPrint(
      '[NetworkAwareness] source=initial_check results=${connectivity.map((e) => e.name).join(",")} '
      'current=${_currentNetwork.value.name}',
    );
    await _updateNetworkType(connectivity, source: 'initial_check');

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        debugPrint(
          '[NetworkAwareness] source=connectivity_stream results=${results.map((e) => e.name).join(",")} '
          'previous=${_currentNetwork.value.name}',
        );
        unawaited(
          _updateNetworkType(results, source: 'connectivity_stream'),
        );
      },
    );
    _connectivityPollTimer?.cancel();
    _connectivityPollTimer = Timer.periodic(
      _connectivityPollInterval,
      (_) => _refreshNetworkTypeFromPoll(),
    );
  }

  Future<void> _refreshNetworkTypeFromPoll() async {
    if (_debugOverrideNetwork != null) return;
    try {
      final results = await Connectivity().checkConnectivity();
      debugPrint(
        '[NetworkAwareness] source=poll_check results=${results.map((e) => e.name).join(",")} '
        'previous=${_currentNetwork.value.name}',
      );
      await _updateNetworkType(results, source: 'poll_check');
    } catch (e) {
      debugPrint('[NetworkAwareness] source=poll_check_failed error=$e');
    }
  }

  Future<void> _updateNetworkType(
    List<ConnectivityResult> results, {
    required String source,
  }) async {
    if (_debugOverrideNetwork != null) {
      return;
    }
    final previousNetwork = _currentNetwork.value;
    final resolvedFromConnectivity =
        _resolveNetworkTypeFromConnectivity(results);
    if (defaultTargetPlatform == TargetPlatform.android &&
        source == 'poll_check' &&
        previousNetwork == NetworkType.wifi &&
        resolvedFromConnectivity == NetworkType.cellular) {
      debugPrint(
        '[NetworkAwareness] source=sticky_wifi_ignore '
        'results=${results.map((e) => e.name).join(",")} '
        'previous=${previousNetwork.name}',
      );
      return;
    }
    final resolved = await _reconcileNativeNetworkType(
      results: results,
      resolvedFromConnectivity: resolvedFromConnectivity,
    );
    if (resolved == NetworkType.none) {
      _handleOfflineCandidate(
        previousNetwork: previousNetwork,
        results: results,
        source: source,
      );
      return;
    }

    _applyResolvedNetworkType(
      resolved,
      previousNetwork: previousNetwork,
      results: results,
      source: source,
    );
  }

  void _handleOfflineCandidate({
    required NetworkType previousNetwork,
    required List<ConnectivityResult> results,
    required String source,
  }) {
    if (_reachabilityState.value == NetworkReachabilityState.offlineConfirmed &&
        _currentNetwork.value == NetworkType.none) {
      debugPrint(
        '[NetworkAwareness] source=offline_still_confirmed '
        'results=${results.map((e) => e.name).join(",")}',
      );
      return;
    }

    _reachabilityState.value = NetworkReachabilityState.unstable;
    _offlineCandidateStartedAtMs = _offlineCandidateStartedAtMs == 0
        ? DateTime.now().millisecondsSinceEpoch
        : _offlineCandidateStartedAtMs;

    debugPrint(
      '[NetworkAwareness] source=offline_candidate '
      'trigger=$source previous=${previousNetwork.name} '
      'held=${_currentNetwork.value.name} '
      'results=${results.map((e) => e.name).join(",")}',
    );

    _offlineConfirmationTimer ??= Timer(
      _offlineConfirmationDelay,
      () => unawaited(_confirmOfflineCandidate()),
    );
  }

  Future<void> _confirmOfflineCandidate() async {
    _offlineConfirmationTimer = null;
    if (_debugOverrideNetwork != null) return;
    try {
      final results = await Connectivity().checkConnectivity();
      final resolvedFromConnectivity =
          _resolveNetworkTypeFromConnectivity(results);
      final resolved = await _reconcileNativeNetworkType(
        results: results,
        resolvedFromConnectivity: resolvedFromConnectivity,
      );
      final previousNetwork = _currentNetwork.value;
      if (resolved == NetworkType.none) {
        debugPrint(
          '[NetworkAwareness] source=offline_confirmed '
          'heldForMs=${DateTime.now().millisecondsSinceEpoch - _offlineCandidateStartedAtMs} '
          'previous=${previousNetwork.name} '
          'results=${results.map((e) => e.name).join(",")}',
        );
        _applyResolvedNetworkType(
          NetworkType.none,
          previousNetwork: previousNetwork,
          results: results,
          source: 'offline_confirmed',
        );
        return;
      }

      debugPrint(
        '[NetworkAwareness] source=offline_recovered_before_confirm '
        'resolved=${resolved.name} '
        'results=${results.map((e) => e.name).join(",")}',
      );
      _applyResolvedNetworkType(
        resolved,
        previousNetwork: previousNetwork,
        results: results,
        source: 'offline_recovered_before_confirm',
      );
    } catch (e) {
      debugPrint('[NetworkAwareness] source=offline_confirm_failed error=$e');
      _offlineConfirmationTimer ??= Timer(
        _offlineConfirmationDelay,
        () => unawaited(_confirmOfflineCandidate()),
      );
    }
  }

  void _applyResolvedNetworkType(
    NetworkType resolved, {
    required NetworkType previousNetwork,
    required List<ConnectivityResult> results,
    required String source,
  }) {
    _offlineConfirmationTimer?.cancel();
    _offlineConfirmationTimer = null;
    _offlineCandidateStartedAtMs = 0;
    _currentNetwork.value = resolved;
    _reachabilityState.value = resolved == NetworkType.none
        ? NetworkReachabilityState.offlineConfirmed
        : NetworkReachabilityState.online;

    debugPrint(
      '[NetworkAwareness] source=network_update trigger=$source '
      'resolved=${_currentNetwork.value.name} '
      'reachability=${_reachabilityState.value.name} '
      'results=${results.map((e) => e.name).join(",")}',
    );

    final scheduler = maybeFindPrefetchScheduler();
    if (scheduler != null) {
      if (_currentNetwork.value != NetworkType.none) {
        final enteredWifi = previousNetwork != NetworkType.wifi;
        if (enteredWifi || scheduler.isPaused) {
          scheduler.resume();
        }
      } else {
        if (!scheduler.isPaused) {
          scheduler.pause();
        }
      }
    }

    final shortController = maybeFindShortController();
    debugPrint(
      '[NetworkAwareness] dispatch=short found=${shortController != null} '
      'network=${_currentNetwork.value.name}',
    );
    if (shortController != null) {
      shortController.handleNetworkPolicyTransition(_currentNetwork.value);
    }

    final agendaController = maybeFindAgendaController();
    debugPrint(
      '[NetworkAwareness] dispatch=feed found=${agendaController != null} '
      'network=${_currentNetwork.value.name}',
    );
    if (agendaController != null) {
      agendaController.handleNetworkPolicyTransition(_currentNetwork.value);
    }
  }

  NetworkType _resolveNetworkTypeFromConnectivity(
    List<ConnectivityResult> results,
  ) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkType.cellular;
    }
    if (results.any((r) => r != ConnectivityResult.none)) {
      return NetworkType.wifi;
    }
    return NetworkType.none;
  }

  Future<NetworkType> _reconcileNativeNetworkType({
    required List<ConnectivityResult> results,
    required NetworkType resolvedFromConnectivity,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return resolvedFromConnectivity;
    }
    if (resolvedFromConnectivity == NetworkType.wifi) {
      return resolvedFromConnectivity;
    }
    try {
      final nativeTransport = await _androidNetworkStateChannel
          .invokeMethod<String>('getDefaultTransport');
      final nativeResolved = switch (nativeTransport) {
        'wifi' => NetworkType.wifi,
        'cellular' => NetworkType.cellular,
        'none' => NetworkType.none,
        _ => resolvedFromConnectivity,
      };
      if (nativeResolved != resolvedFromConnectivity) {
        debugPrint(
          '[NetworkAwareness] source=native_override '
          'connectivity=${resolvedFromConnectivity.name} '
          'native=${nativeResolved.name} '
          'results=${results.map((e) => e.name).join(",")}',
        );
        return nativeResolved;
      }
    } on MissingPluginException {
      return resolvedFromConnectivity;
    } catch (e) {
      debugPrint('[NetworkAwareness] source=native_override_failed error=$e');
    }
    return resolvedFromConnectivity;
  }

  void debugSetNetworkOverride(NetworkType? type) {
    _debugOverrideNetwork = type;
    if (type != null) {
      _offlineConfirmationTimer?.cancel();
      _offlineConfirmationTimer = null;
      _reachabilityState.value = type == NetworkType.none
          ? NetworkReachabilityState.offlineConfirmed
          : NetworkReachabilityState.online;
    }
    final scheduler = maybeFindPrefetchScheduler();
    if (scheduler == null) return;
    if (isOnWiFi) {
      if (scheduler.isPaused) {
        scheduler.resume();
      }
    } else {
      if (!scheduler.isPaused) {
        scheduler.pause();
      }
    }
  }

  CompressionQuality getOptimalCompressionQuality() {
    if (!allowUploadAttempt) return CompressionQuality.low;

    final mode = isOnWiFi ? settings.wifiDataMode : settings.cellularDataMode;

    switch (mode) {
      case DataUsageMode.low:
        return CompressionQuality.low;
      case DataUsageMode.normal:
        return CompressionQuality.medium;
      case DataUsageMode.high:
        return CompressionQuality.high;
    }
  }

  bool shouldAllowUpload({required int fileSizeMB}) {
    if (!allowUploadAttempt) return false;

    if (isOnCellular && settings.pauseOnCellular) {
      return false;
    }

    if (isOnCellular && settings.showDataWarnings) {
      final currentUsage = dataUsage.totalMB;
      final limit = settings.monthlyDataLimitMB;

      if (currentUsage + fileSizeMB > limit) {
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> getUploadRecommendation({required int fileSizeMB}) {
    if (!allowUploadAttempt) {
      return {
        'allowed': false,
        'reason': 'network_awareness.no_internet_reason'.tr,
        'suggestion': 'network_awareness.no_internet_suggestion'.tr,
      };
    }

    if (isOnCellular && settings.pauseOnCellular) {
      return {
        'allowed': false,
        'reason': 'network_awareness.cellular_paused_reason'.tr,
        'suggestion': 'network_awareness.cellular_paused_suggestion'.tr,
      };
    }

    final currentUsage = dataUsage.totalMB;
    final limit = settings.monthlyDataLimitMB;
    final remaining = limit - currentUsage;

    if (isOnCellular && fileSizeMB > remaining) {
      return {
        'allowed': false,
        'reason': 'network_awareness.limit_exceeded_reason'.tr,
        'suggestion': 'network_awareness.limit_exceeded_suggestion'.tr,
        'dataInfo': {
          'current': currentUsage,
          'limit': limit,
          'remaining': remaining,
          'fileSize': fileSizeMB,
        },
      };
    }

    final quality = getOptimalCompressionQuality();
    final estimatedSizeMB = (fileSizeMB * (quality.value / 100)).round();

    return {
      'allowed': true,
      'reason': 'network_awareness.upload_recommended'.tr,
      'suggestion': isOnWiFi
          ? 'network_awareness.wifi_optimal'.tr
          : 'network_awareness.cellular_in_use'.tr,
      'optimization': {
        'originalSize': fileSizeMB,
        'optimizedSize': estimatedSizeMB,
        'quality': quality.label,
        'savings': fileSizeMB - estimatedSizeMB,
      },
    };
  }

  double getDataUsagePercentage() {
    final total = dataUsage.totalMB;
    final limit = settings.monthlyDataLimitMB;
    return (total / limit * 100).clamp(0.0, 100.0);
  }

  String getDataUsageWarningLevel() {
    final percentage = getDataUsagePercentage();

    if (percentage >= 95) return 'critical';
    if (percentage >= 80) return 'high';
    if (percentage >= 60) return 'medium';
    return 'low';
  }

  bool shouldShowDataWarning() {
    if (!settings.showDataWarnings || !isOnCellular) return false;
    return getDataUsagePercentage() >= 80;
  }

  Map<String, dynamic> getNetworkStats() {
    return {
      'currentNetwork': currentNetwork.label,
      'isConnected': isConnected,
      'dataUsagePercentage': getDataUsagePercentage(),
      'warningLevel': getDataUsageWarningLevel(),
      'monthlyUsageMB': dataUsage.totalMB,
      'wifiUsageMB': dataUsage.uploadedWifiMB + dataUsage.downloadedWifiMB,
      'cellularUsageMB':
          dataUsage.uploadedCellularMB + dataUsage.downloadedCellularMB,
      'monthlyLimitMB': settings.monthlyDataLimitMB,
      'remainingMB': settings.monthlyDataLimitMB - dataUsage.totalMB,
      'autoUploadEnabled': settings.autoUploadOnWiFi,
      'cellularPaused': settings.pauseOnCellular,
    };
  }
}
