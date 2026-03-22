import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

part 'optical_form_repository_query_part.dart';
part 'optical_form_repository_action_part.dart';

class OpticalFormRepository extends GetxService {
  OpticalFormRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'optical_form_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;

  static OpticalFormRepository? maybeFind() {
    final isRegistered = Get.isRegistered<OpticalFormRepository>();
    if (!isRegistered) return null;
    return Get.find<OpticalFormRepository>();
  }

  static OpticalFormRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(OpticalFormRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<Map<String, dynamic>?> _getCachedMap(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is Map<String, dynamic>) return cached;
    return null;
  }

  Future<int?> _getCachedInt(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is int) return cached;
    return null;
  }

  Future<List<String>?> _getCachedStringList(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is List) {
      return cached.map((e) => e.toString()).toList(growable: false);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is List) {
      return cached
          .map((e) => Map<String, dynamic>.from((e as Map)))
          .toList(growable: false);
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null && DateTime.now().difference(memory.cachedAt) <= _ttl) {
      return memory.value;
    }
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
          _ttl) {
        return null;
      }
      final value = decoded['v'];
      _memory[key] = _TimedValue<dynamic>(
        value: value,
        cachedAt: DateTime.now(),
      );
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storePrimitive(key, value);

  Future<void> _storePrimitive(String key, dynamic value) async {
    final now = DateTime.now();
    _memory[key] = _TimedValue<dynamic>(value: value, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$key',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'v': value,
      }),
    );
  }
}

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
