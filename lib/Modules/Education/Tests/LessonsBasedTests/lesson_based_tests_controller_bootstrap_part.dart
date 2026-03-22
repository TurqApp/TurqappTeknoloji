part of 'lesson_based_tests_controller.dart';

extension LessonBasedTestsControllerBootstrapPart
    on LessonBasedTestsController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchByType(
      testTuru,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:type:$testTuru',
        minInterval: LessonBasedTestsController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }
}
