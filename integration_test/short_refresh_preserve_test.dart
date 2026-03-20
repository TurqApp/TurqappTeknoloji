import 'package:flutter_test/flutter_test.dart';

import 'helpers/route_replay.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short smoke bootstraps without refresh-preserve exception',
    (tester) async {
      await launchTurqApp(tester);
      await replayFeedToShortToFeed(tester);
      expectSurfaceRegistered('feed');
    },
    skip: !kRunIntegrationSmoke,
  );
}
