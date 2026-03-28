import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('real sign-in screen opens login form from start screen', (
    tester,
  ) async {
    await pumpApp(tester, const SignIn());

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.screenSignIn)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('login_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('email')), findsNothing);
    expect(find.byKey(const ValueKey('password')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('login_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('email')), findsOneWidget);
    expect(find.byKey(const ValueKey('password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
  });

  testWidgets('real sign-in screen keeps initial identifier in login form', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SignIn(initialIdentifier: 'test@mail.com'),
    );

    expect(find.byKey(const ValueKey('login_button')), findsNothing);
    expect(find.byKey(const ValueKey('email')), findsOneWidget);
    expect(find.byKey(const ValueKey('password')), findsOneWidget);

    final emailField = tester.widget<TextField>(
      find.byKey(const ValueKey('email')),
    );

    expect(emailField.controller?.text, 'test@mail.com');
    expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
  });
}
