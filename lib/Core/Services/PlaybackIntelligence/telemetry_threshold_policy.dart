import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_summary_models.dart';

enum TelemetryThresholdSeverity {
  warning,
  blocking,
}

class TelemetryThresholdIssue {
  const TelemetryThresholdIssue({
    required this.surface,
    required this.code,
    required this.message,
    required this.severity,
    this.metrics = const <String, dynamic>{},
  });

  final String surface;
  final String code;
  final String message;
  final TelemetryThresholdSeverity severity;
  final Map<String, dynamic> metrics;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'code': code,
      'message': message,
      'severity': severity.name,
      'metrics': metrics,
    };
  }
}

class SurfaceTelemetrySnapshot {
  const SurfaceTelemetrySnapshot({
    required this.surface,
    this.cacheFirst,
    this.renderDiff,
    this.playbackWindow,
  });

  final String surface;
  final CacheFirstSurfaceSummary? cacheFirst;
  final RenderDiffSurfaceSummary? renderDiff;
  final PlaybackWindowSurfaceSummary? playbackWindow;

  factory SurfaceTelemetrySnapshot.fromJson(Map<String, dynamic> json) {
    return SurfaceTelemetrySnapshot(
      surface: (json['surface'] ?? '').toString().trim(),
      cacheFirst: _parseCacheFirst(json['cacheFirst']),
      renderDiff: _parseRenderDiff(json['renderDiff']),
      playbackWindow: _parsePlaybackWindow(json['playbackWindow']),
    );
  }

  static CacheFirstSurfaceSummary? _parseCacheFirst(dynamic raw) {
    if (raw is! Map) return null;
    return CacheFirstSurfaceSummary(
      eventCount: _asInt(raw['eventCount']),
      localHitCount: _asInt(raw['localHitCount']),
      warmHitCount: _asInt(raw['warmHitCount']),
      liveSuccessCount: _asInt(raw['liveSuccessCount']),
      liveFailCount: _asInt(raw['liveFailCount']),
      preservedPreviousCount: _asInt(raw['preservedPreviousCount']),
    );
  }

  static RenderDiffSurfaceSummary? _parseRenderDiff(dynamic raw) {
    if (raw is! Map) return null;
    return RenderDiffSurfaceSummary(
      eventCount: _asInt(raw['eventCount']),
      patchEventCount: _asInt(raw['patchEventCount']),
      zeroDiffCount: _asInt(raw['zeroDiffCount']),
      averageOperations: _asDouble(raw['averageOperations']),
      maxOperations: _asInt(raw['maxOperations']),
    );
  }

  static PlaybackWindowSurfaceSummary? _parsePlaybackWindow(dynamic raw) {
    if (raw is! Map) return null;
    return PlaybackWindowSurfaceSummary(
      eventCount: _asInt(raw['eventCount']),
      averageVisibleCount: _asDouble(raw['averageVisibleCount']),
      averageHotCount: _asDouble(raw['averageHotCount']),
      activeLostCount: _asInt(raw['activeLostCount']),
      maxAttachedPlayers: _asInt(raw['maxAttachedPlayers']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class TelemetryThresholdReport {
  const TelemetryThresholdReport({
    required this.issues,
  });

  final List<TelemetryThresholdIssue> issues;

  bool get hasIssues => issues.isNotEmpty;

  bool get hasBlocking => issues
      .any((issue) => issue.severity == TelemetryThresholdSeverity.blocking);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hasIssues': hasIssues,
      'hasBlocking': hasBlocking,
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
    };
  }
}

class _SurfaceThresholds {
  const _SurfaceThresholds({
    required this.minCacheEvents,
    required this.warnLocalHitRatio,
    required this.blockLocalHitRatio,
    required this.warnLiveFailCount,
    required this.blockLiveFailCount,
    required this.minRenderPatchEvents,
    required this.warnRenderAverageOps,
    required this.blockRenderAverageOps,
    required this.warnRenderMaxOps,
    required this.blockRenderMaxOps,
    required this.minPlaybackEvents,
    required this.warnActiveLostCount,
    required this.blockActiveLostCount,
    required this.warnAttachedPlayers,
    required this.blockAttachedPlayers,
  });

  final int minCacheEvents;
  final double warnLocalHitRatio;
  final double blockLocalHitRatio;
  final int warnLiveFailCount;
  final int blockLiveFailCount;
  final int minRenderPatchEvents;
  final double warnRenderAverageOps;
  final double blockRenderAverageOps;
  final int warnRenderMaxOps;
  final int blockRenderMaxOps;
  final int minPlaybackEvents;
  final int warnActiveLostCount;
  final int blockActiveLostCount;
  final int warnAttachedPlayers;
  final int blockAttachedPlayers;
}

class TelemetryThresholdPolicy {
  const TelemetryThresholdPolicy._();

  static const Map<String, _SurfaceThresholds> _defaults =
      <String, _SurfaceThresholds>{
    'feed': _SurfaceThresholds(
      minCacheEvents: 3,
      warnLocalHitRatio: 0.45,
      blockLocalHitRatio: 0.20,
      warnLiveFailCount: 1,
      blockLiveFailCount: 3,
      minRenderPatchEvents: 3,
      warnRenderAverageOps: 12,
      blockRenderAverageOps: 24,
      warnRenderMaxOps: 24,
      blockRenderMaxOps: 48,
      minPlaybackEvents: 3,
      warnActiveLostCount: 1,
      blockActiveLostCount: 3,
      warnAttachedPlayers: 4,
      blockAttachedPlayers: 6,
    ),
    'short': _SurfaceThresholds(
      minCacheEvents: 3,
      warnLocalHitRatio: 0.35,
      blockLocalHitRatio: 0.15,
      warnLiveFailCount: 1,
      blockLiveFailCount: 3,
      minRenderPatchEvents: 3,
      warnRenderAverageOps: 10,
      blockRenderAverageOps: 20,
      warnRenderMaxOps: 18,
      blockRenderMaxOps: 36,
      minPlaybackEvents: 3,
      warnActiveLostCount: 1,
      blockActiveLostCount: 2,
      warnAttachedPlayers: 5,
      blockAttachedPlayers: 8,
    ),
  };

  static TelemetryThresholdReport evaluateSnapshots(
    List<SurfaceTelemetrySnapshot> snapshots,
  ) {
    final issues = <TelemetryThresholdIssue>[];
    for (final snapshot in snapshots) {
      final thresholds = _defaults[snapshot.surface];
      if (thresholds == null) continue;
      issues.addAll(_evaluateSurface(snapshot, thresholds));
    }
    return TelemetryThresholdReport(issues: issues);
  }

  static List<TelemetryThresholdIssue> _evaluateSurface(
    SurfaceTelemetrySnapshot snapshot,
    _SurfaceThresholds thresholds,
  ) {
    final issues = <TelemetryThresholdIssue>[];
    final cache = snapshot.cacheFirst;
    final render = snapshot.renderDiff;
    final playback = snapshot.playbackWindow;

    if (cache != null && cache.eventCount >= thresholds.minCacheEvents) {
      if (cache.localHitRatio < thresholds.blockLocalHitRatio) {
        issues.add(_issue(
          snapshot.surface,
          'local_hit_ratio_critical',
          'Local snapshot hit ratio critically low',
          TelemetryThresholdSeverity.blocking,
          <String, dynamic>{
            'localHitRatio': cache.localHitRatio,
            'eventCount': cache.eventCount,
          },
        ));
      } else if (cache.localHitRatio < thresholds.warnLocalHitRatio) {
        issues.add(_issue(
          snapshot.surface,
          'local_hit_ratio_low',
          'Local snapshot hit ratio below warning threshold',
          TelemetryThresholdSeverity.warning,
          <String, dynamic>{
            'localHitRatio': cache.localHitRatio,
            'eventCount': cache.eventCount,
          },
        ));
      }

      if (cache.liveFailCount >= thresholds.blockLiveFailCount) {
        issues.add(_issue(
          snapshot.surface,
          'live_fail_spike_critical',
          'Live sync failures exceeded blocking threshold',
          TelemetryThresholdSeverity.blocking,
          <String, dynamic>{
            'liveFailCount': cache.liveFailCount,
          },
        ));
      } else if (cache.liveFailCount >= thresholds.warnLiveFailCount) {
        issues.add(_issue(
          snapshot.surface,
          'live_fail_spike',
          'Live sync failures exceeded warning threshold',
          TelemetryThresholdSeverity.warning,
          <String, dynamic>{
            'liveFailCount': cache.liveFailCount,
          },
        ));
      }
    }

    if (render != null &&
        render.patchEventCount >= thresholds.minRenderPatchEvents) {
      if (render.averageOperations >= thresholds.blockRenderAverageOps ||
          render.maxOperations >= thresholds.blockRenderMaxOps) {
        issues.add(_issue(
          snapshot.surface,
          'render_diff_critical',
          'Render diff volume exceeded blocking threshold',
          TelemetryThresholdSeverity.blocking,
          <String, dynamic>{
            'averageOperations': render.averageOperations,
            'maxOperations': render.maxOperations,
          },
        ));
      } else if (render.averageOperations >= thresholds.warnRenderAverageOps ||
          render.maxOperations >= thresholds.warnRenderMaxOps) {
        issues.add(_issue(
          snapshot.surface,
          'render_diff_high',
          'Render diff volume exceeded warning threshold',
          TelemetryThresholdSeverity.warning,
          <String, dynamic>{
            'averageOperations': render.averageOperations,
            'maxOperations': render.maxOperations,
          },
        ));
      }
    }

    if (playback != null &&
        playback.eventCount >= thresholds.minPlaybackEvents) {
      if (playback.activeLostCount >= thresholds.blockActiveLostCount) {
        issues.add(_issue(
          snapshot.surface,
          'active_lost_critical',
          'Active playback target was lost too often',
          TelemetryThresholdSeverity.blocking,
          <String, dynamic>{
            'activeLostCount': playback.activeLostCount,
          },
        ));
      } else if (playback.activeLostCount >= thresholds.warnActiveLostCount) {
        issues.add(_issue(
          snapshot.surface,
          'active_lost_warning',
          'Active playback target was lost',
          TelemetryThresholdSeverity.warning,
          <String, dynamic>{
            'activeLostCount': playback.activeLostCount,
          },
        ));
      }

      if (playback.maxAttachedPlayers >= thresholds.blockAttachedPlayers) {
        issues.add(_issue(
          snapshot.surface,
          'attached_players_critical',
          'Attached player count exceeded blocking threshold',
          TelemetryThresholdSeverity.blocking,
          <String, dynamic>{
            'maxAttachedPlayers': playback.maxAttachedPlayers,
          },
        ));
      } else if (playback.maxAttachedPlayers >=
          thresholds.warnAttachedPlayers) {
        issues.add(_issue(
          snapshot.surface,
          'attached_players_high',
          'Attached player count exceeded warning threshold',
          TelemetryThresholdSeverity.warning,
          <String, dynamic>{
            'maxAttachedPlayers': playback.maxAttachedPlayers,
          },
        ));
      }
    }

    return issues;
  }

  static TelemetryThresholdIssue _issue(
    String surface,
    String code,
    String message,
    TelemetryThresholdSeverity severity,
    Map<String, dynamic> metrics,
  ) {
    return TelemetryThresholdIssue(
      surface: surface,
      code: code,
      message: message,
      severity: severity,
      metrics: metrics,
    );
  }
}
