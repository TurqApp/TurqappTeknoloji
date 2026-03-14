import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Widgets/Ads/ad_placement_hooks.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/texts.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import '../../Core/empty_row.dart';
import '../../Core/Helpers/RoadToTop/road_to_top.dart';
import '../Agenda/TagPosts/tag_media_widgets.dart';
import '../Agenda/TagPosts/tag_posts.dart';
import '../Agenda/FloodListing/flood_listing.dart';
import 'SearchedUser/search_user_content.dart';
import 'explore_controller.dart';

class StaggeredTile {
  final int crossAxisCellCount;
  final num mainAxisCellCount;

  const StaggeredTile.count(this.crossAxisCellCount, this.mainAxisCellCount);
}

class SliverStaggeredGrid {
  static Widget countBuilder({
    required int crossAxisCount,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required StaggeredTile Function(int) staggeredTileBuilder,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
  }) {
    return SliverMasonryGrid.count(
      crossAxisCount: crossAxisCount,
      childCount: itemCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      itemBuilder: (context, index) {
        final tile = staggeredTileBuilder(index);
        final aspectRatio = tile.mainAxisCellCount == 0
            ? 1.0
            : tile.crossAxisCellCount / tile.mainAxisCellCount;
        return AspectRatio(
          aspectRatio: aspectRatio.toDouble(),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

class ExploreView extends StatelessWidget {
  ExploreView({super.key});

  ExploreController get controller {
    if (Get.isRegistered<ExploreController>()) {
      return Get.find<ExploreController>();
    } else {
      return Get.put(ExploreController());
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TurqSearchBar(
                            controller: controller.searchController,
                            focusNode: controller.searchFocus,
                            hintText: "Ara",
                            onTap: () {
                              controller.isSearchMode.value = true;
                            },
                            onChanged: (v) {
                              controller.onSearchChanged(v);
                            },
                          ),
                        ),
                      ),
                      Obx(() {
                        if (!controller.isKeyboardOpen.value) {
                          return const SizedBox.shrink();
                        }

                        return GestureDetector(
                          onTap: () {
                            controller.searchFocus.unfocus();
                            controller.searchController.clear();
                            controller.searchText.value = "";
                            controller.searchedList.clear();
                            controller.searchedHashtags.clear();
                            controller.searchedTags.clear();
                            controller.showAllRecent.value = false;
                            controller.isKeyboardOpen.value = false;
                            controller.isSearchMode.value = false;
                            closeKeyboard(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                color: Colors.black,
                                size: 17,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Obx(() {
                  final showExploreTabs =
                      !controller.isSearchMode.value &&
                      !controller.isKeyboardOpen.value &&
                      controller.searchText.value.trim().isEmpty;

                  if (showExploreTabs) {
                    return Expanded(
                      child: Column(
                        children: [
                          PageLineBar(
                            barList: const [
                              "Gündem",
                              "Sana Özel",
                              "Floods",
                            ],
                            pageName: 'Explore',
                            pageController: controller.pageController,
                          ),
                          Expanded(
                            child: PageView(
                              controller: controller.pageController,
                              physics: const ClampingScrollPhysics(),
                              onPageChanged: (idx) {
                                Get.find<PageLineBarController>(tag: "Explore")
                                    .selection
                                    .value = idx;
                              },
                              children: [
                                // ---- 1. Sekme: Gündemdekiler ----
                                Obx(() {
                                  final items =
                                      controller.trendingTags.take(30).toList();
                                  return RefreshIndicator(
                                    backgroundColor: Colors.black,
                                    color: Colors.white,
                                    onRefresh: () async {
                                      await controller.fetchTrendingTags();
                                    },
                                    child: ListView.builder(
                                      key: const PageStorageKey(
                                          'Explore_Gundemdekiler'),
                                      itemCount: items.length,
                                      itemBuilder: (context, i) {
                                        final item = items[i];
                                        final title = item.hasHashtag
                                            ? "#${item.hashtag}"
                                            : item.hashtag;
                                        return Column(
                                          children: [
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                Get.to(() => TagPosts(
                                                    tag: item.hashtag));
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15,
                                                        vertical: 10),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "${i + 1} - Türkiye tarihinde gündemde",
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: 14,
                                                                fontFamily:
                                                                    "Montserrat",
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Text(
                                                              title,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 18,
                                                                fontFamily:
                                                                    "MontserratBold",
                                                                height: 1.1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 8),
                                                        child: Icon(
                                                          CupertinoIcons
                                                              .chevron_right,
                                                          color: Colors.black38,
                                                          size: 16,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15),
                                              child: SizedBox(
                                                height: 1,
                                                child: Divider(
                                                  color:
                                                      Colors.grey.withAlpha(50),
                                                ),
                                              ),
                                            )
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                }),

                                // ---- 1. Sekme: Sana Özel ----
                                Obx(() {
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
                                    child: list.isEmpty &&
                                            !controller.exploreIsLoading.value
                                        ? Center(
                                            child: EmptyRow(
                                                text: "Sonuç bulunamadı"))
                                        : GridView.builder(
                                            key: const PageStorageKey(
                                                'Explore_SanaOzel'),
                                            controller:
                                                controller.exploreScroll,
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 1,
                                              crossAxisSpacing: 1,
                                              childAspectRatio: 0.68,
                                            ),
                                            itemCount: list.length +
                                                (controller.exploreHasMore.value
                                                    ? 1
                                                    : 0),
                                            itemBuilder: (context, i) {
                                              if (i == list.length) {
                                                return const Center(
                                                    child:
                                                        CupertinoActivityIndicator());
                                              }
                                              final model = list[i];
                                              final shouldPlayPreview =
                                                  _shouldPlayExplorePreview(i);
                                              return RepaintBoundary(
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    if (model.floodCount > 1 &&
                                                        model.flood == false) {
                                                      await VideoControllerPool
                                                          .pauseAll();
                                                      Get.to(() => FloodListing(
                                                          mainModel: model));
                                                      return;
                                                    }
                                                    await VideoControllerPool
                                                        .pauseAll();
                                                    final videos = list;
                                                    Get.to(
                                                        () => SingleShortView(
                                                              startList: videos,
                                                              startModel: model,
                                                            ));
                                                  },
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      _buildCoverFrame(
                                                        aspectRatio:
                                                            _safeAspectRatio(
                                                          model.aspectRatio,
                                                        ),
                                                        child: shouldPlayPreview
                                                            ? SmartMiniVideoPlayer(
                                                                videoUrl: model
                                                                    .playbackUrl,
                                                                thumbnailUrl: model
                                                                    .thumbnail,
                                                                visibilityKey:
                                                                    "${model.docID}_$i",
                                                                muted: true,
                                                                aspectRatio:
                                                                    _safeAspectRatio(
                                                                  model
                                                                      .aspectRatio,
                                                                ),
                                                                useAspectRatio:
                                                                    true,
                                                              )
                                                            : CachedNetworkImage(
                                                                imageUrl: model
                                                                    .thumbnail,
                                                                fit: BoxFit
                                                                    .cover,
                                                                memCacheWidth:
                                                                    200,
                                                                memCacheHeight:
                                                                    600,
                                                                placeholder: (c,
                                                                        u) =>
                                                                    Container(
                                                                  color: Colors
                                                                          .grey[
                                                                      300],
                                                                ),
                                                                errorWidget: (c,
                                                                        u, e) =>
                                                                    const Icon(
                                                                  Icons.error,
                                                                ),
                                                              ),
                                                      ),
                                                      Positioned(
                                                        bottom: 6,
                                                        left: 6,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              shouldPlayPreview
                                                                  ? CupertinoIcons
                                                                      .play_circle_fill
                                                                  : CupertinoIcons
                                                                      .eye,
                                                              color:
                                                                  Colors.white,
                                                              size: 13,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              _formatCountCompact(
                                                                  model.stats
                                                                      .statsCount),
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontFamily:
                                                                    "MontserratBold",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (model.floodCount > 1)
                                                        Positioned(
                                                          bottom: 0,
                                                          right: 0,
                                                          child: Texts
                                                              .colorfulFloodForExplore,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  );
                                }),

                                // ---- 2. Sekme: floods ----
                                Obx(() {
                                  final list = controller.exploreFloods;
                                  final showLoader =
                                      controller.floodsHasMore.value &&
                                          controller.floodsIsLoading.value;
                                  if (list.isEmpty &&
                                      !controller.floodsIsLoading.value) {
                                    return Center(
                                        child: EmptyRow(
                                            text: "Floods bulunamadı"));
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
                                    child: GridView.builder(
                                      key: const PageStorageKey(
                                          'Explore_Floods'),
                                      controller: controller.floodsScroll,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 1,
                                        crossAxisSpacing: 1,
                                        childAspectRatio: 0.8,
                                      ),
                                      itemCount:
                                          list.length + (showLoader ? 1 : 0),
                                      itemBuilder: (c, i) {
                                        if (i == list.length) {
                                          return const Center(
                                              child:
                                                  CupertinoActivityIndicator());
                                        }
                                        final p = list[i];
                                        return RepaintBoundary(
                                          child: GestureDetector(
                                            onTap: () {
                                              // Floods sekmesinde daima flood listesine git
                                              Get.to(() =>
                                                  FloodListing(mainModel: p));
                                            },
                                            child: Stack(
                                              fit: StackFit.expand,
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                _buildCoverFrame(
                                                  aspectRatio: _safeAspectRatio(
                                                    p.aspectRatio,
                                                    fallback: 1.0,
                                                  ),
                                                  child: CachedNetworkImage(
                                                    imageUrl: p.img.isNotEmpty
                                                        ? p.img.first
                                                        : p.thumbnail,
                                                    memCacheWidth: 200,
                                                    memCacheHeight: 400,
                                                    fit: BoxFit.cover,
                                                    placeholder: (c, u) =>
                                                        Container(
                                                            color: Colors
                                                                .grey[300]),
                                                    errorWidget: (c, u, e) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                ),
                                                if (p.floodCount > 1)
                                                  Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Texts
                                                        .colorfulFloodForExplore,
                                                  ),
                                                if (p.gizlendi)
                                                  _overlayStatus("Gizlendi")
                                                else if (p.arsiv)
                                                  _overlayStatus("Arşivlendi")
                                                else if (p.deletedPost)
                                                  _overlayStatus("Silindi"),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView(
                      children: controller.searchText.value.trim().isEmpty
                          ? [
                              Obx(() {
                                final recent = controller.recentSearchUsers;
                                if (recent.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: recent
                                      .map(
                                        (m) => SearchUserContent(
                                          model: m,
                                          isSearch: false,
                                        ),
                                      )
                                      .toList(),
                                );
                              }),
                            ]
                          : [
                              ...controller.searchedHashtags.map((tag) {
                                final title = "#${tag.hashtag}";
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(CupertinoIcons.number,
                                      color: Colors.black87, size: 20),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: "MontserratSemiBold",
                                    ),
                                  ),
                                  onTap: () =>
                                      Get.to(() => TagPosts(tag: tag.hashtag)),
                                  trailing: const Icon(
                                      CupertinoIcons.arrow_turn_up_left,
                                      color: Colors.black45,
                                      size: 18),
                                );
                              }),
                              ...controller.searchedTags.map((tag) {
                                final title = tag.hashtag;
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(CupertinoIcons.tag,
                                      color: Colors.black87, size: 20),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: "MontserratSemiBold",
                                    ),
                                  ),
                                  onTap: () =>
                                      Get.to(() => TagPosts(tag: tag.hashtag)),
                                  trailing: const Icon(
                                      CupertinoIcons.arrow_turn_up_left,
                                      color: Colors.black45,
                                      size: 18),
                                );
                              }),
                              ...controller.searchedList.map(
                                (u) => SearchUserContent(
                                  model: u,
                                  isSearch: true,
                                ),
                              )
                            ],
                    ),
                  );
                }),
              ],
            ),
            Obx(() {
              return controller.showScrollToTop.value
                  ? Positioned(
                      bottom: 80,
                      right: 20,
                      child: GestureDetector(
                          onTap: () {
                            controller.floodsScroll.animateTo(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.bounceIn);
                            controller.scrollController.animateTo(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.bounceIn);
                            controller.exploreScroll.animateTo(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.bounceIn);
                            controller.photoScroll.animateTo(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.bounceIn);
                            controller.videoScroll.animateTo(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.bounceIn);
                          },
                          child: RoadToTop()),
                    )
                  : SizedBox();
            }),
            IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: ExploreAdPlacementHook(index: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Durum (Gizlendi, Arşivlendi, Silindi) için kısa widget
  Widget _overlayStatus(String status) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Text(
        status,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontFamily: "Montserrat"),
      ),
    );
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
    final oneBased = index + 1;
    if (oneBased == 1) return true;
    if (oneBased < 6) return false;
    return ((oneBased - 6) % 6 == 0) || ((oneBased - 7) % 6 == 0);
  }
}
