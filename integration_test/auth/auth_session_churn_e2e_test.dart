import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Auth session churn signs out and reauthenticates cleanly',
    (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('cloud_firestore/permission-denied') ||
            text.contains('Invalid statusCode: 503')) {
          debugPrint('Suppressed non-fatal: $text');
          return;
        }
        originalOnError?.call(details);
      };

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

          await CurrentUserService.instance.logout();
          await FirebaseAuth.instance.signOut();
          await tester.pump(const Duration(milliseconds: 300));
          _drainExpectedChurnExceptions(tester);

          final signedOut = await _waitForSurfaceProbeAllowingExpectedErrors(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == false &&
                (payload['currentUid'] as String? ?? '').isEmpty,
            reason: 'Sign-out did not clear the auth snapshot cleanly.',
          );
          expect(signedOut['currentUserLoaded'], isFalse);

          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: kIntegrationLoginEmail,
            password: kIntegrationLoginPassword,
          );
          await tester.pump(const Duration(milliseconds: 300));
          _drainExpectedChurnExceptions(tester);
          await CurrentUserService.instance.initialize();
          await tester.pump(const Duration(milliseconds: 300));
          _drainExpectedChurnExceptions(tester);

          final afterAuth = await _waitForSurfaceProbeAllowingExpectedErrors(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == true &&
                (payload['currentUid'] as String? ?? '').isNotEmpty &&
                payload['activeUid'] == payload['currentUid'],
            reason: 'Reauth did not restore an active signed-in session.',
          );
          expect(afterAuth['currentUid'], beforeAuth['currentUid']);
        },
      );
      } finally {
        FlutterError.onError = originalOnError;
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<Map<String, dynamic>> _waitForSurfaceProbeAllowingExpectedErrors(
  WidgetTester tester,
  String surface,
  bool Function(Map<String, dynamic>) predicate, {
  int maxPumps = 16,
  Duration step = const Duration(milliseconds: 250),
  String? reason,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    final payload = readSurfaceProbe(surface);
    if (predicate(payload)) {
      return payload;
    }
    await tester.pump(step);
    _drainExpectedChurnExceptions(tester);
  }
  final payload = readSurfaceProbe(surface);
  if (predicate(payload)) {
    return payload;
  }
  throw TestFailure(
    reason ?? 'Surface probe did not reach expected state: $surface',
  );
}

void _drainExpectedChurnExceptions(WidgetTester tester) {
  while (true) {
    final error = tester.takeException();
    if (error == null) {
      return;
    }
    final text = error.toString();
    if (text.contains('cloud_firestore/permission-denied')) {
      debugPrint('Suppressed non-fatal: $text');
      continue;
    }
    throw TestFailure('Unexpected flutter exception during auth churn: $error');
  }
}
