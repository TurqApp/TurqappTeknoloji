part of 'job_repository.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _state = _JobRepositoryState(
          firestore: firestore ?? FirebaseFirestore.instance,
        );

  final _JobRepositoryState _state;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';

  static JobRepository? maybeFind() =>
      Get.isRegistered<JobRepository>() ? Get.find<JobRepository>() : null;

  static JobRepository ensure() =>
      maybeFind() ?? Get.put(JobRepository(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
