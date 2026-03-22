part of 'network_awareness_service.dart';

extension NetworkAwarenessServicePolicyPart on NetworkAwarenessService {
  void _startNetworkMonitoring() async {
    final connectivity = await Connectivity().checkConnectivity();
    _updateNetworkType(connectivity);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          _updateNetworkType,
        );
  }

  void _updateNetworkType(List<ConnectivityResult> results) {
    if (_debugOverrideNetwork != null) {
      return;
    }
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

    final scheduler = PrefetchScheduler.maybeFind();
    if (scheduler == null) return;
    if (_currentNetwork.value == NetworkType.wifi) {
      scheduler.resume();
    } else {
      scheduler.pause();
    }
  }

  void debugSetNetworkOverride(NetworkType? type) {
    _debugOverrideNetwork = type;
    final scheduler = PrefetchScheduler.maybeFind();
    if (scheduler == null) return;
    if (isOnWiFi) {
      scheduler.resume();
    } else {
      scheduler.pause();
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
