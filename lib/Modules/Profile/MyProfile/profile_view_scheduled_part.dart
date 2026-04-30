part of 'profile_view.dart';

extension _ProfileViewScheduledPart on _ProfileViewState {
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
                model.izBirakYayinTarihi.toInt(),
              );
              final kalanText = kacGunKaldiFormatter(hedef);
              final isPublished = DateTime.now().millisecondsSinceEpoch >=
                  hedef.millisecondsSinceEpoch;

              return GestureDetector(
                onTap: () {},
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text(
                        "profile.scheduled_post_title".tr,
                        style: TextStyles.bold15Black,
                        textAlign: TextAlign.center,
                      ),
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
                            controller.scheduledPosts
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
                        imageUrl: model.thumbnail.isNotEmpty
                            ? model.thumbnail
                            : (model.img.isNotEmpty ? model.img.first : ''),
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        ),
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
                                  vertical: 6,
                                  horizontal: 10,
                                ),
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
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.32,
              child: AppStateView.empty(title: "profile.scheduled_none".tr),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }
}
