import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/account_session_vault.dart';
import 'package:turqappv2/main.dart' as app;

const bool kRunIntegrationSmoke =
    bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);
const String kIntegrationLoginEmail =
    String.fromEnvironment('INTEGRATION_LOGIN_EMAIL', defaultValue: '');
const String kIntegrationLoginPassword =
    String.fromEnvironment('INTEGRATION_LOGIN_PASSWORD', defaultValue: '');

AccountSessionCredential? _cachedIntegrationCredential;

IntegrationTestWidgetsFlutterBinding ensureIntegrationBinding() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> launchTurqApp(WidgetTester tester) async {
  await app.main();
  await pumpForAppStartup(tester);
  await ensureSignedInForSmoke(tester);
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

Future<void> ensureSignedInForSmoke(WidgetTester tester) async {
  if (!kRunIntegrationSmoke) return;
  if (FirebaseAuth.instance.currentUser != null) return;

  final credentials =
      _cachedIntegrationCredential ??= await _resolveIntegrationCredentials();
  if (credentials == null) {
    throw TestFailure(
      'Integration smoke requires an authenticated session. '
      'Provide INTEGRATION_LOGIN_EMAIL/INTEGRATION_LOGIN_PASSWORD or keep a stored account session on device.',
    );
  }

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: credentials.email,
      password: credentials.password,
    );
  } on FirebaseAuthException catch (error) {
    throw TestFailure(
      'Integration smoke sign-in failed for ${credentials.email}: ${error.code}',
    );
  }

  await pumpForAppStartup(
    tester,
    step: const Duration(milliseconds: 250),
    maxPumps: 32,
  );
}

Future<AccountSessionCredential?> _resolveIntegrationCredentials() async {
  final envEmail = kIntegrationLoginEmail.trim().toLowerCase();
  final envPassword = kIntegrationLoginPassword;
  if (envEmail.isNotEmpty && envPassword.isNotEmpty) {
    return AccountSessionCredential(email: envEmail, password: envPassword);
  }

  final accountCenter = AccountCenterService.ensure();
  await accountCenter.init();
  final candidates = <String>{
    if (accountCenter.lastUsedUid.value.trim().isNotEmpty)
      accountCenter.lastUsedUid.value.trim(),
    ...accountCenter.accounts
        .map((account) => account.uid.trim())
        .where((uid) => uid.isNotEmpty),
  };
  for (final uid in candidates) {
    final credential = await AccountSessionVault.instance.read(uid);
    if (credential != null) {
      return credential;
    }
  }
  return null;
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
