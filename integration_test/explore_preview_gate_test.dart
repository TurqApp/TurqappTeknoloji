import 'package:flutter_test/flutter_test.dart';

import 'helpers/route_replay.dart';
import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Explore smoke bootstraps without preview-gate exception',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'explore_preview_gate',
        tester,
        () async {
          await launchTurqApp(tester);
          final beforeFeed = readSurfaceProbe('feed');
          await replayFeedToExploreToFeed(tester);
          final probe = readIntegrationProbe();
          expect(probe['currentRoute'], isA<String>());
          expect(probe['previousRoute'], isA<String>());
          expectSurfaceRegistered('feed');
          final afterFeed = readSurfaceProbe('feed');
          expectSurfaceMatchesFixture('feed', afterFeed);
          expectCountNeverDropsToZeroAfterReplay(
            'feed',
            before: beforeFeed,
            after: afterFeed,
          );
          expectDocPreservedIfStillPresent(
            'feed',
            before: beforeFeed,
            after: afterFeed,
            activeDocField: 'centeredDocId',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
