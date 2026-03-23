part of 'follower_content.dart';

extension _FollowerContentActionsPart on _FollowerContentState {
  void _openProfile() {
    if (widget.userID == _currentUid) return;
    Get.to(() => SocialProfile(userID: widget.userID))!.then((v) {
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
}
