part of 'tests_controller_library.dart';

extension TestsControllerDataPart on TestsController {
  String get _snapshotUserId {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    return uid.isEmpty ? 'guest' : uid;
  }

  void _handleControllerInit() {
    unawaited(_bootstrapData());
    _bindScrollControl();
  }

  void _handleControllerClose() {
    scrollController.dispose();
  }

  Future<void> _bootstrapData() async {
    final cached = (await _testSnapshotRepository.loadCachedSharedPage(
          userId: _snapshotUserId,
          page: 1,
          limit: TestsController._pageSize,
        ))
            .data ??
        const <TestsModel>[];
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      hasMore.value = cached.length >= TestsController._pageSize;
      _currentPage = 1;
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
    _currentPage = 1;
    try {
      final items = forceRefresh
          ? ((await _testSnapshotRepository.loadSharedPage(
                userId: _snapshotUserId,
                page: 1,
                limit: TestsController._pageSize,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[])
          : ((await _testSnapshotRepository.loadCachedSharedPage(
                userId: _snapshotUserId,
                page: 1,
                limit: TestsController._pageSize,
              ))
                  .data ??
              (await _testSnapshotRepository.loadSharedPage(
                userId: _snapshotUserId,
                page: 1,
                limit: TestsController._pageSize,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[]);
      list.assignAll(items);
      hasMore.value = items.length >= TestsController._pageSize;
      SilentRefreshGate.markRefreshed('tests:shared');
    } catch (e) {
      log('TestsController.getData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final items = (await _testSnapshotRepository.loadSharedPage(
            userId: _snapshotUserId,
            page: nextPage,
            limit: TestsController._pageSize,
            forceSync: true,
          ))
              .data ??
          const <TestsModel>[];
      if (items.isEmpty) {
        hasMore.value = false;
        return;
      }
      list.addAll(items);
      _currentPage = nextPage;
      hasMore.value = items.length >= TestsController._pageSize;
    } catch (e) {
      log('TestsController.loadMore error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
