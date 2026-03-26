part of 'antreman_comments_controller.dart';

class AntremanCommentsController extends GetxController {
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
