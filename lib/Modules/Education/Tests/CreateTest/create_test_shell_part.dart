part of 'create_test.dart';

extension CreateTestShellPart on _CreateTestState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(
                  text: controller.model != null
                      ? "tests.edit_title".tr
                      : "tests.create_title".tr,
                ),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CupertinoActivityIndicator(
                              radius: 20,
                              color: Colors.black,
                            ),
                          )
                        : controller.appStore.isEmpty ||
                                controller.googlePlay.isEmpty
                            ? _buildMissingStoresState()
                            : testHazirla(context, controller),
                  ),
                ),
              ],
            ),
            _buildBranchPicker(context),
            _buildLanguagePicker(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingStoresState() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.black,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            "tests.create_data_missing".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "Montserrat",
            ),
          ),
        ],
      ),
    );
  }
}
