import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_content.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_controller.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class PostComments extends StatefulWidget {
  final String postID;
  final String collection;
  final String userID;
  final Function(bool increment)? onCommentCountChange;

  const PostComments({
    super.key,
    required this.postID,
    required this.userID,
    required this.collection,
    this.onCommentCountChange,
  });

  @override
  State<PostComments> createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments> {
  late final PostCommentController controller;
  late final String _controllerTag;
  late final bool _ownsController;
  final user = CurrentUserService.instance;
  final emojis = ["😂", "😍", "🔥", "👏", "👍", "🙏", "😅", "❤️"];
  final textEditingController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'post_comments_${widget.postID}_${identityHashCode(this)}';
    _ownsController =
        PostCommentController.maybeFind(tag: _controllerTag) == null;
    controller = PostCommentController.ensure(
      postID: widget.postID,
      userID: widget.userID,
      collection: widget.collection,
      onCommentCountChange: widget.onCommentCountChange,
      tag: _controllerTag,
    );

    focusNode.requestFocus();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    if (_ownsController &&
        identical(
          PostCommentController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PostCommentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenComments),
      backgroundColor: Colors.transparent,
      // <<< Prevent the layout from resizing when keyboard opens
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              // Main sheet
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    header(),
                    // Comment list or placeholder
                    Expanded(
                      child: controller.list.isNotEmpty
                          ? ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 6, bottom: 4),
                              itemCount: controller.list.length,
                              itemBuilder: (ctx, i) => Column(
                                children: [
                                  PostCommentContent(
                                    model: controller.list[i],
                                    postID: widget.postID,
                                    commentControllerTag: _controllerTag,
                                    isPending: controller.isPendingComment(
                                        controller.list[i].docID),
                                    onReplyTap: (commentId, nickname) {
                                      controller.setReplyTarget(
                                        commentId: commentId,
                                        nickname: nickname,
                                      );
                                      final mention = '@$nickname ';
                                      if (textEditingController.text !=
                                          mention) {
                                        textEditingController.text = mention;
                                        textEditingController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: textEditingController
                                                .text.length,
                                          ),
                                        );
                                      }
                                      focusNode.requestFocus();
                                      setState(() {});
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 58, top: 6, bottom: 6),
                                    child: SizedBox(
                                      height: 1,
                                      child: Divider(
                                        color: Colors.grey.withAlpha(20),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.black54,
                                      size: 30,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'comments.empty'.tr,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                        fontFamily: "Montserrat",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Emoji row
                    Container(
                      color: Colors.grey.withAlpha(0),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: emojis.map((e) {
                          return GestureDetector(
                            onTap: () {
                              textEditingController.text += e;
                              setState(() {});
                            },
                            child:
                                Text(e, style: const TextStyle(fontSize: 24)),
                          );
                        }).toList(),
                      ),
                    ),

                    // Placeholder for space under the input row
                    const SizedBox(height: 72),
                  ],
                ),
              ),

              inputRow()
            ],
          );
        }),
      ),
    );
  }

  Widget header() {
    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
              ),
            ],
          ),
        ),

        // Title
        Text(
          'comments.title'.tr,
          style: TextStyle(
            color: AppColors.textBlack,
            fontSize: 16,
            fontFamily: AppFontFamilies.mbold,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget inputRow() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 14,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              child: SizedBox(
                width: 28,
                height: 28,
                child: user.avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        CupertinoIcons.person_fill,
                        color: Colors.black54,
                        size: 14,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    if (controller.replyingToCommentId.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'comments.replying_to'.trParams({
                                'nickname': controller.replyingToNickname.value,
                              }),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontFamily: "MontserratMedium",
                                fontSize: 11,
                              ),
                            ),
                          ),
                          GestureDetector(
                            key: const ValueKey(
                              IntegrationTestKeys.actionCommentClearReply,
                            ),
                            onTap: () {
                              controller.clearReplyTarget();
                              textEditingController.clear();
                              setState(() {});
                            },
                            child: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 14,
                              color: Colors.black38,
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                  Obx(() {
                    final gifUrl = controller.selectedGifUrl.value.trim();
                    if (gifUrl.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: gifUrl,
                              cacheManager: TurqImageCacheManager.instance,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholderFadeInDuration: Duration.zero,
                              placeholder: (context, _) => Container(
                                width: 76,
                                height: 76,
                                color: const Color(0xFFF5F6F8),
                                child: const Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 76,
                                height: 76,
                                color: const Color(0xFFF5F6F8),
                                child: const Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: controller.clearSelectedGif,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.xmark,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 62),
                      child: TextField(
                        key: const ValueKey(IntegrationTestKeys.inputComment),
                        controller: textEditingController,
                        focusNode: focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(280)
                        ],
                        decoration: InputDecoration(
                          hintText: 'comments.input_hint'.tr,
                          hintStyle: const TextStyle(
                            color: Colors.black45,
                            fontFamily: "MontserratMedium",
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: "MontserratMedium",
                          height: 1.35,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              key: const ValueKey(IntegrationTestKeys.actionCommentGifPicker),
              onTap: () async {
                await controller.pickGif(context);
                if (mounted) {
                  setState(() {});
                }
              },
              child: Container(
                width: 34,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "chat.gif".tr,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontFamily: AppFontFamilies.mbold,
                  ),
                ),
              ),
            ),
            if (textEditingController.text.isNotEmpty ||
                controller.selectedGifUrl.value.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  key: const ValueKey(IntegrationTestKeys.actionCommentSend),
                  onTap: () {
                    controller.yorumYap(
                      context,
                      textEditingController.text,
                      onComplete: () {
                        textEditingController.clear();
                        setState(() {});
                      },
                    );
                    setState(() {});
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
