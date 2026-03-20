import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
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
      key: const ValueKey(IntegrationTestKeys.screenFollowingFollowers),
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
                      'following.followers_tab'.trParams({
                        'count':
                            NumberFormatter.format(controller.takipciCounter.value),
                      }),
                      'following.following_tab'.trParams({
                        'count': NumberFormatter.format(
                          controller.takipedilenCounter.value,
                        ),
                      }),
                    ],
                    pageName: kFollowersPageLineBarTag,
                    initialIndex: selection,
                    pageController: controller.pageController,
                  );
                }),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (idx) {
                      Get.find<PageLineBarController>(
                              tag: kFollowersPageLineBarTag)
                          .selection
                          .value = idx;
                    },
                    children: [
                      _buildList(context,
                          list: controller.takipciler,
                          isLoading: () => controller.isLoadingFollowers,
                          hasMore: () => controller.hasMoreFollowers,
                          scrollController: scrollController,
                          loadMore: () =>
                              controller.getFollowers(initial: false)),
                      _buildList(context,
                          list: controller.takipEdilenler,
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
          itemCount: list.isEmpty ? 1 : list.length + 1,
          itemBuilder: (ctx, i) {
            if (list.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'following.none'.tr,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              );
            }

            if (i == list.length) {
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
            final id = list[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 15 : 0),
              child: FollowerContent(userID: id, key: ValueKey(id)),
            );
          },
        ),
      ),
    );
  }
}
