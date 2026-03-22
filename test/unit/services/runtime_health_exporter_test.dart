import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/runtime_health_exporter.dart';

void main() {
  test('exports telemetry surfaces and threshold report', () {
    final service = PlaybackKpiService();
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

    final payload = RuntimeHealthExporter.exportFromKpiService(service);
    expect(payload['surfaceCount'], 2);
    expect(payload['thresholdReport'], isA<Map<String, dynamic>>());
    expect(payload['recentEvents'], isA<List<dynamic>>());
  });
}
