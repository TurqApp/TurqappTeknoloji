import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';

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

  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final memory = _memory[key];
    if (memory != null && DateTime.now().difference(memory.cachedAt) <= _ttl) {
      return List<Map<String, dynamic>>.from(memory.items);
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      await prefs.remove('$_prefsPrefix::$key');
      return null;
    }
    final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    _memory[key] = _TimedJsonList(items: items, cachedAt: DateTime.now());
    return items;
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    _memory[key] = _TimedJsonList(
      items: List<Map<String, dynamic>>.from(items),
      cachedAt: DateTime.now(),
    );
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsPrefix::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
  }
}

class _TimedJsonList {
  const _TimedJsonList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}
