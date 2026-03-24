import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_content.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';

part 'following_followers_content_part.dart';

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
    final existingController =
        FollowingFollowersController.maybeFind(tag: widget.userId);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = FollowingFollowersController.ensure(
        userId: widget.userId,
        initialPage: widget.selection,
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
        identical(
          FollowingFollowersController.maybeFind(tag: widget.userId),
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
                PageLineBar(
                  barList: [
                    'following.followers_tab'.tr,
                    'following.following_tab'.tr,
                  ],
                  pageName: _pageLineBarTag,
                  initialIndex: widget.selection,
                  pageController: controller.pageController,
                ),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: (idx) {
                      _setCurrentPage(idx);
                      syncPageLineBarSelection(_pageLineBarTag, idx);
                    },
                    children: [
                      _buildFollowersList(
                        list: controller.takipciler,
                        isLoading: () => controller.isLoadingFollowers,
                        hasMore: () => controller.hasMoreFollowers,
                        scrollController: _followersScrollController,
                        loadMore: () => controller.getFollowers(initial: false),
                      ),
                      _buildFollowersList(
                        list: controller.takipEdilenler,
                        isLoading: () => controller.isLoadingFollowing,
                        hasMore: () => controller.hasMoreFollowing,
                        scrollController: _followingScrollController,
                        loadMore: () => controller.getFollowing(initial: false),
                      ),
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
                  activeController.animateTo(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                  );
                },
                child: RoadToTop(),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _setCurrentPage(int index) {
    if (!mounted || _currentPage == index) return;
    setState(() {
      _currentPage = index;
    });
  }
}
