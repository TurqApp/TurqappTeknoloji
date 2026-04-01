part of 'antreman_comments_controller.dart';

abstract class _AntremanCommentsControllerBase extends GetxController {
  _AntremanCommentsControllerBase(QuestionBankModel question)
      : _state = _AntremanCommentsControllerState(question);

  final _AntremanCommentsControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleAntremanCommentsInit(this as AntremanCommentsController);
  }

  @override
  void onClose() {
    _handleAntremanCommentsClose(this as AntremanCommentsController);
    super.onClose();
  }
}
