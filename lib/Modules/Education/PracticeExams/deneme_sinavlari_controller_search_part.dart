part of 'deneme_sinavlari_controller.dart';

extension DenemeSinavlariControllerSearchPart on DenemeSinavlariController {
  void _setupScrollControllerImpl() {
    scrollController.addListener(() {
      final currentOffset = scrollController.position.pixels;
      scrollOffset.value = currentOffset;

      if (currentOffset > _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (ustBar.value) ustBar.value = false;
      } else if (currentOffset < _previousOffset) {
        if (showButons.value) showButons.value = false;
        if (!ustBar.value) ustBar.value = true;
      }

      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !hasActiveSearch &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMore();
      }

      _previousOffset = currentOffset;
    });
  }

  void _setSearchQueryImpl(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      isSearchLoading.value = false;
      searchResults.clear();
      _searchToken++;
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesenseImpl(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesenseImpl(String query, int token) async {
    final normalized = query.trim();
    try {
      final resource = await _practiceExamSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }

      final results = resource.data ?? const <SinavModel>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      if (!_sameExamEntries(searchResults, results)) {
        searchResults.assignAll(results);
      }
    } catch (e) {
      log("Deneme typesense search error: $e");
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }
}
