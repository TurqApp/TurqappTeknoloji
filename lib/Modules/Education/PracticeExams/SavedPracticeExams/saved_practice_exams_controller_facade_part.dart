part of 'saved_practice_exams_controller.dart';

SavedPracticeExamsController? maybeFindSavedPracticeExamsController() {
  final isRegistered = Get.isRegistered<SavedPracticeExamsController>();
  if (!isRegistered) return null;
  return Get.find<SavedPracticeExamsController>();
}

SavedPracticeExamsController ensureSavedPracticeExamsController({
  bool permanent = false,
}) {
  final existing = maybeFindSavedPracticeExamsController();
  if (existing != null) return existing;
  return Get.put(SavedPracticeExamsController(), permanent: permanent);
}

extension SavedPracticeExamsControllerFacadePart
    on SavedPracticeExamsController {
  bool _sameIds(Iterable<String> next) {
    return listEquals(
      savedExamIds.toList(growable: false),
      next.toList(growable: false),
    );
  }

  bool _sameExamEntries(List<SinavModel> current, List<SinavModel> next) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  Future<void> loadSavedExams({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _SavedPracticeExamsControllerRuntimeX(this).loadSavedExams(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> toggleSavedExam(String docId) =>
      _SavedPracticeExamsControllerRuntimeX(this).toggleSavedExam(docId);
}
