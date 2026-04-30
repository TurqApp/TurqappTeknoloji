import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/launch_motor_selection_service.dart';
import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

const int _kRequestedFeedMotorIndex = int.fromEnvironment(
  'INTEGRATION_FEED_TARGET_MOTOR_INDEX',
  defaultValue: 0,
);

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed boot respects forced launch motor contract',
    (tester) async {
      final normalizedMotorIndex = _normalizeMotorIndex(
        _kRequestedFeedMotorIndex,
        feedLaunchMotorContract.minuteSets.length,
      );
      await _primeFeedMotorForSmoke(normalizedMotorIndex);

      await SmokeArtifactCollector.runScenario(
        'feed_motor_bootstrap_contract_m$normalizedMotorIndex',
        tester,
        () async {
          await launchTurqApp(
            tester,
            primeFeedSnapshot: false,
          );
          await expectFeedScreen(tester);

          expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
          expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);

          final anchorMs = startupSurfaceSessionSeed(sessionNamespace: 'feed');
          final actualMotorIndex =
              LaunchMotorSelectionService.resolveMotorIndex(
            anchorMs: anchorMs,
            bandMinutes: feedLaunchMotorContract.bandMinutes,
            minuteSets: feedLaunchMotorContract.minuteSets,
          );
          final ownedMinutes = LaunchMotorSelectionService.resolveOwnedMinutes(
            anchorMs: anchorMs,
            bandMinutes: feedLaunchMotorContract.bandMinutes,
            minuteSets: feedLaunchMotorContract.minuteSets,
          );

          debugPrint(
            '[integration-smoke] feed motor requested=$normalizedMotorIndex '
            'actual=$actualMotorIndex ownedMinutes=${ownedMinutes.join(",")}',
          );

          expect(
            actualMotorIndex,
            normalizedMotorIndex,
            reason:
                'Feed startup motor did not match the forced target. anchorMs=$anchorMs',
          );

          final feed = await waitForSurfaceProbeContract(
            tester,
            'feed',
            (payload) =>
                payload['registered'] == true &&
                (payload['count'] as num?) != null &&
                (payload['count'] as num).toInt() > 0 &&
                payload['feedViewMode'] == 'forYou' &&
                payload['usesPrimaryFeedPaging'] ==
                    FeedHomeContract.primaryHybridV1.usesPrimaryFeedPaging &&
                payload['feedContractId'] ==
                    FeedHomeContract.primaryHybridV1.contractId,
            reason:
                'Feed did not stabilize on the expected primary shell contract.',
            context: 'feed motor bootstrap',
          );

          expect(feed['playbackSuspended'], isFalse);
          expect(feed['pauseAll'], isFalse);
          expectFeedUsesPrimaryContract(feed);
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<void> _primeFeedMotorForSmoke(int targetMotorIndex) async {
  final prefs = await SharedPreferences.getInstance();
  final motorCount = feedLaunchMotorContract.minuteSets.length;
  final previousMotorIndex = (targetMotorIndex - 1 + motorCount) % motorCount;
  await prefs.setInt('startup_motor_cycle_feed', previousMotorIndex);
  debugPrint(
    '[integration-smoke] preset feed motor target=$targetMotorIndex '
    'storedPrevious=$previousMotorIndex',
  );
}

int _normalizeMotorIndex(int requestedMotorIndex, int motorCount) {
  if (motorCount <= 0) {
    return 0;
  }
  final normalized = requestedMotorIndex % motorCount;
  return normalized < 0 ? normalized + motorCount : normalized;
}
