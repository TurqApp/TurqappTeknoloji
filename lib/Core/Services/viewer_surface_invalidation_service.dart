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
      maybeFindFeedSnapshotRepository()
              ?.clearUserSnapshots(userId: normalized) ??
          Future<void>.value(),
      maybeFindShortSnapshotRepository()?.clearUserSnapshots(
            userId: normalized,
          ) ??
          Future<void>.value(),
      ProfilePostsSnapshotRepository.maybeFind()?.clearUserSnapshots(
            userId: normalized,
          ) ??
          Future<void>.value(),
      maybeFindRecommendedUsersRepository()?.invalidate() ??
          Future<void>.value(),
      StoryRepository.maybeFind()?.invalidateStoryCachesForUser(
            normalized,
            clearDeletedStories: clearDeletedStories,
          ) ??
          Future<void>.value(),
      maybeFindExploreController()?.invalidateViewerScopedContent(
            viewerUserId: normalized,
          ) ??
          Future<void>.value(),
    ]);
  }
}
