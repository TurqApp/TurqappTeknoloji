part of 'search_answer_key_controller.dart';

extension SearchAnswerKeyControllerRuntimePart on SearchAnswerKeyController {
  void _handleSearchAnswerKeyOnInit() {
    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
  }

  void _handleSearchAnswerKeyOnClose() {
    searchController.dispose();
  }

  Future<void> onSearchChanged(String value) async {
    final normalized = value.trim();
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
      final resource = await _answerKeySnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.effectiveUserId,
        limit: 40,
        forceSync: true,
      );
      if (token != _searchToken) return;
      final results = resource.data ?? const <BookletModel>[];
      if (!_sameBookletEntries(filteredList, results)) {
        filteredList.assignAll(results);
      }
    } catch (e) {
      log('Answer key typesense search error: $e');
      if (token == _searchToken && filteredList.isNotEmpty) {
        filteredList.clear();
      }
    } finally {
      if (token == _searchToken) {
        isLoading.value = false;
      }
    }
  }

  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }
}
