import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_summary_models.dart';

part 'playback_kpi_service_summary_part.dart';

const bool _suppressPlaybackKpiSmokeLogs =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);

enum PlaybackKpiEventType {
  startup,
  cacheFirstLifecycle,
  renderDiff,
  playbackWindow,
  firstFrame,
  rebuffer,
  cacheHitRatio,
  prefetchHealth,
  playbackIntent,
  mobileBytesPerMinute,
  profileLocalHitRatio,
}

class PlaybackKpiEvent {
  final PlaybackKpiEventType type;
  final Map<String, dynamic> payload;

  const PlaybackKpiEvent({
    required this.type,
    required this.payload,
  });
}

class PlaybackKpiService extends GetxService {
  static PlaybackKpiService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PlaybackKpiService(), permanent: true);
  }

  static PlaybackKpiService? maybeFind() {
    final isRegistered = Get.isRegistered<PlaybackKpiService>();
    if (!isRegistered) return null;
    return Get.find<PlaybackKpiService>();
  }

  final RxList<PlaybackKpiEvent> _recent = <PlaybackKpiEvent>[].obs;

  List<PlaybackKpiEvent> get recentEvents => List.unmodifiable(_recent);

  void track(PlaybackKpiEventType type, Map<String, dynamic> payload) {
    final event = PlaybackKpiEvent(type: type, payload: payload);
    scheduleMicrotask(() {
      _appendEvent(event);
    });
    if (kDebugMode && !_suppressPlaybackKpiSmokeLogs) {
      debugPrint('[PlaybackKPI] ${type.name}: $payload');
    }
  }

  void _appendEvent(PlaybackKpiEvent event) {
    _recent.add(event);
    if (_recent.length > 200) {
      _recent.removeRange(0, _recent.length - 200);
    }
  }

  CacheFirstSurfaceSummary summarizeCacheFirst({
    required String surfaceKeyPrefix,
    int limit = 60,
  }) =>
      _PlaybackKpiServiceSummaryX(this).summarizeCacheFirst(
        surfaceKeyPrefix: surfaceKeyPrefix,
        limit: limit,
      );

  RenderDiffSurfaceSummary summarizeRenderDiff({
    required String surface,
    int limit = 60,
  }) =>
      _PlaybackKpiServiceSummaryX(this).summarizeRenderDiff(
        surface: surface,
        limit: limit,
      );

  PlaybackWindowSurfaceSummary summarizePlaybackWindow({
    required String surface,
    int limit = 60,
  }) =>
      _PlaybackKpiServiceSummaryX(this).summarizePlaybackWindow(
        surface: surface,
        limit: limit,
      );
}
