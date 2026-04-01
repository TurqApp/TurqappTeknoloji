part of 'job_repository.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _state = _JobRepositoryState(
          firestore: firestore ?? FirebaseFirestore.instance,
        );

  final _JobRepositoryState _state;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
