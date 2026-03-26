part of 'create_book_controller.dart';

abstract class _CreateBookAnswerKeyControllerBase extends GetxController {
  _CreateBookAnswerKeyControllerBase(
    CevapAnahtariHazirlikModel model,
    Function onBack,
  ) : _state = _CreateBookAnswerKeyControllerState(
          model: model,
          onBack: onBack,
        ) {
    _initializeCreateBookAnswerKeyController(
        this as CreateBookAnswerKeyController);
  }

  final _CreateBookAnswerKeyControllerState _state;

  @override
  void onClose() {
    _state.baslikController.dispose();
    _state.inputController.dispose();
    super.onClose();
  }
}
