import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short smoke bootstraps without refresh-preserve exception',
    (tester) async {
      await launchTurqApp(tester);
      await expectNoFlutterException(tester);
    },
    skip: !kRunIntegrationSmoke,
  );
}
