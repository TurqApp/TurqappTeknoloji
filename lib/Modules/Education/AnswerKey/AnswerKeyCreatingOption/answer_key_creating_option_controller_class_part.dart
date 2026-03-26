part of 'answer_key_creating_option_controller.dart';

class AnswerKeyCreatingOptionController extends GetxController {
  static AnswerKeyCreatingOptionController ensure(
    Function onBack, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      AnswerKeyCreatingOptionController(onBack),
      tag: tag,
      permanent: permanent,
    );
  }

  static AnswerKeyCreatingOptionController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<AnswerKeyCreatingOptionController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AnswerKeyCreatingOptionController>(tag: tag);
  }

  final Function onBack;

  AnswerKeyCreatingOptionController(this.onBack);
}
