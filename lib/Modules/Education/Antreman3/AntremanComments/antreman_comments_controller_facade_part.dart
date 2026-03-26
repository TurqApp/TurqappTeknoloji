part of 'antreman_comments_controller.dart';

AntremanCommentsController ensureAntremanCommentsController({
  required QuestionBankModel question,
  String? tag,
  bool permanent = false,
}) =>
    _ensureAntremanCommentsController(
      question: question,
      tag: tag,
      permanent: permanent,
    );

AntremanCommentsController? maybeFindAntremanCommentsController({
  String? tag,
}) =>
    _maybeFindAntremanCommentsController(tag: tag);

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
