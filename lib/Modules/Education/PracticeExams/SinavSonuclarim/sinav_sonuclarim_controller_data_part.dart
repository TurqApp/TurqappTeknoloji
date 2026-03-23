part of 'sinav_sonuclarim_controller.dart';

extension SinavSonuclarimControllerDataPart on SinavSonuclarimController {
  Future<void> _bootstrapDataImpl() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty) return;
    final cached = await _practiceExamRepository.fetchAnsweredByUser(
      currentUserID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      if (!_sameExamEntries(list, cached)) {
        list.assignAll(cached);
      }
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'practice_exams:results:$currentUserID',
        minInterval: SinavSonuclarimController._silentRefreshInterval,
      )) {
        unawaited(findAndGetSinavlar(silent: true, forceRefresh: true));
      }
      return;
    }
    await findAndGetSinavlar();
  }

  Future<void> _findAndGetSinavlarImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final currentUserID = CurrentUserService.instance.effectiveUserId;
      final exams = await _practiceExamRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameExamEntries(list, exams)) {
        list.assignAll(exams);
      }
      SilentRefreshGate.markRefreshed('practice_exams:results:$currentUserID');
    } catch (e) {
      log("SinavSonuclarimController error: $e");
      AppSnackbar('common.error'.tr, 'tests.results_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
