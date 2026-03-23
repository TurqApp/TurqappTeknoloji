import 'package:flutter_test/flutter_test.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Auth reauth restores an active session after sign-out',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();

      try {
        await SmokeArtifactCollector.runScenario(
          'auth_reauth_restore',
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
              reason: 'Signed-in auth snapshot was not ready before reauth.',
            );

            await performSmokeSignOut(tester);

            final signedOut = await waitForSurfaceProbeContract(
              tester,
              'auth',
              (payload) =>
                  payload['registered'] == true &&
                  payload['isFirebaseSignedIn'] == false &&
                  (payload['currentUid'] as String? ?? '').isEmpty &&
                  (payload['activeUid'] as String? ?? '').isEmpty,
              reason: 'Sign-out did not complete before reauth.',
              context: 'auth reauth precondition',
            );
            expect(signedOut['currentUserLoaded'], isFalse);

            await performSmokeReauth(
              tester,
              email: kIntegrationLoginEmail,
              password: kIntegrationLoginPassword,
            );

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
            expect(afterAuth['currentUserLoaded'], isTrue);
          },
        );
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}
