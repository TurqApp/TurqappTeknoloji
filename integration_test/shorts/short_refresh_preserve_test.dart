import 'package:flutter_test/flutter_test.dart';

import '../core/helpers/route_replay.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short smoke bootstraps without refresh-preserve exception',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'short_refresh_preserve',
        tester,
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
