part of 'antreman_comments_controller.dart';

class AntremanCommentsController extends GetxController {
  static AntremanCommentsController ensure({
    required QuestionBankModel question,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureAntremanCommentsController(
        question: question,
        tag: tag,
        permanent: permanent,
      );

  static AntremanCommentsController? maybeFind({String? tag}) =>
      _maybeFindAntremanCommentsController(tag: tag);

  final _AntremanCommentsControllerState _state;

  AntremanCommentsController(QuestionBankModel question)
      : _state = _AntremanCommentsControllerState(question);

  @override
  void onInit() {
    super.onInit();
    _handleAntremanCommentsInit(this);
  }

  @override
  void onClose() {
    _handleAntremanCommentsClose(this);
    super.onClose();
  }
}
