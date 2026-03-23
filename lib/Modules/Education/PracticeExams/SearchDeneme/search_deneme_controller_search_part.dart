part of 'search_deneme_controller.dart';

extension SearchDenemeControllerSearchPart on SearchDenemeController {
  Future<void> _getDataImpl() async {
    await filterSearchResults(searchController.text);
  }

  Future<void> _filterSearchResultsImpl(String query) async {
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
}
