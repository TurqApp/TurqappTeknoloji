part of 'explore_view.dart';

extension _ExploreViewTabsPart on _ExploreViewState {
  double _safeAspectRatio(num ratio, {double fallback = 9 / 16}) {
    final value = ratio.toDouble();
    if (!value.isFinite || value <= 0) return fallback;
    return value.clamp(0.56, 1.91);
  }

  Widget _buildCoverFrame({
    required double aspectRatio,
    required Widget child,
  }) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth;
          final cellHeight = constraints.maxHeight;
          double mediaWidth = cellWidth;
          double mediaHeight = mediaWidth / aspectRatio;

          if (mediaHeight < cellHeight) {
            mediaHeight = cellHeight;
            mediaWidth = mediaHeight * aspectRatio;
          }

          return OverflowBox(
            alignment: Alignment.center,
            minWidth: mediaWidth,
            maxWidth: mediaWidth,
            minHeight: mediaHeight,
            maxHeight: mediaHeight,
            child: SizedBox(
              width: mediaWidth,
              height: mediaHeight,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreTabs(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          PageLineBar(
            barList: [
              'explore.tab.trending'.tr,
              'explore.tab.for_you'.tr,
              'explore.tab.series'.tr,
            ],
            pageName: kExplorePageLineBarTag,
            pageController: controller.pageController,
          ),
          Expanded(
            child: PageView(
              controller: controller.pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (idx) {
                controller.selection.value = idx;
                syncPageLineBarSelection(
                  kExplorePageLineBarTag,
                  idx,
                );
                if (idx == 0 && controller.trendingTags.isEmpty) {
                  controller.fetchTrendingTags();
                } else if (idx == 1 &&
                    controller.explorePosts.isEmpty &&
                    !controller.exploreIsLoading.value) {
                  controller.fetchExplorePosts();
                } else if (idx == 2 &&
                    controller.exploreFloods.isEmpty &&
                    !controller.floodsIsLoading.value) {
                  controller.fetchFloods();
                }
              },
              children: [
                _buildTrendingTab(context),
                _buildForYouTab(context),
                _buildSeriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTab(BuildContext context) {
    return Obx(() {
      final items = controller.trendingTags.take(30).toList();
      return RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () async {
          await controller.fetchTrendingTags();
        },
        child: items.isEmpty
            ? ListView(
                key: const PageStorageKey('Explore_Gundemdekiler_Empty'),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  Center(
                    child: EmptyRow(text: 'explore.no_results'.tr),
                  ),
                ],
              )
            : ListView.builder(
                key: const PageStorageKey('Explore_Gundemdekiler'),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final title =
                      item.hasHashtag ? "#${item.hashtag}" : item.hashtag;
                  return Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          controller.suspendExplorePreview();
                          Get.to(() => TagPosts(tag: item.hashtag))?.then((_) {
                            controller.resumeExplorePreview();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'explore.trending_rank'.trParams(
                                          {
                                            'index': '${i + 1}',
                                          },
                                        ),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontFamily: "Montserrat",
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontFamily: "MontserratBold",
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.black38,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          height: 1,
                          child: Divider(
                            color: Colors.grey.withAlpha(50),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      );
    });
  }

  Widget _buildForYouTab(BuildContext context) {
    return Obx(() {
      final list = controller.explorePosts;
      return RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () async {
          controller.explorePosts.clear();
          controller.lastExploreDoc = null;
          controller.exploreHasMore.value = true;
          await controller.fetchExplorePosts();
        },
        child: list.isEmpty && !controller.exploreIsLoading.value
            ? Center(child: EmptyRow(text: 'explore.no_results'.tr))
            : GridView.builder(
                key: const PageStorageKey('Explore_SanaOzel'),
                controller: controller.exploreScroll,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  childAspectRatio: 0.68,
                ),
                itemCount:
                    list.length + (controller.exploreHasMore.value ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == list.length) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  final model = list[i];
                  final shouldPlayPreview = _shouldPlayExplorePreview(i);
                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () async {
                        controller.suspendExplorePreview(
                          focusIndex: i,
                        );
                        if (model.floodCount > 1) {
                          await VideoControllerPool.pauseAll();
                          await Get.to(() => FloodListing(mainModel: model));
                          controller.resumeExplorePreview();
                          return;
                        }
                        await VideoControllerPool.pauseAll();
                        final videos = list;
                        await Get.to(
                          () => SingleShortView(
                            startList: videos,
                            startModel: model,
                          ),
                        );
                        controller.resumeExplorePreview();
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildCoverFrame(
                            aspectRatio: _safeAspectRatio(model.aspectRatio),
                            child: shouldPlayPreview
                                ? SmartMiniVideoPlayer(
                                    videoUrl: model.playbackUrl,
                                    thumbnailUrl: model.thumbnail,
                                    visibilityKey: "${model.docID}_$i",
                                    muted: true,
                                    aspectRatio:
                                        _safeAspectRatio(model.aspectRatio),
                                    useAspectRatio: true,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: model.thumbnail,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 200,
                                    memCacheHeight: 600,
                                    placeholder: (c, u) => Container(
                                      color: Colors.grey[300],
                                    ),
                                    errorWidget: (c, u, e) =>
                                        const Icon(Icons.error),
                                  ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Row(
                              children: [
                                Icon(
                                  shouldPlayPreview
                                      ? CupertinoIcons.play_circle_fill
                                      : CupertinoIcons.eye,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCountCompact(model.stats.statsCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (model.floodCount > 1)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Texts.colorfulFloodForExplore,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _buildSeriesTab() {
    return Obx(() {
      final list = controller.exploreFloods;
      final showLoader =
          controller.floodsHasMore.value && controller.floodsIsLoading.value;
      if (list.isEmpty && !controller.floodsIsLoading.value) {
        return Center(child: EmptyRow(text: 'explore.no_series'.tr));
      }
      return RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () async {
          controller.exploreFloods.clear();
          controller.lastFloodsDoc = null;
          controller.floodsHasMore.value = true;
          await controller.fetchFloods();
        },
        child: ListView.builder(
          key: const PageStorageKey('Explore_Floods'),
          controller: controller.floodsScroll,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: list.length + (showLoader ? 1 : 0),
          itemBuilder: (c, i) {
            if (i == list.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            final p = list[i];
            return RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? 8 : 0,
                  bottom: i == list.length - 1 ? 24 : 10,
                ),
                child: AgendaContent(
                  key: ValueKey('explore-series-${p.docID}'),
                  model: p,
                  isPreview: true,
                  instanceTag: 'explore_series_${p.docID}',
                  shouldPlay: false,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  String _formatCountCompact(num value) {
    final v = value.toDouble();
    if (v >= 1000000) {
      return "${(v / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M";
    }
    if (v >= 1000) {
      return "${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}B";
    }
    return value.toInt().toString();
  }

  bool _shouldPlayExplorePreview(int index) {
    if (controller.explorePreviewSuspended.value) {
      return false;
    }
    final exploreTabSelected = controller.selection.value == 1 &&
        !controller.isSearchMode.value &&
        !controller.isKeyboardOpen.value &&
        controller.searchText.value.trim().isEmpty;
    if (!exploreTabSelected) {
      return false;
    }
    if (controller.explorePreviewFocusIndex.value == index) {
      return true;
    }
    final oneBased = index + 1;
    if (oneBased == 1) return true;
    if (oneBased < 6) return false;
    return ((oneBased - 6) % 6 == 0) || ((oneBased - 7) % 6 == 0);
  }
}
