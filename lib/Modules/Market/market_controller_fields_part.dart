part of 'market_controller.dart';

class _MarketControllerState {
  final schemaService = ensureMarketSchemaService();
  final marketSnapshotRepository = MarketSnapshotRepository.ensure();
  final cityDirectoryService = ensureCityDirectoryService();
  final scrollController = ScrollController();
  final search = TextEditingController();
  final scrollOffset = 0.0.obs;
  final listingSelectionReady = false.obs;
  final listingSelection = 1.obs;
  final isLoading = false.obs;
  final isSearchLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedCategoryKey = ''.obs;
  final selectedCityFilter = ''.obs;
  final selectedContactFilter = ''.obs;
  final sortSelection = 'newest'.obs;
  final minPriceFilter = ''.obs;
  final maxPriceFilter = ''.obs;
  final categories = <Map<String, dynamic>>[].obs;
  final roundMenuItems = <Map<String, dynamic>>[].obs;
  final items = <MarketItemModel>[].obs;
  final searchedItems = <MarketItemModel>[].obs;
  final visibleItems = <MarketItemModel>[].obs;
  final pendingCreatedItems = <MarketItemModel>[].obs;
  final allCityOptions = <String>[].obs;
  final savedItemIds = <String>[].obs;
  final roundMenuBadges = <String, int>{}.obs;
  final recentSearches = <String>[].obs;
  StreamSubscription<CachedResource<List<MarketItemModel>>>? homeSnapshotSub;
  Timer? searchDebounce;
  int searchRequestId = 0;
  Future<void>? startupPrepareFuture;
  bool primarySurfacePrimedOnce = false;
  bool startupShardHydrated = false;
  int? startupShardAgeMs;
}

extension MarketControllerFieldsPart on MarketController {
  MarketSchemaService get _schemaService => _state.schemaService;
  MarketSnapshotRepository get _marketSnapshotRepository =>
      _state.marketSnapshotRepository;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  ScrollController get scrollController => _state.scrollController;
  TextEditingController get search => _state.search;
  RxDouble get scrollOffset => _state.scrollOffset;
  RxBool get listingSelectionReady => _state.listingSelectionReady;
  RxInt get listingSelection => _state.listingSelection;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSearchLoading => _state.isSearchLoading;
  RxString get searchQuery => _state.searchQuery;
  RxString get selectedCategoryKey => _state.selectedCategoryKey;
  RxString get selectedCityFilter => _state.selectedCityFilter;
  RxString get selectedContactFilter => _state.selectedContactFilter;
  RxString get sortSelection => _state.sortSelection;
  RxString get minPriceFilter => _state.minPriceFilter;
  RxString get maxPriceFilter => _state.maxPriceFilter;
  RxList<Map<String, dynamic>> get categories => _state.categories;
  RxList<Map<String, dynamic>> get roundMenuItems => _state.roundMenuItems;
  RxList<MarketItemModel> get items => _state.items;
  RxList<MarketItemModel> get searchedItems => _state.searchedItems;
  RxList<MarketItemModel> get visibleItems => _state.visibleItems;
  RxList<MarketItemModel> get pendingCreatedItems => _state.pendingCreatedItems;
  RxList<String> get allCityOptions => _state.allCityOptions;
  RxList<String> get savedItemIds => _state.savedItemIds;
  RxMap<String, int> get roundMenuBadges => _state.roundMenuBadges;
  RxList<String> get recentSearches => _state.recentSearches;
  StreamSubscription<CachedResource<List<MarketItemModel>>>?
      get _homeSnapshotSub => _state.homeSnapshotSub;
  set _homeSnapshotSub(
          StreamSubscription<CachedResource<List<MarketItemModel>>>? value) =>
      _state.homeSnapshotSub = value;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchRequestId => _state.searchRequestId;
  set _searchRequestId(int value) => _state.searchRequestId = value;
  Future<void>? get _startupPrepareFuture => _state.startupPrepareFuture;
  set _startupPrepareFuture(Future<void>? value) =>
      _state.startupPrepareFuture = value;
  bool get _primarySurfacePrimedOnce => _state.primarySurfacePrimedOnce;
  set _primarySurfacePrimedOnce(bool value) =>
      _state.primarySurfacePrimedOnce = value;
  bool get _startupShardHydrated => _state.startupShardHydrated;
  set _startupShardHydrated(bool value) => _state.startupShardHydrated = value;
  int? get _startupShardAgeMs => _state.startupShardAgeMs;
  set _startupShardAgeMs(int? value) => _state.startupShardAgeMs = value;
}
