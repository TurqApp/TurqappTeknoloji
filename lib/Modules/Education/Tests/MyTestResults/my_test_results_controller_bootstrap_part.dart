part of 'my_test_results_controller.dart';

extension MyTestResultsControllerBootstrapPart on MyTestResultsController {
  void _handleControllerInit() {
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
}
