part of 'practice_exam_repository.dart';

class PracticeExamRepository extends GetxService {
  PracticeExamRepository({FirebaseFirestore? firestore})
      : _state = _PracticeExamRepositoryState(firestore: firestore);

  final _PracticeExamRepositoryState _state;

  @override
  void onInit() {
    super.onInit();
    _PracticeExamRepositoryLifecyclePart(this).handleOnInit();
  }
}

extension _PracticeExamRepositoryLifecyclePart on PracticeExamRepository {
  void handleOnInit() {
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
