part of 'saved_tests_controller.dart';

extension SavedTestsControllerDataPart on SavedTestsController {
  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      final items = await _testRepository.fetchFavorites(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:saved:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
