import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_posts_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/recommended_users_repository.dart';
import 'package:turqappv2/Core/Repositories/short_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';

class ViewerSurfaceInvalidationService {
  const ViewerSurfaceInvalidationService._();

  static Future<void> invalidateForViewer(
    String uid, {
    bool clearDeletedStories = false,
  }) async {
    final normalized = uid.trim();
    if (normalized.isEmpty) return;
    await Future.wait(<Future<void>>[
      ensureFeedSnapshotRepository().clearUserSnapshots(userId: normalized),
      ensureShortSnapshotRepository().clearUserSnapshots(userId: normalized),
      ProfilePostsSnapshotRepository.ensure().clearUserSnapshots(
        userId: normalized,
      ),
      ensureRecommendedUsersRepository().invalidate(),
      StoryRepository.ensure().invalidateStoryCachesForUser(
        normalized,
        clearDeletedStories: clearDeletedStories,
      ),
      maybeFindExploreController()?.invalidateViewerScopedContent(
            viewerUserId: normalized,
          ) ??
          Future<void>.value(),
    ]);
  }
}
