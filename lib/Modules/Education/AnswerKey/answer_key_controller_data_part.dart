part of 'answer_key_controller.dart';

extension AnswerKeyControllerDataPart on AnswerKeyController {
  bool _sameBookletList(List<BookletModel> next) {
    return _sameBookletEntries(bookList, next);
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

  void _handleControllerInit() {
    unawaited(_restoreListingSelection());
    scrollController.addListener(_onScroll);
    unawaited(_bootstrapInitialData());
  }

  void _handleControllerClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
  }

  Future<void> _bootstrapInitialData() async {
    await warmAnswerKeyContentSavedIdsForCurrentUser();
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _answerKeySnapshotRepository
        .openHome(userId: userId, limit: AnswerKeyController._pageSize)
        .listen(_applyHomeSnapshotResource);
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !hasActiveSearch &&
        !isLoadingMore.value &&
        hasMore.value) {
      loadMore();
    }
  }

  Future<void> refreshData() async {
    final hadLocalItems = bookList.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final resource = await _answerKeySnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: AnswerKeyController._pageSize,
      );
      final items = resource.data ?? const <BookletModel>[];
      if (!_sameBookletList(items)) {
        bookList.assignAll(items);
      }
      hasMore.value = items.length >= AnswerKeyController._pageSize;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _bookletRepository.fetchPage(
        startAfter: _lastDocument,
        limit: AnswerKeyController._pageSize,
      );
      bookList.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _applyHomeSnapshotResource(
    CachedResource<List<BookletModel>> resource,
  ) {
    final items = resource.data ?? const <BookletModel>[];
    if (items.isNotEmpty) {
      if (!_sameBookletList(items)) {
        bookList.assignAll(items);
      }
      hasMore.value = items.length >= AnswerKeyController._pageSize;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (bookList.isEmpty) {
      isLoading.value = true;
    }
  }
}
