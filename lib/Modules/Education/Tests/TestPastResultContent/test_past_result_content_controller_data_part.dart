part of 'test_past_result_content_controller.dart';

extension TestPastResultContentControllerDataPart
    on TestPastResultContentController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchAnswers(
      model.docID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      _applySnapshot(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:past_result:${model.docID}',
        minInterval: TestPastResultContentController._silentRefreshInterval,
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
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final snapshot = await _testRepository.fetchAnswers(
        model.docID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      _applySnapshot(snapshot);
      SilentRefreshGate.markRefreshed('tests:past_result:${model.docID}');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
