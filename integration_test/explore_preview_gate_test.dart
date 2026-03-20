import 'package:flutter_test/flutter_test.dart';

import 'helpers/route_replay.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Explore smoke bootstraps without preview-gate exception',
    (tester) async {
      await launchTurqApp(tester);
      await replayFeedToExploreToFeed(tester);
      final probe = readIntegrationProbe();
      expect(probe['currentRoute'], isA<String>());
      expectSurfaceRegistered('feed');
    },
    skip: !kRunIntegrationSmoke,
  );
}
