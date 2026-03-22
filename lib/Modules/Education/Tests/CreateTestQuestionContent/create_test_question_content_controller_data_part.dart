part of 'create_test_question_content_controller.dart';

extension CreateTestQuestionContentControllerDataPart
    on CreateTestQuestionContentController {
  bool get hasInvalidDocId => model.docID.isEmpty;

  void initializeState() {
    if (hasInvalidDocId) {
      isInvalid.value = true;
    }
  }
}
