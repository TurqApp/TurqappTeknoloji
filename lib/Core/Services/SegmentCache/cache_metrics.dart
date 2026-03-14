import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';

/// Cache hit/miss sayaçları ve debug dump.
class CacheMetrics {
  int proxyRequestsTotal = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int bytesServedFromCache = 0;
  int bytesDownloaded = 0;
  int evictions = 0;

  Timer? _logTimer;

  double get cacheHitRate =>
      proxyRequestsTotal > 0 ? cacheHits / proxyRequestsTotal : 0.0;

  void recordHit(int bytes) {
    proxyRequestsTotal++;
    cacheHits++;
    bytesServedFromCache += bytes;
    _publishKpiIfNeeded();
  }

  void recordMiss(int bytes) {
    proxyRequestsTotal++;
    cacheMisses++;
    bytesDownloaded += bytes;
    _publishKpiIfNeeded();
  }

  void recordEviction() {
    evictions++;
    _publishKpi(force: true);
  }

  Map<String, dynamic> toJson() => {
        'proxyRequestsTotal': proxyRequestsTotal,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
        'cacheHitRate': '${(cacheHitRate * 100).toStringAsFixed(1)}%',
        'bytesServedFromCache': formatBytes(bytesServedFromCache),
        'bytesDownloaded': formatBytes(bytesDownloaded),
        'evictions': evictions,
      };

  void startPeriodicLog({Duration interval = const Duration(seconds: 30)}) {
    if (!kDebugMode) return;
    _logTimer?.cancel();
    _logTimer = Timer.periodic(interval, (_) {
      if (proxyRequestsTotal > 0) {
        debugPrint('[CacheMetrics] ${toJson()}');
      }
    });
  }

  void stopPeriodicLog() {
    _logTimer?.cancel();
    _logTimer = null;
  }

  void reset() {
    proxyRequestsTotal = 0;
    cacheHits = 0;
    cacheMisses = 0;
    bytesServedFromCache = 0;
    bytesDownloaded = 0;
    evictions = 0;
  }

  void _publishKpiIfNeeded() {
    if (proxyRequestsTotal < 10) return;
    if (proxyRequestsTotal % 25 != 0) return;
    _publishKpi();
  }

  void _publishKpi({bool force = false}) {
    if (!Get.isRegistered<PlaybackKpiService>()) return;
    if (!force && proxyRequestsTotal == 0) return;
    Get.find<PlaybackKpiService>().track(
      PlaybackKpiEventType.cacheHitRatio,
      {
        'proxyRequestsTotal': proxyRequestsTotal,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
        'cacheHitRate': cacheHitRate,
        'bytesServedFromCache': bytesServedFromCache,
        'bytesDownloaded': bytesDownloaded,
        'evictions': evictions,
      },
    );
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}
