part of 'saved_practice_exams_controller.dart';

extension SavedPracticeExamsControllerDataPart on SavedPracticeExamsController {
  Future<void> _bootstrapDataImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;

    final savedEntries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'saved_practice_exams',
      orderByField: 'timeStamp',
      descending: true,
      cacheOnly: true,
    );
    final cachedIds = savedEntries.map((doc) => doc.id).toList(growable: false);
    if (!_sameIds(cachedIds)) {
      savedExamIds.assignAll(cachedIds);
    }
    if (savedEntries.isNotEmpty) {
      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        cacheOnly: true,
      );
      if (exams.isNotEmpty) {
        if (!_sameExamEntries(savedExams, exams)) {
          savedExams.assignAll(exams);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'practice_exams:saved:$uid',
          minInterval: SavedPracticeExamsController._silentRefreshInterval,
        )) {
          unawaited(loadSavedExams(silent: true, forceRefresh: true));
        }
        return;
      }
    }
    await loadSavedExams();
  }

  Future<void> _loadSavedExamsImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;

    if (!silent || savedExams.isEmpty) {
      isLoading.value = true;
    }
    try {
      final savedEntries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'saved_practice_exams',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      final nextIds = savedEntries.map((doc) => doc.id).toList(growable: false);
      if (!_sameIds(nextIds)) {
        savedExamIds.assignAll(nextIds);
      }
      if (savedEntries.isEmpty) {
        if (savedExams.isNotEmpty) {
          savedExams.clear();
        }
        return;
      }

      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        preferCache: !forceRefresh,
      );
      if (!_sameExamEntries(savedExams, exams)) {
        savedExams.assignAll(exams);
      }
      SilentRefreshGate.markRefreshed('practice_exams:saved:$uid');
    } finally {
      isLoading.value = false;
    }
  }
}
