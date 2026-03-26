part of 'test_repository_parts.dart';

class TestRepository extends GetxService {
  TestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'test_repository_v1';
  final Map<String, _TimedTests> _memory = <String, _TimedTests>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleTestRepositoryInit(this);
  }
}
