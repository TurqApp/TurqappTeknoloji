part of 'network_awareness_service.dart';

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
    this.monthlyDataLimitMB = 1024,
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
