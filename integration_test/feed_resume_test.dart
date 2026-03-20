import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed smoke bootstraps without route-return exception',
    (tester) async {
      await launchTurqApp(tester);
      await expectNoFlutterException(tester);
    },
    skip: !kRunIntegrationSmoke,
  );
}
