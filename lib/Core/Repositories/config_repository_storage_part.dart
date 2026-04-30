part of 'config_repository.dart';

extension ConfigRepositoryStoragePart on ConfigRepository {
  int _asIntImpl(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  Future<void> _putAdminConfigDocImpl(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (docId.isEmpty) return;
    final key = _docKeyImpl(docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedConfigDoc(
      data: _cloneMapImpl(data),
      cachedAt: cachedAt,
    );
    final preferences = _preferences ??= ensureLocalPreferenceRepository();
    await preferences.setString(
      _prefsKeyImpl(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'd': data,
      }),
    );
  }

  Future<void> _invalidateAdminConfigDocImpl(String docId) async {
    final key = _docKeyImpl(docId);
    _memory.remove(key);
    final preferences = _preferences ??= ensureLocalPreferenceRepository();
    await preferences.remove(_prefsKeyImpl(key));
  }

  Future<void> _putLegacyConfigDocImpl({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final key = _legacyDocKeyImpl(collection, docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedConfigDoc(
      data: _cloneMapImpl(data),
      cachedAt: cachedAt,
    );
    final preferences = _preferences ??= ensureLocalPreferenceRepository();
    await preferences.setString(
      _prefsKeyImpl(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'd': data,
      }),
    );
  }

  Map<String, dynamic>? _getFromMemoryImpl(
    String key, {
    required Duration ttl,
  }) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > ttl) {
      _memory.remove(key);
      return null;
    }
    return _cloneMapImpl(entry.data);
  }

  Future<Map<String, dynamic>?> _getFromPrefsImpl(
    String key, {
    required Duration ttl,
  }) async {
    final preferences = _preferences ??= ensureLocalPreferenceRepository();
    final prefsKey = _prefsKeyImpl(key);
    final raw = await preferences.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await preferences.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = _asIntImpl(decoded['t']);
      final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
      if (ts <= 0 || data == null) {
        await preferences.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > ttl) {
        await preferences.remove(prefsKey);
        return null;
      }
      return _cloneMapImpl(data);
    } catch (_) {
      await preferences.remove(prefsKey);
      return null;
    }
  }

  String _docKeyImpl(String docId) => 'adminConfig:$docId';

  String _legacyDocKeyImpl(String collection, String docId) =>
      'legacy:$collection:$docId';

  String _prefsKeyImpl(String key) =>
      '${ConfigRepository._prefsKeyPrefix}:$key';

  Map<String, dynamic> _cloneMapImpl(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _cloneValueImpl(value)));
  }

  dynamic _cloneValueImpl(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _cloneValueImpl(child)),
      );
    }
    if (value is List) {
      return value.map(_cloneValueImpl).toList(growable: false);
    }
    return value;
  }
}
