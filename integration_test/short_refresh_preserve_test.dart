import 'package:flutter_test/flutter_test.dart';

import 'helpers/route_replay.dart';
import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short smoke bootstraps without refresh-preserve exception',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'short_refresh_preserve',
        () async {
          await launchTurqApp(tester);
          final beforeFeed = readSurfaceProbe('feed');
          await replayFeedToShortToFeed(tester, beforeFeed: beforeFeed);
          expectSurfaceRegistered('feed');
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
