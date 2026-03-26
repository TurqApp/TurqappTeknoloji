part of 'booklet_repository.dart';

class BookletRepository extends GetxService {
  BookletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'booklet_repository_v1';
  final Map<String, _TimedBooklets> _memory = <String, _TimedBooklets>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleBookletRepositoryInit();
  }
}

BookletRepository? maybeFindBookletRepository() {
  final isRegistered = Get.isRegistered<BookletRepository>();
  if (!isRegistered) return null;
  return Get.find<BookletRepository>();
}

BookletRepository ensureBookletRepository() {
  final existing = maybeFindBookletRepository();
  if (existing != null) return existing;
  return Get.put(BookletRepository(), permanent: true);
}
