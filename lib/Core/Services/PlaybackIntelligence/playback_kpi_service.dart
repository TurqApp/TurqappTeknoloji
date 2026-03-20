import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_summary_models.dart';

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
  final RxList<PlaybackKpiEvent> _recent = <PlaybackKpiEvent>[].obs;

  List<PlaybackKpiEvent> get recentEvents => List.unmodifiable(_recent);

  void track(PlaybackKpiEventType type, Map<String, dynamic> payload) {
    final event = PlaybackKpiEvent(type: type, payload: payload);
    scheduleMicrotask(() {
      _appendEvent(event);
    });
    if (kDebugMode) {
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
  }) {
    var eventCount = 0;
    var localHitCount = 0;
    var warmHitCount = 0;
    var liveSuccessCount = 0;
    var liveFailCount = 0;
    var preservedPreviousCount = 0;

    for (final event in _recent.reversed.take(limit)) {
      if (event.type != PlaybackKpiEventType.cacheFirstLifecycle) continue;
      final surfaceKey = (event.payload['surfaceKey'] ?? '').toString();
      if (!surfaceKey.startsWith(surfaceKeyPrefix)) continue;
      eventCount += 1;
      switch ((event.payload['event'] ?? '').toString()) {
        case 'memoryHit':
        case 'scopedSnapshotHit':
          localHitCount += 1;
          break;
        case 'warmLaunchHit':
          warmHitCount += 1;
          break;
        case 'liveSyncSucceeded':
          liveSuccessCount += 1;
          break;
        case 'liveSyncFailed':
          liveFailCount += 1;
          break;
        case 'liveSyncPreservedPrevious':
          preservedPreviousCount += 1;
          break;
      }
    }

    return CacheFirstSurfaceSummary(
      eventCount: eventCount,
      localHitCount: localHitCount,
      warmHitCount: warmHitCount,
      liveSuccessCount: liveSuccessCount,
      liveFailCount: liveFailCount,
      preservedPreviousCount: preservedPreviousCount,
    );
  }

  RenderDiffSurfaceSummary summarizeRenderDiff({
    required String surface,
    int limit = 60,
  }) {
    var eventCount = 0;
    var patchEventCount = 0;
    var zeroDiffCount = 0;
    var maxOperations = 0;
    var totalOperations = 0;

    for (final event in _recent.reversed.take(limit)) {
      if (event.type != PlaybackKpiEventType.renderDiff) continue;
      if ((event.payload['surface'] ?? '').toString() != surface) continue;
      eventCount += 1;
      final stage = (event.payload['stage'] ?? '').toString();
      if (stage != 'render_patch') continue;
      patchEventCount += 1;
      final operations = _asInt(event.payload['operations']);
      totalOperations += operations;
      if (operations == 0) {
        zeroDiffCount += 1;
      }
      if (operations > maxOperations) {
        maxOperations = operations;
      }
    }

    return RenderDiffSurfaceSummary(
      eventCount: eventCount,
      patchEventCount: patchEventCount,
      zeroDiffCount: zeroDiffCount,
      averageOperations:
          patchEventCount == 0 ? 0 : totalOperations / patchEventCount,
      maxOperations: maxOperations,
    );
  }

  PlaybackWindowSurfaceSummary summarizePlaybackWindow({
    required String surface,
    int limit = 60,
  }) {
    var eventCount = 0;
    var activeLostCount = 0;
    var visibleOrHotTotal = 0.0;
    var maxAttachedPlayers = 0;

    for (final event in _recent.reversed.take(limit)) {
      if (event.type != PlaybackKpiEventType.playbackWindow) continue;
      if ((event.payload['surface'] ?? '').toString() != surface) continue;
      eventCount += 1;
      final activeIndex = _asInt(event.payload['activeIndex']);
      if (activeIndex < 0) {
        activeLostCount += 1;
      }
      final countValue = surface == 'feed'
          ? _asDouble(event.payload['visibleCount'])
          : _asDouble(event.payload['hotCount']);
      visibleOrHotTotal += countValue;
      final attached = _asInt(event.payload['maxAttachedPlayers']);
      if (attached > maxAttachedPlayers) {
        maxAttachedPlayers = attached;
      }
    }

    return PlaybackWindowSurfaceSummary(
      eventCount: eventCount,
      averageVisibleCount: surface == 'feed' && eventCount > 0
          ? visibleOrHotTotal / eventCount
          : 0,
      averageHotCount: surface == 'short' && eventCount > 0
          ? visibleOrHotTotal / eventCount
          : 0,
      activeLostCount: activeLostCount,
      maxAttachedPlayers: maxAttachedPlayers,
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
