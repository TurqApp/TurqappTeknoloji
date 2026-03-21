import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_content.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';

class FollowingFollowers extends StatefulWidget {
  final int selection;
  final String userId;

  const FollowingFollowers({
    super.key,
    required this.selection,
    required this.userId,
  });

  @override
  State<FollowingFollowers> createState() => _FollowingFollowersState();
}

class _FollowingFollowersState extends State<FollowingFollowers> {
  late final FollowingFollowersController controller;
  late final ScrollController _followersScrollController;
  late final ScrollController _followingScrollController;
  bool _ownsController = false;
  late int _currentPage;

  String get _pageLineBarTag => '${kFollowersPageLineBarTag}_${widget.userId}';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<FollowingFollowersController>(tag: widget.userId)) {
      controller = Get.find<FollowingFollowersController>(tag: widget.userId);
    } else {
      controller = Get.put(
        FollowingFollowersController(
          userId: widget.userId,
          initialPage: widget.selection,
        ),
        tag: widget.userId,
      );
      _ownsController = true;
    }
    _followersScrollController = ScrollController();
    _followingScrollController = ScrollController();
    _currentPage = widget.selection;
  }

  @override
  void dispose() {
    _followersScrollController.dispose();
    _followingScrollController.dispose();
    if (_ownsController &&
        Get.isRegistered<FollowingFollowersController>(tag: widget.userId) &&
        identical(
          Get.find<FollowingFollowersController>(tag: widget.userId),
          controller,
        )) {
      Get.delete<FollowingFollowersController>(
        tag: widget.userId,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PageLineBarController is created inside PageLineBar; initial index is passed below.

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
                      'following.followers_tab'.tr,
                      'following.following_tab'.tr,
                    ],
                    pageName: _pageLineBarTag,
                    initialIndex: widget.selection,
                    pageController: controller.pageController,
                  );
                }),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (idx) {
                      if (mounted && _currentPage != idx) {
                        setState(() {
                          _currentPage = idx;
                        });
                      }
                      syncPageLineBarSelection(_pageLineBarTag, idx);
                    },
                    children: [
                      _buildList(context,
                          list: controller.takipciler,
                          isLoading: () => controller.isLoadingFollowers,
                          hasMore: () => controller.hasMoreFollowers,
                          scrollController: _followersScrollController,
                          loadMore: () =>
                              controller.getFollowers(initial: false)),
                      _buildList(context,
                          list: controller.takipEdilenler,
                          isLoading: () => controller.isLoadingFollowing,
                          hasMore: () => controller.hasMoreFollowing,
                          scrollController: _followingScrollController,
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
                  final activeController = _currentPage == 0
                      ? _followersScrollController
                      : _followingScrollController;
                  activeController.animateTo(0,
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
