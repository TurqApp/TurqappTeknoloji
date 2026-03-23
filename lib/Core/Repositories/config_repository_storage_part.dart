part of 'config_repository.dart';

extension ConfigRepositoryStoragePart on ConfigRepository {
  Future<void> _putAdminConfigDocImpl(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (docId.isEmpty) return;
    final key = _docKeyImpl(docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedConfigDoc(
      data: Map<String, dynamic>.from(data),
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
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
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKeyImpl(key));
  }

  Future<void> _putLegacyConfigDocImpl({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final key = _legacyDocKeyImpl(collection, docId);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedConfigDoc(
      data: Map<String, dynamic>.from(data),
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
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
      return null;
    }
    return Map<String, dynamic>.from(entry.data);
  }

  Future<Map<String, dynamic>?> _getFromPrefsImpl(
    String key, {
    required Duration ttl,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKeyImpl(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
      if (ts <= 0 || data == null) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > ttl) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  String _docKeyImpl(String docId) => 'adminConfig:$docId';

  String _legacyDocKeyImpl(String collection, String docId) =>
      'legacy:$collection:$docId';

  String _prefsKeyImpl(String key) =>
      '${ConfigRepository._prefsKeyPrefix}:$key';
}
