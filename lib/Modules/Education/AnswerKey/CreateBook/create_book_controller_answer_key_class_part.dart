part of 'create_book_controller.dart';

class CreateBookAnswerKeyController extends GetxController {
  final _CreateBookAnswerKeyControllerState _state;

  CreateBookAnswerKeyController(
    CevapAnahtariHazirlikModel model,
    Function onBack,
  ) : _state = _CreateBookAnswerKeyControllerState(
          model: model,
          onBack: onBack,
        ) {
    _initializeCreateBookAnswerKeyController(this);
  }

  @override
  void onClose() {
    baslikController.dispose();
    inputController.dispose();
    super.onClose();
  }
}
