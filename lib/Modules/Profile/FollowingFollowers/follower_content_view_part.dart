part of 'follower_content.dart';

extension _FollowerContentViewPart on _FollowerContentState {
  void _openProfile() {
    if (widget.userID == _currentUid) return;
    const ProfileNavigationService().openSocialProfile(widget.userID).then((v) {
      controller.followControl(widget.userID);
    });
  }

  Widget _buildFollowAction() {
    if (controller.isFollowed.value == false) {
      return ScaleTap(
        enabled: !controller.followLoading.value,
        onPressed: controller.followLoading.value
            ? null
            : () {
                controller.follow(widget.userID);
              },
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: controller.followLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    "following.follow".tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: "MontserratBold",
                    ),
                  ),
          ),
        ),
      );
    }

    return ScaleTap(
      enabled: !controller.followLoading.value,
      onPressed: controller.followLoading.value
          ? null
          : () {
              noYesAlert(
                title: "following.unfollow_title".tr,
                message: "following.unfollow_body".trParams({
                  'nickname': controller.nickname.value,
                }),
                cancelText: "common.cancel".tr,
                yesText: "following.unfollow_title".tr,
                onYesPressed: () {
                  controller.follow(widget.userID);
                },
              );
            },
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(50),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: controller.followLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  "following.following".tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: "MontserratBold",
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFollowerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openProfile,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Obx(
                () => CachedUserAvatar(
                  userId: widget.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 25,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openProfile,
                      child: Obx(
                        () => Text(
                          controller.nickname.value,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    RozetContent(size: 15, userID: widget.userID),
                  ],
                ),
                GestureDetector(
                  onTap: _openProfile,
                  child: Obx(
                    () => Text(
                      controller.fullname.value,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (widget.userID != _currentUid)
            Obx(() {
              if (!controller.isLoaded.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  _buildFollowAction(),
                ],
              );
            }),
        ],
      ),
    );
  }
}
