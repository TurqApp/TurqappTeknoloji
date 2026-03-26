part of 'tests_controller_library.dart';

extension TestsControllerDataPart on TestsController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
    _bindScrollControl();
  }

  void _handleControllerClose() {
    scrollController.dispose();
  }

  Future<void> _bootstrapData() async {
    final cachedPage = await _testRepository.fetchSharedPage(
      limit: TestsController._pageSize,
      cacheOnly: true,
    );
    if (cachedPage.items.isNotEmpty) {
      list.assignAll(cachedPage.items);
      hasMore.value = cachedPage.hasMore;
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:shared',
        minInterval: TestsController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _lastDocument = null;
    try {
      final page = await _testRepository.fetchSharedPage(
        limit: TestsController._pageSize,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
      SilentRefreshGate.markRefreshed('tests:shared');
    } catch (e) {
      log('TestsController.getData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _testRepository.fetchSharedPage(
        startAfter: _lastDocument,
        limit: TestsController._pageSize,
      );
      list.addAll(page.items);
      _lastDocument = page.lastDocument;
      hasMore.value = page.hasMore;
    } catch (e) {
      log('TestsController.loadMore error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
