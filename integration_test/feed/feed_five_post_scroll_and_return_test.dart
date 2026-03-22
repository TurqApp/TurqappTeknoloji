import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/SinglePost/single_post.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/helpers/smoke_artifact_collector.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed survives five autoplay posts with single-post return',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_five_post_scroll_and_return',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          final controller = AgendaController.ensure();
          final targetIndices =
              await _waitForFiveFeedPosts(tester, controller: controller);

          final firstIndex = targetIndices.first;
          await _focusCurrentFeedPost(
            tester,
            controller: controller,
            targetIndex: firstIndex,
          );

          for (final targetIndex in targetIndices.skip(1)) {
            await _swipeFeedUpUntilCentered(
              tester,
              controller: controller,
              targetIndex: targetIndex,
            );
            await _focusCurrentFeedPost(
              tester,
              controller: controller,
              targetIndex: targetIndex,
            );
          }

          for (final targetIndex in targetIndices.reversed.skip(1)) {
            await _swipeFeedDownUntilCentered(
              tester,
              controller: controller,
              targetIndex: targetIndex,
            );
            await _focusCurrentFeedPost(
              tester,
              controller: controller,
              targetIndex: targetIndex,
            );
          }
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}

Future<List<int>> _waitForFiveFeedPosts(
  WidgetTester tester, {
  required AgendaController controller,
}) async {
  const timeout = Duration(seconds: 12);
  const step = Duration(milliseconds: 250);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    final list = controller.agendaList;
    if (list.length >= 5) {
      return List<int>.generate(5, (index) => index, growable: false);
    }
  }

  throw TestFailure(
    'Feed did not expose five posts '
    '(count=${controller.agendaList.length}).',
  );
}

Future<void> _focusCurrentFeedPost(
  WidgetTester tester, {
  required AgendaController controller,
  required int targetIndex,
}) async {
  final post = controller.agendaList[targetIndex];
  await _waitForCenteredIndex(
    tester,
    controller: controller,
    targetIndex: targetIndex,
  );
  if (controller.canAutoplayInTests(post)) {
    await _waitForPlayingDoc(
      tester,
      expectedDocId: post.docID,
    );
  }

  await _openSinglePostAndReturn(
    tester,
    controller: controller,
    targetIndex: targetIndex,
    post: post,
  );
}

Future<void> _swipeFeedUpUntilCentered(
  WidgetTester tester, {
  required AgendaController controller,
  required int targetIndex,
}) async {
  const maxSwipes = 8;
  for (var i = 0; i < maxSwipes; i++) {
    if (controller.centeredIndex.value == targetIndex) return;
    await tester.drag(
      byItKey(IntegrationTestKeys.screenFeed),
      const Offset(0, -520),
    );
    for (var j = 0; j < 10; j++) {
      await tester.pump(const Duration(milliseconds: 180));
      if (controller.centeredIndex.value == targetIndex) return;
    }
  }
  throw TestFailure(
    'Feed did not reach target while swiping up '
    '(target=$targetIndex, centered=${controller.centeredIndex.value}).',
  );
}

Future<void> _swipeFeedDownUntilCentered(
  WidgetTester tester, {
  required AgendaController controller,
  required int targetIndex,
}) async {
  const maxSwipes = 8;
  for (var i = 0; i < maxSwipes; i++) {
    if (controller.centeredIndex.value == targetIndex) return;
    await tester.drag(
      byItKey(IntegrationTestKeys.screenFeed),
      const Offset(0, 520),
    );
    for (var j = 0; j < 10; j++) {
      await tester.pump(const Duration(milliseconds: 180));
      if (controller.centeredIndex.value == targetIndex) return;
    }
  }
  throw TestFailure(
    'Feed did not reach target while swiping down '
    '(target=$targetIndex, centered=${controller.centeredIndex.value}).',
  );
}

Future<void> _waitForCenteredIndex(
  WidgetTester tester, {
  required AgendaController controller,
  required int targetIndex,
}) async {
  const timeout = Duration(seconds: 6);
  const step = Duration(milliseconds: 200);
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;

  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (controller.centeredIndex.value == targetIndex) {
      return;
    }
  }

  throw TestFailure(
    'Feed did not center target post '
    '(target=$targetIndex, centered=${controller.centeredIndex.value}).',
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
    'Feed did not play expected doc '
    '(expected=$expectedDocId, current=${manager.currentPlayingDocID}).',
  );
}

Future<void> _openSinglePostAndReturn(
  WidgetTester tester, {
  required AgendaController controller,
  required int targetIndex,
  required PostsModel post,
}) async {
  Get.to(() => SinglePost(model: post, showComments: false));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);

  await popRouteAndSettle(tester, settlePumps: 10);
  await expectFeedScreen(tester);

  await _waitForCenteredIndex(
    tester,
    controller: controller,
    targetIndex: targetIndex,
  );
  if (controller.canAutoplayInTests(post)) {
    await _waitForPlayingDoc(
      tester,
      expectedDocId: post.docID,
    );
  }
}
