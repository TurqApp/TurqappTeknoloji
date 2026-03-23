part of 'my_practice_exams.dart';

extension MyPracticeExamsShellPart on _MyPracticeExamsState {
  Widget _buildMissingSessionShell() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'pasaj.common.published'.tr),
            Expanded(
              child: Center(
                child: Text(
                  'practice.user_session_missing'.tr,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
