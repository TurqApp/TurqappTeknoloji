import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import 'helpers/smoke_artifact_collector.dart';
import 'helpers/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed first autoplay video advances playback on boot',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_first_video_playback',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final controller = AgendaController.ensure();
          final targetIndex = await _waitForInitialAutoplayIndex(
            tester,
            controller: controller,
          );
          final targetPost = controller.agendaList[targetIndex];

          await _waitForPlayingDoc(
            tester,
            expectedDocId: targetPost.docID,
          );

          await _waitForPlaybackAdvance(
            tester,
            expectedDocId: targetPost.docID,
            minimumAdvance: const Duration(seconds: 3),
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<int> _waitForInitialAutoplayIndex(
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
    final centered = controller.centeredIndex.value;
    if (centered >= 0 &&
        centered < items.length &&
        controller.canAutoplayInTests(items[centered])) {
      return centered;
    }
  }

  throw TestFailure(
    'Feed did not expose an autoplay-centered video '
    '(count=${controller.agendaList.length}, centered=${controller.centeredIndex.value}).',
  );
}

Future<void> _waitForPlayingDoc(
  WidgetTester tester, {
  required String expectedDocId,
}) async {
  const timeout = Duration(seconds: 6);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  final manager = VideoStateManager.instance;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (manager.currentPlayingDocID == expectedDocId) {
      return;
    }
  }

  throw TestFailure(
    'Feed did not assign expected playing doc '
    '(expected=$expectedDocId, current=${manager.currentPlayingDocID}).',
  );
}

Future<void> _waitForPlaybackAdvance(
  WidgetTester tester, {
  required String expectedDocId,
  required Duration minimumAdvance,
}) async {
  const timeout = Duration(seconds: 8);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  final manager = VideoStateManager.instance;

  Duration? baseline;
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final state = manager.getVideoState(expectedDocId);
    if (manager.currentPlayingDocID != expectedDocId || state == null) {
      continue;
    }
    if (baseline == null) {
      if (state.position > Duration.zero) {
        baseline = state.position;
      }
      continue;
    }
    if (state.position - baseline >= minimumAdvance) {
      return;
    }
  }

  final state = manager.getVideoState(expectedDocId);
  throw TestFailure(
    'Feed first video did not advance playback '
    '(doc=$expectedDocId, position=${state?.position}, playing=${state?.isPlaying}).',
  );
}
