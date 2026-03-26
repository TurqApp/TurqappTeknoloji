part of 'results_and_answers_controller.dart';

class _ResultsAndAnswersControllerState {
  final opticalFormRepository = OpticalFormRepository.ensure();
  final cevaplar = <String>[].obs;
  final dogruSayisi = 0.obs;
  final yanlisSayisi = 0.obs;
  final bosSayisi = 0.obs;
  final puan = 0.obs;
}

extension ResultsAndAnswersControllerFieldsPart on ResultsAndAnswersController {
  OpticalFormRepository get _opticalFormRepository =>
      _state.opticalFormRepository;
  RxList<String> get cevaplar => _state.cevaplar;
  RxInt get dogruSayisi => _state.dogruSayisi;
  RxInt get yanlisSayisi => _state.yanlisSayisi;
  RxInt get bosSayisi => _state.bosSayisi;
  RxInt get puan => _state.puan;
}
