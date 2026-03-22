part of 'my_tests_controller.dart';

extension MyTestsControllerBootstrapPart on MyTestsController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final cached = await _testRepository.fetchByOwner(
      uid,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:owner:$uid',
        minInterval: MyTestsController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }
}
