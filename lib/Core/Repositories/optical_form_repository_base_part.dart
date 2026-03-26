part of 'optical_form_repository.dart';

class _TimedValue<T> {
  const _TimedValue({required this.value, required this.cachedAt});

  final T value;
  final DateTime cachedAt;
}

class OpticalFormRepository extends _OpticalFormRepositoryBase {
  static const Duration _ttl = _OpticalFormRepositoryBase._ttl;
  static const String _prefsPrefix = _OpticalFormRepositoryBase._prefsPrefix;

  OpticalFormRepository({FirebaseFirestore? firestore})
      : super(firestore: firestore);
}

abstract class _OpticalFormRepositoryBase extends GetxService {
  _OpticalFormRepositoryBase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'optical_form_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
