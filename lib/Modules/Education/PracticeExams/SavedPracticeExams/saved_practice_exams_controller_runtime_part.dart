part of 'saved_practice_exams_controller.dart';

extension _SavedPracticeExamsControllerRuntimeX
    on SavedPracticeExamsController {
  void handleOnInit() {
    unawaited(_bootstrapDataImpl());
  }

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

  Future<void> loadSavedExams({
    bool silent = false,
    bool forceRefresh = false,
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

  Future<void> toggleSavedExam(String docId) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;

    if (savedExamIds.contains(docId)) {
      savedExamIds.remove(docId);
      savedExams.removeWhere((exam) => exam.docID == docId);
      await _subcollectionRepository.deleteEntry(
        uid,
        subcollection: 'saved_practice_exams',
        docId: docId,
      );
      return;
    }

    savedExamIds.add(docId);
    await _subcollectionRepository.upsertEntry(
      uid,
      subcollection: 'saved_practice_exams',
      docId: docId,
      data: {
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
