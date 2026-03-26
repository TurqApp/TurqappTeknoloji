part of 'tutoring_repository.dart';

class TutoringRepository extends GetxService {
  TutoringRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'tutoring_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;
  static const int _thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    _handleTutoringRepositoryInit(this);
  }

  static TutoringRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringRepository>();
    if (!isRegistered) return null;
    return Get.find<TutoringRepository>();
  }

  static TutoringRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringRepository(), permanent: true);
  }
}
