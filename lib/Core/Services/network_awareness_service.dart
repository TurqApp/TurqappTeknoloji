import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/bool_utils.dart';
import 'media_compression_service.dart';
import 'SegmentCache/prefetch_scheduler.dart';

part 'network_awareness_service_policy_part.dart';
part 'network_awareness_service_storage_part.dart';

enum NetworkType {
  wifi('network_awareness.type_wifi'),
  cellular('network_awareness.type_cellular'),
  none('network_awareness.type_none');

  const NetworkType(this.labelKey);
  final String labelKey;
  String get label => labelKey.tr;
}

enum DataUsageMode {
  low('network_awareness.mode_low', 50),
  normal('network_awareness.mode_normal', 75),
  high('network_awareness.mode_high', 90);

  const DataUsageMode(this.labelKey, this.quality);
  final String labelKey;
  final int quality;
  String get label => labelKey.tr;
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
    return parseFlexibleBool(value, fallback: fallback);
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
  static NetworkAwarenessService? maybeFind() {
    final isRegistered = Get.isRegistered<NetworkAwarenessService>();
    if (!isRegistered) return null;
    return Get.find<NetworkAwarenessService>();
  }

  static NetworkAwarenessService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NetworkAwarenessService(), permanent: true);
  }

  final Rx<NetworkType> _currentNetwork = NetworkType.none.obs;
  final Rx<NetworkSettings> _settings = NetworkSettings().obs;
  final Rx<DataUsageStats> _dataUsage = DataUsageStats(
    uploadedMB: 0,
    downloadedMB: 0,
    lastReset: DateTime.now(),
  ).obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  NetworkType? _debugOverrideNetwork;

  NetworkType get currentNetwork =>
      _debugOverrideNetwork ?? _currentNetwork.value;
  NetworkSettings get settings => _settings.value;
  DataUsageStats get dataUsage => _dataUsage.value;

  bool get isConnected => currentNetwork != NetworkType.none;
  bool get isOnWiFi => currentNetwork == NetworkType.wifi;
  bool get isOnCellular => currentNetwork == NetworkType.cellular;

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
}
