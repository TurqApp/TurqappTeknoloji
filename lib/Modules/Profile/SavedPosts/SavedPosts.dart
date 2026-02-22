import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Core/PageLineBar.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/SavedPostsController.dart';
import 'package:turqappv2/Modules/Short/SingleShortView.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/PhotoShorts.dart';

import '../../Agenda/AgendaContent/AgendaContent.dart';

class SavedPosts extends StatefulWidget {
  const SavedPosts({super.key});

  @override
  State<SavedPosts> createState() => _SavedPostsState();
}

class _SavedPostsState extends State<SavedPosts> {
  late SavedPostsController controller;
  late PageLineBarController pageLineBarController;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(SavedPostsController());
    pageLineBarController = Get.put(
        PageLineBarController(pageName: "SavedPosts"),
        tag: "SavedPosts");
    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    if (Get.isRegistered<SavedPostsController>()) {
      Get.delete<SavedPostsController>(force: true);
    }
    super.dispose();
  }

  void _onScroll() {
    // ScrollController bağlı değilse çık
    if (!scrollController.hasClients) return;

    // Ortadaki widget’ı tespit etmek için
    final screenHeight = MediaQuery.of(context).size.height;
    final centerY = screenHeight / 2;

    for (int i = 0; i < controller.savedAgendas.length; i++) {
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
            BackButtons(text: "Kaydedilenler"),
            PageLineBar(
                barList: ["Tümü", "Video", "Fotoğraf"],
                pageName: 'SavedPosts',
                pageController: controller.pageController),
            Expanded(
              child: Obx(() {
                return PageView(
                  controller: controller.pageController,
                  onPageChanged: (v) {
                    Get.find<PageLineBarController>(tag: 'SavedPosts')
                        .selection
                        .value = v;
                  },
                  children: [
                    // Tümü
                    SizedBox.expand(
                      child: Container(
                          color: Colors.white,
                          child: controller.isLoading.value
                              ? const CupertinoActivityIndicator(
                                  color: Colors.grey,
                                )
                              : controller.savedAgendas.isNotEmpty
                                  ? RefreshIndicator(
                                      backgroundColor: Colors.black,
                                      color: Colors.white,
                                      onRefresh: controller.refresh,
                                      child: NotificationListener<
                                              ScrollNotification>(
                                          onNotification: (notification) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback(
                                              (_) => _onScroll(),
                                            );
                                            return false;
                                          },
                                          child: ListView.builder(
                                            controller: scrollController,
                                            itemCount: controller
                                                    .savedAgendas.length +
                                                2, // +2 çünkü hem header hem bottom space
                                            itemBuilder: (context, index) {
                                              if (index == 0) {
                                                return SizedBox();
                                              }

                                              // EN ALTA GELİNCE 50PX LİK BOŞLUK EKLE
                                              if (index ==
                                                  controller
                                                          .savedAgendas.length +
                                                      1) {
                                                return const SizedBox(
                                                    height: 50);
                                              }

                                              final actualIndex = index - 1;
                                              final model = controller
                                                  .savedAgendas[actualIndex];
                                              final itemKey = controller
                                                  .getPostKey(actualIndex);
                                              final isCentered = controller
                                                      .centeredIndex.value ==
                                                  actualIndex;

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5),
                                                child: Column(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: actualIndex == 0
                                                              ? 12
                                                              : 0),
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
                                                        color: Colors.grey
                                                            .withAlpha(50),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )),
                                    )
                                  : Center(
                                      child: EmptyRow(text: "Gönderi yok"),
                                    )),
                    ),
                    // Video
                    if (controller.isLoading.value &&
                        controller.savedVideos.isEmpty)
                      const CupertinoActivityIndicator(color: Colors.grey)
                    else if (controller.savedVideos.isEmpty)
                      Center(child: EmptyRow(text: "Video Bulunamadı"))
                    else
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 1,
                          childAspectRatio: 1 / 1.9,
                        ),
                        itemCount: controller.savedVideos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => SingleShortView(
                                      startList: controller.savedVideos,
                                      startModel: controller.savedVideos[index],
                                    ),
                                  )?.then((_) => controller.refresh());
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        controller.savedVideos[index].thumbnail,
                                    fit: BoxFit.cover,
                                    fadeOutDuration: Duration.zero,
                                    memCacheHeight: 400,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey[300]),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  CupertinoIcons.play_circle,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    // Fotoğraf
                    if (controller.isLoading.value &&
                        controller.savedPhotos.isEmpty)
                      const CupertinoActivityIndicator(color: Colors.grey)
                    else if (controller.savedPhotos.isEmpty)
                      Center(child: EmptyRow(text: "Fotoğraf Bulunamadı"))
                    else
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 1,
                          childAspectRatio: 1,
                        ),
                        itemCount: controller.savedPhotos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Get.to(
                                () => PhotoShorts(
                                  fetchedList: controller.savedPhotos,
                                  startModel: controller.savedPhotos[index],
                                ),
                              )?.then((_) => controller.refresh());
                            },
                            child: CachedNetworkImage(
                              imageUrl: controller.savedPhotos[index].img.first,
                              fit: BoxFit.cover,
                              fadeOutDuration: Duration.zero,
                              memCacheHeight: 400,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[300]),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
