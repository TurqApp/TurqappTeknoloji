part of 'create_answer_key_controller.dart';

class CreateAnswerKeyController extends GetxController {
  final _CreateAnswerKeyControllerState _state;

  CreateAnswerKeyController(Function onBack)
      : _state = _CreateAnswerKeyControllerState(onBack: onBack);

  @override
  void onClose() {
    _disposeCreateAnswerKeyController(this);
    super.onClose();
  }
}
