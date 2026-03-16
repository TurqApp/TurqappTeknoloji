part of 'short_content.dart';

extension ShortsContentBodyPart on ShortsContent {
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
                        videoPlayerController.play();
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
                          if (model.userID !=
                              FirebaseAuth.instance.currentUser!.uid) {
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
                                      if (model.userID !=
                                          FirebaseAuth
                                              .instance.currentUser!.uid) {
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
                          model.userID !=
                              FirebaseAuth.instance.currentUser!.uid &&
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
                                          "Takip Et",
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
                    // SHORT SAYFASINA ÖZEL: # ve @ beyaz olacak
                    hashtagColor: Colors.white,
                    mentionColor: Colors.white,
                    // SHORT SAYFASINA ÖZEL: #/@/link beyaz; buton mavi
                    interactiveColor: Colors.white,
                    expandButtonColor: Colors.blue,
                    onHashtagTap: (tag) {
                      videoPlayerController.pause();
                      Get.to(() => TagPosts(tag: tag))?.then((_) {
                        videoPlayerController.play();
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
                            targetUid !=
                                FirebaseAuth.instance.currentUser!.uid) {
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
                const Text(
                  "Gönderi Gizlendi",
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
                const Text(
                  "Bu gönderi gizlendi. Bunun gibi gönderileri akışında daha altlarda göreceksin.",
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
                    videoPlayerController.play();
                  },
                  child: const Text(
                    "Geri Al",
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
                        "Sonraki Gönderiye Geç",
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
                const Text(
                  "Gönderi Arşivlendi",
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
                const Text(
                  "Bu gönderiyi arşivlediniz.\nArtık kimseye bu gönderi gözükmeyecektir.",
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
                    videoPlayerController.play();
                  },
                  child: const Text(
                    "Geri Al",
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
                        "Sonraki Gönderiye Geç",
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
                const Text(
                  "Gönderi Sildiniz",
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
                const Text(
                  "Bu gönderi artık yayında değil.",
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
                        "Sonraki Gönderiye Geç",
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
              videoPlayerController.play();
            });
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            videoPlayerController.pause();
            await PostStoryShareService.openStoryMakerForPost(model);
            videoPlayerController.play();
          },
          title: 'Hikayene ekle',
          icon: CupertinoIcons.sparkles,
        ),
        if (model.userID == FirebaseAuth.instance.currentUser!.uid ||
            AdminAccessService.isKnownAdminSync())
          PullDownMenuItem(
            onTap: () {
              videoPlayerController.pause();
              Get.to(() => PostSharers(
                    postID: PostStoryShareService.resolveOriginalPostId(model),
                  ))?.then((_) {
                videoPlayerController.play();
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
            controller.gizle();
            videoPlayerController.pause();
          },
          title: 'Gizle',
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

            AppSnackbar("Kopyalandı", "Bağlantı linki panoya kopyalandı");
          },
          title: 'Linki Kopyala',
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
                title: 'TurqApp Gönderisi',
                subject: 'TurqApp Gönderisi',
              );
            });
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share_up,
        ),
        if (model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              // Videoyu durdur
              videoPlayerController.pause();

              noYesAlert(
                title: "Gönderiyi Sil",
                message: "Bu gönderiyi silmek istediğinizden emin misiniz?",
                cancelText: "Vazgeç",
                yesText: "Gönderiyi Sil",
                yesButtonColor: CupertinoColors.destructiveRed,
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                if (!controller.silindi.value) {
                  videoPlayerController.play();
                }
              });
            },
            title: 'Sil',
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsivlendi.value == false &&
            controller.model.arsiv == false &&
            model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
              videoPlayerController.pause();
            },
            title: "Arşivle",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsivlendi.value == false &&
            controller.model.arsiv == true &&
            model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              videoPlayerController.play();
            },
            title: "Arşivden Çıkart",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (model.userID != FirebaseAuth.instance.currentUser!.uid)
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
            title: 'Şikayet Et',
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
            child: _isBlackBadgeUser
                ? Obx(() {
                    final alreadyFlagged =
                        ShortsContent._flaggedPostIds.contains(model.docID);
                    return PullDownButton(
                      itemBuilder: (context) {
                        if (alreadyFlagged) {
                          return const <PullDownMenuEntry>[];
                        }
                        return ShortsContent._flagReasons
                            .map(
                              (reason) => PullDownMenuItem(
                                onTap: () async {
                                  try {
                                    final result =
                                        await Get.put(PostInteractionService())
                                            .flagPostWithReason(
                                      model.docID,
                                      reason: reason,
                                    );
                                    if (result.isOk) {
                                      ShortsContent._flaggedPostIds
                                          .add(model.docID);
                                    }
                                    if (result.accepted) {
                                      AppSnackbar(
                                          'İşaretle', 'İşaretleme kaydedildi.');
                                    } else if (result.alreadyFlagged) {
                                      AppSnackbar('Bilgi',
                                          'Bu gönderiyi zaten işaretlediniz.');
                                    } else {
                                      AppSnackbar(
                                          'Hata', 'İşaretleme başarısız oldu.');
                                    }
                                  } catch (_) {
                                    AppSnackbar(
                                        'Hata', 'İşaretleme başarısız oldu.');
                                  }
                                },
                                title: reason,
                              ),
                            )
                            .toList();
                      },
                      buttonBuilder: (context, showMenu) {
                        return IconButton(
                          onPressed: alreadyFlagged ? null : showMenu,
                          icon: Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: alreadyFlagged ? Colors.grey : Colors.amber,
                            size: 20,
                          ),
                        );
                      },
                    );
                  })
                : IconButton(
                    onPressed: controller.sendPost,
                    icon: const Icon(
                      CupertinoIcons.paperplane,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
