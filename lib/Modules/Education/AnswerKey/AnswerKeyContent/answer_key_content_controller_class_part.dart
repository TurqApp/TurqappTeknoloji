part of 'answer_key_content_controller.dart';

class AnswerKeyContentController extends GetxController {
  final _AnswerKeyContentControllerState _state;

  AnswerKeyContentController(BookletModel model, Function(bool) onUpdate)
      : _state = _AnswerKeyContentControllerState(
          model: model,
          onUpdate: onUpdate,
        );

  @override
  void onInit() {
    super.onInit();
    _handleAnswerKeyContentInit(this);
  }
}
