part of 'my_test_results_controller.dart';

extension MyTestResultsControllerRuntimePart on MyTestResultsController {
  void handleRuntimeInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    final cached = await _testRepository.fetchAnsweredByUser(
      currentUserID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:answered:$currentUserID',
        minInterval: MyTestResultsController._silentRefreshInterval,
      )) {
        unawaited(findAndGetTestler(silent: true, forceRefresh: true));
      }
      return;
    }
    await findAndGetTestler();
  }

  Future<void> findAndGetTestler({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final currentUserID = CurrentUserService.instance.effectiveUserId;
      final items = await _testRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:answered:$currentUserID');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
