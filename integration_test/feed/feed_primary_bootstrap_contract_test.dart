import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed startup keeps primary contract, centered playback, and shell state stable',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_primary_bootstrap_contract',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          expect(byItKey(IntegrationTestKeys.navBarRoot), findsOneWidget);
          expect(byItKey(IntegrationTestKeys.navFeed), findsOneWidget);

          final feed = await waitForSurfaceProbeContract(
            tester,
            'feed',
            (payload) =>
                payload['registered'] == true &&
                (payload['count'] as num?) != null &&
                (payload['count'] as num).toInt() > 0 &&
                payload['feedViewMode'] == 'forYou',
            reason:
                'Feed did not stabilize on the expected primary shell contract.',
            context: 'feed primary bootstrap',
          );

          expect(feed['playbackSuspended'], isFalse);
          expect(feed['pauseAll'], isFalse);
          expectCenteredIndexValid(
            'feed',
            indexField: 'centeredIndex',
            countField: 'count',
          );
          expectSurfaceMatchesFixture('feed', feed);

          final auth = readSurfaceProbe('auth');
          expect(auth['isFirebaseSignedIn'], isTrue);
          expect(auth['currentUserLoaded'], isTrue);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
