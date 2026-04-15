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
    'Feed growth preserves primary contract while scrolling',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_typesense_growth_contract',
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
            reason: 'Feed did not stabilize before growth contract scroll.',
            context: 'feed growth initial contract',
          );

          final beforeCount = (initialFeed['count'] as num?)?.toInt() ?? 0;
          expect(beforeCount, greaterThan(0));

          Map<String, dynamic> afterFeed = initialFeed;
          for (var i = 0; i < 6; i++) {
            await tester.drag(
              byItKey(IntegrationTestKeys.screenFeed),
              const Offset(0, -520),
            );
            await settleSmokeShell(
              tester,
              context: 'feed growth scroll settle',
            );
            afterFeed = readSurfaceProbe('feed');
            final count = (afterFeed['count'] as num?)?.toInt() ?? 0;
            if (count > beforeCount) {
              break;
            }
          }

          expectFeedUsesPrimaryContract(afterFeed);
          final afterCount = (afterFeed['count'] as num?)?.toInt() ?? 0;
          expect(
            afterCount,
            greaterThan(beforeCount),
            reason:
                'Feed did not grow after scroll (before=$beforeCount after=$afterCount payload=$afterFeed)',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
