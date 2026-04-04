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
          await launchTurqApp(
            tester,
            forceFeedTab: false,
            relaxFeedFixtureDocRequirement: true,
          );
          await ensureFeedTabVisibleForSmoke(tester);

          await openCommentsForFirstFeedPost(tester);

          final targetCommentId = await ensureCommentTargetForSmoke(
            tester,
            preferredCommentId: _seedCommentId,
          );

          await tapItKey(
            tester,
            IntegrationTestKeys.commentLikeButton(targetCommentId),
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
                  ids.contains(targetCommentId);
            },
            reason:
                'Comment like did not add the signed-in user to the target comment.',
          );

          await tapItKey(
            tester,
            IntegrationTestKeys.commentLikeButton(targetCommentId),
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
                  !ids.contains(targetCommentId);
            },
            reason:
                'Comment unlike did not remove the signed-in user from the target comment.',
          );

          await popRouteAndSettle(tester);
          await expectFeedScreen(tester);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
