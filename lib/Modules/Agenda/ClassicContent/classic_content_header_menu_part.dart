part of 'classic_content.dart';

extension ClassicContentHeaderMenuPart on _ClassicContentState {
  Widget pulldownmenu(Color color) {
    final canManagePost =
        widget.model.userID == _currentUid || controller.canSendAdminPush;
    final canEditPost = controller.canSendAdminPush;
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            _suspendClassicFeedForRoute();

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
              _restoreClassicFeedCenter();
            });
          },
          title: 'short.publish_as_post'.tr,
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            _suspendClassicFeedForRoute();
            await PostStoryShareService.openStoryMakerForPost(widget.model);
            _restoreClassicFeedCenter();
          },
          title: 'short.add_to_story'.tr,
          icon: CupertinoIcons.sparkles,
        ),
        if (canEditPost)
          PullDownMenuItem(
            onTap: () {
              _suspendClassicFeedForRoute();
              Get.to(() => PostSharers(
                    postID: PostStoryShareService.resolveOriginalPostId(
                      widget.model,
                    ),
                  ))?.then((_) {
                _restoreClassicFeedCenter();
              });
            },
            title: 'short.shared_as_post_by'.tr,
            icon: CupertinoIcons.person_2,
          ),
        PullDownMenuItem(
          onTap: controller.sendPost,
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
              _suspendClassicFeedForRoute();
              Get.to(() => PostCreator(
                    editMode: true,
                    editPost: widget.model,
                  ))?.then((_) {
                _restoreClassicFeedCenter();
              });
            },
            title: 'common.edit'.tr,
            icon: CupertinoIcons.pencil_circle,
          ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              _suspendClassicFeedForRoute();
              controller.sendAdminPushForPost().whenComplete(() {
                _restoreClassicFeedCenter();
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
              existingShortUrl: widget.model.shortUrl,
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
                existingShortUrl: widget.model.shortUrl,
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
              _suspendClassicFeedForRoute();
              noYesAlert(
                title: 'common.delete_post_title'.tr,
                message: 'common.delete_post_message'.tr,
                yesText: 'common.delete_post_confirm'.tr,
                cancelText: 'common.cancel'.tr,
                onYesPressed: controller.sil,
              ).then((_) {
                if (!controller.silindi.value) {
                  _restoreClassicFeedCenter();
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
              _suspendClassicFeedForRoute();
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {
                _restoreClassicFeedCenter();
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
        minimumSize: const Size(0, 0),
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
        final profileCache = ensureUserProfileCacheService();
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
    final resolvedQuotedText = widget.model.quotedPost &&
            widget.model.quotedOriginalText.trim().isNotEmpty
        ? widget.model.quotedOriginalText.trim()
        : widget.model.metin.trim();
    final resolvedQuotedSourceUserID = widget.model.quotedPost &&
            widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : sourceSnapshot.userId;
    final resolvedQuotedSourceDisplayName = sourceSnapshot.displayName.trim();
    final resolvedQuotedSourceUsername = sourceSnapshot.username.trim();
    final resolvedQuotedSourceAvatarUrl = sourceSnapshot.avatarUrl.trim();

    if (widget.model.originalUserID.isNotEmpty) {
      finalOriginalUserID = widget.model.originalUserID;
      finalOriginalPostID = widget.model.originalPostID;
    } else {
      finalOriginalUserID = widget.model.userID;
      finalOriginalPostID = widget.model.docID;
    }

    _suspendClassicFeedForRoute();
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
      _restoreClassicFeedCenter();
    });
  }

  void _openReshareUsersSheet() {
    _suspendClassicFeedForRoute();
    final targetPostId = widget.model.originalPostID.trim().isNotEmpty
        ? widget.model.originalPostID.trim()
        : widget.model.docID;
    Get.bottomSheet(
      PostReshareListing(postID: targetPostId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      _restoreClassicFeedCenter();
    });
  }
}
