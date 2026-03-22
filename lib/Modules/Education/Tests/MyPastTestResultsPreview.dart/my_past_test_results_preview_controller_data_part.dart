part of 'my_past_test_results_preview_controller.dart';

extension MyPastTestResultsPreviewControllerDataPart
    on MyPastTestResultsPreviewController {
  void _handleControllerInit() {
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cachedAnswers = await _testRepository.fetchAnswers(
      model.docID,
      cacheOnly: true,
    );
    final cachedQuestions = await _testRepository.fetchQuestions(
      model.docID,
      cacheOnly: true,
    );
    if (cachedAnswers.isNotEmpty || cachedQuestions.isNotEmpty) {
      _applyAnswers(cachedAnswers);
      soruList.assignAll(cachedQuestions);
      updateStats();
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:preview:${model.docID}',
        minInterval: MyPastTestResultsPreviewController._silentRefreshInterval,
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
      final yanitSnapshot = await _testRepository.fetchAnswers(
        model.docID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      _applyAnswers(yanitSnapshot);

      final soruSnapshot = await _testRepository.fetchQuestions(
        model.docID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      soruList.assignAll(soruSnapshot);

      updateStats();
      SilentRefreshGate.markRefreshed('tests:preview:${model.docID}');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _applyAnswers(List<Map<String, dynamic>> snapshot) {
    yanitlar.clear();
    timeStamp.value = 0;
    for (final doc in snapshot) {
      yanitlar.assignAll(List<String>.from(doc['cevaplar'] ?? const []));
      timeStamp.value = ((doc['timeStamp'] ?? 0) as num).toInt();
    }
  }

  void updateStats() {
    dogruSayisi.value = 0;
    yanlisSayisi.value = 0;
    bosSayisi.value = 0;

    for (var i = 0; i < yanitlar.length && i < soruList.length; i++) {
      if (yanitlar[i] == '') {
        bosSayisi.value++;
      } else if (yanitlar[i] == soruList[i].dogruCevap) {
        dogruSayisi.value++;
      } else {
        yanlisSayisi.value++;
      }
    }

    totalPuan.value =
        soruList.isNotEmpty ? (100 / soruList.length) * dogruSayisi.value : 0;
  }
}
