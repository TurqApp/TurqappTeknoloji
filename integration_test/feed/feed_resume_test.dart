import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/helpers/route_replay.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/test_state_probe.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed smoke bootstraps without route-return exception',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();
      try {
        await SmokeArtifactCollector.runScenario('feed_resume', tester,
            () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);
          expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
          expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);
          final beforeFeed = await waitForSurfaceProbeContract(
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
            reason: 'Feed did not stabilize on the canonical primary contract.',
            context: 'feed resume before replay',
          );
          expectSurfaceRegistered('feed');
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
          expectFeedUsesPrimaryContract(beforeFeed);
          expectSurfaceMatchesFixture(
            'feed',
            beforeFeed,
            enforceRequiredDocIds: false,
          );
          await settleSmokeShell(
            tester,
            context: 'feed route replay settle',
          );
          print('[integration-smoke] feed_resume: before profile replay');
          await replayFeedToProfileToFeed(tester, beforeFeed: beforeFeed);
          await settleSmokeShell(
            tester,
            context: 'feed post-profile replay settle',
          );
          print('[integration-smoke] feed_resume: after profile replay');
          final afterFeed = await waitForSurfaceProbeContract(
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
                'Feed lost the canonical primary contract after route replay.',
            context: 'feed resume after replay',
          );
          expectSurfaceRegistered('feed');
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
          expectFeedUsesPrimaryContract(afterFeed);
          expectCountNeverDropsToZeroAfterReplay(
            'feed',
            before: beforeFeed,
            after: afterFeed,
          );
          expectSurfaceMatchesFixture(
            'feed',
            afterFeed,
            enforceRequiredDocIds: false,
          );
        });
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}
