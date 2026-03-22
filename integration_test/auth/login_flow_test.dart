import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/main.dart' as app;

import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  const loginEmail =
      String.fromEnvironment('INTEGRATION_LOGIN_EMAIL', defaultValue: '');
  const loginPassword =
      String.fromEnvironment('INTEGRATION_LOGIN_PASSWORD', defaultValue: '');

  testWidgets('launch -> login -> navbar shell', (tester) async {
    expect(
      loginEmail,
      isNotEmpty,
      reason: 'Pass --dart-define=INTEGRATION_LOGIN_EMAIL=...',
    );
    expect(
      loginPassword,
      isNotEmpty,
      reason: 'Pass --dart-define=INTEGRATION_LOGIN_PASSWORD=...',
    );

    await app.main();
    await pumpForAppStartup(tester, maxPumps: 32);

    final navBarFinder = byItKey(IntegrationTestKeys.navBarRoot);
    if (navBarFinder.evaluate().isNotEmpty) {
      fail(
        'login_flow_test expects a signed-out app state. '
        'Clear the existing session on the device before running it.',
      );
    }

    final loginButton = find.byKey(const ValueKey<String>('login_button'));
    final emailField = find.byKey(const ValueKey<String>('email'));
    final passwordField = find.byKey(const ValueKey<String>('password'));
    final submitButton =
        find.byKey(const ValueKey<String>('login_submit_button'));

    await pumpUntilVisible(tester, loginButton, maxPumps: 48);
    await tester.tap(loginButton);
    await tester.pump(const Duration(milliseconds: 300));

    await pumpUntilVisible(tester, emailField, maxPumps: 24);
    await tester.enterText(emailField, loginEmail);
    await tester.enterText(passwordField, loginPassword);

    await tester.tap(submitButton);
    await pumpUntilVisible(tester, navBarFinder, maxPumps: 72);
    await expectNoFlutterException(tester);
  });
}
