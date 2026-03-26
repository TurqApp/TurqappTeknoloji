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
part 'prefetch_scheduler_runtime_part.dart';
part 'prefetch_scheduler_models_part.dart';
part 'prefetch_scheduler_fields_part.dart';

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

  final _state = _PrefetchSchedulerState();

  @override
  void onClose() {
    _handlePrefetchSchedulerClose();
    super.onClose();
  }
}
