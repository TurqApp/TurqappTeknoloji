part of 'antreman_comments.dart';

extension _AntremanCommentsInputPart on _AntremanCommentsState {
  Widget _buildCommentComposer() {
    return Obx(() {
      final userInfo =
          controller.userInfoCache[controller.userID] ??
          {
            'avatarUrl': '',
            'displayName': 'training.unknown_user'.tr,
            'nickname': 'training.unknown_user'.tr,
          };
      final userImage = (userInfo['avatarUrl'] ?? '').toString();
      controller.fetchUserInfo(controller.userID);

      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 1,
            decoration: const BoxDecoration(color: Colors.grey),
          ),
          _buildEmojiRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundImage: userImage.isNotEmpty
                      ? CachedNetworkImageProvider(userImage)
                      : null,
                  child: userImage.isEmpty
                      ? const Icon(CupertinoIcons.person, size: 15)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComposerContextLabel(),
                      _buildSelectedImagePreview(),
                      _buildComposerInputRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmojiRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildEmojiButton("❤️"),
        _buildEmojiButton("🙌🏻"),
        _buildEmojiButton("🔥"),
        _buildEmojiButton("😎"),
        _buildEmojiButton("👍🏻"),
        _buildEmojiButton("😍"),
        _buildEmojiButton("🥳"),
      ],
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return IconButton(
      icon: Text(emoji, style: const TextStyle(fontSize: 24)),
      onPressed: () {
        controller.commentController.text += emoji;
      },
    );
  }

  Widget _buildComposerContextLabel() {
    if (controller.replyingToCommentDocID.value.isEmpty &&
        controller.editingCommentDocID.value.isEmpty &&
        controller.editingReplyDocID.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          if (controller.replyingToCommentDocID.value.isNotEmpty &&
              controller.editingCommentDocID.value.isEmpty &&
              controller.editingReplyDocID.value.isEmpty)
            Obx(() {
              final replyingComment = controller.comments.firstWhere(
                (c) => c.docID == controller.replyingToCommentDocID.value,
                orElse: () => Comment(
                  docID: '',
                  userID: '',
                  metin: '',
                  timeStamp: 0,
                  begeniler: [],
                ),
              );
              final replyUserInfo =
                  controller.userInfoCache[replyingComment.userID] ??
                  {
                    'avatarUrl': '',
                    'displayName': 'training.unknown_user'.tr,
                    'nickname': 'training.unknown_user'.tr,
                  };
              final replyUserName =
                  (replyUserInfo['displayName'] ??
                          replyUserInfo['username'] ??
                          replyUserInfo['nickname'] ??
                          'training.unknown_user'.tr)
                      .toString();
              controller.fetchUserInfo(replyingComment.userID);
              return Text(
                'training.reply_to_user'.trParams({'name': replyUserName}),
                style: TextStyles.textFieldTitle.copyWith(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              );
            }),
          if (controller.editingCommentDocID.value.isNotEmpty ||
              controller.editingReplyDocID.value.isNotEmpty)
            Text(
              'training.edit'.tr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const Spacer(),
          if (controller.editingCommentDocID.value.isNotEmpty ||
              controller.editingReplyDocID.value.isNotEmpty)
            TextButton(
              onPressed: () => controller.cancelEditing(),
              child: Text(
                'training.cancel'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Obx(() {
      if (controller.selectedImage.value != null &&
          controller.editingCommentDocID.value.isEmpty &&
          controller.editingReplyDocID.value.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Stack(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      controller.selectedImage.value!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => controller.selectedImage.value = null,
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildComposerInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              focusNode: controller.focusNode,
              controller: controller.commentController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: _composerHintText,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(0),
              ),
            ),
          ),
        ),
        _buildSendButton(),
        _buildMediaMenuButton(),
      ],
    );
  }

  String get _composerHintText {
    if (controller.replyingToCommentDocID.value.isEmpty &&
        controller.editingCommentDocID.value.isEmpty &&
        controller.editingReplyDocID.value.isEmpty) {
      return 'training.write_hint'.tr;
    }
    if (controller.editingCommentDocID.value.isNotEmpty ||
        controller.editingReplyDocID.value.isNotEmpty) {
      return 'training.edit_comment_hint'.tr;
    }
    return 'training.write_hint'.tr;
  }

  Widget _buildSendButton() {
    return Obx(() {
      return (controller.isTextFieldNotEmpty.value ||
              controller.selectedImage.value != null)
          ? IconButton(
              icon: const Icon(
                CupertinoIcons.paperplane_fill,
                color: Colors.black,
              ),
              onPressed: _handleSubmit,
            )
          : const SizedBox.shrink();
    });
  }

  void _handleSubmit() {
    if (controller.editingCommentDocID.value.isNotEmpty) {
      controller.editComment(
        controller.editingCommentDocID.value,
        controller.commentController.text,
      );
    } else if (controller.editingReplyDocID.value.isNotEmpty) {
      controller.editReply(
        controller.replyingToCommentDocID.value,
        controller.editingReplyDocID.value,
        controller.commentController.text,
      );
    } else if (controller.replyingToCommentDocID.value.isEmpty) {
      controller.addComment();
    } else {
      controller.addReply(controller.replyingToCommentDocID.value);
    }
  }

  Widget _buildMediaMenuButton() {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          title: 'training.pick_from_gallery'.tr,
          icon: CupertinoIcons.photo,
          onTap: () async {
            await controller.pickImageFromGallery();
          },
        ),
        PullDownMenuItem(
          title: 'training.take_photo'.tr,
          icon: CupertinoIcons.photo_camera,
          onTap: () async {
            await controller.pickImageFromCamera();
          },
        ),
      ],
      buttonBuilder: (context, showMenu) => IconButton(
        icon: const Icon(CupertinoIcons.add_circled, color: Colors.black),
        onPressed:
            controller.editingCommentDocID.value.isEmpty &&
                controller.editingReplyDocID.value.isEmpty
            ? showMenu
            : null,
      ),
    );
  }
}
