part of 'cikmis_sorular_repository.dart';

abstract class _CikmisSorularRepositoryBase extends GetxService {
  _CikmisSorularRepositoryBase({
    required FirebaseStorage storage,
  }) : _storage = storage;

  final FirebaseStorage _storage;
  final Map<String, _TimedJsonList> _memory = <String, _TimedJsonList>{};
  SharedPreferences? _prefs;
}
