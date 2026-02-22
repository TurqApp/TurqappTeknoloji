import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/PageLineBar.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Core/Texts.dart';
import 'package:turqappv2/Modules/Short/SingleShortView.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import '../../Core/EmptyRow.dart';
import '../../Core/Helpers/RoadToTop/RoadToTop.dart';
import '../../Services/FirebaseMyStore.dart';
import '../Agenda/TagPosts/TagMediaWidgets.dart';
import '../Agenda/TagPosts/TagPosts.dart';
import '../Agenda/FloodListing/FloodListing.dart';
import 'ExploreController.dart';

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

  final FirebaseMyStore user = Get.find<FirebaseMyStore>();

  ExploreController get controller {
    if (Get.isRegistered<ExploreController>()) {
      return Get.find<ExploreController>();
    } else {
      return Get.put(ExploreController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Obx(() {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.03),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller.searchController,
                                      focusNode: controller.searchFocus,
                                      decoration: InputDecoration(
                                          hintText: "Ara",
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "MontserratMedium"),
                                          border: InputBorder.none,
                                          icon: Icon(CupertinoIcons.search)),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium"),
                                      onChanged: (v) {
                                        if (v.isEmpty) {
                                          controller.searchedList.clear();
                                        } else {
                                          controller.search(v);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (controller.isKeyboardOpen.value)
                          GestureDetector(
                            onTap: () {
                              controller.searchFocus.unfocus();
                              controller.searchController.clear();
                              controller.isKeyboardOpen.value = false;
                              closeKeyboard(context);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 15, left: 15),
                              child: const Icon(CupertinoIcons.xmark,
                                  color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ——————————— İçerik Sekmeleri ———————————
                  if (!controller.isKeyboardOpen.value)
                    Expanded(
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
                                                Get.to(() =>
                                                    TagPosts(tag: item.hashtag));
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
                                                          color:
                                                              Colors.black38,
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
                                                  color: Colors.grey
                                                      .withAlpha(50),
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
                                  final list = controller.explorePosts
                                      .where((e) => e.hasPlayableVideo)
                                      .toList();
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
                                            child:
                                                EmptyRow(text: "Sonuç bulunamadı"))
                                        : GridView.builder(
                                            key: const PageStorageKey(
                                                'Explore_SanaOzel'),
                                            controller: controller.exploreScroll,
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
                                              return GestureDetector(
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
                                                  Get.to(() => SingleShortView(
                                                        startList: videos,
                                                        startModel: model,
                                                      ));
                                                },
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    shouldPlayPreview
                                                        ? SmartMiniVideoPlayer(
                                                            videoUrl:
                                                                model.playbackUrl,
                                                            thumbnailUrl: model
                                                                .thumbnail,
                                                            visibilityKey:
                                                                "${model.docID}_$i",
                                                            muted: true,
                                                          )
                                                        : CachedNetworkImage(
                                                            imageUrl: model
                                                                .thumbnail,
                                                            fit: BoxFit.cover,
                                                            memCacheHeight: 600,
                                                            placeholder: (c,
                                                                    u) =>
                                                                Container(
                                                                    color: Colors
                                                                            .grey[
                                                                        300]),
                                                            errorWidget: (c, u,
                                                                    e) =>
                                                                const Icon(Icons
                                                                    .error),
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
                                                              color:
                                                                  Colors.white,
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
                                        return GestureDetector(
                                          onTap: () {
                                            // Floods sekmesinde daima flood listesine git
                                            Get.to(() =>
                                                FloodListing(mainModel: p));
                                          },
                                          child: Stack(
                                            fit: StackFit.expand,
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              SizedBox.expand(
                                                child: CachedNetworkImage(
                                                  imageUrl: p.img.isNotEmpty
                                                      ? p.img.first
                                                      : p.thumbnail,
                                                  memCacheHeight: 400,
                                                  fit: BoxFit.cover,
                                                  placeholder: (c, u) =>
                                                      Container(
                                                          color:
                                                              Colors.grey[300]),
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
                    )
                  else
                    Expanded(
                        child: ListView.builder(
                      itemCount: controller.searchedList.length,
                      itemBuilder: (context, index) {
                        final user = controller.searchedList[index];
                        return TextButton(
                          style: TextButton.styleFrom(
                            padding:
                                EdgeInsets.zero, // Varsayılan padding'i kaldır
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            backgroundColor:
                                Colors.transparent, // Arka plan yok
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Get.to(() => SocialProfile(userID: user.userID));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 7),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ClipOval(
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CachedNetworkImage(
                                          imageUrl: user.pfImage,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "${user.firstName} ${user.lastName}",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 13,
                                                    fontFamily:
                                                        "MontserratBold"),
                                              ),
                                              RozetContent(
                                                  size: 15, userID: user.userID)
                                            ],
                                          ),
                                          Text(
                                            user.nickname,
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                                fontFamily: "MontserratMedium"),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 50),
                                  child: SizedBox(
                                    height: 2,
                                    child: Divider(
                                        color: Colors.grey.withAlpha(20)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ))
                ],
              );
            }),
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
            })
          ],
        ),
      ),
    );
  }

  /// Durum (Gizlendi, Arşivlendi, Silindi) için kısa widget
  Widget _overlayStatus(String status) {
    return Container(
      color: Colors.black.withOpacity(0.7),
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
