part of 'practice_exam_repository.dart';

extension _PracticeExamRepositoryLifecyclePart on PracticeExamRepository {
  void handleOnInit() {
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
