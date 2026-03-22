import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_controller.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'notification_content_controller.dart';

class NotificationContent extends StatefulWidget {
  final NotificationModel model;
  final VoidCallback? onOpen;
  final VoidCallback? onCardTap;
  const NotificationContent({
    super.key,
    required this.model,
    this.onOpen,
    this.onCardTap,
  });

  @override
  State<NotificationContent> createState() => _NotificationContentState();
}

class _NotificationContentState extends State<NotificationContent> {
  late NotificationContentController controller;
  late String _controllerTag;
  bool _ownsController = false;

  NotificationModel get model => widget.model;
  VoidCallback? get onOpen => widget.onOpen;
  VoidCallback? get onCardTap => widget.onCardTap;

  @override
  void initState() {
    super.initState();
    _bindController();
    _primePostData();
  }

  @override
  void didUpdateWidget(covariant NotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.docID != widget.model.docID ||
        oldWidget.model.postID != widget.model.postID ||
        oldWidget.model.userID != widget.model.userID ||
        oldWidget.model.postType != widget.model.postType) {
      _disposeController();
      _bindController();
    }
    _primePostData();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _bindController() {
    _controllerTag =
        'notification_content_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        NotificationContentController.maybeFind(tag: _controllerTag) == null;
    controller = NotificationContentController.ensure(
      userID: widget.model.userID,
      notification: widget.model,
      tag: _controllerTag,
    );
  }

  void _disposeController() {
    if (_ownsController &&
        identical(
          NotificationContentController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<NotificationContentController>(
        tag: _controllerTag,
        force: true,
      );
    }
  }

  void _primePostData() {
    if (model.postType == kNotificationPostTypePosts &&
        controller.model.value.docID != model.postID) {
      controller.getPostData(model.postID);
    }
  }

  String _buildPrimaryText() {
    final base = model.desc.trim().isEmpty
        ? "notification.item.default_interaction".tr
        : model.desc.trim();
    return base.endsWith(".") ? base : "$base.";
  }

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Container(
            key: ValueKey(IntegrationTestKeys.notificationItem(model.docID)),
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: model.isRead ? Colors.white : const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A000000)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    onOpen?.call();
                    if (onCardTap != null) {
                      onCardTap!.call();
                      return;
                    }
                    if (model.userID != _currentUserId) {
                      Get.to(() => SocialProfile(userID: model.userID));
                    }
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.grey.withAlpha(50))),
                          child: controller.avatarUrl.value != ""
                              ? ClipOval(
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CachedNetworkImage(
                                      imageUrl: controller.avatarUrl.value,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    CupertinoIcons.person_fill,
                                    size: 20,
                                    color: Colors.black45,
                                  ),
                                )),
                      if (!model.isRead)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      onOpen?.call();
                      if (onCardTap != null) {
                        onCardTap!.call();
                      } else {
                        yonlendirme();
                      }
                    },
                    child: Container(
                      color: Colors.white.withAlpha(1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 3,
                            runSpacing: 1,
                            children: [
                              Text(
                                controller.nickname.value,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: model.isRead
                                      ? "MontserratSemiBold"
                                      : "MontserratBold",
                                ),
                              ),
                              RozetContent(size: 14, userID: controller.userID),
                              Text(
                                _buildPrimaryText(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontFamily: model.isRead
                                      ? "MontserratMedium"
                                      : "MontserratSemiBold",
                                  height: 1.15,
                                ),
                              ),
                              Text(
                                "· ${timeAgoMetin(model.timeStamp)}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ],
                          ),
                          if (model.title.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                model.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ),
                          if (controller.targetHint.value.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.arrow_turn_down_right,
                                    size: 12,
                                    color: Colors.black45,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      controller.targetHint.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (controller.model.value.img.isNotEmpty ||
                    controller.model.value.hasPlayableVideo)
                  GestureDetector(
                    onTap: () {
                      onOpen?.call();
                      if (onCardTap != null) {
                        onCardTap!.call();
                      } else {
                        yonlendirme();
                      }
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: SizedBox(
                        width: 44,
                        height: 56,
                        child: CachedNetworkImage(
                          imageUrl: controller.model.value.thumbnail != ""
                              ? controller.model.value.thumbnail
                              : controller.model.value.img.first,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          key: ValueKey(controller.model.value.thumbnail),
                        ),
                      ),
                    ),
                  ),
                if (model.postType == kNotificationPostTypeUser)
                  TextButton(
                    onPressed: controller.followLoading.value
                        ? null
                        : () {
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
                            } else {
                              controller.toggleFollowStatus(model.userID);
                            }
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(74, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: controller.following.value
                          ? Colors.grey.withAlpha(50)
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      child: Center(
                        child: Obx(() {
                          if (controller.followLoading.value) {
                            return SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  controller.following.value
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            );
                          }
                          return Text(
                            controller.following.value
                                ? "following.following".tr
                                : "following.follow".tr,
                            style: TextStyle(
                              color: controller.following.value
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                          );
                        }),
                      ),
                    ),
                  )
              ],
            ),
          )
        ],
      );
    });
  }

  void yonlendirme() async {
    final notifyReader = NotifyReaderController.ensure();
    await notifyReader.openNotification(model);
  }
}
