part of 'short_content.dart';

extension ShortsContentActionsPart on _ShortsContentState {
  static const String _shortLinkFallbackDomain = 'https://turqapp.com';

  String? _shortPreviewImage() {
    final thumbnail = model.thumbnail.trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    if (model.img.isEmpty) return null;
    final image = model.img.first.trim();
    return image.isNotEmpty ? image : null;
  }

  Future<String> _resolveShortPublicUrl() async {
    final originalPostId = PostStoryShareService.resolveOriginalPostId(model);
    final sharePostId =
        originalPostId.isNotEmpty ? originalPostId : model.docID.trim();
    if (sharePostId.isEmpty) {
      return _shortLinkFallbackDomain;
    }

    final currentShortId = model.docID.trim();
    final url = await ShortLinkService().getPostPublicUrl(
      postId: sharePostId,
      desc: model.metin,
      imageUrl: _shortPreviewImage(),
      shortId: currentShortId.isNotEmpty && currentShortId != sharePostId
          ? currentShortId
          : null,
    );
    final normalizedUrl = url.trim();
    if (normalizedUrl.isNotEmpty && normalizedUrl != _shortLinkFallbackDomain) {
      return normalizedUrl;
    }
    return '$_shortLinkFallbackDomain/p/$sharePostId';
  }

  String _resolveShortPublicUrlForImmediateShare() {
    final originalPostId = PostStoryShareService.resolveOriginalPostId(model);
    final sharePostId =
        originalPostId.isNotEmpty ? originalPostId : model.docID.trim();
    if (sharePostId.isEmpty) {
      return _shortLinkFallbackDomain;
    }

    final currentShortId = model.docID.trim();
    return ShortLinkService().getPostPublicUrlForImmediateShare(
      postId: sharePostId,
      desc: model.metin,
      imageUrl: _shortPreviewImage(),
      shortId: currentShortId.isNotEmpty && currentShortId != sharePostId
          ? currentShortId
          : null,
    );
  }

  Widget pulldownmenu(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            videoPlayerController.pause();

            Get.to(() => PostCreator(
                  sharedVideoUrl: model.playbackUrl,
                  sharedAspectRatio: model.aspectRatio.toDouble(),
                  sharedThumbnail: model.thumbnail,
                  originalUserID:
                      PostStoryShareService.resolveOriginalUserId(model),
                  originalPostID:
                      PostStoryShareService.resolveOriginalPostId(model),
                  sharedAsPost: true,
                ))?.then((_) {
              resumeIfActive();
            });
          },
          title: 'short.publish_as_post'.tr,
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            videoPlayerController.pause();
            await PostStoryShareService.openStoryMakerForPost(model);
            resumeIfActive();
          },
          title: 'short.add_to_story'.tr,
          icon: CupertinoIcons.sparkles,
        ),
        if (model.userID == _currentUserId ||
            AdminAccessService.isKnownAdminSync())
          PullDownMenuItem(
            onTap: () {
              videoPlayerController.pause();
              Get.to(() => PostSharers(
                    postID: PostStoryShareService.resolveOriginalPostId(model),
                  ))?.then((_) {
                resumeIfActive();
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
            controller.gizle();
            videoPlayerController.pause();
          },
          title: 'common.hide'.tr,
          icon: CupertinoIcons.eye_slash,
        ),
        PullDownMenuItem(
          onTap: () async {
            final url = await _resolveShortPublicUrl();
            await Clipboard.setData(ClipboardData(text: url));

            AppSnackbar('common.copied'.tr, 'common.link_copied'.tr);
          },
          title: 'common.copy_link'.tr,
          icon: CupertinoIcons.doc_on_doc,
        ),
        PullDownMenuItem(
          onTap: () async {
            await ShareActionGuard.run(() async {
              final url = _resolveShortPublicUrlForImmediateShare();
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
        if (model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              videoPlayerController.pause();

              noYesAlert(
                title: 'common.delete_post_title'.tr,
                message: 'common.delete_post_message'.tr,
                cancelText: 'common.cancel'.tr,
                yesText: 'common.delete_post_confirm'.tr,
                yesButtonColor: CupertinoColors.destructiveRed,
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                if (!controller.silindi.value) {
                  resumeIfActive();
                }
              });
            },
            title: 'common.delete'.tr,
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsivlendi.value == false &&
            controller.model.arsiv == false &&
            model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
              videoPlayerController.pause();
            },
            title: 'common.archive'.tr,
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsivlendi.value == false &&
            controller.model.arsiv == true &&
            model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              resumeIfActive();
            },
            title: 'common.unarchive'.tr,
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (model.userID != _currentUserId)
          PullDownMenuItem(
            onTap: () {
              volumeOff(false);
              Get.to(() => ReportUser(
                    userID: model.userID,
                    postID: model.docID,
                    commentID: "",
                  ))?.then((_) {
                volumeOff(true);
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
        child: const Icon(Icons.more_vert, color: Colors.white, size: 25),
      ),
    );
  }

  Widget butonlar(BuildContext context) {
    final int commentVisibility = model.yorumVisibility;
    final int reshareVisibility = model.paylasimVisibility;
    final currentUser = CurrentUserService.instance.currentUser;
    final bool isOwner = _currentUserId == model.userID;
    final bool isVerified = currentUser?.hesapOnayi ?? false;
    final bool isFollowing = controller.takipEdiyorum.value;
    final bool canComment = isOwner ||
        commentVisibility == 0 ||
        (commentVisibility == 1 && isVerified) ||
        (commentVisibility == 2 && isFollowing);
    final bool canReshare = isOwner ||
        reshareVisibility == 0 ||
        (reshareVisibility == 1 && isVerified) ||
        (reshareVisibility == 2 && isFollowing);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: canComment
                  ? () {
                      volumeOff(false);
                      Get.bottomSheet(
                        Builder(
                          builder: (context) => buildPostCommentsSheet(
                            context: context,
                            postID: model.docID,
                            userID: model.userID,
                            collection: 'Posts',
                            preferredHeightFactor: 0.55,
                          ),
                        ),
                        isScrollControlled: true,
                        isDismissible: true,
                        enableDrag: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.black54,
                      ).then((v) {
                        volumeOff(true);
                      });
                    }
                  : null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bubble_right,
                    color:
                        canComment ? Colors.white : Colors.grey.withAlpha(80),
                    size: 20,
                  ),
                  2.pw,
                  Text(
                    NumberFormatter.format(controller.commentCount.value),
                    style: TextStyle(
                      color: canComment ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: () async {
                controller.toggleLike();
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.isLiked.value
                        ? CupertinoIcons.hand_thumbsup_fill
                        : CupertinoIcons.hand_thumbsup,
                    color: controller.isLiked.value
                        ? Colors.blueAccent
                        : Colors.white,
                    size: 20,
                  ),
                  2.pw,
                  Text(
                    NumberFormatter.format(controller.likeCount.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: canReshare ? controller.toggleReshare : null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 20,
                    color: canReshare
                        ? (controller.isReshared.value
                            ? Colors.green
                            : Colors.white)
                        : Colors.grey,
                  ),
                  2.pw,
                  Text(
                    NumberFormatter.format(controller.retryCount.value.toInt()),
                    style: TextStyle(
                      color: canReshare
                          ? (controller.isReshared.value
                              ? Colors.green
                              : Colors.white)
                          : Colors.grey,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: () {
                controller.toggleSave();
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.isSaved.value
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    color:
                        controller.isSaved.value ? Colors.orange : Colors.white,
                    size: 20,
                  ),
                  2.pw,
                  Text(
                    NumberFormatter.format(controller.savedCount.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 20,
                      color: Colors.white,
                    ),
                    2.pw,
                    Text(
                      NumberFormatter.format(
                        controller.viewCount.value.toInt(),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: AppFontFamilies.mmedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: IconButton(
              onPressed: () async {
                await ShareActionGuard.run(() async {
                  final url = _resolveShortPublicUrlForImmediateShare();
                  await ShareLinkService.shareUrl(
                    url: url,
                    title: 'post.share_title'.tr,
                    subject: 'post.share_title'.tr,
                  );
                });
              },
              icon: Transform.translate(
                offset: const Offset(0, -2),
                child: const Icon(
                  CupertinoIcons.share_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
