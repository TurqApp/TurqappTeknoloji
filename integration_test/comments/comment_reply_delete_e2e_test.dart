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
          await launchTurqApp(
            tester,
            forceFeedTab: false,
            relaxFeedFixtureDocRequirement: true,
          );
          await ensureFeedTabVisibleForSmoke(tester);

          await openCommentsForFirstFeedPost(tester);

          final replyCommentId = await ensureCommentTargetForSmoke(tester);

          await tapItKey(
            tester,
            IntegrationTestKeys.commentReplyButton(replyCommentId),
            settlePumps: 6,
          );
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
          await sendCommentFromComposer(tester, replyText);

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
          await sendCommentFromComposer(tester, rootCommentText);

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
