part of 'create_test_question_content_controller_library.dart';

extension CreateTestQuestionContentControllerDataPart
    on CreateTestQuestionContentController {
  bool get hasInvalidDocId => model.docID.isEmpty;

  void initializeState() {
    if (hasInvalidDocId) {
      isInvalid.value = true;
    }
  }
}
