import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'media_compression_service.dart';
import 'SegmentCache/prefetch_scheduler.dart';

enum NetworkType {
  wifi('Wi-Fi'),
  cellular('Mobil Veri'),
  none('Bağlantı Yok');

  const NetworkType(this.label);
  final String label;
}

enum DataUsageMode {
  low('Düşük Kalite', 50),
  normal('Normal Kalite', 75),
  high('Yüksek Kalite', 90);

  const DataUsageMode(this.label, this.quality);
  final String label;
  final int quality;
}

class NetworkSettings {
  bool autoUploadOnWiFi;
  bool pauseOnCellular;
  DataUsageMode cellularDataMode;
  DataUsageMode wifiDataMode;
  bool showDataWarnings;
  int monthlyDataLimitMB;
  double mobileTargetMbps;

  NetworkSettings({
    this.autoUploadOnWiFi = true,
    this.pauseOnCellular = false,
    this.cellularDataMode = DataUsageMode.low,
    this.wifiDataMode = DataUsageMode.high,
    this.showDataWarnings = true,
    this.monthlyDataLimitMB = 1024, // 1GB default
    this.mobileTargetMbps = 5.0,
  });

  Map<String, dynamic> toJson() => {
        'autoUploadOnWiFi': autoUploadOnWiFi,
        'pauseOnCellular': pauseOnCellular,
        'cellularDataMode': cellularDataMode.name,
        'wifiDataMode': wifiDataMode.name,
        'showDataWarnings': showDataWarnings,
        'monthlyDataLimitMB': monthlyDataLimitMB,
        'mobileTargetMbps': mobileTargetMbps,
      };

  factory NetworkSettings.fromJson(Map<String, dynamic> json) =>
      NetworkSettings(
        autoUploadOnWiFi: _asBool(json['autoUploadOnWiFi'], fallback: true),
        pauseOnCellular: _asBool(json['pauseOnCellular']),
        cellularDataMode: DataUsageMode.values.firstWhere(
          (mode) => mode.name == json['cellularDataMode']?.toString(),
          orElse: () => DataUsageMode.low,
        ),
        wifiDataMode: DataUsageMode.values.firstWhere(
          (mode) => mode.name == json['wifiDataMode']?.toString(),
          orElse: () => DataUsageMode.high,
        ),
        showDataWarnings: _asBool(json['showDataWarnings'], fallback: true),
        monthlyDataLimitMB: _asInt(json['monthlyDataLimitMB'], fallback: 1024),
        mobileTargetMbps: _asDouble(json['mobileTargetMbps'], fallback: 5.0),
      );

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}

class DataUsageStats {
  final int uploadedMB;
  final int downloadedMB;
  final int uploadedWifiMB;
  final int downloadedWifiMB;
  final int uploadedCellularMB;
  final int downloadedCellularMB;
  final int totalMB;
  final DateTime lastReset;

  DataUsageStats({
    required this.uploadedMB,
    required this.downloadedMB,
    this.uploadedWifiMB = 0,
    this.downloadedWifiMB = 0,
    this.uploadedCellularMB = 0,
    this.downloadedCellularMB = 0,
    required this.lastReset,
  }) : totalMB = uploadedMB + downloadedMB;

  Map<String, dynamic> toJson() => {
        'uploadedMB': uploadedMB,
        'downloadedMB': downloadedMB,
        'uploadedWifiMB': uploadedWifiMB,
        'downloadedWifiMB': downloadedWifiMB,
        'uploadedCellularMB': uploadedCellularMB,
        'downloadedCellularMB': downloadedCellularMB,
        'lastReset': lastReset.millisecondsSinceEpoch,
      };

  factory DataUsageStats.fromJson(Map<String, dynamic> json) => DataUsageStats(
        uploadedMB: _asInt(json['uploadedMB']),
        downloadedMB: _asInt(json['downloadedMB']),
        uploadedWifiMB: _asInt(json['uploadedWifiMB']),
        downloadedWifiMB: _asInt(json['downloadedWifiMB']),
        uploadedCellularMB: _asInt(json['uploadedCellularMB']),
        downloadedCellularMB: _asInt(json['downloadedCellularMB']),
        lastReset: DateTime.fromMillisecondsSinceEpoch(
          _asInt(
            json['lastReset'],
            fallback: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class NetworkAwarenessService extends GetxController {
  final Rx<NetworkType> _currentNetwork = NetworkType.none.obs;
  final Rx<NetworkSettings> _settings = NetworkSettings().obs;
  final Rx<DataUsageStats> _dataUsage = DataUsageStats(
    uploadedMB: 0,
    downloadedMB: 0,
    lastReset: DateTime.now(),
  ).obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  NetworkType get currentNetwork => _currentNetwork.value;
  NetworkSettings get settings => _settings.value;
  DataUsageStats get dataUsage => _dataUsage.value;

  bool get isConnected => _currentNetwork.value != NetworkType.none;
  bool get isOnWiFi => _currentNetwork.value == NetworkType.wifi;
  bool get isOnCellular => _currentNetwork.value == NetworkType.cellular;

  static const String _settingsKey = 'network_settings';
  static const String _dataUsageKey = 'data_usage_stats';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadDataUsage();
    _startNetworkMonitoring();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  /// Start monitoring network changes
  void _startNetworkMonitoring() async {
    // Check initial connectivity
    final connectivity = await Connectivity().checkConnectivity();
    _updateNetworkType(connectivity);

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          _updateNetworkType,
        );
  }

  /// Update network type
  void _updateNetworkType(List<ConnectivityResult> results) {
    // iOS'ta sonuç listesi [vpn, wifi] gibi gelebiliyor.
    // first'e bakmak yanlış şekilde offline kararına yol açıyordu.
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      _currentNetwork.value = NetworkType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _currentNetwork.value = NetworkType.cellular;
    } else if (results.any((r) => r != ConnectivityResult.none)) {
      // bluetooth/vpn/other benzeri bağlı durumları offline sayma.
      _currentNetwork.value = NetworkType.wifi;
    } else {
      _currentNetwork.value = NetworkType.none;
    }

    // Prefetch scheduler'ı bilgilendir
    try {
      final scheduler = Get.find<PrefetchScheduler>();
      if (_currentNetwork.value == NetworkType.wifi) {
        scheduler.resume();
      } else {
        scheduler.pause();
      }
    } catch (_) {}
  }

  /// Get optimal compression quality based on network
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

  /// Check if upload should be allowed
  bool shouldAllowUpload({required int fileSizeMB}) {
    if (!isConnected) return false;

    // Check if paused on cellular
    if (isOnCellular && settings.pauseOnCellular) {
      return false;
    }

    // Check data limit
    if (isOnCellular && settings.showDataWarnings) {
      final currentUsage = dataUsage.totalMB;
      final limit = settings.monthlyDataLimitMB;

      if (currentUsage + fileSizeMB > limit) {
        return false;
      }
    }

    return true;
  }

  /// Get upload recommendation
  Map<String, dynamic> getUploadRecommendation({required int fileSizeMB}) {
    if (!isConnected) {
      return {
        'allowed': false,
        'reason': 'İnternet bağlantısı yok',
        'suggestion': 'Bağlantı kurulduktan sonra tekrar deneyin',
      };
    }

    if (isOnCellular && settings.pauseOnCellular) {
      return {
        'allowed': false,
        'reason': 'Mobil veri üzerinden yükleme kapalı',
        'suggestion': 'Wi-Fi bağlantısı kurun veya ayarları değiştirin',
      };
    }

    final currentUsage = dataUsage.totalMB;
    final limit = settings.monthlyDataLimitMB;
    final remaining = limit - currentUsage;

    if (isOnCellular && fileSizeMB > remaining) {
      return {
        'allowed': false,
        'reason': 'Aylık veri limitini aşacak',
        'suggestion': 'Wi-Fi bekleyin veya dosya boyutunu küçültün',
        'dataInfo': {
          'current': currentUsage,
          'limit': limit,
          'remaining': remaining,
          'fileSize': fileSizeMB,
        },
      };
    }

    // Calculate estimated cost (rough estimation)
    final quality = getOptimalCompressionQuality();
    final estimatedSizeMB = (fileSizeMB * (quality.value / 100)).round();

    return {
      'allowed': true,
      'reason': 'Yükleme önerilir',
      'suggestion':
          isOnWiFi ? 'Wi-Fi bağlantısı optimal' : 'Mobil veri kullanılacak',
      'optimization': {
        'originalSize': fileSizeMB,
        'optimizedSize': estimatedSizeMB,
        'quality': quality.label,
        'savings': fileSizeMB - estimatedSizeMB,
      },
    };
  }

  /// Track data usage
  Future<void> trackDataUsage(
      {required int uploadMB, int downloadMB = 0}) async {
    // Reset monthly stats if needed
    final now = DateTime.now();
    final lastReset = dataUsage.lastReset;

    final isWifiNow = isOnWiFi;
    final isCellularNow = isOnCellular;

    if (now.month != lastReset.month || now.year != lastReset.year) {
      _dataUsage.value = DataUsageStats(
        uploadedMB: uploadMB,
        downloadedMB: downloadMB,
        uploadedWifiMB: isWifiNow ? uploadMB : 0,
        downloadedWifiMB: isWifiNow ? downloadMB : 0,
        uploadedCellularMB: isCellularNow ? uploadMB : 0,
        downloadedCellularMB: isCellularNow ? downloadMB : 0,
        lastReset: DateTime(now.year, now.month, 1),
      );
    } else {
      _dataUsage.value = DataUsageStats(
        uploadedMB: dataUsage.uploadedMB + uploadMB,
        downloadedMB: dataUsage.downloadedMB + downloadMB,
        uploadedWifiMB: dataUsage.uploadedWifiMB + (isWifiNow ? uploadMB : 0),
        downloadedWifiMB:
            dataUsage.downloadedWifiMB + (isWifiNow ? downloadMB : 0),
        uploadedCellularMB:
            dataUsage.uploadedCellularMB + (isCellularNow ? uploadMB : 0),
        downloadedCellularMB:
            dataUsage.downloadedCellularMB + (isCellularNow ? downloadMB : 0),
        lastReset: dataUsage.lastReset,
      );
    }

    await _saveDataUsage();
  }

  /// Update network settings
  Future<void> updateSettings(NetworkSettings newSettings) async {
    _settings.value = newSettings;
    await _saveSettings();
  }

  /// Get data usage percentage
  double getDataUsagePercentage() {
    final total = dataUsage.totalMB;
    final limit = settings.monthlyDataLimitMB;
    return (total / limit * 100).clamp(0.0, 100.0);
  }

  /// Get data usage warning level
  String getDataUsageWarningLevel() {
    final percentage = getDataUsagePercentage();

    if (percentage >= 95) return 'critical';
    if (percentage >= 80) return 'high';
    if (percentage >= 60) return 'medium';
    return 'low';
  }

  /// Should show data warning
  bool shouldShowDataWarning() {
    if (!settings.showDataWarnings || !isOnCellular) return false;
    return getDataUsagePercentage() >= 80;
  }

  /// Reset data usage stats
  Future<void> resetDataUsage() async {
    _dataUsage.value = DataUsageStats(
      uploadedMB: 0,
      downloadedMB: 0,
      uploadedWifiMB: 0,
      downloadedWifiMB: 0,
      uploadedCellularMB: 0,
      downloadedCellularMB: 0,
      lastReset: DateTime.now(),
    );
    await _saveDataUsage();
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_settingsKey);

    if (settingsString != null) {
      final settingsJson = Map<String, dynamic>.from(
        prefs.getString(_settingsKey) != null
            ? Uri.splitQueryString(settingsString)
            : {},
      );
      _settings.value = NetworkSettings.fromJson(settingsJson);
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = Uri(
        queryParameters: _settings.value
            .toJson()
            .map((key, value) => MapEntry(key, value.toString()))).query;
    await prefs.setString(_settingsKey, settingsString);
  }

  /// Load data usage from storage
  Future<void> _loadDataUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final dataUsageString = prefs.getString(_dataUsageKey);

    if (dataUsageString != null) {
      final dataUsageJson = Map<String, dynamic>.from(
        Uri.splitQueryString(dataUsageString),
      );
      _dataUsage.value = DataUsageStats.fromJson(dataUsageJson);
    }
  }

  /// Save data usage to storage
  Future<void> _saveDataUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final dataUsageString = Uri(
        queryParameters: _dataUsage.value
            .toJson()
            .map((key, value) => MapEntry(key, value.toString()))).query;
    await prefs.setString(_dataUsageKey, dataUsageString);
  }

  /// Get network statistics
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
