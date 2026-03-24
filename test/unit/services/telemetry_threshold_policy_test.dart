import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_summary_models.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';

void main() {
  test('flags blocking issue when feed local hit ratio collapses', () {
    final report = TelemetryThresholdPolicy.evaluateSnapshots(
      const <SurfaceTelemetrySnapshot>[
        SurfaceTelemetrySnapshot(
          surface: 'feed',
          cacheFirst: CacheFirstSurfaceSummary(
            eventCount: 6,
            localHitCount: 0,
            warmHitCount: 0,
            liveSuccessCount: 1,
            liveFailCount: 0,
            preservedPreviousCount: 0,
          ),
        ),
      ],
    );

    expect(report.hasBlocking, isTrue);
    expect(
      report.issues.any((issue) => issue.code == 'local_hit_ratio_critical'),
      isTrue,
    );
  });

  test('flags warning when short attached players exceed warning threshold',
      () {
    final report = TelemetryThresholdPolicy.evaluateSnapshots(
      const <SurfaceTelemetrySnapshot>[
        SurfaceTelemetrySnapshot(
          surface: 'short',
          playbackWindow: PlaybackWindowSurfaceSummary(
            eventCount: 5,
            averageVisibleCount: 0,
            averageHotCount: 3.2,
            activeLostCount: 0,
            maxAttachedPlayers: 6,
          ),
        ),
      ],
    );

    expect(report.hasBlocking, isFalse);
    expect(
      report.issues.any((issue) => issue.code == 'attached_players_high'),
      isTrue,
    );
  });

  test('builds report from playback kpi service summaries', () async {
    final service = PlaybackKpiService();
    for (var i = 0; i < 4; i++) {
      service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
        'surfaceKey': 'feed_home_snapshot',
        'event': 'liveSyncFailed',
      });
      service.track(PlaybackKpiEventType.renderDiff, <String, dynamic>{
        'surface': 'feed',
        'stage': 'render_patch',
        'operations': 30,
      });
      service.track(PlaybackKpiEventType.playbackWindow, <String, dynamic>{
        'surface': 'feed',
        'activeIndex': -1,
        'visibleCount': 1,
        'maxAttachedPlayers': 3,
      });
    }

    await Future<void>.delayed(Duration.zero);

    final report = TelemetryThresholdPolicyAdapter.evaluateKpiService(service);
    expect(report.hasIssues, isTrue);
    expect(
      report.issues.any((issue) => issue.surface == 'feed'),
      isTrue,
    );
  });

  test('builds cache-first snapshots for extended QA surfaces', () async {
    final service = PlaybackKpiService();
    service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
      'surfaceKey': 'story_row_snapshot',
      'event': 'scopedSnapshotHit',
    });
    service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
      'surfaceKey': 'notifications_inbox_snapshot',
      'event': 'liveSyncSucceeded',
    });

    await Future<void>.delayed(Duration.zero);

    final snapshots = TelemetryThresholdPolicyAdapter.buildSnapshots(service);
    final storySnapshot =
        snapshots.firstWhere((item) => item.surface == 'story');
    final notificationsSnapshot =
        snapshots.firstWhere((item) => item.surface == 'notifications');

    expect(storySnapshot.cacheFirst?.eventCount, 1);
    expect(notificationsSnapshot.cacheFirst?.eventCount, 1);
  });

  test('reports telemetry coverage summary for observed and missing surfaces',
      () async {
    final service = PlaybackKpiService();
    service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
      'surfaceKey': 'feed_home_snapshot',
      'event': 'scopedSnapshotHit',
    });
    service.track(PlaybackKpiEventType.cacheFirstLifecycle, <String, dynamic>{
      'surfaceKey': 'story_row_snapshot',
      'event': 'scopedSnapshotHit',
    });

    await Future<void>.delayed(Duration.zero);

    final coverage = TelemetryThresholdPolicyAdapter.buildCoverageSummary(
      service,
    );
    final observed = coverage['observedSurfaces'] as List<dynamic>;
    final missing = coverage['unobservedSurfaces'] as List<dynamic>;

    expect(observed, containsAll(<String>['feed', 'story']));
    expect(missing, contains('short'));
    expect(coverage['configuredSurfaceCount'], greaterThan(5));
  });
}
