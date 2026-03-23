part of 'deneme_turleri_listesi_controller.dart';

extension DenemeTurleriListesiControllerDataPart
    on DenemeTurleriListesiController {
  Future<void> _bootstrapDataImpl() async {
    final cached = await _practiceExamRepository.fetchByExamType(
      sinavTuru,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      if (!_sameExamEntries(list, cached)) {
        list.assignAll(cached);
      }
      isLoading.value = false;
      isInitialized.value = true;
      if (SilentRefreshGate.shouldRefresh(
        'practice_exams:type:$sinavTuru',
        minInterval: DenemeTurleriListesiController._silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
      return;
    }
    await getData();
  }

  Future<void> _getDataImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final items = await _practiceExamRepository.fetchByExamType(
        sinavTuru,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameExamEntries(list, items)) {
        list.assignAll(items);
      }
      SilentRefreshGate.markRefreshed('practice_exams:type:$sinavTuru');
    } catch (error) {
      AppSnackbar('common.error'.tr, 'tests.exams_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }
}
