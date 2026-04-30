part of 'liked_posts.dart';

extension _LikedPostsContentPart on _LikedPostsState {
  Widget _buildGridTab({
    required List<PostsModel> posts,
    required String emptyText,
  }) {
    if (controller.isLoading.value && posts.isEmpty) {
      return const AppStateView.loading(title: '');
    }
    if (posts.isEmpty) {
      return AppStateView.empty(title: emptyText);
    }

    return SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: controller.refresh,
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 50),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 0.9,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final model = posts[index];
              final previewUrl = model.hasPlayableVideo
                  ? model.thumbnail
                  : (model.img.isNotEmpty ? model.img.first : '');
              return GestureDetector(
                onTap: () => _openLikedPost(posts, model),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (previewUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: 300,
                        memCacheHeight: 500,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey[300]),
                      )
                    else
                      Container(color: Colors.grey[300]),
                    if (model.hasPlayableVideo)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    if (model.floodCount > 1)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(170),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'saved_posts.series_badge'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openLikedPost(List<PostsModel> posts, PostsModel model) {
    if (model.floodCount > 1) {
      Get.to(() => FloodListing(mainModel: model));
      return;
    }
    if (model.hasPlayableVideo) {
      Get.to(() => SingleShortView(startList: posts, startModel: model));
      return;
    }
    Get.to(() => PhotoShorts(fetchedList: posts, startModel: model));
  }
}
