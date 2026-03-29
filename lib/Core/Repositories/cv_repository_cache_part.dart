part of 'cv_repository.dart';

extension CvRepositoryCachePart on CvRepository {
  Future<Map<String, dynamic>?> getCv(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return null;

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(uid);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(uid);
      if (disk != null) {
        return _cloneCvMap(disk);
      }
    }

    if (cacheOnly) return null;

    final snap =
        await FirebaseFirestore.instance.collection('CV').doc(uid).get();
    final data = snap.exists && snap.data() != null
        ? Map<String, dynamic>.from(snap.data()!)
        : null;
    await setCv(uid, data);
    return data == null ? null : _cloneCvMap(data);
  }

  Future<void> setCv(String uid, Map<String, dynamic>? data) async {
    if (uid.isEmpty) return;
    final cachedAt = DateTime.now();
    _memory[uid] = _CachedCv(
      data: data == null ? null : _cloneCvMap(data),
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(uid),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> updateCvFields(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty || data.isEmpty) return;
    await FirebaseFirestore.instance.collection('CV').doc(uid).update(data);
    final current = await getCv(uid, preferCache: true, forceRefresh: false) ??
        <String, dynamic>{};
    final merged = _cloneCvMap(current)..addAll(_cloneCvMap(data));
    await setCv(uid, merged);
  }

  Future<void> invalidate(String uid) async {
    _memory.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
  }

  Map<String, dynamic>? _getFromMemory(String uid) {
    final entry = _memory[uid];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= CvRepository._ttl;
    if (!fresh) {
      _memory.remove(uid);
      return null;
    }
    return entry.data == null ? null : _cloneCvMap(entry.data!);
  }

  Future<Map<String, dynamic>?> _getFromPrefs(String uid) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKey(uid);
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
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh = DateTime.now().difference(cachedAt) <= CvRepository._ttl;
      if (!fresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final data = decoded['data'];
      Map<String, dynamic>? mapped;
      if (data is Map<String, dynamic>) {
        mapped = _cloneCvMap(data);
      } else if (data is Map) {
        mapped = _cloneCvMap(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      if (mapped == null) {
        await prefs?.remove(prefsKey);
        return null;
      }
      _memory[uid] = _CachedCv(data: _cloneCvMap(mapped), cachedAt: cachedAt);
      return _cloneCvMap(mapped);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  String _prefsKey(String uid) => '${CvRepository._prefsPrefix}:$uid';

  Map<String, dynamic> _cloneCvMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _cloneCvValue(value)));
  }

  dynamic _cloneCvValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _cloneCvValue(child)),
      );
    }
    if (value is List) {
      return value.map(_cloneCvValue).toList(growable: false);
    }
    return value;
  }
}
