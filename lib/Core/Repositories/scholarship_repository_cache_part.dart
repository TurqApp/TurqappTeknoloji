part of 'scholarship_repository.dart';

extension _ScholarshipRepositoryCacheX on ScholarshipRepository {
  Map<String, dynamic>? _readMemory(String docId) {
    final cached = _memory[docId];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) >
        _scholarshipRepositoryTtl) {
      _memory.remove(docId);
      return null;
    }
    return cached.data;
  }

  Future<Map<String, dynamic>?> _readPrefs(String docId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_scholarshipRepositoryPrefsPrefix$docId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _scholarshipRepositoryTtl) {
        return null;
      }
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
      '$_scholarshipRepositoryPrefsPrefix$docId',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  List<Map<String, dynamic>>? _readQueryMemory(String key) {
    final cached = _queryMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) >
        _scholarshipRepositoryTtl) {
      _queryMemory.remove(key);
      return null;
    }
    return cached.items;
  }

  Future<List<Map<String, dynamic>>?> _readQueryPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_scholarshipRepositoryPrefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _scholarshipRepositoryTtl) {
        return null;
      }
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
      '$_scholarshipRepositoryPrefsPrefix:$key',
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
      if (!key.startsWith('$_scholarshipRepositoryPrefsPrefix:')) {
        return false;
      }
      final scoped =
          key.substring('$_scholarshipRepositoryPrefsPrefix:'.length);
      return scoped.startsWith(prefix);
    }).toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  bool? _readApplyMemory(String key) {
    final cached = _applyMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) >
        _scholarshipRepositoryTtl) {
      _applyMemory.remove(key);
      return null;
    }
    return cached.value;
  }

  Future<bool?> _readApplyPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_scholarshipRepositoryApplyPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _scholarshipRepositoryTtl) {
        return null;
      }
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
      '$_scholarshipRepositoryApplyPrefix$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'value': value,
      }),
    );
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_scholarshipRepositoryPrefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw =
        _prefs?.getString('$_scholarshipRepositoryPrefsPrefix:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _scholarshipRepositoryTtl;
      if (!fresh) return null;
      return Map<String, dynamic>.from(
        (decoded['data'] as Map?) ?? const <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }
}
