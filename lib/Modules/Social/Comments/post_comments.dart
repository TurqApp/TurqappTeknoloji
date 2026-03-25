import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_content.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_controller.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'comment_composer_bar.dart';

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
                                    key: ValueKey(
                                      'post_comment_${controller.list[i].docID}',
                                    ),
                                    model: controller.list[i],
                                    postID: widget.postID,
                                    postOwnerUserId: widget.userID,
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
      child: Obx(
        () => CommentComposerBar(
          avatarUrl: user.avatarUrl,
          textController: textEditingController,
          focusNode: focusNode,
          replyingToNickname: controller.replyingToNickname.value,
          selectedGifUrl: controller.selectedGifUrl.value.trim(),
          onTextChanged: (_) => setState(() {}),
          onClearReply: () {
            controller.clearReplyTarget();
            textEditingController.clear();
            setState(() {});
          },
          onPickGif: () async {
            await controller.pickGif(context);
            if (mounted) {
              setState(() {});
            }
          },
          onClearGif: () {
            controller.clearSelectedGif();
            setState(() {});
          },
          onSend: () {
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
        ),
      ),
    );
  }
}
