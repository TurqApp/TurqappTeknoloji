part of 'practice_exam_repository.dart';

class _PracticeExamRepositoryState {
  _PracticeExamRepositoryState({FirebaseFirestore? firestore})
      : firestore = firestore ?? AppFirestore.instance;

  final FirebaseFirestore firestore;
  final Map<String, _TimedPracticeExams> memory =
      <String, _TimedPracticeExams>{};
  final Map<String, _TimedPracticeExamBool> boolMemory =
      <String, _TimedPracticeExamBool>{};
  SharedPreferences? prefs;
}

extension PracticeExamRepositoryFieldsPart on PracticeExamRepository {
  FirebaseFirestore get _firestore => _state.firestore;
  Map<String, _TimedPracticeExams> get _memory => _state.memory;
  Map<String, _TimedPracticeExamBool> get _boolMemory => _state.boolMemory;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
}
