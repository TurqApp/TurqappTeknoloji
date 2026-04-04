import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_data_usage_probe.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';

class RuntimeHealthExporter {
  const RuntimeHealthExporter._();

  static Map<String, dynamic> _clonePayloadMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _clonePayloadValue(value)),
    );
  }

  static dynamic _clonePayloadValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _clonePayloadValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_clonePayloadValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> exportFromKpiService(
    PlaybackKpiService service, {
    int recentEventLimit = 60,
    bool? integrationMode,
    Map<String, dynamic>? probeSnapshot,
  }) {
    final snapshots = TelemetryThresholdPolicyAdapter.buildSnapshots(service);
    final isIntegrationMode = integrationMode ?? IntegrationTestMode.enabled;
    final probe = probeSnapshot ??
        (isIntegrationMode
            ? IntegrationTestStateProbe.snapshot()
            : const <String, dynamic>{});
    final report = _filterIntegrationBackgroundCacheIssues(
      TelemetryThresholdPolicy.evaluateSnapshots(snapshots),
      snapshots: snapshots,
      probe: probe,
      isIntegrationMode: isIntegrationMode,
    );
    final telemetryCoverage =
        TelemetryThresholdPolicyAdapter.buildCoverageSummary(service);
    final observedSurfaceCount =
        telemetryCoverage['observedSurfaceCount'] as int? ?? 0;
    final recentEvents = service.recentEvents;
    final startIndex = recentEvents.length > recentEventLimit
        ? recentEvents.length - recentEventLimit
        : 0;
    final hlsProbe = maybeFindHlsDataUsageProbe();
    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'surfaceCount': snapshots.length,
      'observedSurfaceCount': observedSurfaceCount,
      'telemetryCoverage': _clonePayloadMap(telemetryCoverage),
      'surfaces': snapshots
          .map((snapshot) => _clonePayloadMap(snapshot.toJson()))
          .toList(growable: false),
      'thresholdReport': _clonePayloadMap(report.toJson()),
      if (hlsProbe != null)
        'hlsDataUsage': _clonePayloadMap(hlsProbe.snapshotJson()),
      'recentEvents': recentEvents
          .skip(startIndex)
          .map(
            (event) => <String, dynamic>{
              'type': event.type.name,
              'payload': _clonePayloadMap(event.payload),
            },
          )
          .toList(growable: false),
    };
  }

  static TelemetryThresholdReport _filterIntegrationBackgroundCacheIssues(
    TelemetryThresholdReport report, {
    required List<SurfaceTelemetrySnapshot> snapshots,
    required Map<String, dynamic> probe,
    required bool isIntegrationMode,
  }) {
    if (!isIntegrationMode || !report.hasIssues) {
      return report;
    }
    final activePrimarySurface = _activePrimarySurface(probe);
    if (activePrimarySurface.isEmpty) {
      return report;
    }
    final snapshotBySurface = <String, SurfaceTelemetrySnapshot>{
      for (final snapshot in snapshots) snapshot.surface: snapshot,
    };
    final filteredIssues = report.issues.where((issue) {
      if (issue.surface == activePrimarySurface) {
        return true;
      }
      if (!_isCacheOnlyThresholdIssue(issue.code) ||
          !_isPrimaryPlaybackSurface(issue.surface)) {
        return true;
      }
      final snapshot = snapshotBySurface[issue.surface];
      if (snapshot == null) {
        return true;
      }
      return !_isCacheOnlyBackgroundSurface(snapshot);
    }).toList(growable: false);
    if (filteredIssues.length == report.issues.length) {
      return report;
    }
    return TelemetryThresholdReport(issues: filteredIssues);
  }

  static bool _isPrimaryPlaybackSurface(String surface) {
    return surface == 'feed' || surface == 'short';
  }

  static bool _isCacheOnlyThresholdIssue(String code) {
    return code == 'local_hit_ratio_critical' ||
        code == 'local_hit_ratio_low' ||
        code == 'live_fail_spike' ||
        code == 'live_fail_spike_critical';
  }

  static bool _isCacheOnlyBackgroundSurface(SurfaceTelemetrySnapshot snapshot) {
    return (snapshot.cacheFirst?.eventCount ?? 0) > 0 &&
        (snapshot.renderDiff?.eventCount ?? 0) == 0 &&
        (snapshot.playbackWindow?.eventCount ?? 0) == 0;
  }

  static String _activePrimarySurface(Map<String, dynamic> probe) {
    final navBar = probe['navBar'] is Map
        ? probe['navBar'] as Map
        : const <String, dynamic>{};
    final selectedIndex = navBar['selectedIndex'];
    if (selectedIndex is int) {
      if (selectedIndex == 0) return 'feed';
      if (selectedIndex == 2) return 'short';
    }
    if (selectedIndex is num) {
      final normalizedIndex = selectedIndex.toInt();
      if (normalizedIndex == 0) return 'feed';
      if (normalizedIndex == 2) return 'short';
    }
    return '';
  }
}
