import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_content.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';

class FollowingFollowers extends StatelessWidget {
  final int selection;
  final String userId;

  const FollowingFollowers({
    super.key,
    required this.selection,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      FollowingFollowersController(userId: userId, initialPage: selection),
      tag: userId, // Use userId as unique tag to prevent controller reuse
    );

    // PageLineBarController is created inside PageLineBar; initial index is passed below.

    final scrollController = ScrollController();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Obx(
                  () => BackButtons(text: controller.nickname.value),
                ),
                Obx(() {
                  return PageLineBar(
                    barList: [
                      'Takipciler ${NumberFormatter.format(controller.takipciCounter.value)}',
                      'Takip Edilenler ${NumberFormatter.format(controller.takipedilenCounter.value)}',
                    ],
                    pageName: 'Followers',
                    initialIndex: selection,
                    pageController: controller.pageController,
                  );
                }),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (idx) {
                      Get.find<PageLineBarController>(tag: 'Followers')
                          .selection
                          .value = idx;
                    },
                    children: [
                      _buildList(context,
                          list: controller.takipciler,
                          searchController: controller.searchTakipciController,
                          searchFn: controller.searchTakipci,
                          isLoading: () => controller.isLoadingFollowers,
                          hasMore: () => controller.hasMoreFollowers,
                          scrollController: scrollController,
                          loadMore: () =>
                              controller.getFollowers(initial: false)),
                      _buildList(context,
                          list: controller.takipEdilenler,
                          searchController:
                              controller.searchTakipEdilenController,
                          searchFn: controller.searchTakipEdilenler,
                          isLoading: () => controller.isLoadingFollowing,
                          hasMore: () => controller.hasMoreFollowing,
                          scrollController: scrollController,
                          loadMore: () =>
                              controller.getFollowing(initial: false)),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  scrollController.animateTo(0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.bounceIn);
                },
                child: RoadToTop(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context, {
    required RxList<String> list,
    required TextEditingController searchController,
    required Future<void> Function() searchFn,
    required bool Function() isLoading,
    required bool Function() hasMore,
    required ScrollController scrollController,
    required Future<void> Function() loadMore,
  }) {
    return Obx(
      () => NotificationListener<ScrollNotification>(
        onNotification: (info) {
          if (info.metrics.pixels >= info.metrics.maxScrollExtent - 300) {
            if (hasMore() && !isLoading()) {
              loadMore();
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.zero,
          itemCount: list.isEmpty ? 2 : list.length + 2,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              // 🔍 Arama kutusu
              return Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                child: Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Ara",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'MontserratMedium',
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                            onSubmitted: (_) => searchFn(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: searchFn,
                        icon: const Icon(Icons.search,
                            color: Colors.black54, size: 24),
                        tooltip: 'Ara',
                      ),
                    ],
                  ),
                ),
              );
            }

            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'Sonuç bulunamadı',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              );
            }

            if (i == list.length + 1) {
              // ⬇️ Footer (yükleniyor veya tümü yüklendi)
              if (isLoading()) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CupertinoActivityIndicator()),
                );
                // } else if (!hasMore()) {
                //   return const Padding(
                //     padding: EdgeInsets.symmetric(vertical: 24),
                //     child: Center(
                //       child: Text(
                //         "Tüm kullanıcılar yüklendi",
                //         style: TextStyle(color: Colors.grey),
                //       ),
                //     ),
                //   );
              } else {
                return const SizedBox.shrink();
              }
            }

            // 👤 Kullanıcı içeriği (veriler)
            final id = list[i - 1]; // i=1 → index 0, i=2 → index 1 ...
            return Padding(
              padding: EdgeInsets.only(top: i == 1 ? 15 : 0),
              child: FollowerContent(userID: id, key: ValueKey(id)),
            );
          },
        ),
      ),
    );
  }
}
