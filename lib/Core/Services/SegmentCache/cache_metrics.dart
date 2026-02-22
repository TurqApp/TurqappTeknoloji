import 'dart:async';
import 'package:flutter/foundation.dart';

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
  }

  void recordMiss(int bytes) {
    proxyRequestsTotal++;
    cacheMisses++;
    bytesDownloaded += bytes;
  }

  void recordEviction() {
    evictions++;
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

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}
