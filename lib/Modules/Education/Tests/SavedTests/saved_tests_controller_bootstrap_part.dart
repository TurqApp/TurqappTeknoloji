part of 'saved_tests_controller.dart';

extension SavedTestsControllerBootstrapPart on SavedTestsController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final cached = await _testRepository.fetchFavorites(
      uid,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:saved:$uid',
        minInterval: SavedTestsController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }
}
