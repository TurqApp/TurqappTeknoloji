import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FollowerContent extends StatefulWidget {
  final String userID;
  @override
  final ValueKey key;

  const FollowerContent({required this.userID, required this.key})
      : super(key: key);

  @override
  State<FollowerContent> createState() => _FollowerContentState();
}

class _FollowerContentState extends State<FollowerContent> {
  late final String _followTag;
  late final FollowerController controller;

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _followTag = 'follower_content_${widget.userID}_${identityHashCode(this)}';
    controller = FollowerController.ensure(tag: _followTag);
    controller.getData(widget.userID);
    if (widget.userID != _currentUid) {
      controller.followControl(widget.userID);
    }
  }

  @override
  void dispose() {
    final existing = FollowerController.maybeFind(tag: _followTag);
    if (identical(existing, controller)) {
      Get.delete<FollowerController>(tag: _followTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.userID != _currentUid) {
                  Get.to(() => SocialProfile(userID: widget.userID))!.then((v) {
                    controller.followControl(widget.userID);
                  });
                }
              },
              child: ClipOval(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: controller.avatarUrl.value != ""
                      ? CachedNetworkImage(
                          imageUrl: controller.avatarUrl.value,
                          fit: BoxFit.cover,
                          memCacheHeight: 400,
                        )
                      : Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
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
                        onTap: () {
                          Get.to(() => SocialProfile(userID: widget.userID))!
                              .then((v) {
                            controller.followControl(widget.userID);
                          });
                        },
                        child: Text(
                          controller.nickname.value,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RozetContent(size: 15, userID: widget.userID),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => SocialProfile(userID: widget.userID))!
                          .then((v) {
                        controller.followControl(widget.userID);
                      });
                    },
                    child: Text(
                      controller.fullname.value,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 12,
            ),
            if (controller.isLoaded.value && widget.userID != _currentUid)
              Column(
                children: [
                  if (controller.isFollowed.value == false)
                    ScaleTap(
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
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
                    )
                  else
                    ScaleTap(
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
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: controller.followLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
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
                    )
                ],
              )
          ],
        ),
      );
    });
  }
}
