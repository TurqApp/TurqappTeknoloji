part of 'deneme_sinavlari_controller.dart';

const String _practiceExamListingSelectionPrefKeyPrefix =
    'pasaj_practice_exam_listing_selection';
const int _practiceExamHomePageSize =
    ReadBudgetRegistry.practiceExamHomeInitialLimit;

class _DenemeSinavlariControllerState {
  final userSummaryResolver = UserSummaryResolver.ensure();
  final practiceExamSnapshotRepository = ensurePracticeExamSnapshotRepository();
  final practiceExamRepository = ensurePracticeExamRepository();
  final localPreferenceRepository = ensureLocalPreferenceRepository();
  final list = <SinavModel>[].obs;
  final okul = false.obs;
  final showButons = false.obs;
  final ustBar = true.obs;
  final showOkulAlert = false.obs;
  final isLoading = true.obs;
  final isSearchLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final listingSelection = 1.obs;
  final listingSelectionReady = false.obs;
  final scrollController = ScrollController();
  double previousOffset = 0.0;
  final scrollOffset = 0.0.obs;
  final searchQuery = ''.obs;
  final searchResults = <SinavModel>[].obs;
  DocumentSnapshot? lastDocument;
  StreamSubscription<CachedResource<List<SinavModel>>>? homeSnapshotSub;
  Timer? searchDebounce;
  int searchToken = 0;
}

extension DenemeSinavlariControllerFieldsPart on DenemeSinavlariController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  PracticeExamSnapshotRepository get _practiceExamSnapshotRepository =>
      _state.practiceExamSnapshotRepository;
  PracticeExamRepository get _practiceExamRepository =>
      _state.practiceExamRepository;
  LocalPreferenceRepository get _localPreferenceRepository =>
      _state.localPreferenceRepository;
  RxList<SinavModel> get list => _state.list;
  RxBool get okul => _state.okul;
  RxBool get showButons => _state.showButons;
  RxBool get ustBar => _state.ustBar;
  RxBool get showOkulAlert => _state.showOkulAlert;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSearchLoading => _state.isSearchLoading;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get hasMore => _state.hasMore;
  RxInt get listingSelection => _state.listingSelection;
  RxBool get listingSelectionReady => _state.listingSelectionReady;
  ScrollController get scrollController => _state.scrollController;
  double get _previousOffset => _state.previousOffset;
  set _previousOffset(double value) => _state.previousOffset = value;
  RxDouble get scrollOffset => _state.scrollOffset;
  RxString get searchQuery => _state.searchQuery;
  RxList<SinavModel> get searchResults => _state.searchResults;
  DocumentSnapshot? get _lastDocument => _state.lastDocument;
  set _lastDocument(DocumentSnapshot? value) => _state.lastDocument = value;
  StreamSubscription<CachedResource<List<SinavModel>>>? get _homeSnapshotSub =>
      _state.homeSnapshotSub;
  set _homeSnapshotSub(
    StreamSubscription<CachedResource<List<SinavModel>>>? value,
  ) =>
      _state.homeSnapshotSub = value;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchToken => _state.searchToken;
  set _searchToken(int value) => _state.searchToken = value;
}
