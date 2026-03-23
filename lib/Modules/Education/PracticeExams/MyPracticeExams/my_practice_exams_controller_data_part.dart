part of 'my_practice_exams_controller.dart';

extension MyPracticeExamsControllerDataPart on MyPracticeExamsController {
  Future<void> _bootstrapExamsImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    try {
      final cached = await _practiceExamRepository.fetchByOwner(uid);
      if (cached.isNotEmpty) {
        if (!_sameExamEntries(exams, cached)) {
          exams.assignAll(cached);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'practice_exams:owner:$uid',
          minInterval: MyPracticeExamsController._silentRefreshInterval,
        )) {
          unawaited(fetchExams(silent: true, forceRefresh: true));
        }
        return;
      }
    } catch (_) {}

    await fetchExams();
  }

  Future<void> _fetchExamsImpl({
    required bool forceRefresh,
    required bool silent,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      exams.clear();
      isLoading.value = false;
      return;
    }

    final shouldShowLoader = !silent && exams.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final items = await _practiceExamRepository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameExamEntries(exams, items)) {
        exams.assignAll(items);
      }
      SilentRefreshGate.markRefreshed('practice_exams:owner:$uid');
    } catch (e) {
      log('MyPracticeExamsController.fetchExams error: $e');
      AppSnackbar('common.error'.tr, 'tests.exams_load_failed'.tr);
    } finally {
      if (shouldShowLoader || exams.isEmpty) {
        isLoading.value = false;
      }
    }
  }
}
