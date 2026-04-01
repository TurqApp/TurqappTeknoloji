part of 'practice_exam_repository.dart';

PracticeExamRepository? maybeFindPracticeExamRepository() =>
    Get.isRegistered<PracticeExamRepository>()
        ? Get.find<PracticeExamRepository>()
        : null;

PracticeExamRepository ensurePracticeExamRepository() =>
    maybeFindPracticeExamRepository() ??
    Get.put(PracticeExamRepository(), permanent: true);
