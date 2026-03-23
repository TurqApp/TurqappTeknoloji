part of 'liked_posts.dart';

extension _LikedPostsShellPart on _LikedPostsState {
  Widget _buildLikedPostsShell(BuildContext context) {
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
                    _buildPostsTab(),
                    _buildVideosTab(),
                    _buildPhotosTab(),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
