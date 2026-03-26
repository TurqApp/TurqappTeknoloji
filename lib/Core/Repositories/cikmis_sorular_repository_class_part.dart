part of 'cikmis_sorular_repository.dart';

class CikmisSorularRepository extends _CikmisSorularRepositoryBase {
  CikmisSorularRepository({
    FirebaseStorage? storage,
  }) : super(storage: storage ?? FirebaseStorage.instance);

  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'cikmis_sorular_repository_v3';

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<List<Map<String, dynamic>>?> _readList(String key) =>
      _CikmisSorularRepositoryCachePart(this)._readList(key);

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) =>
      _CikmisSorularRepositoryCachePart(this)._writeList(key, items);
}
