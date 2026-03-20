import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Explore smoke bootstraps without preview-gate exception',
    (tester) async {
      await launchTurqApp(tester);
      await tapItKey(tester, IntegrationTestKeys.navExplore);
      expect(byItKey(IntegrationTestKeys.screenExplore), findsOneWidget);
    },
    skip: !kRunIntegrationSmoke,
  );
}
