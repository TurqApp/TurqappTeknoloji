import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';

part 'cikmis_sorular_repository_cache_part.dart';
part 'cikmis_sorular_repository_query_part.dart';
part 'cikmis_sorular_repository_detail_part.dart';

class CikmisSorularRepository extends GetxService {
  CikmisSorularRepository({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'cikmis_sorular_repository_v3';
  final Map<String, _TimedJsonList> _memory = <String, _TimedJsonList>{};
  SharedPreferences? _prefs;

  static CikmisSorularRepository? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularRepository>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularRepository>();
  }

  static CikmisSorularRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CikmisSorularRepository(), permanent: true);
  }

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
