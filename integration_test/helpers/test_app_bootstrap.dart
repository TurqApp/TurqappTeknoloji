import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/main.dart' as app;

const bool kRunIntegrationSmoke =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);

IntegrationTestWidgetsFlutterBinding ensureIntegrationBinding() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> launchTurqApp(WidgetTester tester) async {
  await app.main();
  await pumpForAppStartup(tester);
}

Future<void> pumpForAppStartup(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxPumps = 24,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    final error = tester.takeException();
    if (error != null) {
      throw TestFailure('App bootstrap exception: $error');
    }
  }
}

Future<void> expectNoFlutterException(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  final error = tester.takeException();
  expect(error, isNull);
}

Finder byItKey(String key) => find.byKey(ValueKey<String>(key));

Future<void> tapItKey(
  WidgetTester tester,
  String key, {
  int settlePumps = 8,
}) async {
  final finder = byItKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}

Future<void> expectFeedScreen(WidgetTester tester) async {
  expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
  await expectNoFlutterException(tester);
}

Future<void> pageBackAndSettle(
  WidgetTester tester, {
  int settlePumps = 8,
}) async {
  await tester.pageBack();
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}
