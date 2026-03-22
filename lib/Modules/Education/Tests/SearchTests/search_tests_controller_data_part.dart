part of 'search_tests_controller.dart';

extension SearchTestsControllerDataPart on SearchTestsController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.focusScope?.requestFocus(focusNode);
    });
  }

  void _handleControllerClose() {
    searchController.dispose();
    focusNode.dispose();
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchAll(cacheOnly: true);
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      filteredList.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:search_all',
        minInterval: SearchTestsController._silentRefreshInterval,
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
    final items = await _testRepository.fetchAll(
      preferCache: !forceRefresh,
      forceRefresh: forceRefresh,
    );
    list.assignAll(items);
    filterSearchResults(searchController.text);
    SilentRefreshGate.markRefreshed('tests:search_all');
    isLoading.value = false;
  }
}
