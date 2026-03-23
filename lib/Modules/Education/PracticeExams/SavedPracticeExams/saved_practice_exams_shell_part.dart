part of 'saved_practice_exams.dart';

extension SavedPracticeExamsShellPart on _SavedPracticeExamsState {
  Widget _buildSavedPracticeExamsBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'common.saved'.tr),
          Expanded(child: _buildSavedPracticeExamsContent()),
        ],
      ),
    );
  }
}
