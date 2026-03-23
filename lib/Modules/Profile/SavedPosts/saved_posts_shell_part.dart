part of 'saved_posts.dart';

extension _SavedPostsShellPart on _SavedPostsState {
  Widget _buildSavedPostsShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.saved_posts".tr),
            PageLineBar(
              barList: [
                "common.all".tr,
                "saved_posts.posts_tab".tr,
                "saved_posts.series_tab".tr,
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
                    _buildAgendaTab(
                      posts: controller.savedAgendas,
                      emptyText: "saved_posts.no_saved_posts".tr,
                    ),
                    _buildAgendaTab(
                      posts: controller.savedPostsOnly,
                      emptyText: "saved_posts.no_saved_posts".tr,
                    ),
                    _buildAgendaTab(
                      posts: controller.savedSeries,
                      emptyText: "saved_posts.no_saved_series".tr,
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
