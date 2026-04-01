import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

const String _seedCommentId = 'it_seed_comment_1';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Comments like flow toggles the seeded comment membership',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'comment_like_e2e',
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

          await popRouteAndSettle(tester);
          await expectFeedScreen(tester);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
