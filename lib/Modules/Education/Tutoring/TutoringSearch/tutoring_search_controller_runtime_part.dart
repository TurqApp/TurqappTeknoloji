part of 'tutoring_search_controller.dart';

extension TutoringSearchControllerRuntimeX on TutoringSearchController {
  bool _sameTutoringEntries(
    List<TutoringModel> current,
    List<TutoringModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  Future<void> _handleOnInit() async {
    await _bootstrapInitialData();
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        performSearch(query);
      } else {
        if (!_sameTutoringEntries(searchResults, _initialTutorings)) {
          searchResults.value = _initialTutorings;
        }
      }
    }, time: const Duration(milliseconds: 500));
  }

  void _handleOnClose() {
    searchController.dispose();
  }

  Future<void> _bootstrapInitialData() async {
    try {
      final resource = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 60,
      );
      final cachedItems = resource.data ?? const <TutoringModel>[];
      if (cachedItems.isNotEmpty) {
        _initialTutorings = cachedItems;
        if (!_sameTutoringEntries(searchResults, cachedItems)) {
          searchResults.value = cachedItems;
        }
        isLoading.value = false;
        await fetchInitialData(silent: true);
        return;
      }
    } catch (_) {}

    await fetchInitialData();
  }

  Future<void> fetchInitialData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && searchResults.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final result = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 60,
        forceSync: forceRefresh,
      );
      _initialTutorings = result.data ?? const <TutoringModel>[];
      if (!_sameTutoringEntries(searchResults, _initialTutorings)) {
        searchResults.value = _initialTutorings;
      }
    } catch (_) {
    } finally {
      if (shouldShowLoader || searchResults.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  Future<void> performSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      if (!_sameTutoringEntries(searchResults, _initialTutorings)) {
        searchResults.value = _initialTutorings;
      }
      return;
    }

    try {
      final result = await _tutoringSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 60,
        forceSync: true,
      );
      final items = result.data ?? const <TutoringModel>[];
      if (!_sameTutoringEntries(searchResults, items)) {
        searchResults.value = items;
      }
    } catch (_) {
      if (searchResults.isNotEmpty) {
        searchResults.value = const <TutoringModel>[];
      }
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
