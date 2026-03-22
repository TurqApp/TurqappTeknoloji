part of 'notification_content.dart';

extension NotificationContentActionsPart on _NotificationContentState {
  void _handleAvatarTap() {
    onOpen?.call();
    if (onCardTap != null) {
      onCardTap!.call();
      return;
    }
    if (model.userID != _currentUserId) {
      Get.to(() => SocialProfile(userID: model.userID));
    }
  }

  void _handleNotificationTap() {
    onOpen?.call();
    if (onCardTap != null) {
      onCardTap!.call();
    } else {
      _openNotification();
    }
  }

  Future<void> _openNotification() async {
    final notifyReader = NotifyReaderController.ensure();
    await notifyReader.openNotification(model);
  }

  Widget _buildFollowButton() {
    return TextButton(
      onPressed: controller.followLoading.value ? null : _toggleFollow,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(74, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: controller.following.value
            ? Colors.grey.withAlpha(50)
            : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Center(
          child: Obx(() {
            if (controller.followLoading.value) {
              return SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    controller.following.value ? Colors.black : Colors.white,
                  ),
                ),
              );
            }
            return Text(
              controller.following.value
                  ? "following.following".tr
                  : "following.follow".tr,
              style: TextStyle(
                color: controller.following.value ? Colors.black : Colors.white,
                fontSize: 12,
                fontFamily: "MontserratMedium",
              ),
            );
          }),
        ),
      ),
    );
  }

  void _toggleFollow() {
    if (controller.following.value) {
      noYesAlert(
        title: "following.unfollow_title".tr,
        message: "following.unfollow_body".trParams({
          'nickname': controller.nickname.value,
        }),
        cancelText: "common.cancel".tr,
        yesText: "following.following".tr,
        onYesPressed: () {
          controller.toggleFollowStatus(model.userID);
        },
      );
      return;
    }

    controller.toggleFollowStatus(model.userID);
  }
}
