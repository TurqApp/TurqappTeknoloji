part of 'job_repository.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _state = _JobRepositoryState(
          firestore: firestore ?? AppFirestore.instance,
        );

  final _JobRepositoryState _state;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';

  @override
  void onInit() {
    super.onInit();
    ensureLocalPreferenceRepository()
        .sharedPreferences()
        .then((prefs) => _prefs = prefs);
  }
}
