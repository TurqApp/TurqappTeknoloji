part of 'answer_key_controller.dart';

class _AnswerKeyControllerState {
  final AnswerKeySnapshotRepository answerKeySnapshotRepository =
      ensureAnswerKeySnapshotRepository();
  final BookletRepository bookletRepository = ensureBookletRepository();
  final LocalPreferenceRepository localPreferenceRepository =
      ensureLocalPreferenceRepository();
  final RxBool isLoading = false.obs;
  final RxBool isSearchLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt listingSelection = 1.obs;
  final RxBool listingSelectionReady = false.obs;
  final RxList<BookletModel> bookList = <BookletModel>[].obs;
  final RxList<BookletModel> searchResults = <BookletModel>[].obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? lastDocument;
  StreamSubscription<CachedResource<List<BookletModel>>>? homeSnapshotSub;
  Timer? searchDebounce;
  int searchToken = 0;
}

extension AnswerKeyControllerFieldsPart on AnswerKeyController {
  AnswerKeySnapshotRepository get _answerKeySnapshotRepository =>
      _state.answerKeySnapshotRepository;
  BookletRepository get _bookletRepository => _state.bookletRepository;
  LocalPreferenceRepository get _localPreferenceRepository =>
      _state.localPreferenceRepository;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSearchLoading => _state.isSearchLoading;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get hasMore => _state.hasMore;
  RxInt get listingSelection => _state.listingSelection;
  RxBool get listingSelectionReady => _state.listingSelectionReady;
  RxList<BookletModel> get bookList => _state.bookList;
  RxList<BookletModel> get searchResults => _state.searchResults;
  RxString get searchQuery => _state.searchQuery;
  ScrollController get scrollController => _state.scrollController;
  RxDouble get scrollOffset => _state.scrollOffset;
  DocumentSnapshot? get _lastDocument => _state.lastDocument;
  set _lastDocument(DocumentSnapshot? value) => _state.lastDocument = value;
  StreamSubscription<CachedResource<List<BookletModel>>>?
      get _homeSnapshotSub => _state.homeSnapshotSub;
  set _homeSnapshotSub(
    StreamSubscription<CachedResource<List<BookletModel>>>? value,
  ) =>
      _state.homeSnapshotSub = value;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchToken => _state.searchToken;
  set _searchToken(int value) => _state.searchToken = value;
}
