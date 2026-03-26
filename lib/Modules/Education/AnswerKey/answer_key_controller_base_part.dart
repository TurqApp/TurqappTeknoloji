part of 'answer_key_controller.dart';

abstract class _AnswerKeyControllerBase extends GetxController {
  final _AnswerKeyControllerState _state = _AnswerKeyControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as AnswerKeyController)._handleControllerInit();
  }

  @override
  void onClose() {
    (this as AnswerKeyController)._handleControllerClose();
    super.onClose();
  }
}
