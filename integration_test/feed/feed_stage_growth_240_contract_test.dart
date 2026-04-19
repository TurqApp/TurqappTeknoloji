import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed reaches 60 120 180 240 milestones under primary contract',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_stage_growth_240_contract',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final initialFeed = await waitForSurfaceProbeContract(
            tester,
            'feed',
            (payload) =>
                payload['registered'] == true &&
                (payload['count'] as num?) != null &&
                (payload['count'] as num).toInt() > 0 &&
                payload['feedViewMode'] == 'forYou' &&
                payload['usesPrimaryFeedPaging'] == true &&
                payload['feedContractId'] ==
                    FeedHomeContract.primaryHybridV1.contractId,
            reason: 'Feed did not stabilize before 240 growth contract.',
            context: 'feed stage growth initial contract',
          );

          expectFeedUsesPrimaryContract(initialFeed);

          Map<String, dynamic> latestFeed = initialFeed;
          for (final milestone in const <int>[60, 120, 180, 240]) {
            final beforeMilestone = latestFeed;
            latestFeed = await _scrollUntilFeedCountAtLeast(
              tester,
              milestone: milestone,
              initialPayload: latestFeed,
            );
            expectFeedUsesPrimaryContract(latestFeed);
            expectCenteredIndexValid(
              'feed',
              indexField: 'centeredIndex',
              countField: 'count',
            );
            final previousCount =
                (beforeMilestone['count'] as num?)?.toInt() ?? 0;
            final count = (latestFeed['count'] as num?)?.toInt() ?? 0;
            final plannedCount =
                (latestFeed['plannedColdFeedCount'] as num?)?.toInt() ?? 0;
            expect(
              count,
              greaterThanOrEqualTo(previousCount),
              reason: 'Feed count regressed before milestone=$milestone '
                  'before=$previousCount after=$count payload=$latestFeed',
            );
            expect(
              count,
              greaterThanOrEqualTo(milestone),
              reason:
                  'Feed did not reach milestone=$milestone payload=$latestFeed',
            );
            if (milestone < 240) {
              expect(
                plannedCount,
                greaterThan(15),
                reason: 'Planned cold feed window did not expand beyond the '
                    'initial head milestone=$milestone count=$count '
                    'planned=$plannedCount '
                    'payload=$latestFeed',
              );
            }
          }
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<Map<String, dynamic>> _scrollUntilFeedCountAtLeast(
  WidgetTester tester, {
  required int milestone,
  required Map<String, dynamic> initialPayload,
  int maxScrolls = 96,
}) async {
  var payload = initialPayload;
  var count = (payload['count'] as num?)?.toInt() ?? 0;
  if (count >= milestone) {
    return payload;
  }

  for (var i = 0; i < maxScrolls; i++) {
    await tester.drag(
      byItKey(IntegrationTestKeys.screenFeed),
      const Offset(0, -560),
    );
    await settleSmokeShell(
      tester,
      context: 'feed stage growth milestone settle',
    );
    payload = readSurfaceProbe('feed');
    expectFeedUsesPrimaryContract(payload);
    count = (payload['count'] as num?)?.toInt() ?? 0;
    final plannedCount =
        (payload['plannedColdFeedCount'] as num?)?.toInt() ?? 0;
    debugPrint(
      '[integration-smoke] feed stage growth milestone=$milestone '
      'scroll=${i + 1} count=$count planned=$plannedCount',
    );
    if (count >= milestone) {
      return payload;
    }
  }

  throw TestFailure(
    'Feed did not reach milestone=$milestone after $maxScrolls scrolls. '
    'Last payload=$payload',
  );
}
