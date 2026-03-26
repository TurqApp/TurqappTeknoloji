part of 'answer_key.dart';

extension AnswerKeyShellContentPart on AnswerKey {
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
                      onPressed: () => Get.back(),
                      icon: Icon(
                        AppIcons.arrowLeft,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                    TypewriterText(text: 'answer_key.answer_keys'.tr),
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
        onRefresh: controller.refreshData,
        child: ListView(
          controller: _scrollController,
          children: [
            Obx(() {
              if (!controller.listingSelectionReady.value) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final items = controller.hasActiveSearch
                  ? controller.searchResults
                  : controller.bookList;
              return _buildListingContent(items);
            }),
          ],
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
                  title: 'answer_key.published'.tr,
                  icon: AppIcons.book,
                  onTap: () => Get.to(OpticsAndBooksPublished()),
                ),
                PullDownMenuItem(
                  title: 'common.saved'.tr,
                  icon: AppIcons.save,
                  onTap: () => Get.to(SavedOpticalForms()),
                ),
                PullDownMenuItem(
                  title: 'answer_key.my_results'.tr,
                  icon: AppIcons.question,
                  onTap: () => Get.to(MyBookletResults()),
                ),
                PullDownMenuItem(
                  title: 'common.create'.tr,
                  icon: AppIcons.addCircled,
                  onTap: () => Get.to(
                    AnswerKeyCreatingOption(onBack: controller.refreshData),
                  ),
                ),
                PullDownMenuItem(
                  title: 'pasaj.answer_key.join'.tr,
                  icon: AppIcons.arrowRight,
                  onTap: () => Get.to(OpticalFormEntry()),
                ),
                PullDownMenuItem(
                  title: 'practice.slider_management'.tr,
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: () => Get.to(
                    () => SliderAdminView(
                      sliderId: 'cevap_anahtari',
                      title: 'answer_key.title'.tr,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
