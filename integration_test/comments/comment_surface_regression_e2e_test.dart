import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

const String _seedCommentId = 'it_seed_comment_1';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Comments surface stays stable across like, reply, create, and delete',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'comment_surface_regression_e2e',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          await openCommentsForFirstFeedPost(tester);

          await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) {
              final docIds = payload['docIds'];
              final ids = docIds is List
                  ? docIds.map((item) => item?.toString() ?? '').toList()
                  : const <String>[];
              return payload['registered'] == true &&
                  ids.contains(_seedCommentId);
            },
            reason:
                'Seeded comment $_seedCommentId was not visible in comments.',
          );
          await expectNoFlutterException(tester);

          await tapItKey(
            tester,
            IntegrationTestKeys.commentLikeButton(_seedCommentId),
            settlePumps: 6,
          );
          await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) {
              final likedDocIds = payload['likedByMeDocIds'];
              final ids = likedDocIds is List
                  ? likedDocIds.map((item) => item?.toString() ?? '').toList()
                  : const <String>[];
              return payload['registered'] == true &&
                  ids.contains(_seedCommentId);
            },
            reason:
                'Comment like did not add the signed-in user to the seeded comment.',
          );
          await expectNoFlutterException(tester);

          await tapItKey(
            tester,
            IntegrationTestKeys.commentLikeButton(_seedCommentId),
            settlePumps: 6,
          );
          await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) {
              final likedDocIds = payload['likedByMeDocIds'];
              final ids = likedDocIds is List
                  ? likedDocIds.map((item) => item?.toString() ?? '').toList()
                  : const <String>[];
              return payload['registered'] == true &&
                  !ids.contains(_seedCommentId);
            },
            reason:
                'Comment unlike did not remove the signed-in user from the seeded comment.',
          );
          await expectNoFlutterException(tester);

          await tapItKey(
            tester,
            IntegrationTestKeys.commentReplyButton(_seedCommentId),
            settlePumps: 6,
          );
          await waitForSurfaceProbe(
            tester,
            'comments',
            (payload) =>
                payload['registered'] == true &&
                payload['replyingToCommentId'] == _seedCommentId,
            reason:
                'Reply target was not activated for comment $_seedCommentId.',
          );
          await expectNoFlutterException(tester);

          final replyText = uniqueTestText('turqapp e2e combo reply');
          await tester.enterText(
            byItKey(IntegrationTestKeys.inputComment),
            replyText,
          );
          await tester.pump(const Duration(milliseconds: 250));
          await expectNoFlutterException(tester);
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
          await expectNoFlutterException(tester);

          final rootCommentText = uniqueTestText('turqapp e2e combo root');
          await tester.enterText(
            byItKey(IntegrationTestKeys.inputComment),
            rootCommentText,
          );
          await tester.pump(const Duration(milliseconds: 250));
          await expectNoFlutterException(tester);
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
          await expectNoFlutterException(tester);

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
          await expectNoFlutterException(tester);

          await popRouteAndSettle(tester);
          await expectFeedScreen(tester);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
