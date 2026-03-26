part of 'answer_key_controller.dart';

AnswerKeyController ensureAnswerKeyController({bool permanent = false}) =>
    maybeFindAnswerKeyController() ??
    Get.put(AnswerKeyController(), permanent: permanent);

AnswerKeyController? maybeFindAnswerKeyController() =>
    Get.isRegistered<AnswerKeyController>()
        ? Get.find<AnswerKeyController>()
        : null;

extension AnswerKeyControllerFacadePart on AnswerKeyController {
  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  void toggleListingSelection() {
    _toggleListingSelectionValue();
  }
}
