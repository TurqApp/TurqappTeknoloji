import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'helpers/route_replay.dart';
import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Profile smoke bootstraps without centered-resume exception',
    (tester) async {
      await SmokeArtifactCollector.runScenario('profile_resume', () async {
        await launchTurqApp(tester);
        await tapItKey(tester, IntegrationTestKeys.navProfile);
        expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
        expectSurfaceRegistered('profile');
        expectCenteredIndexValid(
          'profile',
          indexField: 'centeredIndex',
          countField: 'count',
        );
        await goToFeedTab(tester);
        expectSurfaceRegistered('feed');
      });
    },
    skip: !kRunIntegrationSmoke,
  );
}
