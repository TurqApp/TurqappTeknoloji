import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

const bool kUseOsPermissionState = bool.fromEnvironment(
    'INTEGRATION_USE_OS_PERMISSION_STATE',
    defaultValue: false);

Future<void> _openPermissionsScreen(WidgetTester tester) async {
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
    IntegrationTestKeys.actionSettingsOpenPermissions,
    settlePumps: 10,
  );
  expect(byItKey(IntegrationTestKeys.screenPermissions), findsOneWidget);
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'OS permission matrix surfaces denied camera, photos, and microphone states',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'permission_os_denied_state_smoke',
        tester,
        () async {
          expect(kUseOsPermissionState, isTrue);
          await launchTurqApp(tester);
          await expectFeedScreen(tester);
          await _openPermissionsScreen(tester);

          final payload = await waitForSurfaceProbe(
            tester,
            'permissions',
            (surface) {
              final statuses = surface['statuses'];
              return statuses is Map<String, dynamic> &&
                  statuses['camera'] == 'denied' &&
                  statuses['photos'] == 'denied' &&
                  statuses['microphone'] == 'denied';
            },
            maxPumps: 24,
            reason: 'OS-level denied permissions did not propagate to probe.',
          );

          final statuses =
              Map<String, dynamic>.from(payload['statuses'] as Map);
          expect(statuses['camera'], 'denied');
          expect(statuses['photos'], 'denied');
          expect(statuses['microphone'], 'denied');
        },
      );
    },
    skip: !kRunIntegrationSmoke || !kUseOsPermissionState,
  );
}
