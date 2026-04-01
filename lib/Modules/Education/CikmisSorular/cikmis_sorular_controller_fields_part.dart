part of 'cikmis_sorular_controller.dart';

class _CikmisSorularControllerState {
  final CikmisSorularSnapshotRepository snapshotRepository =
      ensureCikmisSorularSnapshotRepository();
  final RxList<Map<String, dynamic>> covers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearchLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  final RxBool pendingScrollReset = false.obs;
  Timer? searchDebounce;
  int searchToken = 0;
  StreamSubscription<CachedResource<List<Map<String, dynamic>>>>?
      homeSnapshotSub;
}

extension CikmisSorularControllerFieldsPart on CikmisSorularController {
  CikmisSorularSnapshotRepository get _snapshotRepository =>
      _state.snapshotRepository;
  RxList<Map<String, dynamic>> get covers => _state.covers;
  RxList<Map<String, dynamic>> get searchResults => _state.searchResults;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSearchLoading => _state.isSearchLoading;
  RxString get searchQuery => _state.searchQuery;
  ScrollController get scrollController => _state.scrollController;
  RxDouble get scrollOffset => _state.scrollOffset;
  RxBool get pendingScrollReset => _state.pendingScrollReset;
  Timer? get _searchDebounce => _state.searchDebounce;
  set _searchDebounce(Timer? value) => _state.searchDebounce = value;
  int get _searchToken => _state.searchToken;
  set _searchToken(int value) => _state.searchToken = value;
  StreamSubscription<CachedResource<List<Map<String, dynamic>>>>?
      get _homeSnapshotSub => _state.homeSnapshotSub;
  set _homeSnapshotSub(
    StreamSubscription<CachedResource<List<Map<String, dynamic>>>>? value,
  ) =>
      _state.homeSnapshotSub = value;
}
