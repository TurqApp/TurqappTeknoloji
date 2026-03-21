import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import '../../Agenda/AgendaContent/agenda_content.dart';
import 'liked_posts_controller.dart';

class LikedPosts extends StatefulWidget {
  const LikedPosts({super.key});

  @override
  State<LikedPosts> createState() => _LikedPostsState();
}

class _LikedPostsState extends State<LikedPosts> {
  late LikedPostControllers controller;
  bool _ownsController = false;
  final scrollController = ScrollController();
  late final String _pageLineBarTag =
      '${kLikedPostsPageLineBarTag}_${identityHashCode(this)}';

  int _estimatedCenteredIndex() {
    if (!scrollController.hasClients || controller.all.isEmpty) {
      return -1;
    }
    final position = scrollController.position;
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final rawIndex = ((position.pixels + position.viewportDimension * 0.25) /
            estimatedItemExtent)
        .floor();
    return rawIndex.clamp(0, controller.all.length - 1);
  }

  @override
  void initState() {
    super.initState();
    final existingController = LikedPostControllers.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = LikedPostControllers.ensure();
      _ownsController = true;
    }

    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    if (_ownsController &&
        identical(LikedPostControllers.maybeFind(), controller)) {
      Get.delete<LikedPostControllers>(force: true);
    }
    super.dispose();
  }

  void _onScroll() {
    final nextIndex = _estimatedCenteredIndex();
    if (nextIndex < 0) return;
    if (controller.centeredIndex.value != nextIndex) {
      final previousIndex = controller.lastCenteredIndex;
      if (previousIndex != null &&
          previousIndex >= 0 &&
          previousIndex < controller.all.length &&
          previousIndex != nextIndex) {
        controller.disposeAgendaContentController(
          controller.all[previousIndex].docID,
        );
      }
      setState(() {
        controller.centeredIndex.value = nextIndex;
        controller.currentVisibleIndex.value = nextIndex;
        controller.lastCenteredIndex = nextIndex;
        controller.capturePendingCenteredEntry(preferredIndex: nextIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.liked_posts".tr),
            PageLineBar(
              barList: [
                "common.all".tr,
                "common.videos".tr,
                "common.photos".tr,
              ],
              pageName: _pageLineBarTag,
              pageController: controller.pageController,
            ),
            Expanded(
              child: Obx(() {
                return PageView(
                  controller: controller.pageController,
                  onPageChanged: (v) {
                    syncPageLineBarSelection(_pageLineBarTag, v);
                  },
                  children: [
                    posts(),
                    videos(),
                    photos(),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget posts() {
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
                        itemCount: controller.all.length +
                            2, // +2 çünkü hem header hem bottom space
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return SizedBox();
                          }

                          // EN ALTA GELİNCE 50PX LİK BOŞLUK EKLE
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
                                    instanceTag: controller
                                        .agendaInstanceTag(model.docID),
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
                      )),
                )
              : Center(
                  child: EmptyRow(text: "liked_posts.no_posts".tr),
                )),
    );
  }

  Widget photos() {
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

  Widget videos() {
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
