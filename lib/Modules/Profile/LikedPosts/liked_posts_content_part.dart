part of 'liked_posts.dart';

extension _LikedPostsContentPart on _LikedPostsState {
  Widget _buildPostsTab() {
    final list = controller.all;
    if (controller.isLoading.value && list.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.grey),
      );
    }
    if (list.isEmpty) {
      return EmptyRow(text: "common.no_results".tr);
    }
    return SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: controller.all.isNotEmpty
            ? RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: controller.refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _onScroll(),
                    );
                    return false;
                  },
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: controller.all.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const SizedBox();
                      }

                      if (index == controller.all.length + 1) {
                        return const SizedBox(height: 50);
                      }

                      final actualIndex = index - 1;
                      final model = controller.all[actualIndex];
                      final itemKey = controller.getPostKey(model.docID);
                      final isCentered =
                          controller.centeredIndex.value == actualIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  top: actualIndex == 0 ? 12 : 0),
                              child: AgendaContent(
                                key: itemKey,
                                model: model,
                                isPreview: false,
                                shouldPlay: isCentered,
                                instanceTag:
                                    controller.agendaInstanceTag(model.docID),
                              ),
                            ),
                            SizedBox(
                              height: 2,
                              child: Divider(
                                color: Colors.grey.withAlpha(50),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            : Center(
                child: EmptyRow(text: "liked_posts.no_posts".tr),
              ),
      ),
    );
  }

  Widget _buildPhotosTab() {
    final list = controller.all.where((val) => val.img.isNotEmpty).toList();
    if (controller.isLoading.value && list.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.grey),
      );
    }
    if (list.isEmpty) {
      return EmptyRow(text: "common.no_results".tr);
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            controller.capturePendingCenteredEntry(model: list[index]);
            controller.lastCenteredIndex =
                controller.currentVisibleIndex.value >= 0
                    ? controller.currentVisibleIndex.value
                    : controller.lastCenteredIndex;
            controller.centeredIndex.value = -1;
            await Get.to(() => PhotoShorts(
                  startModel: list[index],
                  fetchedList: list,
                ));
            controller.resumeCenteredPost();
          },
          child: CachedNetworkImage(
            imageUrl: list[index].img.first,
            fit: BoxFit.cover,
            fadeOutDuration: Duration.zero,
            memCacheWidth: 200,
            memCacheHeight: 500,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final list = controller.all.where((val) => val.hasPlayableVideo).toList();
    if (controller.isLoading.value && list.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.grey),
      );
    }
    if (list.isEmpty) {
      return EmptyRow(text: "common.no_results".tr);
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 0.7,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            controller.capturePendingCenteredEntry(model: list[index]);
            controller.lastCenteredIndex =
                controller.currentVisibleIndex.value >= 0
                    ? controller.currentVisibleIndex.value
                    : controller.lastCenteredIndex;
            controller.centeredIndex.value = -1;
            await Get.to(() => SingleShortView(
                  startModel: list[index],
                  startList: list,
                ));
            controller.resumeCenteredPost();
          },
          child: CachedNetworkImage(
            imageUrl: list[index].thumbnail,
            fit: BoxFit.cover,
            fadeOutDuration: Duration.zero,
            memCacheWidth: 200,
            memCacheHeight: 500,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );
      },
    );
  }
}
