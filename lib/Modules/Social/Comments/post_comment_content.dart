import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/sizes.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Models/post_interactions_models_new.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_content_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';
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
      final currentUID = CurrentUserService.instance.userId;
      final hasLiked =
          currentUID.isNotEmpty && controller.likes.contains(currentUID);
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
              child: SizedBox(
                width: 34,
                height: 34,
                child: CachedUserAvatar(
                  userId: model.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 17,
                  backgroundColor: Colors.grey.shade200,
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
                          child: Text(
                            'comments.sending'.tr,
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
                  if (model.text.trim().isNotEmpty)
                    Text(
                      model.text,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: AppFontFamilies.mregular,
                        height: 1.2,
                      ),
                    ),
                  if (model.imgs.isNotEmpty) ...[
                    6.ph,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: model.imgs.first,
                        cacheManager: TurqImageCacheManager.instance,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        placeholder: (context, _) => Container(
                          width: 140,
                          height: 140,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 140,
                          height: 140,
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                                  ? 'common.unknown_user'.tr
                                  : controller.nickname.value.trim(),
                            );
                          },
                          child: Text(
                            'comments.reply'.tr,
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
                            onTap: () => _confirmDelete(controller),
                            child: Text(
                              'common.delete'.tr,
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
              GestureDetector(
                onTap: controller.toggleLike,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasLiked
                            ? CupertinoIcons.hand_thumbsup_fill
                            : CupertinoIcons.hand_thumbsup,
                        color: hasLiked ? Colors.blueAccent : Colors.black54,
                        size: 18,
                      ),
                      if (controller.likes.isNotEmpty) ...[
                        4.pw,
                        Text(
                          controller.likes.length.toString(),
                          style: TextStyle(
                            color:
                                hasLiked ? Colors.blueAccent : Colors.black54,
                            fontSize: 11,
                            fontFamily: AppFontFamilies.mmedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _confirmDelete(PostCommentContentController controller) {
    noYesAlert(
      title: 'common.delete'.tr,
      message: 'comments.delete_message'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.delete'.tr,
      onYesPressed: () async {
        final ok = await controller.deleteComment();
        if (!ok) {
          AppSnackbar('common.error'.tr, 'comments.delete_failed'.tr);
        }
      },
    );
  }
}
