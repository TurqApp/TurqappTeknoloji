part of 'tests.dart';

extension _TestsShellContentPart on _TestsState {
  Widget _buildEmbeddedPage({
    required Widget bodyContent,
    required List<Widget> overlays,
  }) {
    return Stack(
      children: [
        Column(children: [bodyContent]),
        if (showEmbeddedControls) ...overlays,
      ],
    );
  }

  Widget _buildStandalonePage(
    BuildContext context, {
    required Widget bodyContent,
    required List<Widget> overlays,
  }) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: Icon(
                        AppIcons.arrowLeft,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                    TypewriterText(text: 'tests.title'.tr),
                  ],
                ),
                bodyContent,
              ],
            ),
            ...overlays,
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    return Expanded(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: controller.getData,
        child: Container(
          color: Colors.white,
          child: ListView(
            controller: _scrollController,
            children: [
              _buildTopContent(),
              _buildTestGrid(),
              Obx(
                () => controller.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOverlays(BuildContext context) {
    return [
      ScrollTotopButton(
        scrollController: _scrollController,
        visibilityThreshold: 350,
      ),
      Obx(
        () => Positioned(
          bottom: 20,
          right: 20,
          child: Visibility(
            visible: controller.scrollOffset.value <= 350,
            child: ActionButton(
              context: context,
              menuItems: [
                PullDownMenuItem(
                  icon: CupertinoIcons.bookmark,
                  title: 'common.saved'.tr,
                  onTap: () =>
                      const EducationTestNavigationService().openSavedTests(),
                ),
                PullDownMenuItem(
                  icon: Icons.history,
                  title: 'pasaj.common.my_results'.tr,
                  onTap: () => const EducationTestNavigationService()
                      .openMyTestResults(),
                ),
                PullDownMenuItem(
                  icon: CupertinoIcons.doc_text,
                  title: 'tests.my_tests_title'.tr,
                  onTap: () =>
                      const EducationTestNavigationService().openMyTests(),
                ),
                PullDownMenuItem(
                  icon: Icons.add,
                  title: 'common.create'.tr,
                  onTap: () =>
                      const EducationTestNavigationService().openCreateTest(),
                ),
                PullDownMenuItem(
                  icon: Icons.exit_to_app,
                  title: 'tests.join_button'.tr,
                  onTap: () =>
                      const EducationTestNavigationService().openTestEntry(),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
