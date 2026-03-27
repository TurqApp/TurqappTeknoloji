part of 'booklet_answer_controller.dart';

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
