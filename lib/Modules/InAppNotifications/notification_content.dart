import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_controller.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

import 'notification_content_controller.dart';

class NotificationContent extends StatelessWidget {
  final NotificationModel model;
  final VoidCallback? onOpen;
  final VoidCallback? onCardTap;
  late final NotificationContentController controller;
  NotificationContent({
    super.key,
    required this.model,
    this.onOpen,
    this.onCardTap,
  }) {
    controller = Get.put(
      NotificationContentController(
        userID: model.userID,
        notification: model,
      ),
      tag: model.docID,
    );
  }

  String _buildPrimaryText() {
    final base = model.desc.trim().isEmpty
        ? "senin gönderinle etkileşime geçti."
        : model.desc.trim();
    return base.endsWith(".") ? base : "$base.";
  }

  @override
  Widget build(BuildContext context) {
    if (model.postType == "Posts" &&
        controller.model.value.docID != model.postID) {
      controller.getPostData(model.postID);
    }
    // FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("Bildirimler").doc(model.docID).update(
    //     {
    //       "postID" : "f4932ae6-19e8-4633-91bf-9f0d5d35f388"
    //     });
    return Obx(() {
      return Column(
        children: [
          Container(
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
                    if (model.userID !=
                        FirebaseAuth.instance.currentUser!.uid) {
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
                if (model.postType == "User")
                  TextButton(
                    onPressed: controller.followLoading.value
                        ? null
                        : () {
                            if (controller.following.value) {
                              noYesAlert(
                                title: "Takibi Bırak",
                                message:
                                    "${controller.nickname.value} kullanıcısını takipten çıkmak istediğinizden emin misiniz?",
                                cancelText: "Vazgeç",
                                yesText: "Takibi Bırak",
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
                                ? "Takibi Bırak"
                                : "Takip Et",
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
    final notifyReader = Get.isRegistered<NotifyReaderController>()
        ? Get.find<NotifyReaderController>()
        : Get.put(NotifyReaderController());
    await notifyReader.openNotification(model);
  }
}
