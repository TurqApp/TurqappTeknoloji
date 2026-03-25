part of 'scholarships_controller.dart';

class _ScholarshipsControllerState {
  final scrollController = ScrollController();
  final allScholarships = <Map<String, dynamic>>[].obs;
  final visibleScholarships = <Map<String, dynamic>>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final likedScholarships = <String, bool>{}.obs;
  final bookmarkedScholarships = <String, bool>{}.obs;
  final isExpandedList = <RxBool>[];
  final followedUsers = <String, bool>{}.obs;
  final followLoading = <String, bool>{}.obs;
  final likedByCurrentUser = <String>{};
  final bookmarkedByCurrentUser = <String>{};
  final shortLinkCache = <String, String>{};
  final shortLinkInFlight = <String>{};
  DateTime? lastRefresh;
  final pageIndices = <int, RxInt>{}.obs;
  final scrollOffset = 0.0.obs;
  final listingSelectionReady = false.obs;
  final listingSelection = 0.obs;
  final hasMoreData = true.obs;
  final totalCount = 0.obs;
  Timer? searchDebounce;
  int searchRequestToken = 0;
  int typesensePage = 0;
  StreamSubscription<CachedResource<ScholarshipListingSnapshot>>?
      homeSnapshotSub;
}

extension ScholarshipsControllerFieldsPart on ScholarshipsController {
  ScrollController get scrollController => _state.scrollController;
  RxList<Map<String, dynamic>> get allScholarships => _state.allScholarships;
  RxList<Map<String, dynamic>> get visibleScholarships =>
      _state.visibleScholarships;
  RxString get searchQuery => _state.searchQuery;
  RxBool get isLoading => _state.isLoading;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get isSearching => _state.isSearching;
  RxMap<String, bool> get likedScholarships => _state.likedScholarships;
  RxMap<String, bool> get bookmarkedScholarships =>
      _state.bookmarkedScholarships;
  List<RxBool> get isExpandedList => _state.isExpandedList;
  RxMap<String, bool> get followedUsers => _state.followedUsers;
  RxMap<String, bool> get followLoading => _state.followLoading;
  Set<String> get _likedByCurrentUser => _state.likedByCurrentUser;
  Set<String> get _bookmarkedByCurrentUser => _state.bookmarkedByCurrentUser;
  Map<String, String> get _shortLinkCache => _state.shortLinkCache;
  Set<String> get _shortLinkInFlight => _state.shortLinkInFlight;
  DateTime? get lastRefresh => _state.lastRefresh;
  set lastRefresh(DateTime? value) => _state.lastRefresh = value;
  RxMap<int, RxInt> get pageIndices => _state.pageIndices;
  RxDouble get scrollOffset => _state.scrollOffset;
  RxBool get listingSelectionReady => _state.listingSelectionReady;
  RxInt get listingSelection => _state.listingSelection;
  RxBool get hasMoreData => _state.hasMoreData;
  RxInt get totalCount => _state.totalCount;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchRequestToken => _state.searchRequestToken;
  set _searchRequestToken(int value) => _state.searchRequestToken = value;
  int get _typesensePage => _state.typesensePage;
  set _typesensePage(int value) => _state.typesensePage = value;
  StreamSubscription<CachedResource<ScholarshipListingSnapshot>>?
      get _homeSnapshotSub => _state.homeSnapshotSub;
  set _homeSnapshotSub(
          StreamSubscription<CachedResource<ScholarshipListingSnapshot>>?
              value) =>
      _state.homeSnapshotSub = value;
}
