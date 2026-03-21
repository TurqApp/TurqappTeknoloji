part of 'short_content.dart';

extension ShortsContentBodyPart on _ShortsContentState {
  Widget userInfoBar(BuildContext context) {
    return Obx(() {
      return Container(
        color: Colors.white.withAlpha(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (videoPlayerController.value.isPlaying) {
                        videoPlayerController.pause();
                        volumeOff(false); // Manual pause bildirimi
                      } else {
                        resumeIfActive();
                        volumeOff(true); // Manual play bildirimi
                      }
                    },
                    child: ListenableBuilder(
                      listenable: videoPlayerController,
                      builder: (_, __) => Icon(
                        videoPlayerController.value.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: videoPlayerController,
                      builder: (_, __) {
                        final val = videoPlayerController.value;
                        return ProgressBar(
                          thumbRadius: 3,
                          timeLabelLocation: TimeLabelLocation.above,
                          progress: val.position,
                          total: val.duration,
                          buffered: val.buffered.isNotEmpty
                              ? val.buffered.last.end
                              : Duration.zero,
                          onSeek: videoPlayerController.seekTo,
                          timeLabelTextStyle:
                              const TextStyle(color: Colors.white),
                          thumbColor: Colors.white,
                          progressBarColor: Colors.white,
                          baseBarColor: Colors.grey,
                          bufferedBarColor: Colors.white38,
                          barHeight: 2,
                          timeLabelPadding: 10,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (model.userID != _currentUserId) {
                            volumeOff(false);
                            Get.to(() => SocialProfile(userID: model.userID))
                                ?.then((v) {
                              volumeOff(true);
                            });
                          }
                        },
                        child: ClipOval(
                          child: SizedBox(
                            width: 35,
                            height: 35,
                            child: controller.avatarUrl.value != ""
                                ? CachedNetworkImage(
                                    imageUrl: controller.avatarUrl.value,
                                    fit: BoxFit.cover,
                                    memCacheHeight: 100,
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (model.userID != _currentUserId) {
                                        volumeOff(false);
                                        Get.to(SocialProfile(
                                                userID: model.userID))
                                            ?.then((v) {
                                          volumeOff(true);
                                        });
                                      }
                                    },
                                    child: Text(
                                      controller.fullName.value,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: AppFontFamilies.mbold,
                                      ),
                                    ),
                                  ),
                                ),
                                RozetContent(
                                  size: 14,
                                  userID: model.userID,
                                  rozetValue: model.rozet,
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
                          model.userID != _currentUserId &&
                          controller.avatarUrl.value != "")
                        Transform.translate(
                          offset: Offset(20, 0),
                          child: Obx(() {
                            final isLoading = controller.followLoading.value;
                            return ScaleTap(
                              enabled: !isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      controller.onlyFollowUserOneTime();
                                    },
                              child: Container(
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12)),
                                    border: Border.all(color: Colors.white)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CupertinoActivityIndicator(
                                            color: Colors.white,
                                            radius: 7,
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
                          offset: Offset(15, -12), child: pulldownmenu(context))
                    ],
                  ),
                  ClickableTextContent(
                    fontSize: 13,
                    text: model.metin,
                    toggleExpandOnTextTap: true,
                    // SHORT SAYFASINA ÖZEL: Normal metin beyaz
                    fontColor: Colors.white,
                    // SHORT SAYFASINA ÖZEL: #/@/link mavi ve tıklanabilir kalsın
                    hashtagColor: Colors.blue,
                    mentionColor: Colors.blue,
                    urlColor: Colors.blue,
                    interactiveColor: Colors.blue,
                    expandButtonColor: Colors.white,
                    expandButtonFontSize: 13,
                    onHashtagTap: (tag) {
                      videoPlayerController.pause();
                      Get.to(() => TagPosts(tag: tag))?.then((_) {
                        resumeIfActive();
                      });
                    },
                    onUrlTap: (v) async {
                      volumeOff(false);
                      final uniqueKey =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      await RedirectionLink().goToLink(v, uniqueKey: uniqueKey);
                      volumeOff(true);
                    },
                    onMentionTap: (mention) {
                      (() async {
                        final targetUid =
                            await UsernameLookupRepository.ensure()
                                    .findUidForHandle(mention) ??
                                "";
                        if (targetUid.isNotEmpty &&
                            targetUid != _currentUserId) {
                          volumeOff(false);
                          await Get.to(() => SocialProfile(userID: targetUid));
                          volumeOff(true);
                        }
                      })();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Transform.translate(
                offset: const Offset(-5, 0),
                child: butonlar(context),
              ),
            ),
          ],
        ),
      );
    });
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
                7.ph,
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
                    resumeIfActive();
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
                    resumeIfActive();
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
            final previewImage = model.thumbnail.trim().isNotEmpty
                ? model.thumbnail.trim()
                : (model.img.isNotEmpty ? model.img.first.trim() : null);
            final url = await ShortLinkService().getPostPublicUrl(
              postId: model.docID,
              desc: model.metin,
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
              final previewImage = model.thumbnail.trim().isNotEmpty
                  ? model.thumbnail.trim()
                  : (model.img.isNotEmpty ? model.img.first.trim() : null);
              final url = await ShortLinkService().getPostPublicUrl(
                postId: model.docID,
                desc: model.metin,
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
        if (model.userID == _currentUserId)
          PullDownMenuItem(
            onTap: () {
              // Videoyu durdur
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
                  commentID: ""))?.then((_) {
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
    final bool isOwner = CurrentUserService.instance.userId == model.userID;
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
          /// Yorum Butonu
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: canComment
                  ? () {
                      volumeOff(false);
                      Get.bottomSheet(
                        SizedBox(
                          height: Get.height *
                              0.55, // Ekranın %95'i kadar yükseklik
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: PostComments(
                              postID: model.docID,
                              userID: model.userID,
                              collection: 'Posts',
                            ),
                          ),
                        ),
                        isScrollControlled: true,
                        isDismissible: true,
                        enableDrag: true, // Sürükleyerek kapatma için
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        backgroundColor:
                            Colors.white, // Alt barda arka plan rengi
                        barrierColor: Colors.black54, // Gri karartma rengi
                      ).then((v) {
                        // Yorum sayısı real-time güncellendiği için getComments() artık gerekli değil
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
                    // controller.commentCount.toString(),
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

          /// Beğen Butonu
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

          /// Kaydet Butonu

          // yeniden paylaşma butonu
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
                    //controller.savedCount.toString(),
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

          /// Görüntüleme Butonu (Sadece bilgi, işlem yok)
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Obx(() => Row(
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
                            controller.viewCount.value.toInt()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: AppFontFamilies.mmedium,
                        ),
                      ),
                    ],
                  )),
            ),
          ),

          /// gönder / işaretle Butonu
          Flexible(
            flex: 1,
            child: IconButton(
              onPressed: () async {
                await ShareActionGuard.run(() async {
                  final previewImage = model.thumbnail.trim().isNotEmpty
                      ? model.thumbnail.trim()
                      : (model.img.isNotEmpty ? model.img.first.trim() : null);
                  final url = await ShortLinkService().getPostPublicUrl(
                    postId: model.docID,
                    desc: model.metin,
                    imageUrl: previewImage,
                  );
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
