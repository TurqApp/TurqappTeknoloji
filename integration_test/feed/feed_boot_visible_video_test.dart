import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/player_contract_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed boot exposes a visible autoplay video contract',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_boot_visible_video',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final controller = ensureAgendaController();
          final sample = await waitForFeedVisibleAutoplayVideo(
            tester,
            controller: controller,
          );
          final payload = readSurfaceProbe('feed');
          final count = (payload['count'] as num?)?.toInt() ?? 0;
          final centeredIndex =
              (payload['centeredIndex'] as num?)?.toInt() ?? -1;
          final docIds =
              (payload['docIds'] as List?)?.map((e) => e.toString()).toList() ??
                  const <String>[];

          expect(payload['registered'], isTrue,
              reason: 'feed controller not registered');
          expect(count, greaterThan(0),
              reason: 'feed did not expose any visible items');
          expect(centeredIndex, sample.index,
              reason: 'feed centered index drifted before first contract read');
          expect(docIds, contains(sample.docId),
              reason: 'visible autoplay doc is missing from feed probe');
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
