part of 'saved_tests.dart';

extension _SavedTestsShellPart on _SavedTestsState {
  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'common.saved'.tr),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(() => _buildContent()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
