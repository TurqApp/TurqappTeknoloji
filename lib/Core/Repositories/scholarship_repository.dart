import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

part 'scholarship_repository_query_part.dart';
part 'scholarship_repository_action_part.dart';

class ScholarshipRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'scholarship_repository_v1:';
  static const String _applyPrefix = 'scholarship_apply_repository_v1:';
  static const String _countKey = 'scholarship_total_count_v1';

  final Map<String, _TimedScholarship> _memory = <String, _TimedScholarship>{};
  final Map<String, _TimedScholarshipList> _queryMemory =
      <String, _TimedScholarshipList>{};
  final Map<String, _TimedScholarshipApply> _applyMemory =
      <String, _TimedScholarshipApply>{};
  SharedPreferences? _prefs;

  static ScholarshipRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipRepository>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipRepository>();
  }

  static ScholarshipRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Map<String, dynamic>? _readMemory(String docId) {
    final cached = _memory[docId];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _memory.remove(docId);
      return null;
    }
    return cached.data;
  }

  Future<Map<String, dynamic>?> _readPrefs(String docId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix$docId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(String docId, Map<String, dynamic> data) async {
    _memory[docId] = _TimedScholarship(
      data: data,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix$docId',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  List<Map<String, dynamic>>? _readQueryMemory(String key) {
    final cached = _queryMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _queryMemory.remove(key);
      return null;
    }
    return cached.items;
  }

  Future<List<Map<String, dynamic>>?> _readQueryPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeQueryDocs(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    _queryMemory[key] = _TimedScholarshipList(
      items: items,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      }),
    );
  }

  Future<void> _invalidateQueryPrefix(String prefix) async {
    _queryMemory.removeWhere((key, _) => key.startsWith(prefix));
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('$_prefsPrefix:')) return false;
      final scoped = key.substring('$_prefsPrefix:'.length);
      return scoped.startsWith(prefix);
    }).toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  bool? _readApplyMemory(String key) {
    final cached = _applyMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _applyMemory.remove(key);
      return null;
    }
    return cached.value;
  }

  Future<bool?> _readApplyPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_applyPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final value = decoded['value'];
      if (value is bool) return value;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeApply(String key, bool value) async {
    _applyMemory[key] = _TimedScholarshipApply(
      value: value,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_applyPrefix$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'value': value,
      }),
    );
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _ttl;
      if (!fresh) return null;
      return Map<String, dynamic>.from(
        (decoded['data'] as Map?) ?? const <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }
}

class _TimedScholarship {
  const _TimedScholarship({
    required this.data,
    required this.cachedAt,
  });

  final Map<String, dynamic> data;
  final DateTime cachedAt;
}

class _TimedScholarshipList {
  const _TimedScholarshipList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}

class _TimedScholarshipApply {
  const _TimedScholarshipApply({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
