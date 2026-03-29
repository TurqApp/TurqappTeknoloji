part of 'optics_and_books_published_controller_library.dart';

class _OpticsAndBooksPublishedControllerState {
  final AnswerKeySnapshotRepository answerKeySnapshotRepository =
      ensureAnswerKeySnapshotRepository();
  final OpticalFormSnapshotRepository opticalFormSnapshotRepository =
      ensureOpticalFormSnapshotRepository();
  final BookletRepository bookletRepository = ensureBookletRepository();
  final RxList<BookletModel> list = <BookletModel>[].obs;
  final RxList<OpticalFormModel> optikler = <OpticalFormModel>[].obs;
  final RxInt selection = 0.obs;
  final RxBool isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  int lastOpenRefreshAt = 0;
}

extension OpticsAndBooksPublishedControllerFieldsPart
    on OpticsAndBooksPublishedController {
  AnswerKeySnapshotRepository get _answerKeySnapshotRepository =>
      _state.answerKeySnapshotRepository;
  OpticalFormSnapshotRepository get _opticalFormSnapshotRepository =>
      _state.opticalFormSnapshotRepository;
  BookletRepository get _bookletRepository => _state.bookletRepository;
  RxList<BookletModel> get list => _state.list;
  RxList<OpticalFormModel> get optikler => _state.optikler;
  RxInt get selection => _state.selection;
  RxBool get isLoading => _state.isLoading;
  RxDouble get scrollOffset => _state.scrollOffset;
  int get _lastOpenRefreshAt => _state.lastOpenRefreshAt;
  set _lastOpenRefreshAt(int value) => _state.lastOpenRefreshAt = value;
}

class OpticsAndBooksPublishedController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _OpticsAndBooksPublishedControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOpticsAndBooksPublishedInit(this);
  }
}
