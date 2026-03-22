part of 'my_tests.dart';

extension _MyTestsShellPart on _MyTestsState {
  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              children: [
                BackButtons(text: 'tests.my_tests_title'.tr),
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: controller.getData,
                    child: Obx(() => _buildContent()),
                  ),
                ),
              ],
            ),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => Get.to(() => const CreateTest()),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Obx(
              () => controller.list.isEmpty
                  ? Transform.translate(
                      offset: const Offset(-20, -30),
                      child: Image.asset(
                        'assets/education/arrowdef.webp',
                        height: 80,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              height: 60,
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.all(
                  Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
