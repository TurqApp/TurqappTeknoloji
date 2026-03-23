part of 'view_changer.dart';

extension ViewChangerShellPart on _ViewChangerState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'view_changer.title'.tr),
            Expanded(
              child: ListView(
                children: [
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.updateViewMode(0);
                              Get.back();
                            },
                            child: _buildClassicSelection(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Divider(
                              color: Colors.grey.withAlpha(50),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.updateViewMode(1);
                              Get.back();
                            },
                            child: _buildModernSelection(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
