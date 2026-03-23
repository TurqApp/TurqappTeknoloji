import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Auth session churn signs out and reauthenticates cleanly',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();

      try {
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

          await performSmokeSignOut(tester);
          _drainExpectedChurnExceptions(tester);

          final signedOut = await waitForSurfaceProbeContract(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == false &&
                (payload['currentUid'] as String? ?? '').isEmpty,
            reason: 'Sign-out did not clear the auth snapshot cleanly.',
            context: 'auth sign-out contract',
          );
          expect(signedOut['currentUserLoaded'], isFalse);

          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: kIntegrationLoginEmail,
            password: kIntegrationLoginPassword,
          );
          await tester.pump(const Duration(milliseconds: 300));
          drainExpectedTesterExceptions(tester, context: 'auth churn reauth');
          await CurrentUserService.instance.initialize();
          await tester.pump(const Duration(milliseconds: 300));
          drainExpectedTesterExceptions(tester, context: 'auth churn init');

          final afterAuth = await waitForSurfaceProbeContract(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == true &&
                (payload['currentUid'] as String? ?? '').isNotEmpty &&
                payload['activeUid'] == payload['currentUid'],
            reason: 'Reauth did not restore an active signed-in session.',
            context: 'auth reauth contract',
          );
          expect(afterAuth['currentUid'], beforeAuth['currentUid']);
        },
      );
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}

void _drainExpectedChurnExceptions(WidgetTester tester) {
  drainExpectedTesterExceptions(tester, context: 'auth churn');
}
