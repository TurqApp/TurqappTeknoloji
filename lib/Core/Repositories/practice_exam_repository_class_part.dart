part of 'practice_exam_repository.dart';

class PracticeExamRepository extends GetxService {
  PracticeExamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'practice_exam_repository_v1';
  final Map<String, _TimedPracticeExams> _memory =
      <String, _TimedPracticeExams>{};
  final Map<String, _TimedPracticeExamBool> _boolMemory =
      <String, _TimedPracticeExamBool>{};
  SharedPreferences? _prefs;

  static PracticeExamRepository? maybeFind() {
    final isRegistered = Get.isRegistered<PracticeExamRepository>();
    if (!isRegistered) return null;
    return Get.find<PracticeExamRepository>();
  }

  static PracticeExamRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PracticeExamRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _PracticeExamRepositoryLifecyclePart(this).handleOnInit();
  }
}
