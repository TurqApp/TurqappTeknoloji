part of 'create_book_controller.dart';

class _CreateBookAnswerKeyControllerState {
  _CreateBookAnswerKeyControllerState({
    required this.model,
    required this.onBack,
  });

  final CevapAnahtariHazirlikModel model;
  final Function onBack;
  final TextEditingController baslikController = TextEditingController();
  final TextEditingController inputController = TextEditingController();
  final RxList<String> cevaplar = <String>[].obs;
  final RxBool onIzlendi = false.obs;
}

extension CreateBookAnswerKeyControllerFieldsPart
    on CreateBookAnswerKeyController {
  CevapAnahtariHazirlikModel get model => _state.model;
  Function get onBack => _state.onBack;
  TextEditingController get baslikController => _state.baslikController;
  TextEditingController get inputController => _state.inputController;
  RxList<String> get cevaplar => _state.cevaplar;
  RxBool get onIzlendi => _state.onIzlendi;
}
