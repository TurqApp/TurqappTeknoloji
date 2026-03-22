part of 'lesson_based_tests_controller.dart';

extension LessonBasedTestsControllerDataPart on LessonBasedTestsController {
  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final items = await _testRepository.fetchByType(
        testTuru,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:type:$testTuru');
    } finally {
      isLoading.value = false;
    }
  }
}
