part of 'profile_view.dart';

extension _ProfileViewPhotoPart on _ProfileViewState {
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
                      title: Text(
                        "profile.post_about_title".tr,
                        style: TextStyles.bold15Black,
                        textAlign: TextAlign.center,
                      ),
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
                          child: Text(
                            "profile.archive".tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            _suspendProfileFeedForRoute();
                            await Get.to(() => EditPost(post: model));
                            _resumeProfileFeedAfterRoute();
                          },
                          child: Text(
                            "profile.edit".tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
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
                          child: Text(
                            "common.delete".tr,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: Text(
                            "common.cancel".tr,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
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
                          SvgPicture.asset(
                            "assets/icons/statsyeni.svg",
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          3.pw,
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    ),
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
}
