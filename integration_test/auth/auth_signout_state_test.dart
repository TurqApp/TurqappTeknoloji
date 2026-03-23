import 'package:flutter_test/flutter_test.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Auth sign-out clears Firebase and probe state cleanly',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();

      try {
        await SmokeArtifactCollector.runScenario(
          'auth_signout_state',
          tester,
          () async {
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
              reason: 'Signed-in auth snapshot was not ready before sign-out.',
            );
            expect(beforeAuth['currentUserLoaded'], isTrue);

            await performSmokeSignOut(tester);

            final signedOut = await waitForSurfaceProbeContract(
              tester,
              'auth',
              (payload) =>
                  payload['registered'] == true &&
                  payload['isFirebaseSignedIn'] == false &&
                  (payload['currentUid'] as String? ?? '').isEmpty &&
                  (payload['activeUid'] as String? ?? '').isEmpty,
              reason: 'Sign-out did not clear Firebase/probe state cleanly.',
              context: 'auth sign-out contract',
            );
            expect(signedOut['currentUserLoaded'], isFalse);
          },
        );
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}
