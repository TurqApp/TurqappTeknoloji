import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Auth session churn signs out and reauthenticates cleanly',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'auth_session_churn_e2e',
        tester,
        () async {
          expect(
            kIntegrationLoginEmail,
            isNotEmpty,
            reason: 'Integration login email is required for reauth.',
          );
          expect(
            kIntegrationLoginPassword,
            isNotEmpty,
            reason: 'Integration login password is required for reauth.',
          );

          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final beforeAuth = await waitForSurfaceProbe(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == true &&
                (payload['currentUid'] as String? ?? '').isNotEmpty &&
                payload['activeUid'] == payload['currentUid'],
            reason: 'Signed-in auth snapshot was not ready before churn.',
          );

          await tapItKey(tester, IntegrationTestKeys.navProfile);
          expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
          await tapItKey(
            tester,
            IntegrationTestKeys.actionProfileOpenSettings,
            settlePumps: 10,
          );
          expect(byItKey(IntegrationTestKeys.screenSettings), findsOneWidget);

          await tapItKey(
            tester,
            IntegrationTestKeys.actionSettingsOpenAccountCenter,
            settlePumps: 10,
          );
          expect(
            byItKey(IntegrationTestKeys.screenAccountCenter),
            findsOneWidget,
          );

          final accountCenterAuth = await waitForSurfaceProbe(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['accountCenterRegistered'] == true &&
                (payload['accountCount'] as num? ?? 0) > 0 &&
                payload['activeUid'] == payload['currentUid'],
            reason: 'Account center did not expose the active account state.',
          );
          expect(accountCenterAuth['activeSessionValid'], isTrue);

          await popRouteAndSettle(tester);
          expect(byItKey(IntegrationTestKeys.screenSettings), findsOneWidget);

          await tapItKey(
            tester,
            IntegrationTestKeys.actionSettingsSignOut,
            settlePumps: 3,
          );
          await confirmCupertinoDialog(tester);

          await pumpUntilVisible(
            tester,
            byItKey(IntegrationTestKeys.screenSignIn),
            maxPumps: 40,
          );
          final signedOut = await waitForSurfaceProbe(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == false &&
                (payload['currentUid'] as String? ?? '').isEmpty,
            reason: 'Sign-out did not clear the auth snapshot cleanly.',
          );
          expect(signedOut['currentUserLoaded'], isFalse);

          final loginButton =
              find.byKey(const ValueKey<String>('login_button'));
          final emailField = find.byKey(const ValueKey<String>('email'));
          final passwordField = find.byKey(const ValueKey<String>('password'));
          final submitButton =
              find.byKey(const ValueKey<String>('login_submit_button'));

          await pumpUntilVisible(tester, loginButton, maxPumps: 24);
          await tester.tap(loginButton);
          await tester.pump(const Duration(milliseconds: 250));

          await pumpUntilVisible(tester, emailField, maxPumps: 24);
          await tester.enterText(emailField, kIntegrationLoginEmail);
          await tester.enterText(passwordField, kIntegrationLoginPassword);
          await tester.tap(submitButton);

          await pumpUntilVisible(
            tester,
            byItKey(IntegrationTestKeys.navBarRoot),
            maxPumps: 72,
          );

          final afterAuth = await waitForSurfaceProbe(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == true &&
                (payload['currentUid'] as String? ?? '').isNotEmpty &&
                payload['activeUid'] == payload['currentUid'] &&
                payload['activeSessionValid'] == true,
            reason: 'Reauth did not restore an active signed-in session.',
          );
          expect(afterAuth['currentUid'], beforeAuth['currentUid']);
          expect(afterAuth['accountCount'], greaterThanOrEqualTo(1));
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
