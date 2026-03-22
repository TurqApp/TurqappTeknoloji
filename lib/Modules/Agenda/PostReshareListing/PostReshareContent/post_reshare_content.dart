import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Agenda/PostReshareListing/post_reshare_listing_controller.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_view.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class PostReshareContent extends StatefulWidget {
  const PostReshareContent({
    super.key,
    required this.item,
  });

  final ReshareUserItem item;

  @override
  State<PostReshareContent> createState() => _PostReshareContentState();
}

class _PostReshareContentState extends State<PostReshareContent> {
  late final String _followTag;
  FollowerController? _followController;

  ReshareUserItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _followTag =
        'post_reshare_follow_${item.userID}_${DateTime.now().microsecondsSinceEpoch}';
    if (!isCurrentUserId(item.userID)) {
      _followController = FollowerController.ensure(tag: _followTag);
      _refreshFollowState();
    }
  }

  @override
  void dispose() {
    if (identical(
      FollowerController.maybeFind(tag: _followTag),
      _followController,
    )) {
      Get.delete<FollowerController>(tag: _followTag, force: true);
    }
    super.dispose();
  }

  Future<void> _refreshFollowState() async {
    if (_followController == null) return;
    await _followController!.getData(item.userID);
    await _followController!.followControl(item.userID);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = isCurrentUserId(item.userID);
    final displayNickname = item.nickname.trim().isEmpty
        ? item.fullName.trim()
        : item.nickname.trim();
    final displayName =
        item.fullName.trim().isEmpty ? displayNickname : item.fullName.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ScaleTap(
              onPressed: () => _openProfile(isMe),
              child: Row(
                children: [
                  CachedUserAvatar(
                    userId: item.userID,
                    imageUrl: item.avatarUrl,
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayNickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                            RozetContent(
                              size: 15,
                              userID: item.userID,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 12),
            if (_followController != null)
              Obx(() => _followButton(_followController!)),
          ],
        ],
      ),
    );
  }

  Widget _followButton(FollowerController controller) {
    final isFollowing = controller.isFollowed.value;
    final isLoading = controller.followLoading.value;

    return ScaleTap(
      enabled: !isLoading,
      onPressed: isLoading
          ? null
          : () {
              if (!isFollowing) {
                controller.follow(item.userID);
                return;
              }
              noYesAlert(
                title: 'profile.unfollow_title'.tr,
                message: 'profile.unfollow_body'.trParams({
                  'nickname':
                      item.nickname.isEmpty ? item.fullName : item.nickname,
                }),
                cancelText: 'common.cancel'.tr,
                yesText: 'profile.unfollow_confirm'.tr,
                onYesPressed: () {
                  controller.follow(item.userID);
                },
              );
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 98),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFollowing ? Colors.grey.withAlpha(40) : Colors.black,
          borderRadius: const BorderRadius.all(Radius.circular(11)),
          border: Border.all(
            color: isFollowing ? Colors.grey.withAlpha(40) : Colors.black,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFollowing ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                isFollowing ? 'following.following'.tr : 'following.follow'.tr,
                style: TextStyle(
                  color: isFollowing ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
      ),
    );
  }

  Future<void> _openProfile(bool isMe) async {
    if (isMe) {
      await Get.to(() => const ProfileView());
      return;
    }
    await Get.to(() => SocialProfile(userID: item.userID));
    await _refreshFollowState();
  }
}
