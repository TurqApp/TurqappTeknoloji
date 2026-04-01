part of 'answer_key_creating_option_controller.dart';

AnswerKeyCreatingOptionController ensureAnswerKeyCreatingOptionController(
  Function onBack, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindAnswerKeyCreatingOptionController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    AnswerKeyCreatingOptionController(onBack),
    tag: tag,
    permanent: permanent,
  );
}

AnswerKeyCreatingOptionController? maybeFindAnswerKeyCreatingOptionController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<AnswerKeyCreatingOptionController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<AnswerKeyCreatingOptionController>(tag: tag);
}

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
