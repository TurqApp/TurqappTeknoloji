import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
