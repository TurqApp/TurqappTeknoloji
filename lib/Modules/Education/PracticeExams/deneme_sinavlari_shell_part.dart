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
}
