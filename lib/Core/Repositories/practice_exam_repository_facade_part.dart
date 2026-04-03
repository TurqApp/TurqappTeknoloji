part of 'practice_exam_repository.dart';

PracticeExamRepository? maybeFindPracticeExamRepository() =>
    Get.isRegistered<PracticeExamRepository>()
        ? Get.find<PracticeExamRepository>()
        : null;

PracticeExamRepository ensurePracticeExamRepository() =>
    maybeFindPracticeExamRepository() ??
    Get.put(PracticeExamRepository(), permanent: true);

extension PracticeExamRepositoryFacadePart on PracticeExamRepository {
  Future<void> invalidateExamListingCaches({
    required String examId,
    String? userId,
  }) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty) return;

    final normalizedUserId = userId?.trim() ?? '';
    final futures = <Future<void>>[
      _removeCacheKey('doc:$normalizedExamId'),
      _removeCacheKey('raw:$normalizedExamId'),
    ];
    if (normalizedUserId.isNotEmpty) {
      futures.add(
        _removeCacheKey('application:$normalizedExamId:$normalizedUserId'),
      );
    }
    await Future.wait(futures);
    await maybeFindPracticeExamSnapshotRepository()?.invalidateAllSurfaces();
  }

  Future<void> invalidateAnswerCaches({
    required String examId,
    required String userId,
    required String answerDocId,
    Iterable<String> lessons = const <String>[],
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedUserId = userId.trim();
    final normalizedAnswerDocId = answerDocId.trim();
    if (normalizedExamId.isEmpty ||
        normalizedUserId.isEmpty ||
        normalizedAnswerDocId.isEmpty) {
      return;
    }

    final futures = <Future<void>>[
      _removeCacheKey('answers:$normalizedExamId'),
      _removeCacheKey('answers:$normalizedExamId:$normalizedUserId'),
    ];
    for (final lesson in lessons) {
      final normalizedLesson = lesson.trim();
      if (normalizedLesson.isEmpty) continue;
      futures.add(
        _removeCacheKey(
          'lesson_result:$normalizedExamId:$normalizedAnswerDocId:$normalizedLesson',
        ),
      );
    }
    await Future.wait(futures);
    await maybeFindPracticeExamSnapshotRepository()
        ?.invalidateAnsweredSurface(normalizedUserId);
  }

  Future<void> invalidateQuestionCaches({
    required String examId,
  }) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty) return;
    await _removeCacheKey('questions:$normalizedExamId');
  }
}
