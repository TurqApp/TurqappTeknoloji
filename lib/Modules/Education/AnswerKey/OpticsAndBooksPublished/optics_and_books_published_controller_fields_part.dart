part of 'optics_and_books_published_controller_library.dart';

class _OpticsAndBooksPublishedControllerState {
  final BookletRepository bookletRepository = ensureBookletRepository();
  final OpticalFormRepository opticalFormRepository =
      ensureOpticalFormRepository();
  final RxList<BookletModel> list = <BookletModel>[].obs;
  final RxList<OpticalFormModel> optikler = <OpticalFormModel>[].obs;
  final RxInt selection = 0.obs;
  final RxBool isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  int lastOpenRefreshAt = 0;
}

extension OpticsAndBooksPublishedControllerFieldsPart
    on OpticsAndBooksPublishedController {
  BookletRepository get _bookletRepository => _state.bookletRepository;
  OpticalFormRepository get _opticalFormRepository =>
      _state.opticalFormRepository;
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
