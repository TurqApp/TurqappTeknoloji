import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/prefetch_scoring_engine.dart';
import 'package:turqappv2/Core/Services/video_telemetry_service.dart';
import 'package:turqappv2/Core/Services/video_emotion_config_service.dart';

import '../network_awareness_service.dart';
import 'cache_manager.dart';
import 'download_worker.dart';
import 'hls_data_usage_probe.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

part 'prefetch_scheduler_queue_part.dart';
part 'prefetch_scheduler_worker_part.dart';

/// Wi-Fi prefetch kuyruğu.
///
/// Breadth-first strateji:
/// 1. Sonraki videolarda ilk 2 segment hazır
/// 2. Aktif videoda ilk 2 segment hazır
/// 3. İzleme sırasında yalnızca 1 sonraki segment hazırlanır
class PrefetchScheduler extends GetxController {
  static PrefetchScheduler ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PrefetchScheduler(), permanent: permanent);
  }

  static PrefetchScheduler? maybeFind() {
    final isRegistered = Get.isRegistered<PrefetchScheduler>();
    if (!isRegistered) return null;
    return Get.find<PrefetchScheduler>();
  }

  static const String _cdnOrigin = 'https://cdn.turqapp.com';
  static const Map<String, String> _cdnHeaders = {
    'X-Turq-App': 'turqapp-mobile',
    'Referer': '$_cdnOrigin/',
  };
  static const int _targetReadySegments = 2;
  // +5/-5 kuralı: önündeki 5 videonun min 2 segmenti hazır olmalı
  static const int _fallbackBreadthCount = 5;
  static const int _fallbackDepthCount = 3;
  static const int _fallbackMaxConcurrent = 2;
  static const int _fallbackFeedFullWindow = 15;
  static const int _fallbackFeedPrepWindow = 8;
  static const int _wifiMinBreadthCount = 12;
  static const int _wifiMinDepthCount = 7;
  static const int _wifiMinMaxConcurrent = 4;
  static const int _wifiMinFeedFullWindow = 15;
  static const int _wifiMinFeedPrepWindow = 20;

  final List<_PrefetchJob> _queue = [];
  bool _paused = false;
  bool _mobileSeedMode = false;
  int _activeDownloads = 0;
  int _pendingDownloadBytes = 0;
  final Map<String, DateTime> _jobEnqueuedAt = {};
  List<String> _lastFeedDocIDs = const [];
  int _lastFeedCurrentIndex = 0;
  int _lastFeedReadyCount = 0;
  int _lastFeedWindowCount = 0;
  double _lastFeedReadyRatio = 0.0;
  int _queueLatencySamples = 0;
  double _avgQueueDispatchLatencyMs = 0.0;
  String? _lastPrefetchHealthSignature;
  DownloadWorker? _worker;
  StreamSubscription? _workerSub;
  Timer? _watchdogTimer;
  final http.Client _httpClient = http.Client();

  int get activeDownloads => _activeDownloads;
  int get queueSize => _queue.length;
  bool get isPaused => _paused;
  bool get isMobileSeedMode => _mobileSeedMode;
  double get feedReadyRatio => _lastFeedReadyRatio;
  int get feedReadyCount => _lastFeedReadyCount;
  int get feedWindowCount => _lastFeedWindowCount;
  double get avgQueueDispatchLatencyMs => _avgQueueDispatchLatencyMs;
  int get maxConcurrentDownloads => _maxConcurrent;
  bool get _isOnWiFi {
    try {
      final network = NetworkAwarenessService.maybeFind();
      if (network != null) {
        return network.isOnWiFi;
      }
    } catch (_) {}
    return CacheNetworkPolicy.canPrefetch;
  }

  int get _breadthCount {
    final base = _remote?.prefetchBreadthCount ?? _fallbackBreadthCount;
    return _isOnWiFi
        ? base < _wifiMinBreadthCount
            ? _wifiMinBreadthCount
            : base
        : base;
  }

  int get _depthCount {
    final base = _remote?.prefetchDepthCount ?? _fallbackDepthCount;
    return _isOnWiFi
        ? base < _wifiMinDepthCount
            ? _wifiMinDepthCount
            : base
        : base;
  }

  int get _maxConcurrent {
    if (_mobileSeedMode) return 1;
    final base = _remote?.prefetchMaxConcurrent ?? _fallbackMaxConcurrent;
    return _isOnWiFi
        ? base < _wifiMinMaxConcurrent
            ? _wifiMinMaxConcurrent
            : base
        : base;
  }

  int get _feedFullWindow => _isOnWiFi
      ? (_fallbackFeedFullWindow < _wifiMinFeedFullWindow
          ? _wifiMinFeedFullWindow
          : _fallbackFeedFullWindow)
      : _fallbackFeedFullWindow;

  int get _feedPrepWindow => _isOnWiFi
      ? (_fallbackFeedPrepWindow < _wifiMinFeedPrepWindow
          ? _wifiMinFeedPrepWindow
          : _fallbackFeedPrepWindow)
      : _fallbackFeedPrepWindow;

  VideoRemoteConfigService? get _remote => VideoRemoteConfigService.maybeFind();

  // ──────────────────────────── Helpers ────────────────────────────

  SegmentCacheManager? _getCacheManager() => SegmentCacheManager.maybeFind();

  @override
  void onClose() {
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
    super.onClose();
  }
}

class _PrefetchJob {
  final String docID;
  final int maxSegments; // Bu job için indirilecek maksimum segment.
  final int priority; // düşük = önce
  final double sortScore;

  _PrefetchJob({
    required this.docID,
    required this.maxSegments,
    required this.priority,
    required this.sortScore,
  });
}
