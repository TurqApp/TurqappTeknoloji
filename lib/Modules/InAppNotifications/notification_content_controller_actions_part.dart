part of 'notification_content_controller.dart';

extension _NotificationContentControllerActionsPart
    on NotificationContentController {
  Future<void> toggleFollowStatus(String userID) async {
    if (followLoading.value) return;
    final wasFollowing = following.value;
    following.value = !wasFollowing;
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      following.value = outcome.nowFollowing;
      if (outcome.limitReached) {
        AppSnackbar(
          'following.limit_title'.tr,
          'following.limit_body'.tr,
        );
      }
    } catch (_) {
      following.value = wasFollowing;
    } finally {
      followLoading.value = false;
    }
  }
}
