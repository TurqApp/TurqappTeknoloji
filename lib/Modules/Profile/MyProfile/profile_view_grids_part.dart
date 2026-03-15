part of 'profile_view.dart';

extension _ProfileViewGridsPart on _ProfileViewState {
  Widget buildPhotoGrid() {
    final templist = controller.photos
        .where((val) => val.img.isNotEmpty && !val.deletedPost && !val.arsiv)
        .toList();

    return CustomScrollView(
      controller: controller.scrollController,
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
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await _postRepository.ensureViewerSeen(model.docID, uid);
                    }
                  } catch (_) {}
                  if (model.floodCount > 1 && model.flood == false) {
                    Get.to(() => FloodListing(mainModel: model));
                  } else {
                    Get.to(() =>
                        PhotoShorts(fetchedList: templist, startModel: model));
                  }
                },
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("Gönderi hakkında",
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Bu gönderi için ne yapmak istiyorsunuz?",
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
                          child: const Text("Arşivle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            Get.to(() => EditPost(post: model));
                          },
                          child: const Text("Düzenle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            final store = Get.find<ProfileController>();
                            store.allPosts
                                .removeWhere((e) => e.docID == model.docID);
                            store.photos
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: const Text("Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: const Text("Vazgeç",
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
          SliverToBoxAdapter(child: EmptyRow(text: "Fotoğraf Yok")),
      ],
    );
  }

  Widget buildVideoGrid() {
    final templist = controller.videos
        .where((val) => val.hasPlayableVideo && !val.deletedPost && !val.arsiv)
        .toList();

    return CustomScrollView(
      controller: controller.scrollController,
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
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await _postRepository.ensureViewerSeen(model.docID, uid);
                    }
                  } catch (_) {}
                  if (model.floodCount > 1 && model.flood == false) {
                    Get.to(() => FloodListing(mainModel: model));
                  } else {
                    Get.to(() => SingleShortView(
                        startList: templist, startModel: model));
                  }
                },
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("Gönderi hakkında",
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Bu gönderi için ne yapmak istiyorsunuz?",
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
                          child: const Text("Arşivle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            Get.to(() => EditPost(post: model));
                          },
                          child: const Text("Düzenle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            final store = Get.find<ProfileController>();
                            store.allPosts
                                .removeWhere((e) => e.docID == model.docID);
                            store.videos
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: const Text("Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: const Text("Vazgeç",
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
            child: Center(child: EmptyRow(text: "Video Yok")),
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
        final me = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (me.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(me)
              .update({'counterOfPosts': FieldValue.increment(-1)});
        }
      }
    } catch (_) {}

    final shortController = Get.find<ShortController>();
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = true;
    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].arsiv = true;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = true;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = true;

    if (Get.isRegistered<AgendaController>()) {
      final store8 = Get.find<AgendaController>();
      final index8 = store8.agendaList.indexOf(model);
      if (index8 >= 0) store8.agendaList[index8].arsiv = true;
    }

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = true;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.videos.indexOf(model);
    if (index10 >= 0) store10.videos[index10].arsiv = true;

    final store11 = Get.find<ProfileController>();
    final index11 = store11.photos.indexOf(model);
    if (index11 >= 0) store11.photos[index11].arsiv = true;

    controller.photos.refresh();
    controller.videos.refresh();
    controller.allPosts.refresh();
  }

  Widget buildReshares() {
    final hasVideos = controller.reshares.isNotEmpty;

    return CustomScrollView(
      controller: controller.scrollController,
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
                onTap: () {
                  if (model.hasPlayableVideo) {
                    Get.to(
                      () => SingleShortView(
                        startList: controller.reshares
                            .where((val) => val.hasPlayableVideo)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  } else {
                    Get.to(
                      () => PhotoShorts(
                        fetchedList: controller.reshares
                            .where((val) => val.img.isNotEmpty)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  }
                },
                onLongPress: () {
                  noYesAlert(
                      title: "Gönderiyi kaldır",
                      message:
                          "Bu gönderiyi yeniden paylaşılan gönderiler arasından silmek istediğinizden emin misiniz ?",
                      onYesPressed: () {
                        final store = Get.find<ProfileController>();
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
              child: Center(child: EmptyRow(text: "Yeniden paylaşım yok"))),
      ],
    );
  }

  Widget buildMarkets(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final itemWidth = screenSize.width / 2;
    final itemHeight = screenSize.height * 0.43;
    final aspectRatio = itemWidth / itemHeight;
    return ListView(
      children: [
        header(),
        const Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                "AlSat",
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  "Almak da satmak da artık çok daha kolay.\nYakında buradayız!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dummyAds.length,
            itemBuilder: (context, index) {
              final item = dummyAds[index];
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: AspectRatio(
                        aspectRatio: 1 / 1.2,
                        child: Image.asset(
                          "assets/dummy/${item.imageAsset}.webp",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          Text(
                            item.category,
                            style: const TextStyle(
                              color: Colors.pink,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          Row(
                            children: [
                              if (item.discount != null) ...[
                                Text(
                                  calculateDiscountedPrice(
                                    item.price,
                                    item.discount!,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                6.pw,
                                Expanded(
                                  child: Text(
                                    item.price,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: "MontserratMedium",
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  item.price,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ],
                            ],
                          ),
                          4.ph,
                          Text(
                            item.shortDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildIzbiraklar(BuildContext context) {
    return CustomScrollView(
      controller: controller.scrollController,
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
                      title: Text("İz Bırak Gönderi",
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Bu gönderi için ne yapmak istersiniz?",
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            Get.to(() => EditPost(post: model));
                          },
                          child: const Text("Düzenle",
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
                          child: const Text("Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: const Text("Vazgeç",
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
                                  'İz Bırak',
                                  'Yayın tarihinde bildirim alacaksınız.',
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
              child: Center(child: EmptyRow(text: "İz bırak gönderisi yok"))),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }
}
