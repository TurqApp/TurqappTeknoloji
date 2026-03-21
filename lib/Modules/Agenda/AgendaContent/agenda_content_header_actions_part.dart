part of 'agenda_content.dart';

extension AgendaContentHeaderActionsPart on _AgendaContentState {
  List<StoryUserModel> _storyUsersSnapshot() {
    if (!Get.isRegistered<StoryRowController>()) return const [];
    return Get.find<StoryRowController>().users.toList(growable: false);
  }

  void _suspendEmbeddedFeedContextsForRoute() {
    if (Get.isRegistered<FloodListingController>()) {
      final floodController = Get.find<FloodListingController>();
      final floodIndex =
          floodController.floods.indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.capturePendingCenteredEntry(model: widget.model);
        floodController.lastCenteredIndex = floodIndex;
        floodController.centeredIndex.value = -1;
      }
    }

    if (Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
      final profileIndex = profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (profileIndex >= 0) {
        profileController.lastCenteredIndex = profileIndex;
        profileController.currentVisibleIndex.value = -1;
        profileController.centeredIndex.value = -1;
        profileController.pausetheall.value = true;
      }
    }

    if (Get.isRegistered<SocialProfileController>()) {
      final socialProfileController = Get.find<SocialProfileController>();
      final socialIndex = socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (socialIndex >= 0) {
        socialProfileController.lastCenteredIndex = socialIndex;
        socialProfileController.currentVisibleIndex.value = -1;
        socialProfileController.centeredIndex.value = -1;
      }
    }

    if (Get.isRegistered<ArchiveController>()) {
      final archiveController = Get.find<ArchiveController>();
      final archiveIndex =
          archiveController.list.indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.capturePendingCenteredEntry(model: widget.model);
        archiveController.lastCenteredIndex = archiveIndex;
        archiveController.centeredIndex.value = -1;
      }
    }

    if (Get.isRegistered<LikedPostControllers>()) {
      final likedController = Get.find<LikedPostControllers>();
      final likedIndex = likedController.all.indexWhere((p) => p.docID == widget.model.docID);
      if (likedIndex >= 0) {
        likedController.capturePendingCenteredEntry(model: widget.model);
        likedController.lastCenteredIndex = likedIndex;
        likedController.currentVisibleIndex.value = -1;
        likedController.centeredIndex.value = -1;
      }
    }

    if (Get.isRegistered<TopTagsController>()) {
      final topTagsController = Get.find<TopTagsController>();
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.capturePendingCenteredEntry(model: widget.model);
        topTagsController.lastCenteredIndex = topTagsIndex;
        topTagsController.currentVisibleIndex.value = -1;
        topTagsController.centeredIndex.value = -1;
      }
    }

    if (Get.isRegistered<TagPostsController>()) {
      final tagPostsController = Get.find<TagPostsController>();
      final tagPostIndex =
          tagPostsController.list.indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.capturePendingCenteredEntry(model: widget.model);
        tagPostsController.lastCenteredIndex = tagPostIndex;
        tagPostsController.currentVisibleIndex.value = -1;
        tagPostsController.centeredIndex.value = -1;
      }
    }
  }

  void _restoreEmbeddedFeedContexts() {
    if (Get.isRegistered<FloodListingController>()) {
      final floodController = Get.find<FloodListingController>();
      final floodIndex =
          floodController.floods.indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.capturePendingCenteredEntry(model: widget.model);
        floodController.centeredIndex.value = floodIndex;
        floodController.currentVisibleIndex.value = floodIndex;
        floodController.lastCenteredIndex = floodIndex;
      }
    }

    if (Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
      final profileIndex = profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (profileIndex >= 0) {
        profileController.lastCenteredIndex = profileIndex;
        profileController.currentVisibleIndex.value = profileIndex;
        profileController.centeredIndex.value = profileIndex;
        profileController.pausetheall.value = false;
      }
    }

    if (Get.isRegistered<SocialProfileController>()) {
      final socialProfileController = Get.find<SocialProfileController>();
      final socialIndex = socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (socialIndex >= 0) {
        socialProfileController.lastCenteredIndex = socialIndex;
        socialProfileController.currentVisibleIndex.value = socialIndex;
        socialProfileController.centeredIndex.value = socialIndex;
      }
    }

    if (Get.isRegistered<ArchiveController>()) {
      final archiveController = Get.find<ArchiveController>();
      final archiveIndex =
          archiveController.list.indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.capturePendingCenteredEntry(model: widget.model);
        archiveController.lastCenteredIndex = archiveIndex;
        archiveController.currentVisibleIndex.value = archiveIndex;
        archiveController.centeredIndex.value = archiveIndex;
      }
    }

    if (Get.isRegistered<LikedPostControllers>()) {
      final likedController = Get.find<LikedPostControllers>();
      final likedIndex = likedController.all.indexWhere((p) => p.docID == widget.model.docID);
      if (likedIndex >= 0) {
        likedController.capturePendingCenteredEntry(model: widget.model);
        likedController.lastCenteredIndex = likedIndex;
        likedController.currentVisibleIndex.value = likedIndex;
        likedController.centeredIndex.value = likedIndex;
      }
    }

    if (Get.isRegistered<TopTagsController>()) {
      final topTagsController = Get.find<TopTagsController>();
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.capturePendingCenteredEntry(model: widget.model);
        topTagsController.lastCenteredIndex = topTagsIndex;
        topTagsController.currentVisibleIndex.value = topTagsIndex;
        topTagsController.centeredIndex.value = topTagsIndex;
      }
    }

    if (Get.isRegistered<TagPostsController>()) {
      final tagPostsController = Get.find<TagPostsController>();
      final tagPostIndex =
          tagPostsController.list.indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.capturePendingCenteredEntry(model: widget.model);
        tagPostsController.lastCenteredIndex = tagPostIndex;
        tagPostsController.currentVisibleIndex.value = tagPostIndex;
        tagPostsController.centeredIndex.value = tagPostIndex;
      }
    }
  }

  void _suspendAgendaFeedForRoute() {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.lastCenteredIndex = modelIndex;
    }
    agendaController.centeredIndex.value = -1;
    _suspendEmbeddedFeedContextsForRoute();
    videoController?.pause();
  }

  void _restoreAgendaFeedCenter() {
    final last = agendaController.lastCenteredIndex;
    int target = -1;
    if (last != null &&
        last >= 0 &&
        last < agendaController.agendaList.length) {
      target = last;
    } else {
      final modelIndex = agendaController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (modelIndex >= 0) {
        target = modelIndex;
      } else if (agendaController.agendaList.isNotEmpty) {
        target = 0;
      }
    }
    if (target >= 0 && target < agendaController.agendaList.length) {
      agendaController.centeredIndex.value = target;
      agendaController.lastCenteredIndex = target;
    }
    _restoreEmbeddedFeedContexts();
  }

  bool _hasStoryAvatar() {
    final storyUser = _resolveStoryUser();
    return storyUser != null && storyUser.stories.isNotEmpty;
  }

  void _openAvatarStoryOrProfile() {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.lastCenteredIndex = modelIndex;
    }
    agendaController.centeredIndex.value = -1;
    final storyUser = _resolveStoryUser();
    if (storyUser != null && storyUser.stories.isNotEmpty) {
      videoController?.pause();
      final users = _storyUsersSnapshot();
      Get.to(() => StoryViewer(
            startedUser: storyUser,
            storyOwnerUsers: users,
          ))?.then((_) {
        _restoreAgendaFeedCenter();
      });
      return;
    }

    videoController?.pause();
    final currentUid = _currentUid;
    final route = widget.model.userID == currentUid
        ? Get.to(() => ProfileView())
        : Get.to(() => SocialProfile(userID: widget.model.userID));
    route?.then((_) {
      _restoreAgendaFeedCenter();
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

  Widget pulldownmenu() {
    final currentUid = _currentUid;
    final canManagePost =
        widget.model.userID == currentUid || controller.canSendAdminPush;
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            _suspendAgendaFeedForRoute();

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
              _restoreAgendaFeedCenter();
            });
          },
          title: 'short.publish_as_post'.tr,
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            _suspendAgendaFeedForRoute();
            await PostStoryShareService.openStoryMakerForPost(widget.model);
            _restoreAgendaFeedCenter();
          },
          title: 'short.add_to_story'.tr,
          icon: CupertinoIcons.sparkles,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              _suspendAgendaFeedForRoute();
              Get.to(() => PostSharers(
                    postID: PostStoryShareService.resolveOriginalPostId(
                      widget.model,
                    ),
                  ))?.then((_) {
                _restoreAgendaFeedCenter();
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
              _suspendAgendaFeedForRoute();
              Get.to(() => PostCreator(
                    editMode: true,
                    editPost: widget.model,
                  ))?.then((_) {
                _restoreAgendaFeedCenter();
              });
            },
            title: 'common.edit'.tr,
            icon: CupertinoIcons.pencil_circle,
          ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              _suspendAgendaFeedForRoute();
              controller.sendAdminPushForPost().whenComplete(() {
                _restoreAgendaFeedCenter();
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
              _suspendAgendaFeedForRoute();
              noYesAlert(
                title: 'common.delete_post_title'.tr,
                message: 'common.delete_post_message'.tr,
                yesText: 'common.delete_post_confirm'.tr,
                cancelText: 'common.cancel'.tr,
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                if (!controller.silindi.value) {
                  _restoreAgendaFeedCenter();
                }
              });
            },
            title: 'common.delete'.tr,
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            widget.model.userID == _currentUid)
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
            widget.model.userID == _currentUid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              videoController?.play();
            },
            title: 'common.unarchive'.tr,
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != _currentUid)
          PullDownMenuItem(
            onTap: () {
              _suspendAgendaFeedForRoute();
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {
                _restoreAgendaFeedCenter();
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
        child: const Icon(Icons.more_vert, color: Colors.black, size: 22),
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
    final bool isLiked =
        _currentUid.isNotEmpty && controller.likes.contains(_currentUid);
    final Color likeColor =
        isLiked ? Colors.blueAccent : _AgendaContentState._actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'common.likes'.tr,
      onTap: controller.like,
      showTapArea: _AgendaContentState._showActionTapAreas,
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
            title: isReshared
                ? 'post.undo_reshare'.tr
                : 'common.reshare'.tr,
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

  void _runSimpleReshare() {
    controller.reshare();
    videoController?.play();
  }

  void _openReshareUsersSheet() {
    _suspendAgendaFeedForRoute();
    final targetPostId = widget.model.originalPostID.trim().isNotEmpty
        ? widget.model.originalPostID.trim()
        : widget.model.docID;
    Get.bottomSheet(
      PostReshareListing(postID: targetPostId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      _restoreAgendaFeedCenter();
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

    _suspendAgendaFeedForRoute();
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
      _restoreAgendaFeedCenter();
    });
  }

  Widget saveButton() {
    final bool isSaved = controller.saved.value == true;
    final Color displayColor =
        isSaved ? Colors.orange : _AgendaContentState._actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'common.save'.tr,
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
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'common.share_external'.tr,
      onTap: _shareExternally,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
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
