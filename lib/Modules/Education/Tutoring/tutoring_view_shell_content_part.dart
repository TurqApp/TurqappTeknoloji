part of 'tutoring_view.dart';

extension TutoringViewShellContentPart on TutoringView {
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
            visible: tutoringController.scrollOffset.value <= 350,
            child: ActionButton(
              context: context,
              menuItems: [
                PullDownMenuItem(
                  title: 'common.search'.tr,
                  icon: CupertinoIcons.search,
                  onTap: () => Get.to(() => const TutoringSearch()),
                ),
                PullDownMenuItem(
                  title: 'tutoring.my_applications'.tr,
                  icon: CupertinoIcons.doc_text,
                  onTap: () => Get.to(() => MyTutoringApplications()),
                ),
                PullDownMenuItem(
                  title: 'tutoring.create_listing'.tr,
                  icon: CupertinoIcons.add_circled,
                  onTap: () => Get.to(CreateTutoringView()),
                ),
                PullDownMenuItem(
                  title: 'tutoring.my_listings'.tr,
                  icon: CupertinoIcons.list_bullet,
                  onTap: () => Get.to(MyTutorings()),
                ),
                PullDownMenuItem(
                  title: 'tutoring.saved'.tr,
                  icon: AppIcons.save,
                  onTap: () => Get.to(() => SavedTutorings()),
                ),
                PullDownMenuItem(
                  title: 'pasaj.tutoring.nearby_listings'.tr,
                  icon: AppIcons.locationSolid,
                  onTap: () => Get.to(() => LocationBasedTutoring()),
                ),
                PullDownMenuItem(
                  title: 'tutoring.slider_admin'.tr,
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: () => Get.to(
                    () => SliderAdminView(
                      sliderId: 'ozel_ders',
                      title: 'tutoring.title'.tr,
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            TypewriterText(text: 'tutoring.title'.tr),
          ],
        ),
      ],
    );
  }
}
