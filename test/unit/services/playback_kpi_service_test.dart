import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';

void main() {
  test('tracks prefetch health events and caps recent history', () async {
    final service = PlaybackKpiService();

    for (var i = 0; i < 205; i++) {
      service.track(
        PlaybackKpiEventType.prefetchHealth,
        {'queueSize': i},
      );
    }

    await Future<void>.delayed(Duration.zero);

    expect(service.recentEvents.length, 200);
    expect(service.recentEvents.last.type, PlaybackKpiEventType.prefetchHealth);
    expect(service.recentEvents.last.payload['queueSize'], 204);
  });

  test('tracks playback intent events', () async {
    final service = PlaybackKpiService();

    service.track(
      PlaybackKpiEventType.playbackIntent,
      const {
        'source': 'short_view',
        'docId': 'video_1',
        'audible': true,
        'stableFocus': true,
      },
    );

    await Future<void>.delayed(Duration.zero);

    expect(service.recentEvents.last.type, PlaybackKpiEventType.playbackIntent);
    expect(service.recentEvents.last.payload['source'], 'short_view');
    expect(service.recentEvents.last.payload['stableFocus'], isTrue);
  });

  testWidgets('defers reactive writes triggered during widget build', (
    tester,
  ) async {
    final service = PlaybackKpiService();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (_) {
            service.track(
              PlaybackKpiEventType.playbackIntent,
              const {'source': 'build_phase'},
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(service.recentEvents, hasLength(1));
    expect(service.recentEvents.single.payload['source'], 'build_phase');
  });
}
