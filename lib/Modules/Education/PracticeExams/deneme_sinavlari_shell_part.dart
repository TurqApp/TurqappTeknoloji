part of 'deneme_sinavlari.dart';

extension DenemeSinavlariShellPart on DenemeSinavlari {
  Widget _buildPage(BuildContext context) {
    final bodyContent = _buildBodyContent(context);

    if (embedded) {
      return Stack(
        children: [
          Column(children: [bodyContent]),
          Obx(
            () => controller.showOkulAlert.value
                ? _buildSchoolAlertSheet(context)
                : const SizedBox.shrink(),
          ),
          if (showEmbeddedControls)
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
          if (showEmbeddedControls) _buildFloatingAction(context),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                bodyContent,
              ],
            ),
            Obx(
              () => controller.showOkulAlert.value
                  ? _buildSchoolAlertSheet(context)
                  : const SizedBox.shrink(),
            ),
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
            _buildFloatingAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: const Icon(
                  AppIcons.arrowLeft,
                  color: Colors.black,
                  size: 25,
                ),
              ),
              TypewriterText(
                text: 'pasaj.tabs.online_exam'.tr,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.to(() => SearchDeneme()),
          icon: const Icon(AppIcons.search, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildFloatingAction(BuildContext context) {
    return Obx(
      () => Positioned(
        bottom: 20,
        right: 20,
        child: Visibility(
          visible: controller.scrollOffset.value <= 350,
          child: ActionButton(
            context: context,
            permissionScope: ActionButtonPermissionScope.practiceExams,
            menuItems: [
              PullDownMenuItem(
                icon: Icons.add,
                title: 'common.create'.tr,
                onTap: () {
                  if (controller.okul.value) {
                    Get.to(() => SinavHazirla());
                  } else {
                    controller.showOkulAlert.value = true;
                  }
                },
              ),
              PullDownMenuItem(
                icon: Icons.history,
                title: 'pasaj.common.my_results'.tr,
                onTap: () => Get.to(() => SinavSonuclarim()),
              ),
              PullDownMenuItem(
                icon: CupertinoIcons.doc_text,
                title: 'pasaj.common.published'.tr,
                onTap: () => Get.to(() => const MyPracticeExams()),
              ),
              PullDownMenuItem(
                icon: CupertinoIcons.bookmark,
                title: 'common.saved'.tr,
                onTap: () => Get.to(() => const SavedPracticeExams()),
              ),
              PullDownMenuItem(
                icon: CupertinoIcons.search,
                title: 'common.search'.tr,
                onTap: () => Get.to(() => SearchDeneme()),
              ),
              PullDownMenuItem(
                icon: CupertinoIcons.slider_horizontal_3,
                title: 'practice.slider_management'.tr,
                onTap: () => Get.to(
                  () => SliderAdminView(
                    sliderId: 'online_sinav',
                    title: 'pasaj.tabs.online_exam'.tr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolAlertSheet(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => controller.showOkulAlert.value = false,
          child: Container(color: Colors.black.withAlpha(50)),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'practice.create_disabled_title'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                12.ph,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    'practice.create_disabled_body'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
                12.ph,
                GestureDetector(
                  onTap: () {
                    Get.to(() => BecomeVerifiedAccount());
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      'settings.become_verified'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
