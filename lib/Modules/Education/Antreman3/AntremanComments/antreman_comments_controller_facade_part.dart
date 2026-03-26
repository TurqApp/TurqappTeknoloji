part of 'antreman_comments_controller.dart';

AntremanCommentsController _ensureAntremanCommentsController({
  required QuestionBankModel question,
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindAntremanCommentsController(tag: tag) ??
    Get.put(
      AntremanCommentsController(question),
      tag: tag,
      permanent: permanent,
    );

AntremanCommentsController? _maybeFindAntremanCommentsController({
  String? tag,
}) =>
    Get.isRegistered<AntremanCommentsController>(tag: tag)
        ? Get.find<AntremanCommentsController>(tag: tag)
        : null;

void _handleAntremanCommentsInit(AntremanCommentsController controller) {
  controller._handleCommentsInit();
}

void _handleAntremanCommentsClose(AntremanCommentsController controller) {
  controller._handleCommentsClose();
}
