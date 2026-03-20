import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'helpers/route_replay.dart';
import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed smoke bootstraps without route-return exception',
    (tester) async {
      await SmokeArtifactCollector.runScenario('feed_resume', tester, () async {
        await launchTurqApp(tester);
        await expectFeedScreen(tester);
        expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
        expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);
        expectSelectedNavIndex(0);
        expectSurfaceRegistered('feed');
        expectCenteredIndexValid(
          'feed',
          indexField: 'centeredIndex',
          countField: 'count',
        );
        final beforeFeed = readSurfaceProbe('feed');
        expectSurfaceMatchesFixture('feed', beforeFeed);
        await replayFeedToProfileToFeed(tester, beforeFeed: beforeFeed);
        expectSurfaceRegistered('feed');
        expectCenteredIndexValid(
          'feed',
          indexField: 'centeredIndex',
          countField: 'count',
        );
        expectSurfaceMatchesFixture('feed', readSurfaceProbe('feed'));
      });
    },
    skip: !kRunIntegrationSmoke,
  );
}
