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
  late PageLineBarController pageLineBarController;
  final scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    controller = Get.put(LikedPostControllers());
    pageLineBarController = Get.put(
      PageLineBarController(pageName: "LikedPosts"),
      tag: "LikedPosts",
    );

    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    if (Get.isRegistered<LikedPostControllers>()) {
      Get.delete<LikedPostControllers>(force: true);
    }
    super.dispose();
  }

  void _onScroll() {
    // ScrollController bağlı değilse çık
    if (!scrollController.hasClients) return;

    // Ortadaki widget’ı tespit etmek için
    final screenHeight = MediaQuery.of(context).size.height;
    final centerY = screenHeight / 2;

    for (int i = 0; i < controller.all.length; i++) {
      final key = controller.getPostKey(i);
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final pos = box.localToGlobal(Offset.zero);
      final top = pos.dy;
      final bottom = pos.dy + box.size.height;

      if (top <= centerY && bottom >= centerY) {
        if (controller.centeredIndex.value != i) {
          setState(() {
            controller.centeredIndex.value = i;
            controller.lastCenteredIndex = i;
          });
        }
        break;
      }
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
              pageName: "LikedPosts",
              pageController: controller.pageController,
            ),
            Expanded(
              child: Obx(() {
                return PageView(
                  controller: controller.pageController,
                  onPageChanged: (v) {
                    Get.find<PageLineBarController>(tag: 'LikedPosts')
                        .selection
                        .value = v;
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
                          final itemKey = controller.getPostKey(actualIndex);
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
            controller.lastCenteredIndex = controller.currentVisibleIndex.value >= 0
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
            controller.lastCenteredIndex = controller.currentVisibleIndex.value >= 0
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
