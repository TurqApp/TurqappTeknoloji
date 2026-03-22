import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Process death restore verify rehydrates the persisted nav tab on cold start',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'process_death_verify_restore',
        tester,
        () async {
          await launchTurqApp(tester);

          await waitForSurfaceProbe(
            tester,
            'navBar',
            (payload) =>
                payload['registered'] == true &&
                (payload['selectedIndex'] as num?)?.toInt() == 3,
            reason:
                'Cold restart did not restore the previously selected nav tab.',
          );
          await pumpUntilVisible(
            tester,
            byItKey(IntegrationTestKeys.screenEducation),
            maxPumps: 32,
          );
          expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
          expectSurfaceRegistered('education');
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
