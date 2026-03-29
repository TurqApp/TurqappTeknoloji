import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/responsive_audit_expectations.dart';
import '../../helpers/widget_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    Get.reset();
  });

  for (final variant in WidgetHarnessVariants.responsiveAuditMatrix) {
    testWidgets('SignIn audit remains stable on ${variant.name}', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SignIn(initialIdentifier: 'audit@example.com'),
        variant: variant,
      );

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byKey(const ValueKey('login_submit_button')),
        criticalInput: find.byKey(const ValueKey('email')),
        header: find.byKey(const ValueKey(IntegrationTestKeys.screenSignIn)),
      );

      logResponsiveAuditFindings(
        screen: 'SignIn',
        variant: variant.name,
        findings: findings,
      );
      expectNoResponsiveAuditFailures(
        findings,
        reason: 'SignIn ${variant.name} responsive audit fail verdi.',
      );
    });
  }

  testWidgets('SignIn stored account audit keeps CTA visible on large text', (
    tester,
  ) async {
    final account = StoredAccount(
      uid: 'stored-audit',
      email: 'audit@example.com',
      username: 'audit',
      displayName: 'Audit User',
      rozet: '',
      avatarUrl: '',
      providers: <String>['password'],
      lastUsedAt: 0,
      isSessionValid: false,
      requiresReauth: true,
      accountState: 'reauth_required',
      isPinned: false,
      sortOrder: 1,
      lastSuccessfulSignInAt: 0,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'account_center.accounts': StoredAccount.encodeList(<StoredAccount>[
        account,
      ]),
    });

    await pumpApp(
      tester,
      const SignIn(storedAccountUid: 'stored-audit'),
      variant: WidgetHarnessVariants.phoneSmallAndroidLargeText,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final findings = await collectResponsiveAuditFindings(
      tester,
      criticalCta: find.byKey(const ValueKey('login_submit_button')),
      criticalInput: find.byKey(const ValueKey('email')),
      header: find.byKey(const ValueKey(IntegrationTestKeys.screenSignIn)),
    );

    logResponsiveAuditFindings(
      screen: 'SignInStoredAccount',
      variant: WidgetHarnessVariants.phoneSmallAndroidLargeText.name,
      findings: findings,
    );
    expectNoResponsiveAuditFailures(
      findings,
      reason: 'SignIn stored-account large text audit fail verdi.',
    );
  });
}
