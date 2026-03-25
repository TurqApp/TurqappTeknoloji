part of 'cikmis_sorular_controller.dart';

extension CikmisSorularControllerRuntimeX on CikmisSorularController {
  Future<void> _handleOnInit() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _snapshotRepository
        .openHome(userId: userId)
        .listen(_applyHomeSnapshotResource);
  }

  Future<void> refreshData({bool silent = false}) async {
    final shouldShowLoader = !silent && covers.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final resource = await _snapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        forceSync: !silent,
      );
      final items = resource.data ?? const <Map<String, dynamic>>[];
      _assignCoverDocs(items);
    } finally {
      if (shouldShowLoader || covers.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  void _assignCoverDocs(List<Map<String, dynamic>> rawDocs) {
    const baslikSirasi = <String>[
      'LGS',
      'YKS',
      'KPSS',
      'ALES',
      'YDS',
      'DGS',
      'TUS',
      'DUS',
    ];
    final seen = <String>{};
    final items = <CikmisSorularCoverModel>[];
    for (final doc in rawDocs) {
      final anaBaslik = (doc['anaBaslik'] ?? '').toString();
      if (anaBaslik.isEmpty || seen.contains(anaBaslik)) continue;
      seen.add(anaBaslik);
      items.add(
        CikmisSorularCoverModel(
          anaBaslik: anaBaslik,
          docID: (doc['_docId'] ?? '').toString(),
          sinavTuru: (doc['sinavTuru'] ?? '').toString(),
        ),
      );
    }
    items.sort((a, b) {
      var indexA = baslikSirasi.indexOf(a.anaBaslik);
      var indexB = baslikSirasi.indexOf(b.anaBaslik);
      if (indexA == -1) indexA = baslikSirasi.length;
      if (indexB == -1) indexB = baslikSirasi.length;
      return indexA.compareTo(indexB);
    });
    covers.assignAll(
      items
          .map(
            (item) => <String, dynamic>{
              '_docId': item.docID,
              'anaBaslik': item.anaBaslik,
              'sinavTuru': item.sinavTuru,
            },
          )
          .toList(growable: false),
    );
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      _searchToken++;
      isSearchLoading.value = false;
      searchResults.clear();
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final resource = await _snapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        forceSync: true,
      );
      final docs = resource.data ?? const <Map<String, dynamic>>[];
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      searchResults.assignAll(docs);
    } catch (e) {
      debugPrint('Past question typesense search error: $e');
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  void _handleOnClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
  }

  void _applyHomeSnapshotResource(
    CachedResource<List<Map<String, dynamic>>> resource,
  ) {
    final docs = resource.data ?? const <Map<String, dynamic>>[];
    if (docs.isNotEmpty) {
      _assignCoverDocs(docs);
    }

    if (!resource.isRefreshing || docs.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (covers.isEmpty) {
      isLoading.value = true;
    }
  }
}
