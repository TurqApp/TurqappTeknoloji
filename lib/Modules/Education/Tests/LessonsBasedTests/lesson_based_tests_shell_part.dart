part of 'lesson_based_tests.dart';

extension _LessonBasedTestsShellPart on _LessonBasedTestsState {
  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackButtons(
              text: 'tests.lesson_based_title'.trParams({'type': testTuru}),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: controller.getData,
                  child: Obx(() => _buildContent()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
