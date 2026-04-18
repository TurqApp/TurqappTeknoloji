part of 'network_awareness_service.dart';

extension NetworkAwarenessServicePolicyPart on NetworkAwarenessService {
  static const Duration _connectivityPollInterval = Duration(seconds: 3);

  void _startNetworkMonitoring() async {
    final connectivity = await Connectivity().checkConnectivity();
    debugPrint(
      '[NetworkAwareness] source=initial_check results=${connectivity.map((e) => e.name).join(",")} '
      'current=${_currentNetwork.value.name}',
    );
    _updateNetworkType(connectivity);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        debugPrint(
          '[NetworkAwareness] source=connectivity_stream results=${results.map((e) => e.name).join(",")} '
          'previous=${_currentNetwork.value.name}',
        );
        _updateNetworkType(results);
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
      _updateNetworkType(results);
    } catch (e) {
      debugPrint('[NetworkAwareness] source=poll_check_failed error=$e');
    }
  }

  void _updateNetworkType(List<ConnectivityResult> results) {
    if (_debugOverrideNetwork != null) {
      return;
    }
    final previousNetwork = _currentNetwork.value;
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      _currentNetwork.value = NetworkType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _currentNetwork.value = NetworkType.cellular;
    } else if (results.any((r) => r != ConnectivityResult.none)) {
      _currentNetwork.value = NetworkType.wifi;
    } else {
      _currentNetwork.value = NetworkType.none;
    }

    debugPrint(
      '[NetworkAwareness] source=network_update resolved=${_currentNetwork.value.name} '
      'results=${results.map((e) => e.name).join(",")}',
    );

    if (_currentNetwork.value != NetworkType.wifi) {
      _wifiSchedulerBootstrapApplied = false;
    }

    final scheduler = maybeFindPrefetchScheduler();
    if (scheduler != null) {
      if (_currentNetwork.value == NetworkType.wifi) {
        final enteredWifi = previousNetwork != NetworkType.wifi;
        if (enteredWifi) {
          _wifiSchedulerBootstrapApplied = false;
        }
        final shouldBootstrapOnSchedulerAttach =
            !_wifiSchedulerBootstrapApplied;
        if (!scheduler.automaticQuotaFillEnabled &&
            (enteredWifi || shouldBootstrapOnSchedulerAttach)) {
          scheduler.setAutomaticQuotaFillEnabled(
            true,
            reason: enteredWifi
                ? 'wifi_network_transition'
                : 'wifi_scheduler_attach',
          );
          _wifiSchedulerBootstrapApplied = true;
        } else if (scheduler.automaticQuotaFillEnabled) {
          _wifiSchedulerBootstrapApplied = true;
        }
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

  void debugSetNetworkOverride(NetworkType? type) {
    _debugOverrideNetwork = type;
    final scheduler = maybeFindPrefetchScheduler();
    if (scheduler == null) return;
    if (isOnWiFi) {
      if (!scheduler.automaticQuotaFillEnabled) {
        scheduler.setAutomaticQuotaFillEnabled(
          true,
          reason: 'wifi_debug_override',
        );
      }
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
    if (!isConnected) return CompressionQuality.low;

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
    if (!isConnected) return false;

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
    if (!isConnected) {
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
