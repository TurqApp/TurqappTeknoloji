import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed selects and starts the first autoplay video on boot',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_first_video_autoplay',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final controller = AgendaController.ensure();
          await _waitForInitialAutoplaySelection(
            tester,
            controller: controller,
          );

          final firstVideoIndex = controller.agendaList
              .indexWhere((post) => controller.canAutoplayInTests(post));
          expect(firstVideoIndex, greaterThanOrEqualTo(0));
          expect(controller.centeredIndex.value, firstVideoIndex);

          final centeredPost = controller.agendaList[firstVideoIndex];
          final manager = VideoStateManager.instance;
          await _waitForCurrentPlayingDoc(
            tester,
            manager: manager,
            expectedDocId: centeredPost.docID,
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<void> _waitForInitialAutoplaySelection(
  WidgetTester tester, {
  required AgendaController controller,
}) async {
  const timeout = Duration(seconds: 12);
  const step = Duration(milliseconds: 250);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final items = controller.agendaList;
    if (items.isEmpty) continue;
    final firstVideoIndex =
        items.indexWhere((post) => controller.canAutoplayInTests(post));
    final centered = controller.centeredIndex.value;
    if (firstVideoIndex >= 0 && centered == firstVideoIndex) {
      return;
    }
  }

  throw TestFailure(
    'Feed did not center the first autoplay video '
    '(count=${controller.agendaList.length}, centered=${controller.centeredIndex.value}).',
  );
}

Future<void> _waitForCurrentPlayingDoc(
  WidgetTester tester, {
  required VideoStateManager manager,
  required String expectedDocId,
}) async {
  const timeout = Duration(seconds: 6);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (_matchesExpectedFeedPlaybackKey(
      manager.currentPlayingDocID,
      expectedDocId,
    )) {
      return;
    }
  }

  throw TestFailure(
    'Feed did not start expected autoplay doc '
    '(expected=$expectedDocId, current=${manager.currentPlayingDocID}, '
    'probe=${readIntegrationProbe()}).',
  );
}

bool _matchesExpectedFeedPlaybackKey(
  String? currentPlayingDocId,
  String expectedDocId,
) {
  final current = currentPlayingDocId?.trim() ?? '';
  final expected = expectedDocId.trim();
  return current == expected || current == 'feed:$expected';
}
