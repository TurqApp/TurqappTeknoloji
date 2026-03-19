part of 'classic_content.dart';

extension ClassicContentHeaderActionsPart on _ClassicContentState {
  Widget headerUserInfoBar() {
    final primaryName = widget.model.authorDisplayName.trim().isNotEmpty
        ? widget.model.authorDisplayName.trim().replaceAll("  ", " ")
        : controller.fullName.value.trim().isNotEmpty
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
    void openProfile() {
      if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
        videoController?.pause();
        Get.to(() => SocialProfile(userID: widget.model.userID))?.then((v) {
          videoController?.play();
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openAvatarStoryOrProfile,
            child: Obx(() => _buildClassicAvatar(
                  userId: widget.model.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 20, // 40px diameter / 2
                )),
          ),
          7.pw,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
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
                                    const SizedBox(width: 4),
                                    RozetContent(
                                      size: 13,
                                      userID: widget.model.userID,
                                      rozetValue: widget.model.rozet,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 6, right: 12),
                                      child: Obx(
                                        () {
                                          _relativeTimeTickService.tick.value;
                                          return Text(
                                            buildDisplayTime(),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '@$handle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ],
                          )),
                    ),
                    if (widget.model.userID !=
                        FirebaseAuth.instance.currentUser!.uid)
                      Obx(() {
                        if (controller.isFollowing.value) {
                          return const SizedBox.shrink();
                        }
                        return Transform.translate(
                          offset: const Offset(0, -5),
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: TextButton(
                                onPressed: controller.followLoading.value
                                    ? null
                                    : () {
                                        controller.followUser();
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: controller.followLoading.value
                                    ? Container(
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(12)),
                                            border: Border.all(
                                                color: Colors.black)),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 15),
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
                              ),
                            ),
                          ),
                        );
                      }),
                    7.pw,
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: pulldownmenu(Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.model.konum != "")
                  Text(
                    widget.model.konum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget headerUserInfoWhite() {
    final compact = Get.width < 380;
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.username.value.trim();
    final handle = controller.username.value.trim().isNotEmpty
        ? controller.username.value.trim()
        : controller.nickname.value.trim();
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} ${'common.edited'.tr}"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    void openProfile() {
      if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
        videoController?.pause();
        Get.to(() => SocialProfile(userID: widget.model.userID))?.then((v) {
          videoController?.play();
        });
      }
    }

    final textShadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 10,
        offset: const Offset(0, 1),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openAvatarStoryOrProfile,
            child: Obx(() => _buildClassicAvatar(
                  userId: widget.model.userID,
                  imageUrl: controller.avatarUrl.value,
                )),
          ),
          7.pw,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        primaryName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: "MontserratBold",
                                          shadows: textShadow,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildClassicWhiteBadge(13),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '@$handle',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      fontSize: 12,
                                      fontFamily: "Montserrat",
                                      shadows: textShadow,
                                    ),
                                  ),
                                  Obx(
                                    () {
                                      _relativeTimeTickService.tick.value;
                                      return Text(
                                        buildDisplayTime(),
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 11,
                                          fontFamily: "MontserratMedium",
                                          shadows: textShadow,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          )),
                    ),
                    if (widget.model.userID !=
                        FirebaseAuth.instance.currentUser!.uid)
                      Obx(() {
                        if (controller.isFollowing.value) {
                          return const SizedBox.shrink();
                        }
                        if (compact) {
                          return const SizedBox.shrink();
                        }
                        return Transform.translate(
                          offset: const Offset(0, -5),
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: TextButton(
                                onPressed: controller.followLoading.value
                                    ? null
                                    : () {
                                        controller.followUser();
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _buildClassicOverlayFollowButton(
                                  loading: controller.followLoading.value,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    7.pw,
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: pulldownmenu(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.model.konum != "")
                  Text(
                    widget.model.konum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: "Montserrat",
                      shadows: textShadow,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pulldownmenu(Color color) {
    final canManagePost =
        widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            controller.canSendAdminPush;
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
          title: 'short.publish_as_post'.tr,
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();
            await PostStoryShareService.openStoryMakerForPost(widget.model);
            videoController?.play();
          },
          title: 'short.add_to_story'.tr,
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
            title: 'short.shared_as_post_by'.tr,
            icon: CupertinoIcons.person_2,
          ),
        PullDownMenuItem(
          onTap: () {
            controller.sendPost();
          },
          title: 'common.send'.tr,
          icon: CupertinoIcons.paperplane,
        ),
        PullDownMenuItem(
          onTap: () {
            videoController?.pause();
            controller.gizle();
          },
          title: 'common.hide'.tr,
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
            title: 'common.edit'.tr,
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
            title: 'common.push'.tr,
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

            AppSnackbar('common.copied'.tr, 'common.link_copied'.tr);
          },
          title: 'common.copy_link'.tr,
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
                title: 'common.post_share_title'.tr,
                subject: 'common.post_share_title'.tr,
              );
            });
          },
          title: 'common.share'.tr,
          icon: CupertinoIcons.share_up,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              // 2) Videoyu durdur
              videoController?.pause();

              // 3) Alert’i göster ve kapandıktan sonra silinme durumuna göre videoyu devam ettir
              noYesAlert(
                title: 'common.delete_post_title'.tr,
                message: 'common.delete_post_message'.tr,
                yesText: 'common.delete_post_confirm'.tr,
                cancelText: 'common.cancel'.tr,
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
            title: 'common.delete'.tr,
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
            title: 'common.archive'.tr,
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
            title: 'common.unarchive'.tr,
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
            title: 'common.report'.tr,
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
        child: Icon(Icons.more_vert, color: color, size: 22),
      ),
    );
  }

  void _runSimpleReshare() {
    controller.reshare();
    videoController?.play();
  }

  Future<
      ({
        String userId,
        String displayName,
        String username,
        String avatarUrl
      })> _resolveQuotedSourceSnapshot() async {
    String pick(List<dynamic> values, [String fallback = '']) {
      for (final value in values) {
        final text = (value ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }

    final sourceUserId = widget.model.quotedPost &&
            widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.userID.trim();

    String displayName = widget.model.quotedPost &&
            widget.model.quotedSourceDisplayName.trim().isNotEmpty
        ? widget.model.quotedSourceDisplayName.trim()
        : pick([
            controller.fullName.value,
            controller.nickname.value,
            controller.username.value,
            widget.model.authorNickname,
          ]);
    String username = widget.model.quotedPost &&
            widget.model.quotedSourceUsername.trim().isNotEmpty
        ? widget.model.quotedSourceUsername.trim()
        : pick([
            controller.username.value,
            controller.nickname.value,
            widget.model.authorNickname,
          ]);
    String avatarUrl = widget.model.quotedPost &&
            widget.model.quotedSourceAvatarUrl.trim().isNotEmpty
        ? widget.model.quotedSourceAvatarUrl.trim()
        : controller.avatarUrl.value.trim();

    if (sourceUserId.isNotEmpty) {
      try {
        final profileCache = Get.isRegistered<UserProfileCacheService>()
            ? Get.find<UserProfileCacheService>()
            : Get.put(UserProfileCacheService(), permanent: true);
        final profile = (await profileCache.getProfile(
              sourceUserId,
              preferCache: true,
              cacheOnly: false,
            )) ??
            const <String, dynamic>{};
        displayName = pick([
          displayName,
          profile['displayName'],
          profile['fullName'],
          profile['name'],
          profile['nickname'],
          profile['username'],
        ], displayName);
        username = pick([
          username,
          profile['username'],
          profile['nickname'],
        ], username);
        final resolvedAvatar = resolveAvatarUrl(profile).trim();
        if (resolvedAvatar.isNotEmpty &&
            resolvedAvatar != kDefaultAvatarUrl &&
            avatarUrl.trim().isEmpty) {
          avatarUrl = resolvedAvatar;
        }
      } catch (_) {}
    }

    return (
      userId: sourceUserId,
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
    );
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
          isReshared ? Colors.green : _ClassicContentState._actionColor;

      return PullDownButton(
        itemBuilder: (context) => [
          PullDownMenuItem(
            onTap: canReshare ? _runSimpleReshare : null,
            title: isReshared ? 'Yeniden paylaşımı geri al' : 'Yeniden paylaş',
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
            semanticsLabel: 'Yeniden paylaş',
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
      final int visibility = widget.model.yorumVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final bool canInteract = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final Color displayColor = _ClassicContentState._actionColor;

      return AnimatedActionButton(
        enabled: canInteract,
        semanticsLabel: 'Yorumlar',
        onTap: canInteract
            ? () {
                videoController?.pause();
                controller.showPostCommentsBottomSheet(
                  onClosed: () => videoController?.play(),
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
      final bool isLiked =
          controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
      final Color displayColor =
          isLiked ? Colors.blueAccent : _ClassicContentState._actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Beğeniler',
        onTap: controller.like,
        onLongPress: _openLikeListing,
        longPressDuration: const Duration(milliseconds: 220),
        child: _iconAction(
          icon: isLiked
              ? CupertinoIcons.hand_thumbsup_fill
              : CupertinoIcons.hand_thumbsup,
          iconSize: 19,
          color: displayColor,
          label: NumberFormatter.format(controller.likeCount.value),
          labelColor: displayColor,
          leadingTransformOffsetY: -2,
        ),
      );
    });
  }

  void _openLikeListing() {
    videoController?.pause();
    Get.bottomSheet(
      PostLikeListing(postID: widget.model.docID),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      videoController?.play();
    });
  }

  Widget saveButton() {
    return Obx(() {
      final bool isSaved = controller.saved.value == true;
      final Color displayColor =
          isSaved ? Colors.orange : _ClassicContentState._actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Kaydet',
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
      semanticsLabel: 'Dış Kaynakta Paylaş',
      onTap: _shareExternally,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
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
      final url = await ShortLinkService().getPostPublicUrl(
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
