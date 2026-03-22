part of 'my_tests_controller.dart';

extension MyTestsControllerDataPart on MyTestsController {
  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      final items = await _testRepository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:owner:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
