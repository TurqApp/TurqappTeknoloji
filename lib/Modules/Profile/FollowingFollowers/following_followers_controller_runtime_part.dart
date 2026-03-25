part of 'following_followers_controller.dart';

extension _FollowingFollowersControllerRuntimeX
    on FollowingFollowersController {
  bool get isSelf => isCurrentUserId(userId);
}

class _FollowingFollowersControllerRuntimePart {
  static void onInit(FollowingFollowersController controller) {
    controller._loadNicknameCached();
    final followersCached = controller._restoreRelationListCache(
      isFollowers: true,
    );
    final followingsCached = controller._restoreRelationListCache(
      isFollowers: false,
    );
    unawaited(
      controller.getFollowers(
        initial: true,
        forceServer: followersCached,
      ),
    );
    unawaited(
      controller.getFollowing(
        initial: true,
        forceServer: followingsCached,
      ),
    );
    unawaited(
      _reconcileInitialRelations(
        controller,
        followersCached: followersCached,
        followingsCached: followingsCached,
      ),
    );
  }

  static Future<void> _reconcileInitialRelations(
    FollowingFollowersController controller, {
    required bool followersCached,
    required bool followingsCached,
  }) async {
    await controller.getCounters();
    final expectedFollowers = controller.takipciCounter.value.clamp(
      0,
      ReadBudgetRegistry.followRelationPreviewInitialLimit,
    );
    if ((controller.takipciCounter.value > 0 &&
            controller.takipciler.isEmpty &&
            !controller.isLoadingFollowers) ||
        (followersCached &&
            !controller.isLoadingFollowers &&
            controller.takipciler.length < expectedFollowers)) {
      await controller.getFollowers(initial: true, forceServer: true);
    }
    final expectedFollowing = controller.takipedilenCounter.value.clamp(
      0,
      ReadBudgetRegistry.followRelationPreviewInitialLimit,
    );
    if (controller.takipedilenCounter.value > 0 &&
        controller.takipEdilenler.isEmpty &&
        !controller.isLoadingFollowing) {
      await controller.getFollowing(initial: true, forceServer: true);
    }
    if (followingsCached &&
        !controller.isLoadingFollowing &&
        controller.takipEdilenler.length < expectedFollowing) {
      await controller.getFollowing(initial: true, forceServer: true);
    }
  }

  static void onClose(FollowingFollowersController controller) {
    controller.pageController.dispose();
    controller.searchTakipciController.dispose();
    controller.searchTakipEdilenController.dispose();
  }
}
