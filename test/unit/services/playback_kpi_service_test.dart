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

  test('ignores bootstrap hydrate and reset patches in render diff summary',
      () async {
    final service = PlaybackKpiService();

    service.track(
      PlaybackKpiEventType.renderDiff,
      const {
        'surface': 'feed',
        'stage': 'render_patch',
        'previousCount': 0,
        'nextCount': 13,
        'operations': 13,
        'insertCount': 13,
        'updateCount': 0,
        'removeCount': 0,
        'moveCount': 0,
      },
    );
    service.track(
      PlaybackKpiEventType.renderDiff,
      const {
        'surface': 'feed',
        'stage': 'render_patch',
        'previousCount': 13,
        'nextCount': 0,
        'operations': 13,
        'insertCount': 0,
        'updateCount': 0,
        'removeCount': 13,
        'moveCount': 0,
      },
    );
    service.track(
      PlaybackKpiEventType.renderDiff,
      const {
        'surface': 'feed',
        'stage': 'render_patch',
        'previousCount': 13,
        'nextCount': 13,
        'operations': 3,
        'insertCount': 0,
        'updateCount': 3,
        'removeCount': 0,
        'moveCount': 0,
      },
    );

    await Future<void>.delayed(Duration.zero);

    final summary = service.summarizeRenderDiff(surface: 'feed');
    expect(summary.eventCount, 3);
    expect(summary.patchEventCount, 1);
    expect(summary.averageOperations, 3);
    expect(summary.maxOperations, 3);
  });

  test('ignores off-surface feed playback loss in playback window summary',
      () async {
    final service = PlaybackKpiService();

    service.track(
      PlaybackKpiEventType.playbackWindow,
      const {
        'surface': 'feed',
        'activeIndex': -1,
        'visibleCount': 0,
      },
    );
    service.track(
      PlaybackKpiEventType.playbackWindow,
      const {
        'surface': 'feed',
        'activeIndex': 0,
        'visibleCount': 1,
      },
    );
    service.track(
      PlaybackKpiEventType.playbackWindow,
      const {
        'surface': 'feed',
        'activeIndex': -1,
        'visibleCount': 1,
      },
    );

    await Future<void>.delayed(Duration.zero);

    final summary = service.summarizePlaybackWindow(surface: 'feed');
    expect(summary.eventCount, 3);
    expect(summary.averageVisibleCount, closeTo(2 / 3, 0.0001));
    expect(summary.activeLostCount, 1);
  });

  test('ignores feed playback loss while external owner is active', () async {
    final service = PlaybackKpiService();

    service.track(
      PlaybackKpiEventType.playbackWindow,
      const {
        'surface': 'feed',
        'activeIndex': -1,
        'visibleCount': 1,
        'ownershipExpected': false,
        'externalOwnerActive': true,
      },
    );
    service.track(
      PlaybackKpiEventType.playbackWindow,
      const {
        'surface': 'feed',
        'activeIndex': -1,
        'visibleCount': 1,
        'ownershipExpected': true,
      },
    );

    await Future<void>.delayed(Duration.zero);

    final summary = service.summarizePlaybackWindow(surface: 'feed');
    expect(summary.eventCount, 2);
    expect(summary.averageVisibleCount, closeTo(1, 0.0001));
    expect(summary.activeLostCount, 1);
  });
}
