import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/runtime_health_exporter.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_data_usage_probe.dart';

void main() {
  test('exports telemetry surfaces and threshold report', () async {
    final service = PlaybackKpiService();
    ensureHlsDataUsageProbe().resetSession(label: 'runtime_health_test');
    for (var i = 0; i < 4; i++) {
      service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
        'surfaceKey': 'feed_home_snapshot',
        'event': 'liveSyncFailed',
      });
      service.track(PlaybackKpiEventType.renderDiff, <String, dynamic>{
        'surface': 'feed',
        'stage': 'render_patch',
        'operations': 28,
      });
      service.track(PlaybackKpiEventType.playbackWindow, <String, dynamic>{
        'surface': 'feed',
        'activeIndex': -1,
        'visibleCount': 1,
        'maxAttachedPlayers': 3,
      });
    }
    service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
      'surfaceKey': 'story_row_snapshot',
      'event': 'scopedSnapshotHit',
    });

    await Future<void>.delayed(Duration.zero);

    final payload = RuntimeHealthExporter.exportFromKpiService(service);
    expect(payload['surfaceCount'], greaterThanOrEqualTo(10));
    expect(payload['observedSurfaceCount'], greaterThanOrEqualTo(2));
    expect(payload['telemetryCoverage'], isA<Map<String, dynamic>>());
    expect(payload['hlsDataUsage'], isA<Map<String, dynamic>>());
    expect(payload['thresholdReport'], isA<Map<String, dynamic>>());
    expect(payload['recentEvents'], isA<List<dynamic>>());
  });

  test('filters background short cache-only blockers during integration launch',
      () async {
    final service = PlaybackKpiService();
    for (var i = 0; i < 2; i++) {
      service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
        'surfaceKey': 'short_home_snapshot',
        'event': 'liveSyncStarted',
      });
      service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
        'surfaceKey': 'short_home_snapshot',
        'event': 'liveSyncFailed',
      });
    }

    await Future<void>.delayed(Duration.zero);

    final payload = RuntimeHealthExporter.exportFromKpiService(
      service,
      integrationMode: true,
      probeSnapshot: const <String, dynamic>{
        'navBar': <String, dynamic>{
          'registered': true,
          'selectedIndex': 0,
        },
        'currentRoute': '/NavBarView',
      },
    );
    final thresholdReport =
        payload['thresholdReport'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final issues =
        thresholdReport['issues'] as List<dynamic>? ?? const <dynamic>[];

    expect(thresholdReport['hasBlocking'], isFalse);
    expect(
      issues.any((issue) {
        final issueMap = issue as Map<String, dynamic>;
        return issueMap['surface'] == 'short' &&
            issueMap['code'] == 'local_hit_ratio_critical';
      }),
      isFalse,
    );
  });
}
