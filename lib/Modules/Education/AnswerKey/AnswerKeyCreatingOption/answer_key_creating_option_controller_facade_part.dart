part of 'answer_key_creating_option_controller.dart';

extension AnswerKeyCreatingOptionControllerFacadePart
    on AnswerKeyCreatingOptionController {
  void navigateToCreateAnswerKey(BuildContext context) {
    Get.to(
      () => CreateAnswerKey(
        onBack: () {
          onBack();
          Get.back();
        },
      ),
    )?.then((_) => Get.back());
  }

  void navigateToCreateBook(BuildContext context) {
    Get.to(
      () => CreateBook(
        onBack: () {
          onBack();
          Get.back();
        },
      ),
    )?.then((_) => Get.back());
  }
}
