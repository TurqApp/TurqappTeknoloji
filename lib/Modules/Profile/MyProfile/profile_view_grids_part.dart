part of 'profile_view.dart';

extension _ProfileViewGridsPart on _ProfileViewState {
  Widget buildPhotoGrid() {
    final templist = controller.photos
        .where((val) => val.img.isNotEmpty && !val.deletedPost && !val.arsiv)
        .toList();

    return CustomScrollView(
      controller: controller.scrollControllerForSelection(2),
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (templist.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = templist[index];
              return GestureDetector(
                onTap: () async {
                  try {
                    final uid = _myUserId;
                    if (uid.isNotEmpty) {
                      await _postRepository.ensureViewerSeen(model.docID, uid);
                    }
                  } catch (_) {}
                  _suspendProfileFeedForRoute();
                  if (model.floodCount > 1) {
                    await Get.to(() => FloodListing(mainModel: model));
                  } else {
                    await Get.to(() =>
                        PhotoShorts(fetchedList: templist, startModel: model));
                  }
                  _resumeProfileFeedAfterRoute();
                },
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("profile.post_about_title".tr,
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "profile.post_about_body".tr,
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            arsivle(model);
                          },
                          child: Text("profile.archive".tr,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            _suspendProfileFeedForRoute();
                            await Get.to(() => EditPost(post: model));
                            _resumeProfileFeedAfterRoute();
                          },
                          child: Text("profile.edit".tr,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            final store = ProfileController.ensure();
                            store.allPosts
                                .removeWhere((e) => e.docID == model.docID);
                            store.photos
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: Text("common.delete".tr,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: Text("common.cancel".tr,
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                      ],
                    ),
                    barrierDismissible: true,
                  );
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.img.first,
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                      ),
                    ),
                    if (model.img.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.photo_on_rectangle,
                          color: Colors.white,
                          size: 20,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset("assets/icons/statsyeni.svg",
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn)),
                          3.pw,
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }, childCount: templist.length),
          )
        else
          SliverToBoxAdapter(child: EmptyRow(text: "profile.no_photos".tr)),
      ],
    );
  }

  Widget buildVideoGrid() {
    final templist = controller.videos
        .where((val) => val.hasPlayableVideo && !val.deletedPost && !val.arsiv)
        .toList();

    return CustomScrollView(
      controller: controller.scrollControllerForSelection(1),
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (templist.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = templist[index];
              return GestureDetector(
                onTap: () async {
                  try {
                    final uid = _myUserId;
                    if (uid.isNotEmpty) {
                      await _postRepository.ensureViewerSeen(model.docID, uid);
                    }
                  } catch (_) {}
                  _suspendProfileFeedForRoute();
                  if (model.floodCount > 1) {
                    await Get.to(() => FloodListing(mainModel: model));
                  } else {
                    await Get.to(() => SingleShortView(
                        startList: templist, startModel: model));
                  }
                  _resumeProfileFeedAfterRoute();
                },
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("profile.post_about_title".tr,
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "profile.post_about_body".tr,
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            arsivle(model);
                          },
                          child: Text("profile.archive".tr,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            _suspendProfileFeedForRoute();
                            await Get.to(() => EditPost(post: model));
                            _resumeProfileFeedAfterRoute();
                          },
                          child: Text("profile.edit".tr,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            final store = ProfileController.ensure();
                            store.allPosts
                                .removeWhere((e) => e.docID == model.docID);
                            store.videos
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: Text("common.delete".tr,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: Text("common.cancel".tr,
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                      ],
                    ),
                    barrierDismissible: true,
                  );
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail,
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        placeholder: (context, url) => const Center(
                            child:
                                CupertinoActivityIndicator(color: Colors.grey)),
                        errorWidget: (context, url, error) => const Center(
                            child:
                                CupertinoActivityIndicator(color: Colors.grey)),
                      ),
                    ),
                    const Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(CupertinoIcons.play_circle_fill,
                          color: Colors.white, size: 20),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset("assets/icons/statsyeni.svg",
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn)),
                          3.pw,
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }, childCount: templist.length),
          )
        else
          SliverToBoxAdapter(
            child: Center(child: EmptyRow(text: "profile.no_videos".tr)),
          ),
      ],
    );
  }

  Future<void> arsivle(PostsModel model) async {
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update({
      "arsiv": true,
    });

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisible = (model.timeStamp <= nowMs) && !model.flood;
      if (isVisible) {
        final me = _myUserId;
        if (me.isNotEmpty) {
          await UserRepository.ensure().updateUserFields(
            me,
            {'counterOfPosts': FieldValue.increment(-1)},
            mergeIntoCache: false,
          );
        }
      }
    } catch (_) {}

    final shortController = ShortController.maybeFind();
    final index = shortController?.shorts.indexOf(model) ?? -1;
    if (index >= 0) shortController!.shorts[index].arsiv = true;
    final exploreController = ExploreController.maybeFind();

    final index3 = exploreController?.explorePosts.indexOf(model) ?? -1;
    if (index3 >= 0) {
      exploreController!.explorePosts[index3].arsiv = true;
    }

    final index4 = exploreController?.explorePhotos.indexOf(model) ?? -1;
    if (index4 >= 0) {
      exploreController!.explorePhotos[index4].arsiv = true;
    }

    final index5 = exploreController?.exploreVideos.indexOf(model) ?? -1;
    if (index5 >= 0) {
      exploreController!.exploreVideos[index5].arsiv = true;
    }

    final store8 = AgendaController.maybeFind();
    if (store8 != null) {
      final index8 = store8.agendaList.indexOf(model);
      if (index8 >= 0) store8.agendaList[index8].arsiv = true;
    }

    final store9 = ProfileController.ensure();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = true;

    final store10 = ProfileController.ensure();
    final index10 = store10.videos.indexOf(model);
    if (index10 >= 0) store10.videos[index10].arsiv = true;

    final store11 = ProfileController.ensure();
    final index11 = store11.photos.indexOf(model);
    if (index11 >= 0) store11.photos[index11].arsiv = true;

    controller.photos.refresh();
    controller.videos.refresh();
    controller.allPosts.refresh();
  }

  Widget buildReshares() {
    final hasVideos = controller.reshares.isNotEmpty;

    return CustomScrollView(
      controller: controller.scrollControllerForSelection(3),
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (hasVideos)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = controller.reshares[index];
              return GestureDetector(
                onTap: () async {
                  _suspendProfileFeedForRoute();
                  if (model.hasPlayableVideo) {
                    await Get.to(
                      () => SingleShortView(
                        startList: controller.reshares
                            .where((val) => val.hasPlayableVideo)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  } else {
                    await Get.to(
                      () => PhotoShorts(
                        fetchedList: controller.reshares
                            .where((val) => val.img.isNotEmpty)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  }
                  _resumeProfileFeedAfterRoute();
                },
                onLongPress: () {
                  noYesAlert(
                      title: "profile.remove_reshare_title".tr,
                      message: "profile.remove_reshare_body".tr,
                      onYesPressed: () {
                        final store = ProfileController.ensure();
                        final index = store.reshares.indexOf(model);
                        if (index >= 0) store.reshares.removeAt(index);
                        PostDeleteService.instance.softDelete(model);
                      });
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail != ""
                            ? model.thumbnail
                            : model.img.first,
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    if (model.hasPlayableVideo)
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    if (model.img.isNotEmpty)
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.photo,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/statsyeni.svg",
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                          3.pw,
                          SeenCountLabel(model.docID)
                        ],
                      ),
                    )
                  ],
                ),
              );
            }, childCount: controller.reshares.length),
          )
        else
          SliverToBoxAdapter(
              child: Center(child: EmptyRow(text: "profile.no_reshares".tr))),
      ],
    );
  }

  Widget buildIzbiraklar(BuildContext context) {
    return CustomScrollView(
      controller: controller.scrollControllerForSelection(5),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (controller.scheduledPosts.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = controller.scheduledPosts[index];
              final hedef = DateTime.fromMillisecondsSinceEpoch(
                  model.izBirakYayinTarihi.toInt());
              final kalanText = kacGunKaldiFormatter(hedef);
              final isPublished = DateTime.now().millisecondsSinceEpoch >=
                  hedef.millisecondsSinceEpoch;

              return GestureDetector(
                onTap: () {},
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("profile.scheduled_post_title".tr,
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "profile.scheduled_post_body".tr,
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            _suspendProfileFeedForRoute();
                            await Get.to(() => EditPost(post: model));
                            _resumeProfileFeedAfterRoute();
                          },
                          child: Text("profile.edit".tr,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            controller.scheduledPosts
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: Text("common.delete".tr,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: Text("common.cancel".tr,
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                      ],
                    ),
                    barrierDismissible: true,
                  );
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail.isNotEmpty
                            ? model.thumbnail
                            : (model.img.isNotEmpty ? model.img.first : ''),
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                            child:
                                CupertinoActivityIndicator(color: Colors.grey)),
                        errorWidget: (context, url, error) => const Center(
                            child:
                                CupertinoActivityIndicator(color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        model.hasPlayableVideo
                            ? CupertinoIcons.play_circle_fill
                            : CupertinoIcons.photo,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (!isPublished)
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                      ),
                    if (!isPublished)
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  kalanText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                await IzBirakSubscriptionService.ensure()
                                    .subscribe(model.docID);
                                AppSnackbar(
                                  'profile.scheduled_subscribe_title'.tr,
                                  'profile.scheduled_subscribe_body'.tr,
                                );
                              },
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.add,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }, childCount: controller.scheduledPosts.length),
          )
        else
          SliverToBoxAdapter(
              child:
                  Center(child: EmptyRow(text: "profile.scheduled_none".tr))),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }
}
