part of 'antreman_comments.dart';

extension _AntremanCommentsContentPart on _AntremanCommentsState {
  Widget _buildAntremanCommentsSheet(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.95;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: AppSheetHeader(title: 'training.comments_title'.tr),
            ),
            Expanded(child: _buildCommentsList()),
            _buildCommentComposer(),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.comments.isEmpty) {
        return const AppStateView.loading(title: '');
      }
      if (controller.comments.isEmpty) {
        return AppStateView.empty(title: "training.no_comments".tr);
      }
      return ListView.builder(
        controller: controller.scrollController,
        itemCount: controller.comments.length,
        itemBuilder: (context, index) {
          final comment = controller.comments[index];
          return _buildCommentItem(context, comment);
        },
      );
    });
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    final GlobalKey commentKey = GlobalKey();
    final userInfo = controller.userInfoCache[comment.userID] ??
        {
          'avatarUrl': '',
          'displayName': 'training.unknown_user'.tr,
          'nickname': 'training.unknown_user'.tr,
        };
    final userImage = (userInfo['avatarUrl'] ?? '').toString();
    final userName = (userInfo['displayName'] ??
            userInfo['username'] ??
            userInfo['nickname'] ??
            'training.unknown_user'.tr)
        .toString();
    controller.fetchUserInfo(comment.userID);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 10),
          key: commentKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CachedUserAvatar(
                  imageUrl: userImage,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: TextStyles.bold20Black.copyWith(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.getTimeAgo(comment.timeStamp),
                          style: TextStyles.textFieldTitle.copyWith(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      comment.metin,
                      style: TextStyles.textFieldTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    if (comment.photoUrl != null)
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => FullScreenImageViewer(
                              imageUrl: comment.photoUrl!,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: comment.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CupertinoActivityIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            controller.replyingToCommentDocID.value =
                                comment.docID;
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.grey,
                          ),
                          child: Text(
                            "training.reply".tr,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Obx(() {
                          final replyList =
                              controller.replies[comment.docID] ?? [];
                          if (replyList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final isVisible =
                              controller.repliesVisible[comment.docID] ?? false;
                          return TextButton(
                            onPressed: () => controller.toggleRepliesVisibility(
                              comment.docID,
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: Colors.grey,
                            ),
                            child: Text(
                              isVisible
                                  ? "training.hide_replies".tr
                                  : "training.view_replies".trParams({
                                      'count': replyList.length.toString(),
                                    }),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCommentActions(context, comment, commentKey),
            ],
          ),
        ),
        _buildReplyList(context, comment),
      ],
    );
  }

  Widget _buildCommentActions(
    BuildContext context,
    Comment comment,
    GlobalKey commentKey,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                comment.begeniler.contains(controller.userID)
                    ? AppIcons.liked
                    : AppIcons.like,
                color: Colors.black,
              ),
              onPressed: () =>
                  controller.toggleLikeComment(comment.docID, comment),
            ),
            Text(
              "${comment.begeniler.length}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            CupertinoIcons.ellipsis_vertical,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            final position = getWidgetPosition(commentKey);
            if (comment.userID == controller.userID) {
              _showPullDownButton(
                  context,
                  [
                    PullDownMenuItem(
                      title: 'training.edit'.tr,
                      icon: CupertinoIcons.create_solid,
                      iconColor: Colors.black,
                      onTap: () {
                        controller.startEditingComment(
                          comment.docID,
                          comment.metin,
                        );
                      },
                    ),
                    PullDownMenuItem(
                      title: 'common.delete'.tr,
                      icon: CupertinoIcons.delete_simple,
                      iconColor: Colors.red,
                      onTap: () => controller.deleteComment(comment.docID),
                    ),
                  ],
                  position);
            } else {
              _showPullDownButton(
                  context,
                  [
                    PullDownMenuItem(
                      title: 'training.report'.tr,
                      icon: CupertinoIcons.question,
                      iconColor: Colors.black,
                      onTap: null,
                    ),
                  ],
                  position);
            }
          },
        ),
      ],
    );
  }

  Widget _buildReplyList(BuildContext context, Comment comment) {
    return Obx(() {
      final replyList = controller.replies[comment.docID] ?? [];
      if (replyList.isEmpty) return const SizedBox.shrink();
      final isVisible = controller.repliesVisible[comment.docID] ?? false;
      if (!isVisible) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: replyList
              .map((reply) => _buildReplyItem(context, comment, reply))
              .toList(),
        ),
      );
    });
  }

  Widget _buildReplyItem(BuildContext context, Comment parent, Reply reply) {
    final GlobalKey replyKey = GlobalKey();
    final replyUserInfo = controller.userInfoCache[reply.userID] ??
        {
          'avatarUrl': '',
          'displayName': 'training.unknown_user'.tr,
          'nickname': 'training.unknown_user'.tr,
        };
    final replyUserImage = (replyUserInfo['avatarUrl'] ?? '').toString();
    final replyUserName = (replyUserInfo['displayName'] ??
            replyUserInfo['username'] ??
            replyUserInfo['nickname'] ??
            'training.unknown_user'.tr)
        .toString();
    controller.fetchUserInfo(reply.userID);

    return Container(
      key: replyKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CachedUserAvatar(
              imageUrl: replyUserImage,
              radius: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      replyUserName,
                      style: TextStyles.textFieldTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.getTimeAgo(reply.timeStamp),
                      style: TextStyles.textFieldTitle.copyWith(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.metin,
                  style: TextStyles.textFieldTitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                if (reply.photoUrl != null)
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => FullScreenImageViewer(imageUrl: reply.photoUrl!),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: reply.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CupertinoActivityIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      reply.begeniler.contains(controller.userID)
                          ? CupertinoIcons.hand_thumbsup_fill
                          : CupertinoIcons.hand_thumbsup,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () => controller.toggleLikeReply(
                      parent.docID,
                      reply.docID,
                      reply,
                    ),
                  ),
                  Text(
                    "${reply.begeniler.length}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () {
                  final position = getWidgetPosition(replyKey);
                  if (reply.userID == controller.userID) {
                    _showPullDownButton(
                        context,
                        [
                          PullDownMenuItem(
                            title: 'training.edit'.tr,
                            onTap: () {
                              controller.startEditingReply(
                                parent.docID,
                                reply.docID,
                                reply.metin,
                              );
                            },
                          ),
                          PullDownMenuItem(
                            title: 'common.delete'.tr,
                            onTap: () => controller.deleteReply(
                                parent.docID, reply.docID),
                          ),
                        ],
                        position);
                  } else {
                    _showPullDownButton(
                        context,
                        [
                          PullDownMenuItem(
                            title: 'training.report'.tr,
                            onTap: null,
                          ),
                        ],
                        position);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPullDownButton(
    BuildContext context,
    List<PullDownMenuItem> items,
    Rect position,
  ) {
    showPullDownMenu(context: context, items: items, position: position);
  }
}
