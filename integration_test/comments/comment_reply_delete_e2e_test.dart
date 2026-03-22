import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Comments reply and delete flow performs real send and delete mutations',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'comment_reply_delete_e2e',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          await openCommentsForFirstFeedPost(tester);

          final replyKey = await waitForKeyPrefix(tester, 'it-comment-reply-');
          final replyCommentId = replyKey.replaceFirst('it-comment-reply-', '');

          await tapItKey(tester, replyKey, settlePumps: 6);
          await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) =>
                payload['registered'] == true &&
                payload['replyingToCommentId'] == replyCommentId,
            reason:
                'Reply target was not activated for comment $replyCommentId.',
          );

          final replyText = uniqueTestText('turqapp e2e reply');
          await tester.enterText(
            byItKey(IntegrationTestKeys.inputComment),
            replyText,
          );
          await tester.pump(const Duration(milliseconds: 250));
          await tapItKey(
            tester,
            IntegrationTestKeys.actionCommentSend,
            settlePumps: 8,
          );

          await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) =>
                payload['registered'] == true &&
                payload['lastSuccessfulSendText'] == replyText &&
                payload['lastSuccessfulSendWasReply'] == true &&
                (payload['replyingToCommentId'] as String? ?? '').isEmpty,
            reason: 'Reply send did not complete cleanly.',
          );

          final rootCommentText = uniqueTestText('turqapp e2e delete target');
          await tester.enterText(
            byItKey(IntegrationTestKeys.inputComment),
            rootCommentText,
          );
          await tester.pump(const Duration(milliseconds: 250));
          await tapItKey(
            tester,
            IntegrationTestKeys.actionCommentSend,
            settlePumps: 8,
          );

          final afterRootSend = await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) =>
                payload['registered'] == true &&
                payload['lastSuccessfulSendText'] == rootCommentText &&
                payload['lastSuccessfulSendWasReply'] == false &&
                (payload['lastSuccessfulCommentId'] as String? ?? '')
                    .isNotEmpty,
            reason: 'Root comment send did not expose a deletable comment id.',
          );

          final commentId =
              (afterRootSend['lastSuccessfulCommentId'] as String).trim();
          final deleteFinder =
              byItKey(IntegrationTestKeys.commentDeleteButton(commentId));
          await pumpUntilVisible(tester, deleteFinder, maxPumps: 20);
          await tapItKey(
            tester,
            IntegrationTestKeys.commentDeleteButton(commentId),
            settlePumps: 4,
          );
          await confirmCupertinoDialog(tester);

          final afterDelete = await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) {
              final docIds = payload['docIds'];
              final ids = docIds is List
                  ? docIds.map((item) => item?.toString() ?? '').toList()
                  : const <String>[];
              return payload['registered'] == true &&
                  payload['lastDeletedCommentId'] == commentId &&
                  !ids.contains(commentId);
            },
            reason: 'Comment delete did not remove the created comment.',
          );
          expect(afterDelete['lastDeletedCommentText'], rootCommentText);

          await popRouteAndSettle(tester);
          await expectFeedScreen(tester);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
