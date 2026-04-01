part of 'lesson_based_tests_controller.dart';

extension LessonBasedTestsControllerRuntimePart on LessonBasedTestsController {
  void handleRuntimeInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final cached = (await _testSnapshotRepository.loadCachedType(
          userId: uid,
          testType: testTuru,
        ))
            .data ??
        const <TestsModel>[];
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

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      final items = forceRefresh
          ? ((await _testSnapshotRepository.loadType(
                userId: uid,
                testType: testTuru,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[])
          : ((await _testSnapshotRepository.loadCachedType(
                userId: uid,
                testType: testTuru,
              ))
                  .data ??
              (await _testSnapshotRepository.loadType(
                userId: uid,
                testType: testTuru,
                forceSync: true,
              ))
                  .data ??
              const <TestsModel>[]);
      list.assignAll(items);
      SilentRefreshGate.markRefreshed('tests:type:$testTuru');
    } finally {
      isLoading.value = false;
    }
  }
}
