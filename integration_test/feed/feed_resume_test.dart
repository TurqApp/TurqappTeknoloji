import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/helpers/route_replay.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/test_state_probe.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed smoke bootstraps without route-return exception',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();
      try {
        await SmokeArtifactCollector.runScenario('feed_resume', tester, () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);
          expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
          expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);
          expectSurfaceRegistered('feed');
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
          final beforeFeed = readSurfaceProbe('feed');
          expectSurfaceMatchesFixture('feed', beforeFeed);
          await settleSmokeShell(
            tester,
            context: 'feed route replay settle',
          );
          print('[integration-smoke] feed_resume: before profile replay');
          await replayFeedToProfileToFeed(tester, beforeFeed: beforeFeed);
          await settleSmokeShell(
            tester,
            context: 'feed post-profile replay settle',
          );
          print('[integration-smoke] feed_resume: after profile replay');
          expectSurfaceRegistered('feed');
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
          expectSurfaceMatchesFixture('feed', readSurfaceProbe('feed'));
        });
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}
