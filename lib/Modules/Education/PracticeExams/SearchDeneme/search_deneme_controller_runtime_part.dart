part of 'search_deneme_controller.dart';

extension SearchDenemeControllerRuntimePart on SearchDenemeController {
  void _resetSearchState() {
    _searchToken++;
    focusNode.unfocus();
    searchController.clear();
    if (filteredList.isNotEmpty) {
      filteredList.clear();
    }
    isLoading.value = false;
  }

  void _handleSearchDenemeOnInit() {
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });
  }

  void _handleSearchDenemeOnClose() {
    searchController.dispose();
    focusNode.dispose();
  }

  Future<void> _performSearchDenemeDataLoad() async {
    await filterSearchResults(searchController.text);
  }

  Future<void> _performFilterSearchResults(String query) async {
    final normalized = query.trim();
    final token = ++_searchToken;
    if (normalized.length < 2) {
      if (filteredList.isNotEmpty) {
        filteredList.clear();
      }
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final resource = await _practiceExamSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken) return;
      final results = resource.data ?? const <SinavModel>[];
      if (!_sameExamEntries(filteredList, results)) {
        filteredList.assignAll(results);
      }
    } finally {
      if (token == _searchToken) {
        isLoading.value = false;
      }
    }
  }

  bool _sameExamEntries(
    List<SinavModel> current,
    List<SinavModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }
}

SearchDenemeController ensureSearchDenemeController({
  bool permanent = false,
}) {
  final existing = maybeFindSearchDenemeController();
  if (existing != null) return existing;
  return Get.put(SearchDenemeController(), permanent: permanent);
}

SearchDenemeController? maybeFindSearchDenemeController() {
  final isRegistered = Get.isRegistered<SearchDenemeController>();
  if (!isRegistered) return null;
  return Get.find<SearchDenemeController>();
}

extension SearchDenemeControllerFacadePart on SearchDenemeController {
  Future<void> getData() => _performSearchDenemeDataLoad();

  Future<void> filterSearchResults(String query) =>
      _performFilterSearchResults(query);

  void resetSearch() => _resetSearchState();
}
