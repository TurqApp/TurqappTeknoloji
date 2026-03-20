import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'helpers/test_app_bootstrap.dart';
import 'helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short smoke bootstraps without refresh-preserve exception',
    (tester) async {
      await launchTurqApp(tester);
      await tapItKey(tester, IntegrationTestKeys.navShort);
      expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
      expectSurfaceRegistered('short');
      expectCenteredIndexValid(
        'short',
        indexField: 'activeIndex',
        countField: 'count',
      );
      await pageBackAndSettle(tester);
      await expectFeedScreen(tester);
    },
    skip: !kRunIntegrationSmoke,
  );
}
