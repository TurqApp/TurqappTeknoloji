part of 'tutoring_controller.dart';

class _TutoringControllerState {
  final TutoringSnapshotRepository tutoringSnapshotRepository =
      ensureTutoringSnapshotRepository();
  final TutoringRepository tutoringRepository = TutoringRepository.ensure();
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchPreviewController = TextEditingController();
  final RxBool isLoading = true.obs;
  final RxBool isSearchLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxList<TutoringModel> tutoringList = <TutoringModel>[].obs;
  final RxList<TutoringModel> searchResults = <TutoringModel>[].obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  StreamSubscription<CachedResource<List<TutoringModel>>>? homeSnapshotSub;
  Timer? searchDebounce;
  int searchToken = 0;
  int currentPage = 1;
}

extension TutoringControllerFieldsPart on TutoringController {
  TutoringSnapshotRepository get _tutoringSnapshotRepository =>
      _state.tutoringSnapshotRepository;
  TutoringRepository get _tutoringRepository => _state.tutoringRepository;
  FocusNode get focusNode => _state.focusNode;
  TextEditingController get searchPreviewController =>
      _state.searchPreviewController;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSearchLoading => _state.isSearchLoading;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get hasMore => _state.hasMore;
  RxList<TutoringModel> get tutoringList => _state.tutoringList;
  RxList<TutoringModel> get searchResults => _state.searchResults;
  RxString get searchQuery => _state.searchQuery;
  ScrollController get scrollController => _state.scrollController;
  RxDouble get scrollOffset => _state.scrollOffset;
  StreamSubscription<CachedResource<List<TutoringModel>>>?
      get _homeSnapshotSub => _state.homeSnapshotSub;
  set _homeSnapshotSub(
    StreamSubscription<CachedResource<List<TutoringModel>>>? value,
  ) =>
      _state.homeSnapshotSub = value;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchToken => _state.searchToken;
  set _searchToken(int value) => _state.searchToken = value;
  int get _currentPage => _state.currentPage;
  set _currentPage(int value) => _state.currentPage = value;
}
