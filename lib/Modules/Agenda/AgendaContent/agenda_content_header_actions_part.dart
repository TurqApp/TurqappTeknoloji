part of 'agenda_content.dart';

extension AgendaContentHeaderActionsPart on _AgendaContentState {
  Widget headerUserInfoBar() {
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.nickname.value.trim();
    final handle = controller.nickname.value.trim().isNotEmpty
        ? controller.nickname.value.trim()
        : controller.username.value.trim();
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} ${'common.edited'.tr}"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final displayTime = buildDisplayTime();
    final shouldHideFollow = primaryName.length +
            controller.nickname.value.length +
            displayTime.length >
        28;
    void openProfile() {
      if (widget.model.userID != _currentUid) {
        final modelIndex = agendaController.agendaList
            .indexWhere((p) => p.docID == widget.model.docID);
        if (modelIndex >= 0) {
          agendaController.lastCenteredIndex = modelIndex;
        }
        agendaController.centeredIndex.value = -1;
        videoController?.pause();
        Get.to(SocialProfile(userID: widget.model.userID))?.then((v) {
          _restoreAgendaFeedCenter();
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openAvatarStoryOrProfile,
            child: Obx(() => _buildStoryAwareAvatar(
                  userId: widget.model.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 20,
                )),
          ),
          6.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: openProfile,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                primaryName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '@$handle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            RozetContent(
                              size: 13,
                              userID: widget.model.userID,
                              rozetValue: widget.model.rozet,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6, right: 12),
                              child: Obx(
                                () {
                                  _relativeTimeTickService.tick.value;
                                  return Text(
                                    buildDisplayTime(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (controller.isFollowing.value == false &&
                        widget.model.userID != _currentUid &&
                        controller.avatarUrl.value != "" &&
                        !shouldHideFollow)
                      Obx(() => TextButton(
                            onPressed: controller.followLoading.value
                                ? null
                                : () {
                                    controller.followUser();
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: controller.followLoading.value
                                ? Container(
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(12)),
                                        border:
                                            Border.all(color: Colors.black)),
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 15),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black),
                                        ),
                                      ),
                                    ),
                                  )
                                : Texts.followMeButtonBlack,
                          )),
                    const SizedBox(width: 7),
                    pulldownmenu(),
                  ],
                ),
                if ((widget.model.hasPlayableVideo ||
                        widget.model.img.isNotEmpty) &&
                    _AgendaContentState._ctaNavigationService
                        .sanitizeCaptionText(
                          widget.model.metin,
                          meta: widget.model.reshareMap,
                        )
                        .isNotEmpty)
                  _buildFeedCaption(
                    text: widget.model.metin.trim(),
                    color: Colors.black,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: outerRadius,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          GestureDetector(
            onTap: _openImageMediaOrFeedCta,
            onDoubleTap: () {
              controller.like();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: outerRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageContent(images),
            ),
          ),
          _buildIzBirakBlurOverlay(),
          _buildIzBirakBottomBar(),
          if (!widget.suppressFloodBadge &&
              widget.model.floodCount > 1 &&
              widget.model.flood == false)
            GestureDetector(
              onTap: () {
                _suspendAgendaFeedForRoute();
                Get.to(() => FloodListing(mainModel: widget.model))?.then((_) {
                  _restoreAgendaFeedCenter();
                });
              },
              child: Texts.colorfulFloodLeftSide,
            ),
          if ((widget.isReshared && widget.model.originalUserID.isEmpty) ||
              widget.model.originalUserID.isNotEmpty)
            Positioned(
              left: 8,
              bottom:
                  (widget.model.floodCount > 1 && widget.model.flood == false)
                      ? 26
                      : 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isReshared && widget.model.originalUserID.isEmpty)
                    _buildAgendaReshareOverlay(),
                  if (widget.model.originalUserID.isNotEmpty)
                    SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      sourceUserID: widget.model.quotedPost
                          ? widget.model.quotedSourceUserID
                          : '',
                      labelSuffix: widget.model.quotedPost ? 'alıntılandı' : '',
                      textColor: Colors.white,
                      fontSize: 12,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgendaReshareOverlay() {
    if (widget.model.originalUserID.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.repeat,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          ReshareAttribution(
            controller: controller,
            model: widget.model,
            explicitReshareUserId: widget.reshareUserID,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }

  Widget commentButton(BuildContext context) {
    return Obx(() {
      final int visibility = widget.model.yorumVisibility;
      final bool isOwner = _currentUid == widget.model.userID;
      final bool canInteract = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final Color displayColor = _AgendaContentState._actionColor;

      return AnimatedActionButton(
        key:
            ValueKey(IntegrationTestKeys.feedCommentButton(widget.model.docID)),
        enabled: canInteract,
        semanticsLabel: 'common.comments'.tr,
        onTap: canInteract
            ? () {
                _suspendAgendaFeedForRoute();
                controller.showPostCommentsBottomSheet(
                  onClosed: _restoreAgendaFeedCenter,
                );
              }
            : null,
        showTapArea: _AgendaContentState._showActionTapAreas,
        child: _iconAction(
          icon: CupertinoIcons.bubble_left,
          color: displayColor,
          label: NumberFormatter.format(controller.commentCount.value),
          labelColor: displayColor,
          iconSize: 17,
        ),
      );
    });
  }

  Widget likeButton() {
    return Obx(() {
      final bool isLiked =
          _currentUid.isNotEmpty && controller.likes.contains(_currentUid);
      final int displayLikeCount = controller.likeCount.value <= 0 && isLiked
          ? 1
          : controller.likeCount.value;
      final Color likeColor =
          isLiked ? Colors.blueAccent : _AgendaContentState._actionColor;

      return AnimatedActionButton(
        key: ValueKey(IntegrationTestKeys.feedLikeButton(widget.model.docID)),
        enabled: true,
        semanticsLabel: 'common.likes'.tr,
        onTap: controller.like,
        showTapArea: _AgendaContentState._showActionTapAreas,
        hitTestBehavior: HitTestBehavior.translucent,
        longPressDuration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
        onLongPress: () {
          _suspendAgendaFeedForRoute();
          Get.bottomSheet(
            Container(
              height: Get.height / 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18),
                  topLeft: Radius.circular(18),
                ),
              ),
              child: PostLikeListing(postID: widget.model.docID),
            ),
          ).then((_) {
            _restoreAgendaFeedCenter();
          });
        },
        child: _iconAction(
          icon: isLiked
              ? CupertinoIcons.hand_thumbsup_fill
              : CupertinoIcons.hand_thumbsup,
          color: likeColor,
          label: NumberFormatter.format(displayLikeCount),
          labelColor: likeColor,
          iconSize: 17,
          leadingTransformOffsetY: -2,
        ),
      );
    });
  }

  Widget reshareButton() {
    return Obx(() {
      final int visibility = widget.model.paylasimVisibility;
      final bool isOwner = _currentUid == widget.model.userID;
      final currentUserId = _currentUid;
      final bool canReshare = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final bool isCurrentUsersReshareCard = currentUserId.isNotEmpty &&
          widget.reshareUserID?.trim() == currentUserId;
      final bool isReshared =
          controller.yenidenPaylasildiMi.value || isCurrentUsersReshareCard;
      final Color displayColor =
          isReshared ? Colors.green : _AgendaContentState._actionColor;

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
            showTapArea: _AgendaContentState._showActionTapAreas,
            child: _iconAction(
              icon: Icons.repeat,
              color: displayColor,
              label: NumberFormatter.format(controller.retryCount.value),
              labelColor: displayColor,
            ),
          ),
        ),
      );
    });
  }

  Widget saveButton() {
    return Obx(() {
      final bool isSaved = controller.saved.value == true;
      final Color displayColor =
          isSaved ? Colors.orange : _AgendaContentState._actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'common.save'.tr,
        onTap: controller.save,
        showTapArea: _AgendaContentState._showActionTapAreas,
        child: _iconAction(
          icon:
              isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
          color: displayColor,
          label: NumberFormatter.format(controller.savedCount.value),
          labelColor: displayColor,
          iconSize: 17,
        ),
      );
    });
  }

  Widget statButton() {
    return SizedBox(
      height: AnimatedActionButton.actionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                Icons.bar_chart,
                color: _AgendaContentState._actionColor,
                size: 20,
              ),
            ),
          ),
          2.pw,
          SizedBox(
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Text(
                NumberFormatter.format(controller.statsCount.value),
                style: const TextStyle(
                  color: _AgendaContentState._actionColor,
                  fontSize: 12,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sendButton() {
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'common.share_external'.tr,
      onTap: _shareExternally,
      showTapArea: _AgendaContentState._showActionTapAreas,
      child: SizedBox(
        width: 20,
        height: AnimatedActionButton.actionHeight,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: Icon(
              CupertinoIcons.share_up,
              color: _AgendaContentState._actionColor,
              size: _AgendaContentState._actionStyle.sendIconSize,
            ),
          ),
        ),
      ),
    );
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
          size: iconSize ?? _AgendaContentState._actionStyle.iconSize,
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
      labelStyle: _AgendaContentState._actionStyle.textStyle.copyWith(
        color: labelColor ?? _AgendaContentState._actionStyle.textStyle.color,
      ),
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
