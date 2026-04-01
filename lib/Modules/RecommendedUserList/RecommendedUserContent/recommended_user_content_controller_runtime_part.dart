part of 'recommended_user_content_controller.dart';

Future<void> _loadRecommendedUserFollowStatus(
  RecommendedUserContentController controller,
) async {
  controller.isFollowing.value = await controller._followRepository.isFollowing(
    controller.userID,
    currentUid: CurrentUserService.instance.effectiveUserId,
    preferCache: true,
  );
}

Future<void> _toggleRecommendedUserFollow(
  RecommendedUserContentController controller,
) async {
  if (controller.followLoading.value) return;
  final wasFollowing = controller.isFollowing.value;
  controller.isFollowing.value = !wasFollowing;
  controller.followLoading.value = true;
  try {
    final outcome = await FollowService.toggleFollowFromLocalState(
      controller.userID,
      assumedFollowing: wasFollowing,
    );
    controller.isFollowing.value = outcome.nowFollowing;
    if (outcome.limitReached) {
      AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
    }
  } catch (_) {
    controller.isFollowing.value = wasFollowing;
  } finally {
    controller.followLoading.value = false;
  }
}
