import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Market tab opens a real listing detail route',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'market_detail_flow_e2e',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          expect(
            byItKey(IntegrationTestKeys.navEducation),
            findsOneWidget,
            reason: 'Education tab is required for market detail coverage.',
          );
          await tapItKey(tester, IntegrationTestKeys.navEducation);
          expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);

          await tapItKey(
            tester,
            IntegrationTestKeys.educationTab(PasajTabIds.market),
            settlePumps: 8,
          );
          final marketItemKey =
              await waitForKeyPrefix(tester, 'it-market-item-');
          await tapItKey(tester, marketItemKey, settlePumps: 10);
          expect(
              byItKey(IntegrationTestKeys.screenMarketDetail), findsOneWidget);

          await pageBackAndSettle(tester, settlePumps: 8);
          expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
