part of 'cikmis_sorular_repository.dart';

class CikmisSorularRepository extends GetxService {
  CikmisSorularRepository({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'cikmis_sorular_repository_v3';
  final Map<String, _TimedJsonList> _memory = <String, _TimedJsonList>{};
  SharedPreferences? _prefs;

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
