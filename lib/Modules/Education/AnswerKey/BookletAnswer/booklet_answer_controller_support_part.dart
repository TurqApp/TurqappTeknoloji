part of 'booklet_answer_controller.dart';

class _BookletAnswerControllerState {
  _BookletAnswerControllerState({
    required this.model,
    required this.anaModel,
    ConfigRepository? configRepository,
  }) : configRepository = configRepository ?? ConfigRepository();

  final ConfigRepository configRepository;
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

class BookletAnswerController extends GetxController {
  final _BookletAnswerControllerState _state;

  BookletAnswerController(AnswerKeySubModel model, BookletModel anaModel)
      : _state =
            _BookletAnswerControllerState(model: model, anaModel: anaModel);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}

BookletAnswerController ensureBookletAnswerController(
  AnswerKeySubModel model,
  BookletModel anaModel, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindBookletAnswerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    BookletAnswerController(model, anaModel),
    tag: tag,
    permanent: permanent,
  );
}

BookletAnswerController? maybeFindBookletAnswerController({String? tag}) {
  final isRegistered = Get.isRegistered<BookletAnswerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<BookletAnswerController>(tag: tag);
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
