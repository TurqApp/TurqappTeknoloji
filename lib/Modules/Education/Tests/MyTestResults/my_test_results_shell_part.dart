part of 'my_test_results.dart';

extension _MyTestResultsShellPart on _MyTestResultsState {
  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'tests.results_title'.tr),
            Expanded(
              child: RefreshIndicator(
                color: Colors.white,
                backgroundColor: Colors.black,
                onRefresh: controller.findAndGetTestler,
                child: Obx(() => _buildContent()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
