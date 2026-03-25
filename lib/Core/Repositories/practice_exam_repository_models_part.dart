part of 'practice_exam_repository.dart';

class PracticeExamPage {
  const PracticeExamPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<SinavModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedPracticeExams {
  const _TimedPracticeExams({
    required this.items,
    required this.cachedAt,
  });

  final List<SinavModel> items;
  final DateTime cachedAt;
}

class _TimedPracticeExamBool {
  const _TimedPracticeExamBool({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
