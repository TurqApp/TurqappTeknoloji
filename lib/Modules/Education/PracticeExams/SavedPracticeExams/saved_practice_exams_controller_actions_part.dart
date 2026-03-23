part of 'saved_practice_exams_controller.dart';

extension SavedPracticeExamsControllerActionsPart
    on SavedPracticeExamsController {
  Future<void> _toggleSavedExamImpl(String docId) async {
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
