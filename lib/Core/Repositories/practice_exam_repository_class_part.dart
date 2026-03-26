part of 'practice_exam_repository.dart';

class PracticeExamRepository extends GetxService {
  PracticeExamRepository({FirebaseFirestore? firestore})
      : _state = _PracticeExamRepositoryState(firestore: firestore);

  final _PracticeExamRepositoryState _state;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'practice_exam_repository_v1';

  static PracticeExamRepository? maybeFind() =>
      Get.isRegistered<PracticeExamRepository>()
          ? Get.find<PracticeExamRepository>()
          : null;

  static PracticeExamRepository ensure() =>
      maybeFind() ?? Get.put(PracticeExamRepository(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    _PracticeExamRepositoryLifecyclePart(this).handleOnInit();
  }
}
