import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Auth startup restores an active session into the feed shell',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'auth_startup_session_restore',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
          expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);

          await waitForSurfaceProbe(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == true &&
                (payload['currentUid'] as String? ?? '').isNotEmpty &&
                payload['activeUid'] == payload['currentUid'] &&
                payload['currentUserLoaded'] == true,
            reason:
                'Startup did not restore the base signed-in auth/session state.',
          );

          final auth = await waitForSurfaceProbeContract(
            tester,
            'auth',
            (payload) =>
                payload['registered'] == true &&
                payload['isFirebaseSignedIn'] == true &&
                (payload['currentUid'] as String? ?? '').isNotEmpty &&
                payload['activeUid'] == payload['currentUid'] &&
                payload['currentUserLoaded'] == true &&
                payload['accountCenterRegistered'] == true &&
                payload['activeSessionValid'] == true,
            reason:
                'Startup did not restore a healthy signed-in auth/session state.',
            context: 'auth startup restore',
            maxPumps: 32,
          );
          expect((auth['accountCount'] as num?)?.toInt() ?? 0, greaterThan(0));

          final feed = await waitForSurfaceProbeContract(
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
            reason:
                'Startup did not land on a populated feed surface in forYou mode.',
            context: 'feed startup contract',
          );
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
          expectFeedUsesPrimaryContract(feed);
          expectSurfaceMatchesFixture(
            'feed',
            feed,
            enforceRequiredDocIds: false,
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
