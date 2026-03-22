import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Process death restore prepare persists a non-default nav tab',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'process_death_prepare_restore',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          await tapItKey(tester, IntegrationTestKeys.navEducation);
          expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);

          final navSnapshot = await waitForSurfaceProbe(
            tester,
            'navBar',
            (payload) =>
                payload['registered'] == true &&
                (payload['selectedIndex'] as num?)?.toInt() == 3,
            reason: 'Education tab did not persist as the active nav index.',
          );
          expect(navSnapshot['showBar'], isTrue);

          expectSurfaceRegistered('education');
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
