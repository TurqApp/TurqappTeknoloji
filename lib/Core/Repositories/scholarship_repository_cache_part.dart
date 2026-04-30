part of 'scholarship_repository.dart';

extension _ScholarshipRepositoryCacheX on ScholarshipRepository {
  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  Map<String, dynamic>? _readMemory(String docId) {
    final cached = _memory[docId];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) >
        _scholarshipRepositoryTtl) {
      _memory.remove(docId);
      return null;
    }
    return _cloneDoc(cached.data);
  }

  Future<Map<String, dynamic>?> _readPrefs(String docId) async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    final prefs = _prefs;
    final prefsKey = '$_scholarshipRepositoryPrefsPrefix$docId';
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final savedAt = _asInt(decoded['savedAt']);
      if (savedAt <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _scholarshipRepositoryTtl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        await prefs?.remove(prefsKey);
        return null;
      }
      return _cloneDoc(data);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _store(String docId, Map<String, dynamic> data) async {
    _memory[docId] = _TimedScholarship(
      data: _cloneDoc(data),
      cachedAt: DateTime.now(),
    );
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.setString(
      '$_scholarshipRepositoryPrefsPrefix$docId',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> _removeDocCache(String docId) async {
    final cleanId = docId.trim();
    if (cleanId.isEmpty) return;
    _memory.remove(cleanId);
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.remove('$_scholarshipRepositoryPrefsPrefix$cleanId');
  }

  List<Map<String, dynamic>>? _readQueryMemory(String key) {
    final cached = _queryMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) >
        _scholarshipRepositoryTtl) {
      _queryMemory.remove(key);
      return null;
    }
    return _cloneDocs(cached.items);
  }

  Future<List<Map<String, dynamic>>?> _readQueryPrefs(String key) async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    final prefs = _prefs;
    final prefsKey = '$_scholarshipRepositoryPrefsPrefix:$key';
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final savedAt = _asInt(decoded['savedAt']);
      if (savedAt <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _scholarshipRepositoryTtl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => _cloneDoc(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      return items;
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _storeQueryDocs(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    _queryMemory[key] = _TimedScholarshipList(
      items: _cloneDocs(items),
      cachedAt: DateTime.now(),
    );
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.setString(
      '$_scholarshipRepositoryPrefsPrefix:$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      }),
    );
  }

  Future<void> _removeRawDoc(String cacheKey) async {
    final normalized = cacheKey.trim();
    if (normalized.isEmpty) return;
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.remove('$_scholarshipRepositoryPrefsPrefix:$normalized');
  }

  Future<void> _invalidateQueryPrefix(String prefix) async {
    _queryMemory.removeWhere((key, _) => key.startsWith(prefix));
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
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
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    final prefs = _prefs;
    final prefsKey = '$_scholarshipRepositoryApplyPrefix$key';
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final savedAt = _asInt(decoded['savedAt']);
      if (savedAt <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _scholarshipRepositoryTtl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final value = decoded['value'];
      if (value is bool) return value;
      await prefs?.remove(prefsKey);
      return null;
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _storeApply(String key, bool value) async {
    _applyMemory[key] = _TimedScholarshipApply(
      value: value,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.setString(
      '$_scholarshipRepositoryApplyPrefix$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'value': value,
      }),
    );
  }

  Future<void> _removeApply(String key) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return;
    _applyMemory.remove(normalized);
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.remove('$_scholarshipRepositoryApplyPrefix$normalized');
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.setString(
      '$_scholarshipRepositoryPrefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'data': _cloneDoc(data),
      }),
    );
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    final prefs = _prefs;
    final prefsKey = '$_scholarshipRepositoryPrefsPrefix:$cacheKey';
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = _asInt(decoded['t']);
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _scholarshipRepositoryTtl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      return _cloneDoc(
        Map<String, dynamic>.from(
          (decoded['data'] as Map?) ?? const <String, dynamic>{},
        ),
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  List<Map<String, dynamic>> _cloneDocs(List<Map<String, dynamic>> items) {
    return items.map(_cloneDoc).toList(growable: false);
  }

  Map<String, dynamic> _cloneDoc(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _cloneValue(value)));
  }

  dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _cloneValue(child)),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }
}
