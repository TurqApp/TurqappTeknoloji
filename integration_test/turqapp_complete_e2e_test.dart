import 'package:flutter_test/flutter_test.dart';

import 'core/bootstrap/test_app_bootstrap.dart';
import 'core/helpers/turqapp_complete_e2e_flow.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'TurqApp complete E2E covers full journey, all tabs and master matrix in one run',
    (tester) async {
      await runTurqAppMasterE2EScenario(
        tester,
        scenario: 'turqapp_complete_e2e',
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
