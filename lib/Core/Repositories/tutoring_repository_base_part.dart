part of 'tutoring_repository.dart';

abstract class _TutoringRepositoryBase extends GetxService {
  _TutoringRepositoryBase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleTutoringRepositoryInit(this as TutoringRepository);
  }
}
