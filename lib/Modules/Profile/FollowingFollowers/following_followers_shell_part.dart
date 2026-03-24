part of 'following_followers.dart';

extension _FollowingFollowersShellPart on _FollowingFollowersState {
  Widget _buildFollowingFollowersShell(BuildContext context) {
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
}
