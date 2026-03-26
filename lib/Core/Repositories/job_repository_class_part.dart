part of 'job_repository.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';
  final Map<String, _TimedJobs> _memory = <String, _TimedJobs>{};
  final Map<String, _TimedBool> _boolMemory = <String, _TimedBool>{};
  SharedPreferences? _prefs;

  static JobRepository? maybeFind() {
    final isRegistered = Get.isRegistered<JobRepository>();
    if (!isRegistered) return null;
    return Get.find<JobRepository>();
  }

  static JobRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(JobRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
