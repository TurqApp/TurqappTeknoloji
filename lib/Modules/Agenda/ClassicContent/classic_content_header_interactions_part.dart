part of 'classic_content.dart';

extension ClassicContentHeaderInteractionsPart on _ClassicContentState {
  Widget reshareButton() {
    return Obx(() {
      final visibility = widget.model.paylasimVisibility;
      final isOwner = _currentUid == widget.model.userID;
      final currentUserId = _currentUid;
      final canReshare = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final isCurrentUsersReshareCard = currentUserId.isNotEmpty &&
          widget.reshareUserID?.trim() == currentUserId;
      final isReshared =
          controller.yenidenPaylasildiMi.value || isCurrentUsersReshareCard;
      final displayColor =
          isReshared ? Colors.green : _ClassicContentState._actionColor;

      return PullDownButton(
        itemBuilder: (context) => [
          PullDownMenuItem(
            onTap: canReshare ? _runSimpleReshare : null,
            title: isReshared ? 'post.undo_reshare'.tr : 'common.reshare'.tr,
            icon: Icons.repeat,
          ),
          PullDownMenuItem(
            onTap: canReshare ? _openQuoteComposer : null,
            title: 'common.quote'.tr,
            icon: CupertinoIcons.quote_bubble,
          ),
        ],
        buttonBuilder: (context, showMenu) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: canReshare ? _openReshareUsersSheet : null,
          child: AnimatedActionButton(
            enabled: canReshare,
            semanticsLabel: 'common.reshare'.tr,
            onTap: canReshare ? showMenu : null,
            child: _iconAction(
              icon:
                  _ClassicContentState._actionStyle.reshareIcon ?? Icons.repeat,
              iconSize: _ClassicContentState._actionStyle.iconSize,
              color: displayColor,
              label: NumberFormatter.format(controller.retryCount.value),
              labelColor: displayColor,
            ),
          ),
        ),
      );
    });
  }

  Widget commentButton(BuildContext context) {
    return Obx(() {
      final visibility = widget.model.yorumVisibility;
      final isOwner = _currentUid == widget.model.userID;
      final canInteract = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      const displayColor = _ClassicContentState._actionColor;

      return AnimatedActionButton(
        key:
            ValueKey(IntegrationTestKeys.feedCommentButton(widget.model.docID)),
        enabled: canInteract,
        semanticsLabel: 'common.comments'.tr,
        onTap: canInteract
            ? () {
                _suspendClassicFeedForRoute();
                controller.showPostCommentsBottomSheet(
                  onClosed: _restoreClassicFeedCenter,
                );
              }
            : null,
        child: _iconAction(
          icon: CupertinoIcons.bubble_left,
          color: displayColor,
          label: NumberFormatter.format(controller.commentCount.value),
          labelColor: displayColor,
          iconSize: 19,
        ),
      );
    });
  }

  Widget likeButton() {
    return Obx(() {
      final isLiked =
          _currentUid.isNotEmpty && controller.likes.contains(_currentUid);
      final displayLikeCount = controller.likeCount.value <= 0 && isLiked
          ? 1
          : controller.likeCount.value;
      final displayColor =
          isLiked ? Colors.blueAccent : _ClassicContentState._actionColor;

      return AnimatedActionButton(
        key: ValueKey(IntegrationTestKeys.feedLikeButton(widget.model.docID)),
        enabled: true,
        semanticsLabel: 'common.likes'.tr,
        onTap: controller.like,
        onLongPress: _openLikeListing,
        longPressDuration: const Duration(milliseconds: 220),
        hitTestBehavior: HitTestBehavior.translucent,
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
        child: _iconAction(
          icon: isLiked
              ? CupertinoIcons.hand_thumbsup_fill
              : CupertinoIcons.hand_thumbsup,
          iconSize: 19,
          color: displayColor,
          label: NumberFormatter.format(displayLikeCount),
          labelColor: displayColor,
          leadingTransformOffsetY: -2,
        ),
      );
    });
  }

  void _openLikeListing() {
    _suspendClassicFeedForRoute();
    Get.bottomSheet(
      PostLikeListing(postID: widget.model.docID),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      _restoreClassicFeedCenter();
    });
  }

  Widget saveButton() {
    return Obx(() {
      final isSaved = controller.saved.value == true;
      final displayColor =
          isSaved ? Colors.orange : _ClassicContentState._actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'common.save'.tr,
        onTap: controller.save,
        child: _iconAction(
          icon:
              isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
          iconSize: 19,
          color: displayColor,
          label: NumberFormatter.format(controller.savedCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget statButton() {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Obx(() => SizedBox(
            height: AnimatedActionButton.actionHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: AnimatedActionButton.actionHeight,
                  child: Center(
                    child: Icon(Icons.bar_chart,
                        color: _ClassicContentState._actionColor, size: 22),
                  ),
                ),
                2.pw,
                SizedBox(
                  height: AnimatedActionButton.actionHeight,
                  child: Center(
                    child: Text(
                      NumberFormatter.format(controller.statsCount.value),
                      style: const TextStyle(
                        color: _ClassicContentState._actionColor,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget sendButton() {
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'common.share_external'.tr,
      onTap: _shareExternally,
      child: SizedBox(
        width: 20,
        height: AnimatedActionButton.actionHeight,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: Icon(
              CupertinoIcons.share_up,
              color: _ClassicContentState._actionColor,
              size: _ClassicContentState._actionStyle.sendIconSize,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareExternally() async {
    await ShareActionGuard.run(() async {
      final previewImage = widget.model.thumbnail.trim().isNotEmpty
          ? widget.model.thumbnail.trim()
          : (widget.model.img.isNotEmpty
              ? widget.model.img.first.trim()
              : null);
      final url = ShortLinkService().getPostPublicUrlForImmediateShare(
        postId: widget.model.docID,
        desc: widget.model.metin,
        imageUrl: previewImage,
      );
      await ShareLinkService.shareUrl(
        url: url,
        title: 'post.share_title'.tr,
        subject: 'post.share_title'.tr,
      );
    });
  }

  Widget gonderiGizlendi(BuildContext context) {
    return PostHiddenMessage(
      onUndo: () {
        controller.gizlemeyiGeriAl();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return PostArchivedMessage(
      onUndo: () {
        controller.arsivdenCikart();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return const PostDeletedMessage();
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    String? label,
    Color? labelColor,
    double? iconSize,
    double leadingTransformOffsetY = 0,
  }) {
    return _actionContent(
      leading: Transform.translate(
        offset: Offset(0, leadingTransformOffsetY),
        child: Icon(
          icon,
          color: color,
          size: iconSize ?? _ClassicContentState._actionStyle.iconSize,
        ),
      ),
      label: label,
      labelColor: labelColor ?? color,
    );
  }

  Widget _actionContent({
    required Widget leading,
    String? label,
    Color? labelColor,
  }) {
    return ActionButtonContent(
      leading: leading,
      label: label,
      labelStyle: _ClassicContentState._actionStyle.textStyle.copyWith(
        color: labelColor ?? _ClassicContentState._actionStyle.textStyle.color,
      ),
      gap: 2,
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
