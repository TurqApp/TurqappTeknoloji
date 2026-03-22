// ignore_for_file: invalid_use_of_protected_member

part of 'photo_short_content.dart';

extension PhotoShortContentBodyPart on _PhotoShortContentState {
  Widget userInfoBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppBackButton(
                  icon: CupertinoIcons.arrow_left,
                  iconColor: Colors.white,
                  surfaceColor: Color(0x50000000),
                ),
                if (widget.model.floodCount > 1)
                  TextButton(
                    onPressed: () {
                      Get.to(() => FloodListing(mainModel: widget.model));
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.blue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        "${widget.model.floodCount} ${'saved_posts.series_badge'.tr}",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 35,
                                height: 35,
                                child: Obx(
                                  () => controller.avatarUrl.value != ""
                                      ? GestureDetector(
                                          onTap: () {
                                            if (widget.model.userID !=
                                                _currentUserId) {
                                              Get.to(
                                                () => SocialProfile(
                                                  userID: widget.model.userID,
                                                ),
                                              );
                                            }
                                          },
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                controller.avatarUrl.value,
                                            fit: BoxFit.cover,
                                            memCacheHeight: 100,
                                          ),
                                        )
                                      : const Center(
                                          child: CupertinoActivityIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (widget.model.userID !=
                                              _currentUserId) {
                                            Get.to(
                                              () => SocialProfile(
                                                userID: widget.model.userID,
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          controller.fullName.value,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: AppFontFamilies.mbold,
                                          ),
                                        ),
                                      ),
                                      RozetContent(
                                        size: 14,
                                        userID: widget.model.userID,
                                        rozetValue: widget.model.rozet,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    controller.nickname.value.trim().isEmpty
                                        ? ''
                                        : '@${controller.nickname.value.trim()}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: AppFontFamilies.mregular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 7),
                            if (!controller.takipEdiyorum.value &&
                                widget.model.userID != _currentUserId &&
                                controller.avatarUrl.value != "")
                              Transform.translate(
                                offset: Offset(15, 0),
                                child: Obx(() {
                                  final isLoading =
                                      controller.followLoading.value;
                                  return ScaleTap(
                                    enabled: !isLoading,
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            controller.toggleFollowStatus(
                                              widget.model.userID,
                                            );
                                          },
                                    child: Container(
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'following.follow'.tr,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily:
                                                        AppFontFamilies.mmedium,
                                                    fontSize: FontSizes.size12),
                                              ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            Transform.translate(
                              offset: Offset(15, -2),
                              child: pulldownmenu(context),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                          ],
                        ),
                      ),
                      HashtagTextVideoPost(
                        text: widget.model.metin,
                        color: Colors.white,
                        volume: (bool) {
                          ///gerek yok
                        },
                      ),
                    ],
                  ),
                ),
                butonlar(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget butonlar(BuildContext context) {
    final int commentVisibility = widget.model.yorumVisibility;
    final int reshareVisibility = widget.model.paylasimVisibility;
    final currentUser = CurrentUserService.instance.currentUser;
    final bool isOwner = _currentUserId == widget.model.userID;
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Yorum Butonu
        Expanded(
          child: TextButton(
            onPressed:
                canComment ? controller.showPostCommentsBottomSheet : null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bubble_right,
                    color:
                        canComment ? Colors.white : Colors.grey.withAlpha(80),
                    size: 23,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(controller.commentCount.value),
                    style: TextStyle(
                      color: canComment ? Colors.white : Colors.grey,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// Beğen Butonu
        Expanded(
          child: TextButton(
            onPressed: () async {
              controller.toggleLike();
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 23,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.likes.contains(
                      _currentUserId,
                    )
                        ? CupertinoIcons.hand_thumbsup_fill
                        : CupertinoIcons.hand_thumbsup,
                    color: controller.likes.contains(
                      _currentUserId,
                    )
                        ? Colors.blueAccent
                        : Colors.white,
                    size: 23,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(controller.likeCount.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: TextButton(
            onPressed: canReshare ? controller.toggleReshare : null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 25,
                    color: canReshare
                        ? (controller.isReshared.value
                            ? Colors.green
                            : Colors.white)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(controller.retryCount.value),
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
        ),

        Expanded(
          child: TextButton(
            onPressed: controller.toggleSave,
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
                  size: 23,
                ),
                SizedBox(width: 4),
                Text(
                  NumberFormatter.format(controller.savedCount.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: AppFontFamilies.mmedium,
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Görüntüleme Butonu (Sadece bilgi, işlem yok)
        Expanded(
          child: TextButton(
            onPressed: null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 35,
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/statsyeni.svg",
                        height: 30,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormatter.format(PostCountManager.instance
                            .getStatsCount(controller.model.docID)
                            .value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: AppFontFamilies.mmedium,
                        ),
                      ),
                    ],
                  )),
            ),
          ),
        ),

        Expanded(
          child: TextButton(
            onPressed: () async {
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
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Icon(
                    CupertinoIcons.share_up,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget pulldownmenu(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            Get.to(() => PostCreator(
                  sharedVideoUrl: widget.model.playbackUrl,
                  sharedAspectRatio: widget.model.aspectRatio.toDouble(),
                  sharedThumbnail: widget.model.thumbnail,
                  originalUserID:
                      PostStoryShareService.resolveOriginalUserId(widget.model),
                  originalPostID:
                      PostStoryShareService.resolveOriginalPostId(widget.model),
                  sharedAsPost: true,
                ))?.then((_) {});
          },
          title: 'short.publish_as_post'.tr,
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            await PostStoryShareService.openStoryMakerForPost(widget.model);
          },
          title: 'short.add_to_story'.tr,
          icon: CupertinoIcons.sparkles,
        ),
        if (widget.model.userID == _currentUserId ||
            controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              Get.to(() => PostSharers(
                    postID: PostStoryShareService.resolveOriginalPostId(
                      widget.model,
                    ),
                  ));
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
          },
          title: 'common.hide'.tr,
          icon: CupertinoIcons.eye_slash,
        ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              controller.sendAdminPushForPost();
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
                title: 'post.share_title'.tr,
                subject: 'post.share_title'.tr,
              );
            });
          },
          title: 'common.share'.tr,
          icon: CupertinoIcons.share_up,
        ),
        if (widget.model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              noYesAlert(
                title: 'common.delete_post_title'.tr,
                message: 'common.delete_post_message'.tr,
                yesText: 'common.delete_post_confirm'.tr,
                cancelText: 'common.cancel'.tr,
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {});
            },
            title: 'common.delete'.tr,
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            widget.model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
            },
            title: 'post.archive'.tr,
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == true &&
            widget.model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
            },
            title: 'post.unarchive'.tr,
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != _currentUserId)
          PullDownMenuItem(
            onTap: () {
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {});
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
        child: Icon(Icons.more_vert, color: Colors.white, size: 22),
      ),
    );
  }

  Widget gonderiGizlendi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'post_state.hidden_title'.tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  'post_state.hidden_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    controller.gizlemeyiGeriAl();
                  },
                  child: Text(
                    'common.undo'.tr,
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                )
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'post_state.archived_title'.tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  'post_state.archived_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    controller.arsivdenCikart();
                  },
                  child: Text(
                    'common.undo'.tr,
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                )
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'post_state.deleted_title'.tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  'post_state.deleted_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
