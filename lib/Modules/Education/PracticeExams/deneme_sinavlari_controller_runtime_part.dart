part of 'deneme_sinavlari_controller.dart';

extension DenemeSinavlariControllerRuntimePart on DenemeSinavlariController {
  bool _sameExamList(List<SinavModel> next) {
    return _sameExamEntries(list, next);
  }

  bool _sameExamEntries(List<SinavModel> current, List<SinavModel> next) {
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

  void _handlePracticeExamInit() {
    unawaited(_restoreListingSelectionImpl());
    scrolControlcu();
    getOkulBilgisi();
    unawaited(_bootstrapInitialDataImpl());
  }

  void _handlePracticeExamClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
  }

  void toggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelectionImpl());
  }

  void scrolControlcu() => _setupScrollControllerImpl();

  Future<void> getOkulBilgisi() => _getOkulBilgisiImpl();

  Future<void> getData() async {
    final hadLocalItems = list.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final resource = await _loadHomeSnapshotImpl();
      final items = resource.data ?? const <SinavModel>[];
      if (!_sameExamList(items)) {
        list.assignAll(items);
      }
      hasMore.value = items.length >= _practiceExamHomePageSize;
    } catch (e) {
      log("DenemeSinavlariController.getData error: $e");
      AppSnackbar('common.error'.tr, 'practice.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _fetchNextPageImpl();
      list.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log("DenemeSinavlariController.loadMore error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setSearchQuery(String query) => _setSearchQueryImpl(query);
}
