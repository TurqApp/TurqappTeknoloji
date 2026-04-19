import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/player_contract_helpers.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed first autoplay video satisfies playback contract on boot',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_first_video_playback',
        tester,
        () async {
          await launchTurqApp(
            tester,
            relaxFeedFixtureDocRequirement: true,
            primeFeedSnapshot: false,
          );
          await expectFeedScreen(tester);

          final controller = ensureAgendaController();
          final sample = await waitForFeedVisibleAutoplayVideo(
            tester,
            controller: controller,
          );
          await waitForPoolAdapterExists(
            tester,
            cacheKey: sample.docId,
            label: 'feed_first.exists',
          );
          await waitForPlayerInitialized(
            tester,
            cacheKey: sample.docId,
            label: 'feed_first.initialized',
          );
          await waitForPlayerFirstFrame(
            tester,
            cacheKey: sample.docId,
            label: 'feed_first.firstFrame',
          );
          await waitForPlayerPositionAdvanced(
            tester,
            cacheKey: sample.docId,
            label: 'feed_first.positionAdvanced',
            minimumAdvance: const Duration(seconds: 3),
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
