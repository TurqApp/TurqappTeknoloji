import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed smoke bootstraps without route-return exception',
    (tester) async {
      await launchTurqApp(tester);
      await expectFeedScreen(tester);
      expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
      expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);
    },
    skip: !kRunIntegrationSmoke,
  );
}
