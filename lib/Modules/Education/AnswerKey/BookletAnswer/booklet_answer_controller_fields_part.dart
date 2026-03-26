part of 'booklet_answer_controller.dart';

class _BookletAnswerControllerState {
  _BookletAnswerControllerState({
    required this.model,
    required this.anaModel,
  });

  final ConfigRepository configRepository = ensureConfigRepository();
  final AnswerKeySubModel model;
  final BookletModel anaModel;
  final RxList<String> cevaplar = <String>[].obs;
  final RxBool completed = false.obs;
  final RxInt correctCount = 0.obs;
  final RxInt wrongCount = 0.obs;
  final RxInt emptyCount = 0.obs;
  final RxDouble scorePercent = 0.0.obs;
  final RxDouble netScore = 0.0.obs;
  final RxBool isInterstitialAdReady = false.obs;
  final RxString iosList = ''.obs;
  final RxString androidList = ''.obs;
}

extension BookletAnswerControllerFieldsPart on BookletAnswerController {
  ConfigRepository get _configRepository => _state.configRepository;
  AnswerKeySubModel get model => _state.model;
  BookletModel get anaModel => _state.anaModel;
  RxList<String> get cevaplar => _state.cevaplar;
  RxBool get completed => _state.completed;
  RxInt get correctCount => _state.correctCount;
  RxInt get wrongCount => _state.wrongCount;
  RxInt get emptyCount => _state.emptyCount;
  RxDouble get scorePercent => _state.scorePercent;
  RxDouble get netScore => _state.netScore;
  RxBool get isInterstitialAdReady => _state.isInterstitialAdReady;
  RxString get iosList => _state.iosList;
  RxString get androidList => _state.androidList;
}
