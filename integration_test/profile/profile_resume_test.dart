import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/helpers/route_replay.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/test_state_probe.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Profile smoke bootstraps without centered-resume exception',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();
      try {
        await SmokeArtifactCollector.runScenario(
          'profile_resume',
          tester,
          () async {
            await launchTurqApp(tester);
            await settleSmokeShell(
              tester,
              context: 'profile route replay settle',
            );
            prepareProfileShellRouteReplay();
            await goToProfileTab(tester);
            expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
            final profileSnapshot = maybeReadSurfaceProbe('profile');
            if (profileSnapshot?['registered'] == true) {
              final profileCount =
                  (profileSnapshot!['count'] as num?)?.toInt() ?? 0;
              final profileIndex =
                  (profileSnapshot['centeredIndex'] as num?)?.toInt() ?? -1;
              if (profileCount <= 0 || profileIndex >= 0) {
                expectCenteredIndexValid(
                  'profile',
                  indexField: 'centeredIndex',
                  countField: 'count',
                );
              }
            }
            await goToFeedTab(tester);
            expectSurfaceRegistered('feed');
          },
        );
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}
