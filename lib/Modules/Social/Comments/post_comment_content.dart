import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Models/post_interactions_models_new.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_content_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class PostCommentContent extends StatelessWidget {
  PostCommentContent({
    super.key,
    required this.model,
    required this.postID,
    this.isPending = false,
    this.onReplyTap,
  }) {
    Get.put(
      PostCommentContentController(model: model, postID: postID),
      tag: model.docID,
    );
  }

  final PostCommentModel model;
  final String postID;
  final bool isPending;
  final void Function(String commentId, String nickname)? onReplyTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostCommentContentController>(tag: model.docID);
    return Obx(() {
      final currentUID = FirebaseAuth.instance.currentUser?.uid;
      final hasLiked =
          currentUID != null && controller.likes.contains(currentUID);
      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 10, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (model.userID != currentUID) {
                  Get.to(() => SocialProfile(userID: model.userID));
                }
              },
              child: ClipOval(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: controller.avatarUrl.value.isNotEmpty
                      ? Image.network(
                          controller.avatarUrl.value,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                ),
              ),
            ),
            10.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (model.userID != currentUID) {
                            Get.to(() => SocialProfile(userID: model.userID));
                          }
                        },
                        child: Text(
                          controller.nickname.value,
                          style: TextStyle(
                            color: AppColors.textBlack,
                            fontSize: FontSizes.size14,
                            fontFamily: AppFontFamilies.mbold,
                          ),
                        ),
                      ),
                      RozetContent(size: 12, userID: model.userID),
                      12.pw,
                      Text(
                        timeAgoMetin(model.timeStamp),
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          fontFamily: AppFontFamilies.mmedium,
                        ),
                      ),
                      if (isPending) ...[
                        8.pw,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Gönderiliyor',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontFamily: AppFontFamilies.mmedium,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  2.ph,
                  Text(
                    model.text,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mregular,
                      height: 1.2,
                    ),
                  ),
                  4.ph,
                  if (!isPending)
                    Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            onReplyTap?.call(
                              model.docID,
                              controller.nickname.value.trim().isEmpty
                                  ? 'kullanıcı'
                                  : controller.nickname.value.trim(),
                            );
                          },
                          child: Text(
                            'Yanıtla',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontFamily: AppFontFamilies.mmedium,
                            ),
                          ),
                        ),
                        if (model.userID == currentUID) ...[
                          10.pw,
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showActionsMenu(context, controller),
                            child: Text(
                              'Sil',
                              style: TextStyle(
                                color: AppColors.deleteText,
                                fontSize: 12,
                                fontFamily: AppFontFamilies.mmedium,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            if (!isPending)
              SizedBox(
                width: 30,
                child: GestureDetector(
                  onTap: controller.toggleLike,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Kalp yok: referansa göre yalnızca beğeni (thumb) ikonu
                      Icon(
                        hasLiked
                            ? CupertinoIcons.hand_thumbsup_fill
                            : CupertinoIcons.hand_thumbsup,
                        color: hasLiked ? Colors.blueAccent : Colors.black54,
                        size: 18,
                      ),
                      if (controller.likes.isNotEmpty)
                        Text(
                          controller.likes.length.toString(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _showActionsMenu(
      BuildContext context, PostCommentContentController controller) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                AppSnackbar('Bilgi', 'Hikayeye ekleme yakında aktif.');
              },
              child: const Text(
                'Hikayene ekleme yap',
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                final ok = await controller.deleteComment();
                if (popupContext.mounted) {
                  Navigator.pop(popupContext);
                }
                if (!ok) {
                  AppSnackbar('Hata', 'Yorum silinemedi.');
                }
              },
              child: const Text(
                'Sil',
                style: TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 16,
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(popupContext),
            child: const Text(
              'Vazgeç',
              style: TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
