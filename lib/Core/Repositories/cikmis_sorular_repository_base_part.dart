part of 'cikmis_sorular_repository_library.dart';

abstract class _CikmisSorularRepositoryBase extends GetxService {
  _CikmisSorularRepositoryBase({
    required FirebaseStorage storage,
  }) : _storage = storage;

  final FirebaseStorage _storage;
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
