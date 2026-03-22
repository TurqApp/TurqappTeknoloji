import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

Finder _storyCircleFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('circle_');
  });
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Story viewer exposes reaction and reply surfaces when available',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'story_reply_reaction_e2e',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          if (byItKey(IntegrationTestKeys.storyRow).evaluate().isEmpty) {
            return;
          }
          final storyCircle = _storyCircleFinder();
          if (storyCircle.evaluate().isEmpty) {
            return;
          }

          await tester.ensureVisible(storyCircle.first);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(storyCircle.first);
          await pumpForAppStartup(
            tester,
            step: const Duration(milliseconds: 200),
            maxPumps: 10,
          );
          expect(
              byItKey(IntegrationTestKeys.screenStoryViewer), findsOneWidget);

          if (findItKeyPrefix('it-story-reaction-').evaluate().isNotEmpty) {
            await tapFirstKeyPrefix(
              tester,
              'it-story-reaction-',
              settlePumps: 6,
            );
          }

          if (byItKey(IntegrationTestKeys.actionStoryOpenComments)
              .evaluate()
              .isNotEmpty) {
            await tapItKey(
              tester,
              IntegrationTestKeys.actionStoryOpenComments,
              settlePumps: 10,
            );
            expect(
              byItKey(IntegrationTestKeys.inputStoryComment),
              findsOneWidget,
            );
            final commentText = uniqueTestText('turqapp story e2e');
            await tester.enterText(
              byItKey(IntegrationTestKeys.inputStoryComment),
              commentText,
            );
            await tester.pump(const Duration(milliseconds: 200));
            await tapItKey(
              tester,
              IntegrationTestKeys.actionStoryCommentSend,
              settlePumps: 8,
            );
            final payload = await waitForSurfaceProbe(
              tester,
              'storyComments',
              (snapshot) =>
                  snapshot['registered'] == true &&
                  snapshot['lastSuccessfulCommentText'] == commentText,
              reason: 'Story comment send did not complete.',
            );
            expect(payload['lastSuccessfulCommentText'], commentText);
            await popRouteAndSettle(tester, settlePumps: 6);
          }

          await pageBackAndSettle(tester);
          await expectFeedScreen(tester);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
