import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Notifications smoke bootstraps without optimistic-mutation exception',
    (tester) async {
      await launchTurqApp(tester);
      await tapItKey(tester, IntegrationTestKeys.actionOpenNotifications);
      expect(byItKey(IntegrationTestKeys.screenNotifications), findsOneWidget);
    },
    skip: !kRunIntegrationSmoke,
  );
}
