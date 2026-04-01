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
}
