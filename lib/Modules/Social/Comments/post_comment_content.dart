import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
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

class PostCommentContent extends StatefulWidget {
  const PostCommentContent({
    super.key,
    required this.model,
    required this.postID,
    required this.postOwnerUserId,
    required this.commentControllerTag,
    this.isPending = false,
    this.onReplyTap,
  });

  final PostCommentModel model;
  final String postID;
  final String postOwnerUserId;
  final String commentControllerTag;
  final bool isPending;
  final void Function(String commentId, String nickname)? onReplyTap;

  @override
  State<PostCommentContent> createState() => _PostCommentContentState();
}

class _PostCommentContentState extends State<PostCommentContent> {
  late final PostCommentContentController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  PostCommentModel get model => widget.model;
  String get postID => widget.postID;
  String get postOwnerUserId => widget.postOwnerUserId;
  bool get isPending => widget.isPending;
  String get commentControllerTag => widget.commentControllerTag;
  void Function(String commentId, String nickname)? get onReplyTap =>
      widget.onReplyTap;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'post_comment_content_${widget.postID}_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        PostCommentContentController.maybeFind(tag: _controllerTag) == null;
    controller = PostCommentContentController.ensure(
      model: widget.model,
      postID: widget.postID,
      commentControllerTag: widget.commentControllerTag,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          PostCommentContentController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PostCommentContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userService = CurrentUserService.instance;
    final currentUID = _resolveViewerUid(userService);
    return Padding(
      key: ValueKey(IntegrationTestKeys.commentItem(model.docID)),
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
              child: Obx(
                () => CachedUserAvatar(
                  userId: model.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 17,
                  backgroundColor: Colors.grey.shade200,
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
                      child: Obx(
                        () => Text(
                          controller.nickname.value,
                          style: TextStyle(
                            color: AppColors.textBlack,
                            fontSize: FontSizes.size14,
                            fontFamily: AppFontFamilies.mbold,
                          ),
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
                  Obx(() {
                    final viewerUid = _resolveViewerUid(userService);
                    final canDeleteComment = viewerUid.isNotEmpty &&
                        (model.userID == viewerUid ||
                            postOwnerUserId.trim() == viewerUid);
                    return Row(
                      children: [
                        GestureDetector(
                          key: ValueKey(
                            IntegrationTestKeys.commentReplyButton(model.docID),
                          ),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final nickname = controller.nickname.value.trim();
                            onReplyTap?.call(
                              model.docID,
                              nickname.isEmpty
                                  ? 'common.unknown_user'.tr
                                  : nickname,
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
                        if (canDeleteComment) ...[
                          10.pw,
                          GestureDetector(
                            key: ValueKey(
                              IntegrationTestKeys.commentDeleteButton(
                                model.docID,
                              ),
                            ),
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
                    );
                  }),
                Obx(() {
                  if (controller.replies.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final viewerUid = _resolveViewerUid(userService);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: controller.replies
                          .map(
                            (reply) => _buildReplyItem(
                              reply,
                              viewerUid: viewerUid,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  );
                }),
              ],
            ),
          ),
          if (!isPending)
            Obx(() {
              final viewerUid = _resolveViewerUid(userService);
              final hasLiked = viewerUid.isNotEmpty &&
                  controller.likes.contains(viewerUid);
              return GestureDetector(
                key: ValueKey(
                  IntegrationTestKeys.commentLikeButton(model.docID),
                ),
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
              );
            }),
        ],
      ),
    );
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

  Widget _buildReplyItem(
    SubCommentModel reply, {
    required String viewerUid,
  }) {
    final replyNickname =
        controller.replyNicknames[reply.userID]?.trim().isNotEmpty == true
            ? controller.replyNicknames[reply.userID]!.trim()
            : 'common.unknown_user'.tr;
    final replyAvatarUrl =
        controller.replyAvatarUrls[reply.userID]?.trim() ?? '';
    final canDeleteReply = viewerUid.isNotEmpty &&
        (reply.userID == viewerUid || postOwnerUserId.trim() == viewerUid);
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CachedUserAvatar(
              userId: reply.userID,
              imageUrl: replyAvatarUrl.isNotEmpty ? replyAvatarUrl : null,
              radius: 13,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          8.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        replyNickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontSize: 12,
                          fontFamily: AppFontFamilies.mbold,
                        ),
                      ),
                    ),
                    Text(
                      timeAgoMetin(reply.timeStamp),
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                        fontFamily: AppFontFamilies.mmedium,
                      ),
                    ),
                  ],
                ),
                2.ph,
                if (reply.text.trim().isNotEmpty)
                  Text(
                    reply.text,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontFamily: AppFontFamilies.mregular,
                      height: 1.2,
                    ),
                  ),
                if (canDeleteReply) ...[
                  4.ph,
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _confirmReplyDelete(reply),
                    child: Text(
                      'common.delete'.tr,
                      style: TextStyle(
                        color: AppColors.deleteText,
                        fontSize: 11,
                        fontFamily: AppFontFamilies.mmedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReplyDelete(SubCommentModel reply) {
    noYesAlert(
      title: 'common.delete'.tr,
      message: 'comments.delete_message'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.delete'.tr,
      onYesPressed: () async {
        final ok = await controller.deleteReply(reply.docID);
        if (!ok) {
          AppSnackbar('common.error'.tr, 'comments.delete_failed'.tr);
        }
      },
    );
  }

  String _resolveViewerUid(CurrentUserService userService) {
    final cachedUid = (userService.currentUserRx.value?.userID ?? '').trim();
    if (cachedUid.isNotEmpty) return cachedUid;
    return userService.authUserId.trim();
  }
}
