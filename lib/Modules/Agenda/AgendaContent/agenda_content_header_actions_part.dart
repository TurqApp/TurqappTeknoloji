part of 'agenda_content.dart';

extension AgendaContentHeaderActionsPart on _AgendaContentState {
  bool _hasStoryAvatar() {
    final storyUser = _resolveStoryUser();
    return storyUser != null && storyUser.stories.isNotEmpty;
  }

  void _openAvatarStoryOrProfile() {
    final storyUser = _resolveStoryUser();
    if (storyUser != null && storyUser.stories.isNotEmpty) {
      videoController?.pause();
      final users =
          Get.find<StoryRowController>().users.toList(growable: false);
      Get.to(() => StoryViewer(
            startedUser: storyUser,
            storyOwnerUsers: users,
          ))?.then((_) {
        videoController?.play();
      });
      return;
    }

    videoController?.pause();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final route = widget.model.userID == currentUid
        ? Get.to(() => ProfileView())
        : Get.to(() => SocialProfile(userID: widget.model.userID));
    route?.then((_) {
      videoController?.play();
    });
  }

  Widget _buildStoryAwareAvatar({
    required String userId,
    required String imageUrl,
    required double radius,
  }) {
    final hasStory = _hasStoryAvatar();
    final ringColors = hasStory
        ? const [
            Color(0xFFB7F3D0),
            Color(0xFF5AD39A),
            Color(0xFF20B26B),
            Color(0xFF12824D),
          ]
        : const [
            Color(0xFFB7D8FF),
            Color(0xFF6EB6FF),
            Color(0xFF2C8DFF),
            Color(0xFF0E5BFF),
          ];

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: hasStory ? 0.018 : 0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: ringColors,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: CachedUserAvatar(
            userId: userId,
            imageUrl: imageUrl,
            radius: radius,
          ),
        ),
      ),
      builder: (context, turns, child) {
        return Transform.rotate(
          angle: turns * 2 * 3.141592653589793,
          child: child,
        );
      },
    );
  }

  Widget headerUserInfoBar() {
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.nickname.value.trim();
    final handle = controller.nickname.value.trim().isNotEmpty
        ? controller.nickname.value.trim()
        : controller.username.value.trim();
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final displayTime = buildDisplayTime();
    final shouldHideFollow = primaryName.length +
            controller.nickname.value.length +
            displayTime.length >
        28;
    void openProfile() {
      if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
        videoController?.pause();
        Get.to(SocialProfile(userID: widget.model.userID))?.then((v) {
          videoController?.play();
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
                        widget.model.userID !=
                            FirebaseAuth.instance.currentUser!.uid &&
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
                Get.to(() => FloodListing(mainModel: widget.model));
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

  Widget pulldownmenu() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canManagePost =
        widget.model.userID == currentUid || controller.canSendAdminPush;
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();

            Get.to(() => PostCreator(
                  sharedVideoUrl: widget.model.playbackUrl,
                  sharedImageUrls: widget.model.img,
                  sharedAspectRatio: widget.model.aspectRatio.toDouble(),
                  sharedThumbnail: widget.model.thumbnail,
                  originalUserID:
                      PostStoryShareService.resolveOriginalUserId(widget.model),
                  originalPostID:
                      PostStoryShareService.resolveOriginalPostId(widget.model),
                  sharedAsPost: true,
                ))?.then((_) {
              videoController?.play();
            });
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();
            await PostStoryShareService.openStoryMakerForPost(widget.model);
            videoController?.play();
          },
          title: 'Hikayene ekle',
          icon: CupertinoIcons.sparkles,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostSharers(
                    postID: PostStoryShareService.resolveOriginalPostId(
                      widget.model,
                    ),
                  ))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Gönderi olarak paylaşanlar',
            icon: CupertinoIcons.person_2,
          ),
        PullDownMenuItem(
          onTap: () {
            controller.sendPost();
          },
          title: 'Gönder',
          icon: CupertinoIcons.paperplane,
        ),
        PullDownMenuItem(
          onTap: () {
            videoController?.pause();
            controller.gizle();
          },
          title: 'Gizle',
          icon: CupertinoIcons.eye_slash,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostCreator(
                    editMode: true,
                    editPost: widget.model,
                  ))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Düzenle',
            icon: CupertinoIcons.pencil_circle,
          ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              controller.sendAdminPushForPost().whenComplete(() {
                if (widget.shouldPlay) {
                  videoController?.play();
                }
              });
            },
            title: 'Push',
            icon: CupertinoIcons.bell,
          ),
        PullDownMenuItem(
          onTap: () async {
            final previewImage = widget.model.thumbnail.trim().isNotEmpty
                ? widget.model.thumbnail.trim()
                : (widget.model.img.isNotEmpty
                    ? widget.model.img.first.trim()
                    : null);
            final url = await ShortLinkService().getPostPublicUrl(
              postId: widget.model.docID,
              desc: widget.model.metin,
              imageUrl: previewImage,
            );

            await Clipboard.setData(ClipboardData(text: url));

            AppSnackbar("Kopyalandı", "Bağlantı linki panoya kopyalandı");
          },
          title: 'Linki Kopyala',
          icon: CupertinoIcons.doc_on_doc,
        ),
        PullDownMenuItem(
          onTap: () async {
            await ShareActionGuard.run(() async {
              final previewImage = widget.model.thumbnail.trim().isNotEmpty
                  ? widget.model.thumbnail.trim()
                  : (widget.model.img.isNotEmpty
                      ? widget.model.img.first.trim()
                      : null);
              final url = await ShortLinkService().getPostPublicUrl(
                postId: widget.model.docID,
                desc: widget.model.metin,
                imageUrl: previewImage,
              );
              await ShareLinkService.shareUrl(
                url: url,
                title: 'TurqApp Gönderisi',
                subject: 'TurqApp Gönderisi',
              );
            });
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share_up,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              // 2) Videoyu durdur
              videoController?.pause();

              // 3) Alert’i göster ve kapandıktan sonra silinme durumuna göre videoyu devam ettir
              noYesAlert(
                title: "Gönderiyi Sil",
                message: "Bu gönderiyi silmek istediğinizden emin misiniz?",
                yesText: "Gönderiyi Sil",
                cancelText: "Vazgeç",
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                // Eğer silinmediyse videoyu tekrar başlat
                if (!controller.silindi.value) {
                  videoController?.play();
                }
              });
            },
            title: 'Sil',
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
              videoController?.pause();
            },
            title: "Arşivle",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == true &&
            widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              videoController?.play();
            },
            title: "Arşivden Çıkart",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Şikayet Et',
            icon: CupertinoIcons.info,
            isDestructive: true,
          ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.6,
        alignment: Alignment.center,
        minimumSize: Size(0, 0),
        child: const Icon(Icons.more_vert, color: Colors.black, size: 22),
      ),
    );
  }

  Widget commentButton(BuildContext context) {
    return Obx(() {
      final int visibility = widget.model.yorumVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final bool canInteract = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final Color displayColor = _AgendaContentState._actionColor;

      return AnimatedActionButton(
        enabled: canInteract,
        semanticsLabel: 'Yorumlar',
        onTap: canInteract ? controller.showPostCommentsBottomSheet : null,
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
    final bool isLiked =
        controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
    final Color likeColor =
        isLiked ? Colors.blueAccent : _AgendaContentState._actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Beğeniler',
      onTap: controller.like,
      showTapArea: _AgendaContentState._showActionTapAreas,
      onLongPress: () {
        videoController?.pause();
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
          videoController?.play();
        });
      },
      child: _iconAction(
        icon: isLiked
            ? CupertinoIcons.hand_thumbsup_fill
            : CupertinoIcons.hand_thumbsup,
        color: likeColor,
        label: NumberFormatter.format(controller.likeCount.value),
        labelColor: likeColor,
        iconSize: 17,
        leadingTransformOffsetY: -2,
      ),
    );
  }

  Widget reshareButton() {
    return Obx(() {
      final int visibility = widget.model.paylasimVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final currentUserId = controller.userService.userId;
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
            title: isReshared ? 'Yeniden paylaşımı geri al' : 'Yeniden paylaş',
            icon: Icons.repeat,
          ),
          PullDownMenuItem(
            onTap: canReshare ? _openQuoteComposer : null,
            title: 'Alıntıla',
            icon: CupertinoIcons.quote_bubble,
          ),
        ],
        buttonBuilder: (context, showMenu) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: canReshare ? _openReshareUsersSheet : null,
          child: AnimatedActionButton(
            enabled: canReshare,
            semanticsLabel: 'Yeniden paylaş',
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

  void _runSimpleReshare() {
    controller.reshare();
    videoController?.play();
  }

  void _openReshareUsersSheet() {
    videoController?.pause();
    final targetPostId = widget.model.originalPostID.trim().isNotEmpty
        ? widget.model.originalPostID.trim()
        : widget.model.docID;
    Get.bottomSheet(
      PostReshareListing(postID: targetPostId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      videoController?.play();
    });
  }

  Future<void> _openQuoteComposer() async {
    String finalOriginalUserID;
    String finalOriginalPostID;
    final sourceSnapshot = await _resolveQuotedSourceSnapshot();
    final String resolvedQuotedText = widget.model.quotedPost &&
            widget.model.quotedOriginalText.trim().isNotEmpty
        ? widget.model.quotedOriginalText.trim()
        : widget.model.metin.trim();
    final String resolvedQuotedSourceUserID = widget.model.quotedPost &&
            widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : sourceSnapshot.userId;
    final String resolvedQuotedSourceDisplayName =
        sourceSnapshot.displayName.trim();
    final String resolvedQuotedSourceUsername = sourceSnapshot.username.trim();
    final String resolvedQuotedSourceAvatarUrl =
        sourceSnapshot.avatarUrl.trim();

    if (widget.model.originalUserID.isNotEmpty) {
      finalOriginalUserID = widget.model.originalUserID;
      finalOriginalPostID = widget.model.originalPostID;
    } else {
      finalOriginalUserID = widget.model.userID;
      finalOriginalPostID = widget.model.docID;
    }

    Get.to(() => PostCreator(
          sharedVideoUrl: widget.model.playbackUrl,
          sharedImageUrls: widget.model.img,
          sharedAspectRatio: widget.model.aspectRatio.toDouble(),
          sharedThumbnail: widget.model.thumbnail,
          originalUserID: finalOriginalUserID,
          originalPostID: finalOriginalPostID,
          sourcePostID: widget.model.docID,
          sharedAsPost: true,
          quotedPost: true,
          quotedOriginalText: resolvedQuotedText,
          quotedSourceUserID: resolvedQuotedSourceUserID,
          quotedSourceDisplayName: resolvedQuotedSourceDisplayName,
          quotedSourceUsername: resolvedQuotedSourceUsername,
          quotedSourceAvatarUrl: resolvedQuotedSourceAvatarUrl,
        ))?.then((_) {
      videoController?.play();
    });
  }

  Widget saveButton() {
    final bool isSaved = controller.saved.value == true;
    final Color displayColor =
        isSaved ? Colors.orange : _AgendaContentState._actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Kaydet',
      onTap: controller.save,
      showTapArea: _AgendaContentState._showActionTapAreas,
      child: _iconAction(
        icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        color: displayColor,
        label: NumberFormatter.format(controller.savedCount.value),
        labelColor: displayColor,
        iconSize: 17,
      ),
    );
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
    if (_isBlackBadgeUser) {
      final alreadyFlagged =
          _AgendaContentState._flaggedPostIds.contains(widget.model.docID);
      if (alreadyFlagged) {
        return AnimatedActionButton(
          enabled: false,
          semanticsLabel: 'İşaretlendi',
          onTap: null,
          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
          showTapArea: _AgendaContentState._showActionTapAreas,
          child: SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.grey,
                size: _AgendaContentState._actionStyle.sendIconSize,
              ),
            ),
          ),
        );
      }

      return PullDownButton(
        itemBuilder: (context) => _AgendaContentState._flagReasons
            .map(
              (reason) => PullDownMenuItem(
                onTap: () async {
                  try {
                    final result = await Get.put(PostInteractionService())
                        .flagPostWithReason(
                      widget.model.docID,
                      reason: reason,
                    );
                    if (result.isOk) {
                      _AgendaContentState._flaggedPostIds
                          .add(widget.model.docID);
                      _refreshFlaggedPostState();
                    }
                    if (result.accepted) {
                      AppSnackbar('İşaretle', 'İşaretleme kaydedildi.');
                    } else if (result.alreadyFlagged) {
                      AppSnackbar('Bilgi', 'Bu gönderiyi zaten işaretlediniz.');
                    } else {
                      AppSnackbar('Hata', 'İşaretleme başarısız oldu.');
                    }
                  } catch (_) {
                    AppSnackbar('Hata', 'İşaretleme başarısız oldu.');
                  }
                },
                title: reason,
              ),
            )
            .toList(),
        buttonBuilder: (context, showMenu) => AnimatedActionButton(
          enabled: true,
          semanticsLabel: 'İşaretle',
          onTap: showMenu,
          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
          showTapArea: _AgendaContentState._showActionTapAreas,
          child: SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.amber,
                size: _AgendaContentState._actionStyle.sendIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Paylaş',
      onTap: controller.sendPost,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
      showTapArea: _AgendaContentState._showActionTapAreas,
      child: SizedBox(
        width: 20,
        height: AnimatedActionButton.actionHeight,
        child: Center(
          child: SlimSendIcon(
            color: _AgendaContentState._actionColor,
            size: _AgendaContentState._actionStyle.sendIconSize,
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
