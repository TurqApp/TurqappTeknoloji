import 'package:flutter_test/flutter_test.dart';

import 'helpers/route_replay.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Notifications smoke bootstraps without optimistic-mutation exception',
    (tester) async {
      await launchTurqApp(tester);
      final beforeFeed = readSurfaceProbe('feed');
      await replayFeedToNotificationsToFeed(tester, beforeFeed: beforeFeed);
      expectSurfaceRegistered('feed');
    },
    skip: !kRunIntegrationSmoke,
  );
}
