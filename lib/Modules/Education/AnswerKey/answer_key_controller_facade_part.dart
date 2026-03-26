part of 'answer_key_controller.dart';

extension AnswerKeyControllerFacadePart on AnswerKeyController {
  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  void toggleListingSelection() {
    _toggleListingSelectionValue();
  }
}
